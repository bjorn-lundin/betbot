with Gnat.Command_Line; use Gnat.Command_Line;
with Sattmate_Types;    use Sattmate_Types;
with Gnat.Strings;
with Sql;
with Sattmate_Calendar;
with Logging;               use Logging;
--with Text_IO;
with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
procedure Equity is


   Sa_Par_Db            : aliased Gnat.Strings.String_Access;
   Sa_Par_Port          : aliased Gnat.Strings.String_Access;
   Sa_Par_Host          : aliased Gnat.Strings.String_Access;
   Sa_Par_Db_Pwd        : aliased Gnat.Strings.String_Access;
   Sa_Par_Bet_Type      : aliased Gnat.Strings.String_Access;
   Sa_Saldo             : aliased Gnat.Strings.String_Access;
   Sa_Start_Date        : aliased Gnat.Strings.String_Access;
   Sa_Stop_Date         : aliased Gnat.Strings.String_Access;
   Config               : Command_Line_Configuration;
   Port                 : Natural := 5432;
   T                    : Sql.Transaction_Type;
   Select_Results       : Sql.Statement_Type;
   Eos : Boolean := False;

   Bet_Placed,
   Start_Date,
   Stop_Date : Sattmate_Calendar.Time_Type;
   Saldo , Profit : Float_8 := 0.0;

   Db_Pwd : Unbounded_String := To_Unbounded_String("bnl");

begin


   Define_Switch
     (Config,
      Sa_Par_Bet_Type'Access,
      "-b:",
      Long_Switch => "--bet_type=",
      Help        => "bet type, HOUNDS_PLACE_BACK_BET");

   Define_Switch
     (Config,
      Sa_Par_Host'Access,
      "-H:",
      Long_Switch => "--host=",
      Help        => "host name");

   Define_Switch
     (Config,
      Sa_Par_Db'Access,
      "-D:",
      Long_Switch => "--database=",
      Help        => "database name");

   Define_Switch
     (Config,
      Sa_Par_Port'Access,
      "-p:",
      Long_Switch => "--port=",
      Help        => "database port");

   Define_Switch
     (Config,
      Sa_Par_Db_Pwd'Access,
      "-r:",
      Long_Switch => "--db_pwd=",
      Help        => "database pwd");

   Define_Switch
     (Config,
      Sa_Stop_Date'Access,
      "-f:",
      Long_Switch => "--stop_date=",
      Help        => "when the simulation stops yyyy-mm-dd, 2013-02-25");

   Define_Switch
     (Config,
      Sa_Start_Date'Access,
      "-t:",
      Long_Switch => "--start_date=",
      Help        => "when the simulation start yyyy-mm-dd, 2013-02-25");

   Define_Switch
     (Config,
      Sa_Saldo'Access,
      "-s:",
      Long_Switch => "--saldo=",
      Help        => "starting saldo");


   Getopt (Config);  -- process the command line

   if Sa_Par_Host.all = "" then
     Display_Help (Config);
     return;
   end if;
   if Sa_Par_Db.all = "" then
     Display_Help (Config);
     return;
   end if;
   if Sa_Par_Port.all /= "" then
     Port := Natural'Value(Sa_Par_Port.all);
   end if;
   if  Sa_Par_Db_Pwd.all /= "" then
     Db_Pwd := To_Unbounded_String(Sa_Par_Db_Pwd.all);
   end if;

   Log ("Get_database_data start: " & Sa_Par_Host.all & "/" & Sa_Par_Db.all & "/" & Port'Img);
   Sql.Connect
        (Host     => Sa_Par_Host.all,
         Port     => Port,
         Db_Name  => Sa_Par_Db.all,
         Login    => "bnl",
         Password => To_String(Db_Pwd));
   Log ("connected to database");
   Saldo := Float_8'Value(Sa_Saldo.all);

   Sql.Start_Read_Write_Transaction (T);
   Sql.Prepare(Select_Results, "select BET_PLACED, PROFIT " &
                               "from BET_WITH_COMMISSION " &
                               "where BET_TYPE = :BET_TYPE " &
                               "and BET_PLACED >= :START_DATE " &
                               "and BET_PLACED <= :STOP_DATE " &
                               "order by BET_PLACED");


   Start_Date := Sattmate_Calendar.To_Time_Type (Sa_Start_Date.all,"00:00:00.000");
   Stop_Date  := Sattmate_Calendar.To_Time_Type (Sa_Stop_Date.all, "23:59:59.999");

   Sql.Set(Select_Results,"BET_TYPE", Sa_Par_Bet_Type.all);
   Sql.Set_Timestamp(Select_Results,"START_DATE", Start_Date);
   Sql.Set_Timestamp(Select_Results,"STOP_DATE", Stop_Date);
   Sql.Open_Cursor(Select_Results);
   loop
     Sql.Fetch(Select_Results,Eos);
     exit when Eos;
     Sql.Get_Timestamp(Select_Results, "BET_PLACED", Bet_Placed);
     Sql.Get(Select_Results, "PROFIT", Profit);
     Saldo := Saldo + Profit;
     Print(Sattmate_Calendar.String_Date_ISO(Bet_Placed) & " " & Sattmate_Calendar.String_Time(Bet_Placed) & " | " &
           Integer'Image(Integer(Saldo)) & " | " & Integer'Image(Integer(Profit)));
   end loop;
   Sql.Close_Cursor(Select_Results);
   Sql.Commit (T);
   sql.Close_Session;
   Log ("done");

end Equity;