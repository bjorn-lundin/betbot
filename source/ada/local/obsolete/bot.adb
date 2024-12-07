with Types; use Types;
with Calendar2; use Calendar2;
with Stacktrace;
with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
with Ada.Exceptions;
with Ada.Command_Line;

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
with Rpc;
with Utils;

procedure Bot is
  package EV renames Ada.Environment_Variables;
  Timeout  : Duration := 120.0;
  My_Lock  : Lock.Lock_Type;
  Msg      : Process_Io.Message_Type;
  Me       : constant String := "Main";
  use type Bot_Types.Bot_Mode_Type;
  OK : Boolean := False;
  Now : Calendar2.Time_Type := Calendar2.Time_Type_First;
  
  Is_Time_To_Exit : Boolean := False;
  use type Sql.Transaction_Status_Type;
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

  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => To_String(Bot_Config.Config.Database_Section.Host),
         Port     => 5432,
         Db_Name  => To_String(Bot_Config.Config.Database_Section.Name),
         Login    => To_String(Bot_Config.Config.Database_Section.Username),
         Password => To_String(Bot_Config.Config.Database_Section.Password));
  Log(Me, "db Connected");
  
  case Bot_Config.Config.System_Section.Bot_Mode is
    when Bot_Types.Real       =>
       Log(Me, "Login betfair");
       Rpc.Init(
         Username   => To_String(Bot_Config.Config.Betfair_Section.Username),
         Password   => To_String(Bot_Config.Config.Betfair_Section.Password),
         Product_Id => To_String(Bot_Config.Config.Betfair_Section.Product_Id),
         Vendor_id  => To_String(Bot_Config.Config.Betfair_Section.Vendor_Id),
         App_Key    => To_String(Bot_Config.Config.Betfair_Section.App_Key)
       );
       Rpc.Login;
       Log(Me, "Login betfair done");
    when Bot_Types.Simulation =>
       Log(Me, "No login to betfair, we are in simulation mode");
  end case;

  Log(Me, "Start main loop");
  
  if not Bot_Config.Config.Global_Section.Logging then
    Logging.Close;
    Logging.Set_Quiet(True);
  end if;
  
  Main_Loop : loop
    begin
      Log(Me, "Start receive");
      Process_Io.Receive(Msg, Timeout);
      Log(Me, "msg : "& Process_Io.Identity(Msg)'Img & " from " & Utils.Trim(Process_Io.Sender(Msg).Name));
      if Sql.Transaction_Status /= Sql.None then
        raise Sql.Transaction_Error with "Uncommited transaction in progress !! BAD!";
      end if;
      case Process_Io.Identity(Msg) is
        when Core_Messages.Exit_Message                  =>
          exit Main_Loop;
        -- when Core_Messages.Enter_Console_Mode_Message    => Enter_Console;
        when Core_Messages.Read_Config_Message           =>
          Bot_Config.Re_Read_Config ;
        when Bot_Messages.Market_Notification_Message    =>
          Bet_Handler.Treat_Market( Bot_Messages.Data(Msg));
        when others =>
          Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Log(Me, "Timeout");
        if Sql.Transaction_Status /= Sql.None then
          raise Sql.Transaction_Error with "Uncommited transaction in progress !! BAD!";
        end if;
        
        case Bot_Config.Config.System_Section.Bot_Mode is
          when Bot_Types.Real       =>
            Rpc.Keep_Alive(OK);
            if not OK then
              Rpc.Login;
            end if;
          when Bot_Types.Simulation => null;
        end case;
    end;
    Now := Calendar2.Clock;
    
    --restart every day
    Is_Time_To_Exit := Now.Hour = 01 and then 
                     ( Now.Minute = 00 or Now.Minute = 01) ; -- timeout = 2 min
  
    exit Main_Loop when Is_Time_To_Exit;
    
    
  end loop Main_Loop;
  Log(Me, "Close Db");
  Sql.Close_Session;
  Log (Me, "db closed, Is_Time_To_Exit " & Is_Time_To_Exit'Img);
 
  case Bot_Config.Config.System_Section.Bot_Mode is
    when Bot_Types.Real       => Rpc.Logout;
    when Bot_Types.Simulation => null;
  end case;
  
  Logging.Close;
  Posix.Do_Exit(0); -- terminate
exception
  when Lock.Lock_Error =>
    Log(Me, "lock error, exit");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
  when E: others =>
    declare
      Last_Exception_Name     : constant String  := Ada.Exceptions.Exception_Name(E);
      Last_Exception_Messsage : constant String  := Ada.Exceptions.Exception_Message(E);
      Last_Exception_Info     : constant String  := Ada.Exceptions.Exception_Information(E);
    begin
      Log(Last_Exception_Name);
      Log("Message : " & Last_Exception_Messsage);
      Log(Last_Exception_Info);
      Log("addr2line" & " --functions --basenames --exe=" &
           Ada.Command_Line.Command_Name & " " & Stacktrace.Pure_Hexdump(Last_Exception_Info));
    end ;

    Log(Me, "Closed log and die");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
end Bot;
