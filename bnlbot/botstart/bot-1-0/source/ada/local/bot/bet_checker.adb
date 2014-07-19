with Stacktrace;
--with General_Routines; use General_Routines;
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
with Gnat.Command_Line; use Gnat.Command_Line;
with Ini;
with Rpc;
with Gnat.Strings;
with Calendar2;
with Types; use Types;

procedure Bet_Checker is
  package EV renames Ada.Environment_Variables;
  Timeout         : Duration := 25.0; 
  My_Lock         : Lock.Lock_Type;
  Msg             : Process_Io.Message_Type;
  Me              : constant String := "Main";  
  Ba_Daemon       : aliased Boolean := False;
  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Config          : Command_Line_Configuration;
  OK              : Boolean := False;
  Is_Time_To_Exit : Boolean := False;
  Now             : Calendar2.Time_Type := Calendar2.Clock;
  
begin
   Define_Switch
     (Config,
      Sa_Par_Bot_User'access,
      Long_Switch => "--user=",
      Help        => "user of bot");

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

  Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");
   --must take lock AFTER becoming a daemon ... 
   --The parent pid dies, and would release the lock...
  My_Lock.Take(EV.Value("BOT_NAME"));
  
  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");
   
  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("database","host",""),
         Port     => Ini.Get_Value("database","port", 5432),
         Db_Name  => Ini.Get_Value("database","name",""),
         Login    => Ini.Get_Value("database","username",""),
         Password => Ini.Get_Value("database","password",""));
  Log(Me, "db Connected");        

  Log(Me, "Login betfair");
  Rpc.Init(
            Username   => Ini.Get_Value("betfair","username",""),
            Password   => Ini.Get_Value("betfair","password",""),
            Product_Id => Ini.Get_Value("betfair","product_id",""),  
            Vendor_Id  => Ini.Get_Value("betfair","vendor_id",""),
            App_Key    => Ini.Get_Value("betfair","appkey","")
          );
  Rpc.Login; 
  Log(Me, "Login betfair done");

  Bet_Handler.Check_Bets;
  Log(Me, "Start main loop");
  Main_Loop : loop
    begin
      Log(Me, "Start receive");
      Process_Io.Receive(Msg, Timeout);
      
      Log(Me, "msg : "& Process_Io.Identity(Msg)'Img & " from " & Trim(Process_Io.Sender(Msg).Name));
      
      case Process_Io.Identity(Msg) is
        when Core_Messages.Exit_Message                            => exit Main_Loop;
        when Bot_Messages.New_Winners_Arrived_Notification_Message =>  
          Bet_Handler.Check_If_Bet_Accepted;
          Bet_Handler.Check_Bets;
        when others => Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Log(Me, "Timeout start");
          Rpc.Keep_Alive(OK);
          if not OK then
            Rpc.Login;
          end if;
          Bet_Handler.Check_If_Bet_Accepted;
          Bet_Handler.Check_Bets;
        Log(Me, "Timeout stop");
    end;    
    
    Now := Calendar2.Clock;
    --restart every day
    Is_Time_To_Exit := Now.Hour = 01 and then 
                       Now.Minute = 00 and then
                       Now.Second >= 50 ;
                                
    exit Main_Loop when Is_Time_To_Exit;

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
  when E: others => Stacktrace.Tracebackinfo(E);
--    Log(Me, "Close Db");
--    Sql.Close_Session;
    Log(Me, "Closed log and die");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
end Bet_Checker;
