
with sattmate_types ; use sattmate_types;
with Sattmate_Exception;
with Sql;

with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;
with Logging; use Logging;
with Sattmate_Calendar; use Sattmate_Calendar;



procedure Sql_Ifc_Leak_Finder is

   T            : Sql.Transaction_Type;
   Select_All   : Sql.Statement_Type;

   Eos          : Boolean := False;

   start_date   : Sattmate_Calendar.time_type := Sattmate_Calendar.Time_Type_First;
   stop_date    : Sattmate_Calendar.time_type := Sattmate_Calendar.Time_Type_First;


--   Sa_Date      : aliased Gnat.Strings.String_Access;
   I_Num_Days   : aliased Integer := 2;
--   Config       : Command_Line_Configuration;
   cnt : integer := 0;

begin
--   Define_Switch
--     (Config,
--      Sa_Date'access,
--      "-d:",
--      Long_Switch => "--date=",
--      Help        => "when the data move starts yyyy-mm-dd");
--
--   Define_Switch
--     (Config,
--      I_Num_Days'access,
--      "-n:",
--      Long_Switch => "--num_days=",
--      Help        => "days to move");
--
--
--   Getopt (Config);  -- process the command line


   Log ("Connect db");
   Sql.Connect
     (Host     => "localhost",
      Port     => 5432,
      Db_Name  => "bfhistory",
      Login    => "bnl",
      Password => "bnl");

   Sql.Prepare (Select_All,
                   "select * from HISTORY " &
                   "where LATESTTAKEN >= :START " &
                   "and LATESTTAKEN <= :STOP " &
                   "order by EVENTID, SELECTIONID, LATESTTAKEN");

   Start_Date := Sattmate_Calendar.To_Time_Type ("2011-01-01", "00:00:00:000");
   Stop_Date  := Sattmate_Calendar.To_Time_Type ("2011-03-01", "23:59:59:999");

   Sql.Set_Timestamp(Select_all, "START", Start_date);
   Sql.Set_Timestamp(Select_all, "STOP",  Stop_date);

   Sql.Start_Read_Write_Transaction (T);
   for i in 0 .. I_Num_Days loop
         Cnt := 0;
         Sql.Open_Cursor(Select_All);
         loop
           Cnt := Cnt + 1;
           Log ("turn #" & i'img & Cnt'Img & " " & eos'img);
           Sql.Fetch(Select_All,Eos);
           exit when Eos;
         end loop;
         Sql.Close_Cursor(Select_All);
   end loop;
   Sql.Commit (T);

   Log ("wait 25 before close");
   delay 25.0;

   Sql.Close_Session;
   Log ("wait 25 before die");
   delay 25.0;

exception
   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);

end Sql_Ifc_Leak_Finder;
