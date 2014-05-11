--with Text_Io;
with Sattmate_Exception;
with Sql;
with Sattmate_Types; use Sattmate_Types;
--with General_Routines; use General_Routines;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
--with Sattmate_Calendar; use Sattmate_Calendar;
--with Ada.Strings; use Ada.Strings;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Lock ;
with Ini;
with Logging; use Logging;
with Ada.Environment_Variables;
--with Process_IO;
--with Core_Messages;
--with Table_Araceprices;
--with Table_Aracepricesold;
with Bot_Svn_Info;
with Posix;

procedure Data_Mover is
  package EV renames Ada.Environment_Variables;


  Me : constant String := "Poll.";

--  Timeout  : Duration := 120.0;
  My_Lock  : Lock.Lock_Type;

--  Msg      : Process_Io.Message_Type;
  type Tables_Type is (Araceprices,Amarkets, Avents, Arunners, Aprices);
  Select_To_Move   : array (Tables_Type'range) of Sql.Statement_Type;
  Select_To_Delete : array (Tables_Type'range) of Sql.Statement_Type;
 
  
  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line : Command_Line_Configuration;

  -------------------------------------------------------------

  -------------------------------------------------------------
  procedure Run is
--    Price_List : Table_Araceprices.Araceprices_List_Pack.List_Type := Table_Araceprices.Araceprices_List_Pack.Create;
--    Price : Table_Araceprices.Data_Type;
--    Old_Price : Table_Aracepricesold.Data_Type;
    T : Sql.Transaction_Type;
    Num : Integer_4 := 500;
    Rows_Inserted,
    Rows_Deleted : Natural := 0;
  begin
    Outer_Loop : for Table in Tables_Type'range loop
       Inner_Loop : loop
           Log("about to insert into " & Table'Img & " in chunks of 1 days worth of data, Num =" & Num'Img);      
           T.Start;
             Select_To_Move(Table).Prepare(
               "insert into :OLDTABLE " &
               "select * from :TABLE " &
               "where IXXLUTS < current_timestamp - interval ':NUM day' "
             );
            Select_To_Move(Table).Set("OLDTABLE", Table'Img & "OLD"); 
            Select_To_Move(Table).Set("TABLE",Table'Img); 
            Select_To_Move(Table).Set("NUM",Num); 
            begin 
              Select_To_Move(Table).Execute(Rows_Inserted);
            exception
              when Sql.No_Such_Row => Rows_Inserted := 0;
            end ;       
            
            Select_To_Delete(Table).Set("TABLE",Table'Img); 
            Select_To_Delete(Table).Prepare(
               "delete from :TABLE " &
               "where IXXLUTS < current_timestamp - interval ':NUM day' " 
             );
            Select_To_Delete(Table).Set("NUM",Num); 
            begin 
              Select_To_Delete(Table).Execute(Rows_Deleted);
            exception
              when Sql.No_Such_Row => Rows_Deleted := 0;
            end ;       
            
           T.Commit;
           Log("chunk ready, Moved" & Rows_Inserted'Img & " and deleted" & Rows_Deleted'Img);
           Num := Num -1;
           exit Inner_Loop when Num = 7; -- leave a week              
       end loop Inner_Loop ;
    end loop Outer_Loop;   
  end Run;
  ---------------------------------------------------------------------
  use type Sql.Transaction_Status_Type;
------------------------------ main start -------------------------------------

begin

   Define_Switch
    (Cmd_Line,
     Sa_Par_Bot_User'access,
     Long_Switch => "--user=",
     Help        => "user of bot");

   Define_Switch
     (Cmd_Line,
      Ba_Daemon'access,
      Long_Switch => "--daemon",
      Help        => "become daemon at startup");

   Define_Switch
     (Cmd_Line,
      Sa_Par_Inifile'access,
      Long_Switch => "--inifile=",
      Help        => "use alternative inifile");

  Getopt (Cmd_Line);  -- process the command line

  if Ba_Daemon then
    Posix.Daemonize;
  end if;
  Logging.Open(EV.Value("BOT_HOME") & "/log/race_price_mover.log");

   --must take lock AFTER becoming a daemon ...
   --The parent pid dies, and would release the lock...
  My_Lock.Take(EV.Value("BOT_NAME"));


  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("database", "host", ""),
         Port     => Ini.Get_Value("database", "port", 5432),
         Db_Name  => Ini.Get_Value("database", "name", ""),
         Login    => Ini.Get_Value("database", "username", ""),
         Password =>Ini.Get_Value("database", "password", ""));
  Log(Me, "db Connected");
  
  Run;
  
  Log(Me, "Close Db");
  Sql.Close_Session;
  Logging.Close;
  Posix.Do_Exit(0); -- terminate

exception
  when Lock.Lock_Error =>
    Log(Me, "lock error, exit");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
  when E: others => Sattmate_Exception.Tracebackinfo(E);
--    Log(Me, "Close Db");
--    Sql.Close_Session;
    Log(Me, "Closed log and die");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
end Data_Mover;

