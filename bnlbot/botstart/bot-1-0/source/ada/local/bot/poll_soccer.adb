with Ada.Exceptions;
with Ada.Command_Line;
with Ada.Environment_Variables;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

with Stacktrace;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Sql;
with Calendar2; use Calendar2;
with Rpc;
with Lock ;
with Posix;
with Ini;
with Logging; use Logging;
with Process_IO;
with Core_Messages;
with Markets;
with Prices;
with Price_Histories;
with Bot_Svn_Info;
with Utils; use Utils;

procedure Poll_Soccer is
  package EV renames Ada.Environment_Variables;
  use type Rpc.Result_Type;

  Me              : constant String := "Poll_Market.";
  My_Lock         : Lock.Lock_Type;
  Msg             : Process_Io.Message_Type;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line        : Command_Line_Configuration;
  Now             : Calendar2.Time_Type;
  Ok              : Boolean := False;
  Select_Markets : Sql.Statement_Type;
  -------------------------------------------------------------
  
  
  procedure Back_The_Leader(Price_History_List : Price_Histories.Lists.List) is
  begin
    null;
  end Back_The_Leader;
  -------------------------------------------------------------
  procedure Lay_The_Draw(Price_History_List : Price_Histories.Lists.List) is
  begin
    null;
  end Lay_The_Draw;
  
  
  procedure Run(Market : in out Markets.Market_Type) is
    Price_List         : Prices.Lists.List;
    Price_History_List : Price_Histories.Lists.List;
    Price_History_Data : Price_Histories.Price_History_Type;    
    T                 : Sql.Transaction_Type;
    In_Play : Boolean := False;
    pragma Warnings(Off, In_Play);
  begin
    Log(Me & "Run", "Treat market: " &  Market.To_String);

    -- do the poll
    --Price_List.Clear;
    Rpc.Get_Market_Prices(Market_Id  => Market.Marketid,
                          Market     => Market,
                          Price_List => Price_List,
                          In_Play    => In_Play);
                            
    --Priceshistory_List.Clear; --we do insert after every poll here
    begin
      T.Start;
      for Price of Price_List loop
        Price_History_Data := (
                               Marketid     => Price.Marketid,
                               Selectionid  => Price.Selectionid,
                               Pricets      => Price.Pricets,
                               Status       => Price.Status,
                               Totalmatched => Price.Totalmatched,
                               Backprice    => Price.Backprice,
                               Layprice     => Price.Layprice,
                               Ixxlupd      => Price.Ixxlupd,
                               Ixxluts      => Price.Ixxluts
                              );
        Price.Update;                      
        Price_History_List.Append(Price_History_Data);
      end loop;
      Log("insert records into Priceshistory:" & Price_History_List.Length'Img);
      for Phd of Price_History_List loop
        Phd.Insert;
      end loop;
      T.Commit;
      
      Back_The_Leader(Price_History_List);
      Lay_The_Draw(Price_History_List);
      
    exception
      when Sql.Duplicate_Index =>
        T.Rollback;
        Log("Duplicate_Index on Priceshistory " );
      when Sql.No_Such_Row =>
        T.Rollback;
        Log("No_Such_Row on Prices ");
    end;       

  end Run;
  ---------------------------------------------------------------------
  procedure Find_Markets is
    Market_List : Markets.Lists.List;
    T           : Sql.Transaction_Type;
  begin 
    T.Start;
      Select_Markets.Prepare(
        "select * from AMARKETS M, AEVENTS E " &
        "where M.EVENTID = E.EVENTID " &
        "and M.MARKETTYPE in ('CORRECT_SCORE','MATCH_ODDS') " &
        "and M.STATUS = 'OPEN' " &
        "and E.EVENTTYPEID = 1 " & --soccer
        "order by M.STARTTS,M.MARKETID ");
      Markets.Read_List(Select_Markets,Market_List);
    T.Commit;
  
    for Market of Market_List loop
      Run(Market => Market);
    end loop;  
  
  end Find_Markets;
  -----------------------------------------------------
  
  use type Sql.Transaction_Status_Type;
  Timeout         : Duration := 1.0;
  
  ------------------------------ main start ---------------
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

  Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");

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
    -- Ask a pythonscript to login for us, returning a token
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


  Main_Loop : loop
  
    begin
      Log(Me, "Start receive");
      Process_Io.Receive(Msg, Timeout);
      Log(Me, "msg : "& Process_Io.Identity(Msg)'Img & " from " & Trim(Process_Io.Sender(Msg).Name));
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
        Timeout := 42.0;
        Rpc.Keep_Alive(OK);
        if not OK then
          Rpc.Login;
        end if;
        Find_Markets;       
    end;
    Now := Calendar2.Clock;

    --restart every day
    exit Main_Loop when Now.Hour = 01 and then Now.Minute <= 02;

  end loop Main_Loop;

  Log(Me, "Close Db");
  Sql.Close_Session;
  Rpc.Logout;
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
end Poll_Soccer;
