

--------------------------------------------------------------------------------
--with Types; use Types;
with Ada;    use Ada;
with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Directories;
with AWS;    use AWS;
with AWS.Server;
with AWS.Server.Log;
with AWS.Log;
with AWS.Response;
with AWS.Status;
with Aws.Messages;
with AWS.Parameters;
with AWS.Config;
with AWS.Config.Set;
with AWS.Mime;
with AWS.Session;
with Ada.Environment_Variables;
with Bot_Ws_Services;
with Process_Io;
with Core_Messages;
with Calendar2;
with Logging; --use Logging;
with Sql;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Ini;
with Lock;
with Posix;
with Bot_Svn_Info;
with Binary_Semaphores;
with Types; use Types;
with Stacktrace;


procedure Bot_Web_Server is
  package EV renames Ada.Environment_Variables;
  package AD renames Ada.Directories;

  Me : constant String := "Bot_Web_Server.";

  Config : Aws.Config.Object := AWS.Config.Get_Current;
  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line        : Command_Line_Configuration;
  My_Lock         : Lock.Lock_Type;

   --===========================================================================
  Semaphore : Binary_Semaphores.Semaphore_Type;

  Saved_Web_Sessions : constant String := "/home/bnl/web_sessions.dat";

 
  function Do_Service(Request : in AWS.Status.Data;
                      Method  : in String) return AWS.Response.Data is
    use Calendar2;
    Params     : constant AWS.Parameters.List := AWS.Status.Parameters(Request);
    Context    : constant String := AWS.Parameters.Get(Params,"context");
    Response   : AWS.Response.Data;
    Start      : Calendar2.Time_Type := Calendar2.Clock;
    Service    : constant String := "Do_Service";
    Session_ID : AWS.Session.ID ;
   -- Username   : constant String := AWS.Session.Get(Session_ID, "username");
    Application_JSON : constant String := "application/json";
  begin

    if not AWS.Status.Has_Session(Request) then
      Logging.Log(Service, "NO SESSION EXISTS - Method : " & Method & "' Context : '" & Context & "'" );
      return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S401); -- unauthorized
    end if;      
      
    Session_ID := Aws.Status.Session(Request);
    declare 
      Username   : constant String := AWS.Session.Get(Session_ID, "username");
    begin    
  
      Logging.Log(Service, "Method : " & Method & " Context : " & Context & " Username : '" & Username & "'" );
      
      if Username = "" then
        Logging.Log(Service, "Username blank - needs login");
        return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S401); -- unauthorized
      
      elsif Context="check_logged_in" then        
        declare 
          Params  : constant Aws.Parameters.List := Aws.Status.Parameters(Request);
          Name    : constant String := Aws.Parameters.Get(Params,"username");
        begin

          Logging.Log(Service, "Method : Get" & " Context : '" & Context &
                        "' Username-session: '" & Username & "'" & 
                        "' Username-param: '" & Name & "'" );
          if Username = Name then
            return Aws.Response.Acknowledge (Status_Code => Aws.Messages.S200); -- OK, already logged in
          else             
            return Aws.Response.Acknowledge (Status_Code => Aws.Messages.S401); -- unauthorized
          end if;
        end;
      end if;
      
      
      if Sql.Is_Session_Open then
        Logging.Log(Service, "was already connected, disconnect!");
        Sql.Close_Session;
        Logging.Log(Service, "did disconnect!");
      end if;
      
      
      Sql.Connect
        (Host     => Bot_Ws_Services.Global.Host.Fix_String,
         Port     => Bot_Ws_Services.Global.Port,
         Db_Name  => Username,                                  -- bnl/jmb/msm
         Login    => Bot_Ws_Services.Global.Login.Fix_String, -- always bnl
         Password => Bot_Ws_Services.Global.Password.Fix_String);
      
      if Context="logout" then
        Response := Aws.Response.Build (Application_JSON,
                                        Bot_Ws_Services.Operator_Logout(Username =>  Username,
                                                                        Context  => Context));
      elsif Context="todays_bets" then
        Response := Aws.Response.Build (Application_JSON,
                                        Bot_Ws_Services.Settled_Bets(Username => Username,
                                                                     Context  => Context));
      elsif Context="yesterdays_bets" then
        Response := Aws.Response.Build (Application_JSON,
                                        Bot_Ws_Services.Settled_Bets(Username => Username,
                                                                     Context  => Context));
      elsif Context="thisweeks_bets" then
        Response := Aws.Response.Build (Application_JSON,
                                        Bot_Ws_Services.Settled_Bets(Username => Username,
                                                                     Context  => Context));
      elsif Context="lastweeks_bets" then
        Response := Aws.Response.Build (Application_JSON,
                                        Bot_Ws_Services.Settled_Bets(Username => Username,
                                                                     Context  => Context));
      elsif Context="thismonths_bets" then
        Response := Aws.Response.Build (Application_JSON,
                                        Bot_Ws_Services.Settled_Bets(Username => Username,
                                                                     Context  => Context));
      elsif Context="lastmonths_bets" then
        Response := Aws.Response.Build (Application_JSON,
                                        Bot_Ws_Services.Settled_Bets(Username => Username,
                                                                     Context  => Context));
      elsif Context="todays_bets_total" then
        Response := Aws.Response.Build (Application_JSON,
                                        Bot_Ws_Services.Settled_Bets(Username => Username,
                                                                     Context  => Context,
                                                                     Total_Only => True));
      elsif Context="thisweeks_bets_total" then
        Response := Aws.Response.Build (Application_JSON,
                                        Bot_Ws_Services.Settled_Bets(Username => Username,
                                                                     Context  => Context,
                                                                     Total_Only => True));
      elsif Context="lastweeks_bets_total" then
        Response := Aws.Response.Build (Application_JSON,
                                        Bot_Ws_Services.Settled_Bets(Username => Username,
                                                                     Context  => Context,
                                                                     Total_Only => True));
      elsif Context="thismonths_bets_total" then
        Response := Aws.Response.Build (Application_JSON,
                                        Bot_Ws_Services.Settled_Bets(Username => Username,
                                                                     Context  => Context,
                                                                     Total_Only => True));
      elsif Context="lastmonths_bets_total" then
        Response := Aws.Response.Build (Application_JSON,
                                        Bot_Ws_Services.Settled_Bets(Username => Username,
                                                                     Context  => Context,
                                                                     Total_Only => True));        
      elsif Context="todays_total" then
        Response := Aws.Response.Build (Application_JSON,
                                        Bot_Ws_Services.Todays_Total(Username => Username,
                                                                    Context  => Context));
      elsif Context="sum_todays_bets" then
        Response := Aws.Response.Build (Application_Json,
                                        Bot_Ws_Services.Sum_Settled_Bets(Username => Username,
                                                                         Context  => Context));
      elsif Context="sum_7_days_bets" then
        Response := Aws.Response.Build (Application_Json,
                                        Bot_Ws_Services.Sum_Settled_Bets(Username => Username,
                                                                         Context  => Context));
      elsif Context="sum_thisweeks_bets" then
        Response := Aws.Response.Build (Application_Json,
                                        Bot_Ws_Services.Sum_Settled_Bets(Username => Username,
                                                                         Context  => Context));
      elsif Context="sum_total_bets" then
        Response := Aws.Response.Build (Application_Json,
                                        Bot_Ws_Services.Sum_Settled_Bets(Username => Username,
                                                                         Context  => Context));
      elsif Context="starttimes" then
        Response := Aws.Response.Build (Application_Json,
                                        Bot_Ws_Services.Get_Starttimes(Username => Username,
                                                                       Context  => Context));
      elsif Context="weeks" then
        Response := Aws.Response.Build (Application_Json,
                                        Bot_Ws_Services.Get_Weeks(Username => Username,
                                                                       Context  => Context));
      elsif Context="months" then
        Response := Aws.Response.Build (Application_Json,
                                        Bot_Ws_Services.Get_Months(Username => Username,
                                                                       Context  => Context));
      else
        Response := AWS.Response.Acknowledge (Status_Code => AWS.Messages.S200);
      end if;
      Logging.Log(Service, " Context : " & Context &
                           " Username : " & Username &
                           " Time consumed " & String_Interval(Calendar2.Clock - Start, Days => False));
      
      
      
      Sql.Close_Session;

      return Response;
    end;
    
  end Do_Service;
   --------------------------------------
  function Put (Request : in AWS.Status.Data) return AWS.Response.Data is
  begin
    return Do_Service(Request, "Put");
  end Put;
   --------------------------------------
  function Post (Request : in AWS.Status.Data) return AWS.Response.Data is
     Params     : constant AWS.Parameters.List := AWS.Status.Parameters(Request);
     Username   : constant String := AWS.Parameters.Get(Params,"username");
     Session_ID : constant AWS.Session.ID := Aws.Status.Session(Request);
     Service    : constant String := "Post";
     Application_JSON : constant String := "application/json";
     Response   : AWS.Response.Data;
   begin

    for I in 1.. Aws.Parameters.Count(Params) loop
      Logging.Log(Service, "Post - index: " &
                    I'Img &
                    "->" &
                    Aws.Parameters.Get_Name(Params,I) &
                    "=" &
                    Aws.Parameters.Get_Value(Params,I)
                 );
    end loop;


     Logging.Log(Service, "Username: '" & Username & "'" );
     AWS.Session.Set (Session_ID, "username", Username);
     Response := Aws.Response.Build (Application_JSON,
                                   Bot_Ws_Services.Operator_Login(Username => Username,
                                                                  Password => "",
                                                                  Context  => "login"));
    return Response;
  end Post;
   --------------------------------------
  function Get (Request : in AWS.Status.Data) return AWS.Response.Data is
    use type Ada.Directories.File_Kind;
    URI    : constant String := AWS.Status.URI(Request);
    Params : constant AWS.Parameters.List := AWS.Status.Parameters(Request);
    Context: constant String := AWS.Parameters.Get(Params,"context");
  --  Action : constant String := AWS.Parameters.Get(Params,"action");
    Service    : constant String := "Get";
  begin
