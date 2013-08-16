with Gnat.Command_Line; use Gnat.Command_Line;
with Sattmate_Types;    use Sattmate_Types;
with Gnat.Strings;
with Sql;
with Sattmate_Calendar; use Sattmate_Calendar;
with Logging;               use Logging;
with Text_IO;
--with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
with Simple_list_Class;
pragma Elaborate_All(Simple_List_Class);


procedure Equity is


   Sa_Par_Db            : aliased Gnat.Strings.String_Access;
   Sa_Par_Port          : aliased Gnat.Strings.String_Access;
   Sa_Par_Host          : aliased Gnat.Strings.String_Access;
   Sa_Par_Db_Pwd        : aliased Gnat.Strings.String_Access;
   Sa_Par_Db_User       : aliased Gnat.Strings.String_Access;
   Sa_Par_Sb_Bet_Name   : aliased Gnat.Strings.String_Access;
   Sa_Par_Dr_Bet_Name   : aliased Gnat.Strings.String_Access;
   Sa_Saldo             : aliased Gnat.Strings.String_Access;
   Config               : Command_Line_Configuration;
   Port                 : Natural := 5432;
   T                    : Sql.Transaction_Type;
   Dates,
   Select_Results       : Sql.Statement_Type;
   type Eos_Type is (date, data);
   Eos : array (Eos_Type'range) of Boolean := (others => False);
   First_Time: Boolean := True;
   Start_Date, Stop_Date: Sattmate_Calendar.Time_Type;
   Saldo , Profit : Float_8 := 0.0;
   Sb_Saldo , Dr_Saldo : Float_8 := 0.0;

   
   
   package Timestamps is new Simple_List_Class(Sattmate_Calendar.Time_Type);
   Timestamp_List : Timestamps.List_Type := Timestamps.Create;
   
   
   function Sort_Condition( Left, Right : Sattmate_Calendar.Time_Type) return Boolean is
    -- Sort new records in list with ascending string
      --use Sattmate_Calendar;
    begin
      return Left <= Right;
    end Sort_Condition;

    procedure Insert_Date is new Timestamps.Put( Sort_Condition);   
   
   -------------------------------
   procedure Debug (What : String) is
   begin
      Text_IO.Put_Line(Text_Io.Standard_Error, What);
   end Debug;
   pragma Warnings(Off, Debug);
   -------------------------------
   
   
begin


   Define_Switch
     (Config,
      Sa_Par_Sb_Bet_Name'access,
      Long_Switch => "--sb_betname=",
      Help        => "bet name, SB_HOUNDS_PLACE_BACK_BET");

   Define_Switch
     (Config,
      Sa_Par_Dr_Bet_Name'access,
      Long_Switch => "--dr_betname=",
      Help        => "bet name, DR_HOUNDS_PLACE_BACK_BET");

   Define_Switch
     (Config,
      Sa_Par_Host'access,
      Long_Switch => "--host=",
      Help        => "host name");

   Define_Switch
     (Config,
      Sa_Par_Db'access,
      Long_Switch => "--database=",
      Help        => "database name");

   Define_Switch
     (Config,
      Sa_Par_Port'access,
      Long_Switch => "--port=",
      Help        => "database port");

   Define_Switch
     (Config,
      Sa_Par_Db_Pwd'access,
      Long_Switch => "--pwd=",
      Help        => "database pwd");
      
   Define_Switch
     (Config,
      Sa_Par_Db_User'access,
      Long_Switch => "--user=",
      Help        => "database user");

   Define_Switch
     (Config,
      Sa_Saldo'access,
      Long_Switch => "--saldo=",
      Help        => "starting saldo");


   Getopt (Config);  -- process the command line

   if Sa_Par_Host.all = "" or else 
      Sa_Par_Db.all = "" or else
      Sa_Par_Dr_Bet_Name.all = "" or else
      Sa_Par_Sb_Bet_Name.all = "" or else
      Sa_Par_Port.all = "" or else
      Sa_Par_Db_User.all = "" or else
      Sa_Par_Db_Pwd.all = "" 
   then
     Display_Help (Config);
     return;
   end if;

   if Sa_Par_Port.all /= "" then
     Port := Natural'Value(Sa_Par_Port.all);
   end if;

   Log ("Get_database_data start: " & Sa_Par_Host.all & "/" & Sa_Par_Db.all & "/" & Port'Img);
   Sql.Connect
        (Host     => Sa_Par_Host.all,
         Port     => Port,
         Db_Name  => Sa_Par_Db.all,
         Login    => Sa_Par_Db_User.all,
         Password => Sa_Par_Db_Pwd.all);
   Log ("connected to database");
   Saldo := Float_8'Value(Sa_Saldo.all);
   T.Start;

   Dates.Prepare("select distinct(STARTTS) " & 
                 "from ABETS  " &
                 "where BETNAME in ( :SB,:DR ) " &
                 "order by STARTTS");

   Dates.Set("DR",Sa_Par_Dr_Bet_Name.all);
   Dates.Set("SB",Sa_Par_Sb_Bet_Name.all);
                 
   Dates.Open_Cursor;
   loop   
     Dates.Fetch(Eos(Date));
     exit when Eos(Date);
     Dates.Get_Timestamp(1,Start_Date);
     Insert_Date(Timestamp_List,Start_Date);
   end loop;
   Dates.Close_Cursor;
   
   -- the same thing with 15 min intervals
   Start_Date := (2013,01,30,0,0,0,0);
   Stop_Date  := (2013,08,31,0,0,0,0);
   
   loop   
     Start_Date := Start_Date + (0,0,15,0,0); --15 mins
     exit when Start_Date > Stop_Date;
     Insert_Date(Timestamp_List,Start_Date);  -- insert them sorted
   end loop;   

   
   
   Select_Results.Prepare( "select PROFIT " &
                            "from ABETS " &
                            "where BETNAME = :BETNAME " &
                            "and STARTTS = :TS");

   Sb_Saldo := Saldo; 
   Dr_Saldo := Saldo;
   -- now loop over all ts, both with db hit and 15 min interval
   while not Timestamps.Is_Empty(Timestamp_List) loop
     Timestamps.Remove_From_Head(Timestamp_List,Start_Date);
     
     Select_Results.Set_Timestamp("TS", Start_Date);
     
     --sb first
     Select_Results.Set("BETNAME", Sa_Par_SB_Bet_Name.all);
     Select_Results.Open_Cursor;
     Select_Results.Fetch(Eos(Data));
     if not Eos(Data) then
       Select_Results.Get("PROFIT", Profit);
     else
       Profit := 0.0;
     end if;
     Select_Results.Close_Cursor;
     Sb_Saldo := Sb_Saldo + Profit;
     
     -- now dr
     Select_Results.Set("BETNAME", Sa_Par_DR_Bet_Name.all);
     Select_Results.Open_Cursor;
     Select_Results.Fetch(Eos(Data));
     if not Eos(Data) then
       Select_Results.Get("PROFIT", Profit);
     else
       Profit := 0.0;
     end if;
     Select_Results.Close_Cursor;
     Dr_Saldo := Dr_Saldo + Profit;
   
   
     if First_Time then 
        Start_Date := Start_Date - (1,0,0,0,0);
        Print(Sattmate_Calendar.String_Date_ISO(Start_Date) & " " & Sattmate_Calendar.String_Time(Start_Date) & " | " &
              Integer'Image(Integer(Saldo)) & " | " & Integer'Image(Integer(Saldo)));
        First_Time := False;   
     end if;
     
--     Debug(Sattmate_Calendar.String_Date_ISO(Start_Date) & " " & Sattmate_Calendar.String_Time(Start_Date) & " | " &
--              Integer'Image(Integer(Dr_Saldo)) & " | " & Integer'Image(Integer(Sb_Saldo)));
--     
     Print(Sattmate_Calendar.String_Date_ISO(Start_Date) & " " & Sattmate_Calendar.String_Time(Start_Date) & " | " &
              Integer'Image(Integer(Dr_Saldo)) & " | " & Integer'Image(Integer(Sb_Saldo)));
   end loop;
      
   T.Commit;
   Sql.Close_Session;
   Log ("done");

end Equity;