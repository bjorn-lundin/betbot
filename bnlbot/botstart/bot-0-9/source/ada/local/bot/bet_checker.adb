--with Sattmate_Types; use Sattmate_Types;
with Sattmate_Exception;
--with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
--with Token;
with General_Routines; use General_Routines;
--with Bot_Config;
with Lock; 
--with Text_io;
with Sql;
--with Bot_Messages;
with Posix;
with Logging; use Logging;
with Process_Io;
with Core_Messages;
with Ada.Environment_Variables;
with Bet_Handler;
with Gnat.Command_Line; use Gnat.Command_Line;
--with Gnat.Strings;
with Ini;

procedure Bet_Checker is
  package EV renames Ada.Environment_Variables;
  Timeout  : Duration := 30.0; 
  My_Lock  : Lock.Lock_Type;
  Msg      : Process_Io.Message_Type;
  Me       : constant String := "Main";  
--  Sa_Par_Token : aliased Gnat.Strings.String_Access;
  Ba_Daemon    : aliased Boolean := False;
  Config : Command_Line_Configuration;
  
begin
--   Define_Switch
--    (Config,
--     Sa_Par_Token'access,
--     "-t:",
--     Long_Switch => "--token=",
--     Help        => "use this token, if token is already retrieved");

  Define_Switch
     (Config,
      Ba_Daemon'access,
      "-d",
      Long_Switch => "--daemon",
      Help        => "become daemon at startup");
  Getopt (Config);  -- process the command line

  if Ba_Daemon then
    Posix.Daemonize;
  end if;

  Logging.Open(EV.Value("BOT_HOME") & "/log/bet_checker.log");
   --must take lock AFTER becoming a daemon ... 
   --The parent pid dies, and would release the lock...
  My_Lock.Take("bet_checker");
  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");
   
  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("database","host",""),
         Port     => Ini.Get_Value("database","port", 5432),
         Db_Name  => Ini.Get_Value("database","name",""),
         Login    => Ini.Get_Value("database","username",""),
         Password => Ini.Get_Value("database","password",""));
  Log(Me, "db Connected");        
         
  Bet_Handler.Check_Bets;
  Log(Me, "Start main loop");
  Main_Loop : loop
    begin
      Log(Me, "Start receive");
      Process_Io.Receive(Msg, Timeout);
      
      Log(Me, "msg : "& Process_Io.Identity(Msg)'Img & " from " & Trim(Process_Io.Sender(Msg).Name));
      
      case Process_Io.Identity(Msg) is
        when Core_Messages.Exit_Message                  => exit Main_Loop;
        when others => Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Log(Me, "Timeout start");
        Bet_Handler.Check_Bets;
        Log(Me, "Timeout stop");
    end;    
  end loop Main_Loop;
  Log(Me, "Close Db");
  Sql.Close_Session;
  Log(Me, "Db Closed");
  Logging.Close;
  
  Posix.Do_Exit(0); -- terminate

exception
  when Lock.Lock_Error => 
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
  when E: others => Sattmate_Exception.Tracebackinfo(E);
    Log(Me, "Close Db");
    Sql.Close_Session;
    Log(Me, "Closed log and die");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
end Bet_Checker;
