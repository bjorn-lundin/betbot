--with Sattmate_Types; use Sattmate_Types;
with Sattmate_Exception;
with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
with Token;
with General_Routines; use General_Routines;
with Bot_Config;
with Lock; 
--with Text_io;
with Sql;
with Bot_Messages;
with Posix;
with Logging; use Logging;
with Process_Io;
with Core_Messages;
with Ada.Environment_Variables;
with Bet_Handler;

procedure Bot is
  package EV renames Ada.Environment_Variables;
  Timeout  : Duration := 120.0; 
  My_Token : Token.Token_Type;
  My_Lock  : Lock.Lock_Type;
  Msg      : Process_Io.Message_Type;
  Me       : constant String := "Main";  
  
begin
  Logging.Open(EV.Value("BOT_HOME") & "/log/bot.log");
  Bot_Config.Config.Read; -- even from cmdline
  
  if Bot_Config.Config.System_Section.Daemonize then
    Posix.Daemonize;
  end if;

   --must take lock AFTER becoming a daemon ... 
   --The parent pid dies, and would release the lock...
  My_Lock.Take("bot");
  
  Log(Bot_Config.Config.To_String);
  Log(Me, "Login betfair");
--  return;
  My_Token.Login(
    Username   => To_String(Bot_Config.Config.Betfair_Section.Username),
    Password   => To_String(Bot_Config.Config.Betfair_Section.Password),
    Product_Id => To_String(Bot_Config.Config.Betfair_Section.Product_Id),  
    Vendor_id  => To_String(Bot_Config.Config.Betfair_Section.Vendor_id)
  );
  Log(Me, "Login betfair done");
   
  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => To_String(Bot_Config.Config.Database_Section.Host),
         Port     => 5432,
         Db_Name  => To_String(Bot_Config.Config.Database_Section.Name),
         Login    => To_String(Bot_Config.Config.Database_Section.Username),
         Password => To_String(Bot_Config.Config.Database_Section.Password));
  Log(Me, "db Connected");
         
  Log(Me, "Start main loop");
  Main_Loop : loop
    begin
      Log(Me, "Start receive");
      Process_Io.Receive(Msg, Timeout);
      
      Log(Me, "msg : "& Process_Io.Identity(Msg)'Img & " from " & Trim(Process_Io.Sender(Msg).Name));
      
      case Process_Io.Identity(Msg) is
        when Core_Messages.Exit_Message                  => exit Main_Loop;
        -- when Core_Messages.Enter_Console_Mode_Message    => Enter_Console;
        when Core_Messages.Read_Config_Message           => Bot_Config.Re_Read_Config ; 
        when Bot_Messages.Market_Notification_Message    => Bet_Handler.Treat_Market( Bot_Messages.Data(Msg),My_Token);
        when others => Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Log(Me, "Timeout");
        if not My_Token.Keep_Alive then
          My_Token.Login(
            Username   => To_String(Bot_Config.Config.Betfair_Section.Username),
            Password   => To_String(Bot_Config.Config.Betfair_Section.Password),
            Product_Id => To_String(Bot_Config.Config.Betfair_Section.Product_Id),  
            Vendor_id  => To_String(Bot_Config.Config.Betfair_Section.Vendor_id)
          );
        end if;
    end;    
  end loop Main_Loop;
  Log(Me, "Close Db");
  Sql.Close_Session;
  Log(Me, "Db Closed");
  Logging.Close;
  
  Posix.Do_Exit(0); -- terminate

exception
  when Lock.Lock_Error => 
    Log(Me, "lock error, exit");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
  when E: others => Sattmate_Exception.Tracebackinfo(E);
    Log(Me, "Close Db");
    Sql.Close_Session;
    Log(Me, "Closed log and die");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
end Bot;
