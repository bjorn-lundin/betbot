

--with Text_io;
with Table_Aevents;
with Table_Amarkets;
with Table_Arunners;
with Table_Aprices;
with Table_Alinks;
with Sql;
with Logging ; use Logging;
with Sattmate_Types; use Sattmate_Types;
with Sattmate_Calendar; use Sattmate_Calendar;
with Ada.Strings ; use Ada.Strings;
with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
with General_Routines; use General_Routines;

--with Gnat.Command_Line; use Gnat.Command_Line;
--with Gnat.Strings;
with Sattmate_Exception;

procedure Create_Eventid is
--  Bad_Input : exception;
 
  Me : constant String := "Main"; 
  T : Sql.Transaction_Type;
 
 -----------------------------------------------------------------
  
 
 
 -------------------------
begin 
 
  Log(Me, "log into database");
  Sql.Connect
     (Host     => Sa_Par_Hostname.all,
      Port     => 5432,
      Db_Name  => Sa_Par_Database.all,
      Login    => Sa_Par_Username.all,
      Password => Sa_Par_Password.all);
  Log(Me, "db Connected");
  
  -- read to list
  T.Start;
  Do_Update;
  T.Commit;

  Log(Me, "close db");
  Sql.Close_Session;

exception
--  when  Gnat.Command_Line.Invalid_Switch =>
--    Display_Help(Config);
  when E: others => 
    Sattmate_Exception.Tracebackinfo(E);  
end Create_Eventid;
