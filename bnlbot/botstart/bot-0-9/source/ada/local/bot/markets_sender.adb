--with Text_Io;
with Sattmate_Exception;
with Sql;
with Sattmate_Calendar;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;

with Lock ;
with Gnat.Command_Line; use Gnat.Command_Line;
with Posix;
with Table_Amarkets;
with Table_Awinners;
with Ini;
with Logging; use Logging;

with Ada.Environment_Variables;
--with Ada.Directories;

with Process_IO;
with Bot_Messages;

procedure Markets_Sender is
  package EV renames Ada.Environment_Variables;
--  package AD renames Ada.Directories;
  
  Me : constant String := "Main.";  
  Ba_Daemon    : aliased Boolean := False;
  Ba_Log       : aliased Boolean := False;
  Config : Command_Line_Configuration;
  My_Lock  : Lock.Lock_Type;
  T : Sql.Transaction_Type;
  Markets : Sql.Statement_Type;
  
------------------------------ main start -------------------------------------
  Amarkets_List : Table_Amarkets.Amarkets_List_Pack.List_Type := Table_Amarkets.Amarkets_List_Pack.Create;
  Amarkets :  Table_Amarkets.Data_Type;
  Awinner : TAble_Awinners.Data_Type;
  Eos      : Boolean := False;
  MNR      : Bot_Messages.Market_Notification_Record;
  Receiver : Process_IO.Process_Type := ((others => ' '), (others => ' '));
  Tot,Cur : Natural := 0;
  
begin
  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");
  
  Define_Switch
     (Config,
      Ba_Log'access,
      "-l",
      Long_Switch => "--log",
      Help        => "open logfile ");
      
  Define_Switch
     (Config,
      Ba_Daemon'access,
      "-d",
      Long_Switch => "--daemon",
      Help        => "become daemon at startup");
  Getopt (Config);  -- process the command line

  if Ba_Log then
    Logging.Open(EV.Value("BOT_HOME") & "/log/markets_sender.log");
  end if;

  if Ba_Daemon then
     Posix.Daemonize;
  end if;
  
   --must take lock AFTER becoming a daemon ... 
   --The parent pid dies, and would release the lock...
  My_Lock.Take("markets_sender");

  Sql.Connect
        (Host     => Ini.Get_Value("database","host",""),
         Port     => Ini.Get_Value("database","port",5432),
         Db_Name  => Ini.Get_Value("database","name",""),
         Login    => Ini.Get_Value("database","username",""),
         Password => Ini.Get_Value("database","password",""));
    
  T.Start;
    Markets.Prepare("select * from AMARKETS where MARKETID > '0' order by MARKETID");
  Table_Amarkets.Read_List(Stm => Markets, List  => Amarkets_List);     
--  Table_Amarkets.Read_All(List  => Amarkets_List, Order=> True);     
  T.Commit;
  Tot := Table_Amarkets.Amarkets_List_Pack.Get_Count(Amarkets_List);
  Log(Me, "found # markets:" & Tot'Img );
  Move("bot", Receiver.Name);
  while not Table_Amarkets.Amarkets_List_Pack.Is_Empty(Amarkets_List) loop
     Cur := Cur +1;
     Table_Amarkets.Amarkets_List_Pack.Remove_From_Head(Amarkets_List, Amarkets);
     Awinner.Marketid := Amarkets.Marketid;
     Table_Awinners.Read_One_Marketid(Awinner,False,Eos);
     if not Eos then -- wants to have a winner
       MNR.Market_Id := (others => ' ');
       Move(Amarkets.Marketid, MNR.Market_Id);
       Log(Me, "Notifying 'bot' with marketid: '" & MNR.Market_Id   & " Startts = " & 
                Sattmate_Calendar.String_Date_And_Time(Amarkets.Startts, Milliseconds => true) 
                & "'" & Cur'Img & "/" & Tot'Img);
       Bot_Messages.Send(Receiver, MNR);
     end if;  
  end loop;    
  
  Log(Me, "shutting down, close db");
  Sql.Close_Session;
  Log(Me, "do_exit");
  Posix.Do_Exit(0); -- terminate
  Log(Me, "after do_exit");
 
exception
  when Lock.Lock_Error => 
      Posix.Do_Exit(0); -- terminate

  when E: others =>
    Sattmate_Exception.Tracebackinfo(E);
    Posix.Do_Exit(0); -- terminate
end Markets_Sender;

