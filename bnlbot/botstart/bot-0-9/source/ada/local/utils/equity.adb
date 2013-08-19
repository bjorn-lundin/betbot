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
with Table_Abethistory;
with Table_Abets;
with Bot_Types;

procedure Equity is
   Sa_Par_Db            : aliased Gnat.Strings.String_Access;
   Sa_Par_Port          : aliased Gnat.Strings.String_Access;
   Sa_Par_Host          : aliased Gnat.Strings.String_Access;
   Sa_Par_Db_Pwd        : aliased Gnat.Strings.String_Access;
   Sa_Par_Db_User       : aliased Gnat.Strings.String_Access;
   Sa_Par_Bet_Name   : aliased Gnat.Strings.String_Access;
   Sa_Saldo             : aliased Gnat.Strings.String_Access;
   Ia_Powerdays         : aliased Integer;
   Config               : Command_Line_Configuration;
   Port                 : Natural := 5432;
   T                    : Sql.Transaction_Type;
   Dates,
   Select_Results       : Sql.Statement_Type;
   type Eos_Type is (Date, Data, History);
   Eos : array (Eos_Type'range) of Boolean := (others => False);
   First_Time: Boolean := True;
   First_Start_Date, Start_Date, Stop_Date: Sattmate_Calendar.Time_Type;
   Profit : Float_8 := 0.0;
   type Saldo_Type is (Ref, Sim, Dry, His);
   Saldo : array (Saldo_Type'range) of Float_8 := (others => 0.0);

   Abet : Table_Abets.Data_Type;
   Abethistory : Table_Abethistory.Data_Type;

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
      Sa_Par_Bet_Name'access,
      Long_Switch => "--betname=",
      Help        => "bet name, HOUNDS_PLACE_BACK_BET");

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
      Ia_Powerdays'access,
      Long_Switch => "--powerdays=",
      Help        => "power of historyfunction and days to look back");
      
   Define_Switch
     (Config,
      Sa_Saldo'access,
      Long_Switch => "--saldo=",
      Help        => "starting saldo");

   Getopt (Config);  -- process the command line

   if Sa_Par_Host.all = "" or else 
      Sa_Par_Db.all = "" or else
      Sa_Par_Bet_Name.all = "" or else
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
   Saldo(Sim) := Float_8'Value(Sa_Saldo.all);
   T.Start;

   Dates.Prepare("select distinct(STARTTS) " & 
                 "from ABETS  " &
                 "where BETNAME = :BETNAME " &
                 "and BETMODE = 4) " & -- ref bets
                 "order by STARTTS");

   Dates.Set("BETNAME",Sa_Par_Bet_Name.all);
                 
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
   Stop_Date  := (2013,08,12,0,0,0,0);
    
   loop   
     Start_Date := Start_Date + (0,0,15,0,0); --15 mins
     exit when Start_Date > Stop_Date;
     Insert_Date(Timestamp_List,Start_Date);  -- insert them sorted
   end loop;   
   
   Select_Results.Prepare( "select * " &
                            "from ABETS " &
                            "where BETNAME = :BETNAME " &
                            "and BETMODE = :BETMODE " &
                            "and POWERDAYS = :POWERDAYS " &
                            "and STARTTS = :TS");

   Select_Results.Set("POWERDAYS", Integer_4(Ia_Powerdays));
   Select_Results.Set("BETNAME", Sa_Par_Bet_Name.all);
   
   Saldo(Dry) := Saldo(Sim);
   Saldo(Ref) := Saldo(Sim);
   Saldo(His) := 0.0;
   
   -- now loop over all ts, both with db hit and 15 min interval
   while not Timestamps.Is_Empty(Timestamp_List) loop
     Timestamps.Remove_From_Head(Timestamp_List,Start_Date);
     
     if First_Time then 
        First_Start_Date := Start_Date - (1,0,0,0,0);
        Print(Sattmate_Calendar.String_Date_ISO(First_Start_Date) & " " & Sattmate_Calendar.String_Time(First_Start_Date) & " | " &
              Integer'Image(Integer(Saldo(Ref))) & " | " &
              Integer'Image(Integer(Saldo(Dry))) & " | " &
              Integer'Image(Integer(Saldo(Sim))) & " | " &
              Integer'Image(Integer(Saldo(His))));
        First_Time := False;   
     end if;
     
     Select_Results.Set_Timestamp("TS", Start_Date);
     
     --ref first
     Select_Results.Set("BETMODE",  Bot_Types.Bet_Mode(Bot_Types.Ref));
     Select_Results.Open_Cursor;
     Select_Results.Fetch(Eos(Data));
     if not Eos(Data) then
       Select_Results.Get("PROFIT", Profit);
     else
       Profit := 0.0;
     end if;
     Select_Results.Close_Cursor;
     Saldo(Ref) := Saldo(Ref) + Profit;
     
     --then sb
     Select_Results.Set("BETMODE",  Bot_Types.Bet_Mode(Bot_Types.Sim));
     Select_Results.Open_Cursor;
     Select_Results.Fetch(Eos(Data));
     if not Eos(Data) then
       Select_Results.Get("PROFIT", Profit);
     else
       Profit := 0.0;
     end if;
     Select_Results.Close_Cursor;
     Saldo(Sim) := Saldo(Sim) + Profit;
       
     
     -- now dr
     Select_Results.Set("BETMODE",  Bot_Types.Bet_Mode(Bot_Types.Dry));
     Select_Results.Open_Cursor;
     Select_Results.Fetch(Eos(Data));
     if not Eos(Data) then
      -- Select_Results.Get("PROFIT", Profit);
       Abet := Table_Abets.Get(Select_Results); 
       Profit := Abet.Profit;
       
       Abethistory.Betid := Abet.Betid;
       Abethistory.Powerdays := Integer_4(Ia_Powerdays);
       Table_Abethistory.Read(Abethistory,Eos(History));
       if not Eos(History) then
         Saldo(His) := Abethistory.Historysum;
       end if;
     else
       Profit := 0.0;
     end if;
     Select_Results.Close_Cursor;
     Saldo(Dry) := Saldo(Dry) + Profit;
   
     
--     Debug(Sattmate_Calendar.String_Date_ISO(Start_Date) & " " & Sattmate_Calendar.String_Time(Start_Date) & " | " &
--              Integer'Image(Integer(Dr_Saldo)) & " | " & Integer'Image(Integer(Sb_Saldo)));
--     
     Print(Sattmate_Calendar.String_Date_ISO(Start_Date) & " " & Sattmate_Calendar.String_Time(Start_Date) & " | " &
              Integer'Image(Integer(Saldo(Ref))) & " | " &
              Integer'Image(Integer(Saldo(Dry))) & " | " &
              Integer'Image(Integer(Saldo(Sim))) & " | " &
              Integer'Image(Integer(Saldo(His))));
   end loop;
      
   T.Commit;
   Sql.Close_Session;
   Log ("done");

end Equity;