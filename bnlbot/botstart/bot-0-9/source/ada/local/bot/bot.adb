with Sattmate_Types; use Sattmate_Types;
with Sattmate_Exception;
with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
with Token;
with General_Routines; use General_Routines;
with Bot_Config;
with Lock; --?
with Text_io;
with Sql;
with Bot_Messages;
with Posix;
with Logging; use Logging;
with Process_Io;

procedure Bot is
  Timeout  : Duration := 2.0; 
  My_Token : Token.Token_Type;
  Msg      : Process_Io.Message_Type;
begin
--  misc_init ; -- read from cmd-line?
  Bot_Config.Config.Read; -- even from cmdline
  
  if Bot_Config.Config.System_Section.Daemonize then
    Posix.Daemonize;
  end if;
  
  Logging.Open(To_String(Bot_Config.Config.Bot_Log_file_Name));
  Log(Bot_Config.Config.To_String);
  Log("Login betfair");
  My_Token.Login;
  Log("Login betfair done");
   
  Log("Connect Db");
  Sql.Connect
        (Host     => To_String(Bot_Config.Config.Database_Section.Host),
         Port     => 5432,
         Db_Name  => To_String(Bot_Config.Config.Database_Section.Name),
         Login    => To_String(Bot_Config.Config.Database_Section.Username),
         Password => To_String(Bot_Config.Config.Database_Section.Password));
  Log("db Connected");
         
  Log("Start main loop");
  Main_Loop : loop
    begin
      Log("Start receive");
      Process_Io.Receive(Msg, Timeout);
      
      Log("msg : "& Process_Io.Identity(Msg)'Img & " from " & Trim(Process_Io.Sender(Msg).Name));
      
      case Process_Io.Identity(Msg) is
        when Bot_Messages.Quit             => exit Main_Loop;
        when Bot_Messages.Console          => null ; --Enter_Console;
        when Bot_Messages.Read_Config      => Bot_Config.Re_Read_Config ; 
        when Bot_Messages.Bet_Notification => null; --Treat_Bet(Msg.Data);
        when others => Log("Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        null;
      --        if Betfair_Timeout_Reached then
--          if not My_Token.Keep_Alive then
--            My_Token.Login ; --???  eller låta dö, och startas om av cron?            
--          end if;
--        end if;
    end;    
  end loop Main_Loop;
  Log("Close db");
  Sql.Close_Session;
  Log("Db Closed");
  Logging.Close;
  

exception
  when E: others => Sattmate_Exception.Tracebackinfo(E);

end Bot;