--    Logging.Log(Service, "Method : Get" & " Context : '" & Context & "' Action: '" & Action & "' URI: '" & Uri & "'");
    Logging.Log(Service, "Method : Get" & " Context : '" & Context & "' URI: '" & Uri & "'");

    for I in 1.. Aws.Parameters.Count(Params) loop
      Logging.Log(Service, "Get - index: " &
                    I'Img &
                    "->" &
                    Aws.Parameters.Get_Name(Params,I) &
                    "=" &
                    Aws.Parameters.Get_Value(Params,I)
                 );
    end loop;


--      if not AWS.Status.Has_Session(Request) and then
--         URI = "/"   then
--          Logging.Log(Service, "No session...");
--        --  return Aws.Response.File (Content_Type => AWS.MIME.Text_Html,
--        --                            Filename     => AWS.Config.WWW_Root(O => Config) & "betbot.html");
--      end if;
--      declare
--        Session_ID : constant AWS.Session.ID := Aws.Status.Session(Request);
--        Name : constant String := AWS.Session.Get(Session_ID, "username");
--      begin
--        Logging.Log(Service, "check for Username in sessionid: " & Aws.Session.Image(Session_Id));
--        Logging.Log(Service, "Username: '" & Name & "'");
--      --  if Name = "" then
--      --    Logging.Log(Service, "No useful session, returning file : betbot.html");
--      --    return Aws.Response.File (Content_Type => AWS.MIME.Text_Html,
--      --                              Filename     => AWS.Config.WWW_Root(O => Config) & "betbot.html");
--      --  end if;
--      end;

    if Context = "" and URI /= "" then
      if URI = "/" then
        Logging.Log(Service, "Returning file : betbot.html");
        return Aws.Response.File (Content_Type => AWS.MIME.Text_Html,
                                  Filename     => AWS.Config.WWW_Root(O => Config) & "betbot.html");
      else
        declare
          Filename     : constant String := URI (2 .. URI'Last);
          FullFilename : constant String := AWS.Config.WWW_Root(O => Config) & Filename;
        begin
          Logging.Log(Service, "Filename=" & Filename & " returning:" & FullFilename);
          if Ada.Directories.Kind(FullFilename) = Ada.Directories.Ordinary_File then
            return AWS.Response.File(Content_Type => AWS.MIME.Content_Type (FullFilename),
                                     Filename     => FullFilename);
          else
            return AWS.Response.Acknowledge(Messages.S404, "<p>Page '" & URI & "' Not found.</p>");
          end if;
        end;
      end if;
    elsif Context = "flower" then
      declare
        Chipid   : constant String := AWS.Parameters.Get(Params,"chipid");
        Moisture : constant String := AWS.Parameters.Get(Params,"level");
        Result   : Boolean := False;
      begin        
        Result := Bot_Ws_Services.Mail_Moisture_Report(Id => Chipid, Moisture => Integer_4'Value(Moisture));
        if Result then 
          return AWS.Response.Acknowledge(Status_Code => Messages.S201, Message_Body => "Created record", Content_Type => Aws.Mime.Text_Plain);      
        else
          return AWS.Response.Acknowledge(Status_Code => Messages.S500, Message_Body => "Bad thing happened", Content_Type => Aws.Mime.Text_Plain);      
        end if;
      end;          
    elsif Context = "air" then
      declare
        Chipid        : constant String := Aws.Parameters.Get(Params,"chipid");
        Temperature   : constant String := Aws.Parameters.Get(Params,"temp");
        Pressure      : constant String := Aws.Parameters.Get(Params,"pressure");
        Humidity      : constant String := Aws.Parameters.Get(Params,"humidity");
        Gasresistance : constant String := Aws.Parameters.Get(Params,"gasresistance");
      begin        
        Bot_Ws_Services.Log_Air_Quality(Id            => Chipid,
                                        Temperature   => Fixed_Type'Value(Temperature),
                                        Pressure      => Integer_4'Value(Pressure),
                                        Humidity      => Fixed_Type'Value(Humidity),
                                        Gasresistance => Integer_4'Value(Gasresistance));
                                        
        return Aws.Response.Acknowledge(Status_Code => Messages.S201, Message_Body => "Created record", Content_Type => Aws.Mime.Text_Plain);      
      exception
        when E: others =>
          Stacktrace.Tracebackinfo(E);          
          return Aws.Response.Acknowledge(Status_Code => Messages.S500, Message_Body => "Bad thing happened", Content_Type => Aws.Mime.Text_Plain);      
      end;          
    elsif Context = "co2" then
      declare
        Chipid        : constant String := Aws.Parameters.Get(Params,"chipid");
        Co2level      : constant String := Aws.Parameters.Get(Params,"level");
      begin        
        Bot_Ws_Services.Log_C02 (Id    => Chipid,
                                 Level => Integer_4'Value(Co2level));
                                        
        return Aws.Response.Acknowledge(Status_Code => Messages.S201, Message_Body => "Created record", Content_Type => Aws.Mime.Text_Plain);      
      exception
        when E: others =>
          Stacktrace.Tracebackinfo(E);          
          return Aws.Response.Acknowledge(Status_Code => Messages.S500, Message_Body => "Bad thing happened", Content_Type => Aws.Mime.Text_Plain);      
      end;          
    else
      return Do_Service(Request, "Get");
    end if;
  end Get;
  --------------------------------------
  function Head (Request : in AWS.Status.Data) return AWS.Response.Data is
    pragma Unreferenced(Request);
  begin
    Logging.Log("Head", "Method : Head");
    return AWS.Response.Acknowledge (Status_Code => AWS.Messages.S200);
  end Head;
  --------------------------------------
  function Unknown (Request : in AWS.Status.Data) return AWS.Response.Data is
    pragma Unreferenced(Request);
  begin
    Logging.Log ("Unknown", "Method : Unknown");
    return AWS.Response.Acknowledge (Status_Code => Messages.S405);
  end Unknown;
  --------------------------------------

  procedure Wait_Terminate is
    Message : Process_Io.Message_Type;
    Is_Time_To_Exit : Boolean := False;
    Now : Calendar2.Time_Type := Calendar2.Time_Type_First;
    --use Types;
  begin
    loop
      delay 2.0;
      Semaphore.Seize;
      begin
        Process_Io.Receive( Message, Time_Out => 0.01);
        case Process_Io.Identity (Message) is
          when Core_Messages.Exit_Message    =>
            Semaphore.Release;
             Logging.Log("Wait_Terminate",
               "got exit message " & Process_Io.Identity_Type'Image(Process_Io.Identity(Message)));
            exit;
          when others                          =>
             Logging.Log("Wait_Terminate",
               "Received unexpected message " & Process_Io.Identity_Type'Image(Process_Io.Identity(Message)));
        end case;
      exception
        when Process_Io.Timeout => null;
      end;
      Semaphore.Release;

      --restart every day
      Now := Calendar2.Clock;
      Is_Time_To_Exit := Now.Hour = 01 and then
       ( Now.Minute = 00 or Now.Minute = 01) ; -- timeout = 2 min

      exit when Is_Time_To_Exit;

    end loop;
  end Wait_Terminate;

   --------------------------------------

  function Service (Request : in AWS.Status.Data) return AWS.Response.Data is
     use type AWS.Status.Request_Method;
     Answer : AWS.Response.Data;
     URI    : constant String                    := AWS.Status.URI(Request);
     Req    : constant AWS.Status.Request_Method := AWS.Status.Method(Request);
  begin
      Semaphore.Seize;
      Logging.Log("Service", Req'Img & " " & URI);
      case Req is
        when AWS.Status.GET  =>  Answer := Get(Request);
        when AWS.Status.POST =>  Answer := Post(Request);
        when AWS.Status.HEAD =>  Answer := Head(Request);
        when AWS.Status.PUT  =>  Answer := Put(Request);
        when others          =>  Answer := Unknown(Request);
      end case;
      AWS.Session.Save (File_Name => Saved_Web_Sessions);
      Semaphore.Release;
      return Answer;
  exception
    when Bot_Ws_Services.Stop_Process =>
      Semaphore.Release;
      raise;
    when E : others =>
      Semaphore.Release;
      Text_Io.Put_Line(Ada.Exceptions.Exception_Information (E));
      return AWS.Response.Build
           (Content_Type => AWS.MIME.Text_Plain,
            Status_Code => AWS.Messages.S500,
            Message_Body => Ada.Exceptions.Exception_Information (E));
  end Service;

   --------------------------------------

   WS : AWS.Server.HTTP;
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
   --must take lock AFTER becoming a daemon ...
   --The parent pid dies, and would release the lock...
  My_Lock.Take(EV.Value("BOT_NAME"));

  Logging.Open(EV.Value("BOT_TARGET") & "/log/" & EV.Value("BOT_NAME") & ".log");
  Logging.Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
  Bot_Ws_Services.Global.Initialize;

  Logging.Log("Main", "AWS " & AWS.Version & " starting at port 9080" );
  AWS.Config.Set.Server_Name             (O => Config, Value => "BetBot");
  AWS.Config.Set.Max_Connection          (O => Config, Value => 8);
  AWS.Config.Set.Server_Port             (O => Config, Value => 9080);
  AWS.Config.Set.Session                 (O => Config, Value => True);
  AWS.Config.Set.Log_File_Directory      (O => Config, Value => Ev.Value("BOT_TARGET") & "/log" );
  AWS.Config.Set.Reuse_Address           (O => Config, Value => True);
  AWS.Config.Set.WWW_Root                (O => Config, Value => Ev.Value("BOT_SOURCE") & "/ada/bot_ws/html");

  Logging.Log (Me, "WWW_Root: " & AWS.Config.WWW_Root (O => Config));
  if AD.Exists (Saved_Web_Sessions) then
    AWS.Session.Load(File_Name => Saved_Web_Sessions);
  end if;

  AWS.Server.Start (Web_Server     => WS,
                    Callback       => Service'Unrestricted_Access,
                    Config         => Config);

  AWS.Server.Log.Start (Web_Server => WS,
                        Split_Mode => Aws.Log.Daily,
                        Auto_Flush => True);

  AWS.Server.Log.Start_Error(Web_Server => WS,
                             Split_Mode => Aws.Log.Daily);
  Logging.Log("Main", "Log file name:" & AWS.Server.Log.Name (WS));

  declare -- prefill list at startup to always get whole day
    Dummy : String := Bot_Ws_Services.Get_Starttimes("noone","startup");
  begin
    null;
  end;

  Wait_Terminate;
  AWS.Server.Shutdown (WS);
  AWS.Server.Log.Stop      (Web_Server => WS);
  AWS.Server.Log.Stop_Error(Web_Server => WS);
exception
  when Bot_Ws_Services.Stop_Process =>
    AWS.Server.Shutdown (WS);
    AWS.Server.Log.Stop      (Web_Server => WS);
    AWS.Server.Log.Stop_Error(Web_Server => WS);
end Bot_Web_Server;
