--with Sattmate_Types; use Sattmate_Types;
with Sattmate_Exception;
with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
with Token;
with General_Routines; use General_Routines;
with Bot_Config;
with Lock;
--with Text_io;
with Bot_Types;
with Sql;
with Bot_Messages;
with Posix;
with Logging; use Logging;
with Process_Io;
with Core_Messages;
with Ada.Environment_Variables;
with Bet_Handler;
with Bot_Svn_Info;

procedure Bot is
  package EV renames Ada.Environment_Variables;
  Timeout  : Duration := 120.0;
  My_Token : Token.Token_Type;
  My_Lock  : Lock.Lock_Type;
  Msg      : Process_Io.Message_Type;
  Me       : constant String := "Main";
  use type Bot_Types.Mode_Type;
  OK : Boolean := False;
begin
  Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");
  Bot_Config.Config.Read; -- even from cmdline

  if Bot_Config.Config.System_Section.Daemonize then
    Posix.Daemonize;
  end if;
  
   --must take lock AFTER becoming a daemon ...
   --The parent pid dies, and would release the lock...
  My_Lock.Take(EV.Value("BOT_NAME"));

  Log(Bot_Config.Config.To_String);
  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  case Bot_Config.Config.System_Section.Bot_Mode is
    when Bot_Types.Real       =>
       Log(Me, "Login betfair");
       My_Token.Init(
         Username   => To_String(Bot_Config.Config.Betfair_Section.Username),
         Password   => To_String(Bot_Config.Config.Betfair_Section.Password),
         Product_Id => To_String(Bot_Config.Config.Betfair_Section.Product_Id),
         Vendor_id  => To_String(Bot_Config.Config.Betfair_Section.Vendor_id)
       );
       My_Token.Login;
       Log(Me, "Login betfair done");
    when Bot_Types.Simulation => null;
  end case;

  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => To_String(Bot_Config.Config.Database_Section.Host),
         Port     => 5432,
         Db_Name  => To_String(Bot_Config.Config.Database_Section.Name),
         Login    => To_String(Bot_Config.Config.Database_Section.Username),
         Password => To_String(Bot_Config.Config.Database_Section.Password));
  Log(Me, "db Connected");

  Log(Me, "Start main loop");
  
  if not Bot_Config.Config.Global_Section.Logging then
    Logging.Close;
    Logging.Set_Quiet(True);
  end if;
  
  Main_Loop : loop
    begin
      Log(Me, "Start receive");
      Process_Io.Receive(Msg, Timeout);
      Log(Me, "msg : "& Process_Io.Identity(Msg)'Img & " from " & Trim(Process_Io.Sender(Msg).Name));
      case Process_Io.Identity(Msg) is
        when Core_Messages.Exit_Message                  =>
          exit Main_Loop;
        -- when Core_Messages.Enter_Console_Mode_Message    => Enter_Console;
        when Core_Messages.Read_Config_Message           =>
          Bot_Config.Re_Read_Config ;
        when Bot_Messages.Market_Notification_Message    =>
          Bet_Handler.Treat_Market( Bot_Messages.Data(Msg),My_Token);
          Bet_Handler.Check_Bets;
        when Bot_Messages.New_Winners_Arrived_Notification_Message =>
          Bet_Handler.Check_Bets;
        when others =>
          Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Log(Me, "Timeout");
        case Bot_Config.Config.System_Section.Bot_Mode is
          when Bot_Types.Real       =>
            My_Token.Keep_Alive(OK);
            if not OK then
              My_Token.Login;
            end if;
          when Bot_Types.Simulation => null;
        end case;
        Bet_Handler.Check_Bets;
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
