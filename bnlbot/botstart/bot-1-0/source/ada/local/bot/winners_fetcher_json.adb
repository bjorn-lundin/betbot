with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
--with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Environment_Variables;
--with Ada.Calendar;
with Sattmate_Types; use Sattmate_Types;
with Sql;
--with Simple_List_Class;
--pragma Elaborate_All(Simple_List_Class);
with Sattmate_Exception;
with Lock ;
with Rpc;
with Posix;
--with Ada.Directories;
with Logging; use Logging;
with Bot_Messages;
with Process_Io;
with Ini;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Core_Messages;
with Bet_Handler;
with Sattmate_Calendar;

procedure Winners_Fetcher_Json is
  package EV renames Ada.Environment_Variables;
  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Cmd_Line : Command_Line_Configuration;

  Me : constant String := "Main.";
  --------------------------
  OK : Boolean := False;
  Has_Inserted_Winner : Boolean := False;
  My_Lock  : Lock.Lock_Type;
  Msg      : Process_Io.Message_Type;
  Long_Timeout  : Duration := 47.0;
  Timeout  : Duration := 1.0;
  

  Ba_Daemon : aliased Boolean := False;
  Now : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
  Is_Time_To_Exit : Boolean := False;
----------------------------------------------

  use type Sql.Transaction_Status_Type;
  
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
    Getopt (Cmd_Line);  -- process the command line
    
    Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");
    Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");
         
    if Ba_Daemon then
      Posix.Daemonize;
    end if;
    My_Lock.Take("winners_fetcher_json");    
    
    Log(Me, "Login betfair");
    Rpc.Init(
            Username   => Ini.Get_Value("betfair","username",""),
            Password   => Ini.Get_Value("betfair","password",""),
            Product_Id => Ini.Get_Value("betfair","product_id",""),  
            Vendor_Id  => Ini.Get_Value("betfair","vendor_id",""),
            App_Key    => Ini.Get_Value("betfair","appkey","")
    );
    Rpc.Login;
    
--    Log (Me, "connect db");
    Sql.Connect
        (Host     => Ini.Get_Value("database","host",""),
         Port     => Ini.Get_Value("database","port",5432),
         Db_Name  => Ini.Get_Value("database","name",""),
         Login    => Ini.Get_Value("database","username",""),
         Password => Ini.Get_Value("database","password",""));
--    Log (Me, "connected to db");
      
    Main_Loop : loop
      begin
        Log(Me, "Start receive");
        Process_Io.Receive(Msg, Timeout);
        if Sql.Transaction_Status /= Sql.None then
          raise Sql.Transaction_Error with "Uncommited transaction in progress !! BAD!";
        end if;
        case Process_Io.Identity(Msg) is
          when Core_Messages.Exit_Message                  =>
            exit Main_Loop;
          when others =>
            Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
        end case;
      exception
        when Process_Io.Timeout =>
          if Sql.Transaction_Status /= Sql.None then
            raise Sql.Transaction_Error with "Uncommited transaction in progress !! BAD!";
          end if;
          Timeout := Long_Timeout; -- first time fast ...
          Log(Me, "Timeout");
          Rpc.Keep_Alive(OK);
          if not OK then
            Rpc.Login;
          end if;
          Bet_Handler.Check_Market_Status;                          -- updates markets status
          Bet_Handler.Check_Unsettled_Markets(Has_Inserted_Winner); -- updates runner status
          
          if Has_Inserted_Winner then
            declare
              NWANR   : Bot_Messages.New_Winners_Arrived_Notification_Record;
              Receiver : Process_IO.Process_Type := ((others => ' '), (others => ' '));
            begin
              Move("bot", Receiver.Name);
              Log(Me, "Notifying 'bot' of that new winners are arrived");
              Bot_Messages.Send(Receiver, NWANR);
            end;
          end if;
      end;
      Now := Sattmate_Calendar.Clock;
      --restart every day
      Is_Time_To_Exit := Now.Hour = 01 and then 
                         Now.Minute = 02 ;
      
      exit Main_Loop when Is_Time_To_Exit;
      
    end loop Main_Loop;

    Sql.Close_Session;
    Log (Me, "db closed, Is_Time_To_Exit " & Is_Time_To_Exit'Img);
    Rpc.Logout;

    Logging.Close;
    Posix.Do_Exit(0); -- terminate
exception
  when Lock.Lock_Error =>
    Posix.Do_Exit(0); -- terminate
  when E: others =>
    Sattmate_Exception. Tracebackinfo(E);
    Logging.Close;
    if Sql.Is_Session_Open then
      Sql.Close_Session;
      Log (Me, "db closed");
    end if;
    Posix.Do_Exit(0); -- terminate
end Winners_Fetcher_Json;

