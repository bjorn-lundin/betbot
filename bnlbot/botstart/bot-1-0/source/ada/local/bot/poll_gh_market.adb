with Ada.Exceptions;
with Ada.Command_Line;
with Ada.Environment_Variables;
with Ada.Strings ; use Ada.Strings;
with Ada.Strings.Fixed ; use Ada.Strings.Fixed;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

with Stacktrace;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Sql;
with Calendar2; use Calendar2;
with Bot_Messages;
with Rpc;
with Lock ;
with Posix;
with Ini;
with Logging; use Logging;
with Process_IO;
with Core_Messages;
with Table_Amarkets;
with Table_Aevents;
with Table_Arunners;
with Table_Aprices;
with Table_Abets;
with Table_Apriceshistory;
with Bot_Svn_Info;
with Utils; use Utils;
with Sim;

procedure Poll_GH_Market is
  package EV renames Ada.Environment_Variables;
  use type Rpc.Result_Type;

  Me              : constant String := "Poll_Market.";
  Timeout         : Duration := 120.0;
  My_Lock         : Lock.Lock_Type;
  Msg             : Process_Io.Message_Type;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line        : Command_Line_Configuration;
  Now             : Calendar2.Time_Type;
  Ok,
  Is_Time_To_Exit : Boolean := False;
  -------------------------------------------------------------
  This_Process    : Process_Io.Process_Type := Process_IO.This_Process;
  Markets_Fetcher : Process_Io.Process_Type := (("gh_mark_fetcher"),(others => ' '));
  Data : Bot_Messages.Poll_State_Record ;
  Update_Betwon_To_Null : Sql.Statement_Type;


  procedure Run(Market_Notification : in Bot_Messages.Market_Notification_Record) is
    Market    : Table_Amarkets.Data_Type;
    Event     : Table_Aevents.Data_Type;
    Price_List : Table_Aprices.Aprices_List_Pack2.List;
    --------------------------------------------

    Priceshistory_Data : Table_Apriceshistory.Data_Type;
    Priceshistory_List : Table_Apriceshistory.Apriceshistory_List_Pack2.List;
    --  Has_Been_In_Play,
    In_Play           : Boolean := False;

    Eos               : Boolean := False;
    T                 : Sql.Transaction_Type;
    --  Current_Turn_Not_Started_Race : Integer_4 := 0;
    Is_Data_Collector : Boolean := EV.Value("BOT_USER") = "ghd" and then EV.Value("BOT_NAME")(1..12) = "poll_market_";

    type Bet_Types is (D4_2, D3_7, D2_8);
    Has_Placed : array (Bet_Types'range) of Boolean := (others => False);
    Lay_Stake  : constant Bet_Size_Type := 30.0;

  begin
    Log(Me & "Run", "Treat market: " &  Market_Notification.Market_Id);
    Market.Marketid := Market_Notification.Market_Id;

    Market.Read(Eos);
    if not Eos then
      if Market.Markettype(1..3) = "WIN" or
         Market.Markettype(1..5) = "PLACE"  then
        Event.Eventid := Market.Eventid;
        Event.Read(Eos);
        if not Eos then
          if Event.Eventtypeid /= Integer_4(4339) then
            Log(Me & "Run", "not a GREYHOUND market: " &  Market_Notification.Market_Id);
            return;
          end if;
        else
          Log(Me & "Run", "no event found");
          return;
        end if;
      else
        Log(Me & "Run", "not a WIN nor PLACE market: " &  Market_Notification.Market_Id);
        return;
      end if;
    else
      Log(Me & "Run", "no market found");
      return;
    end if;

    -- do the poll
    Poll_Loop : loop
      Price_List.Clear;
      Rpc.Get_Market_Prices(Market_Id  => Market_Notification.Market_Id,
                            Market     => Market,
                            Price_List => Price_List,
                            In_Play    => In_Play);

      if not Is_Data_Collector then
        --place bet and exit
        declare
          Betname : Bet_Name_Type := (others => ' ');
          Runner  : Table_Arunners.Data_Type;
          Eos     : Boolean := False;
          Laybet  : Table_Abets.Data_Type;
        begin
          T.Start;
          Update_Betwon_To_Null.Prepare("update ABETS set BETWON = null where BETID = :BETID");
          for Price of Price_List loop
            Runner.Marketid := Price.Marketid;
            Runner.Selectionid := Price.Selectionid;
            Runner.Read(Eos);
            Laybet := Table_Abets.Empty_Data;
            if not Has_Placed(D4_2) and then
               Price.Layprice > Float_8(1.0) and then
               Price.Layprice <= Float_8(4.2) then
               Move("LAY_DOGS_MAX_4.2", Betname);
               Sim.Place_Bet(Bet_Name         => Betname,
                             Market_Id        => Market.Marketid,
                             Side             => Lay,
                             Runner_Name      => Runner.Runnernamestripped,
                             Selection_Id     => Price.Selectionid,
                             Size             => Lay_Stake,
                             Price            => Bet_Price_Type(Price.Layprice),
                             Bet_Persistence  => Persist,
                             Bet_Placed       => Price.Pricets,
                             Bet              => Laybet ) ;
               Log("insert Bet " & Laybet.To_String );
               Laybet.Insert;
             --  Has_Placed(D4_2) := True;
               Update_Betwon_To_Null.Set("BETID", Laybet.Betid);
               Update_Betwon_To_Null.Execute; 
               
            end if;
            if not Has_Placed(D3_7) and then
               Price.Layprice > Float_8(1.0) and then
               Price.Layprice <= Float_8(3.7) then
               Move("LAY_DOGS_MAX_3.7", Betname);
               Sim.Place_Bet(Bet_Name         => Betname,
                             Market_Id        => Market.Marketid,
                             Side             => Lay,
                             Runner_Name      => Runner.Runnernamestripped,
                             Selection_Id     => Price.Selectionid,
                             Size             => Lay_Stake,
                             Price            => Bet_Price_Type(Price.Layprice),
                             Bet_Persistence  => Persist,
                             Bet_Placed       => Price.Pricets,
                             Bet              => Laybet ) ;
               Log("insert Bet " & Laybet.To_String );
               Laybet.Insert;
               Update_Betwon_To_Null.Set("BETID", Laybet.Betid);
               Update_Betwon_To_Null.Execute; 
             --  Has_Placed(D3_7) := True;
            end if;
            if not Has_Placed(D2_8) and then
               Price.Layprice > Float_8(1.0) and then
               Price.Layprice <= Float_8(2.8) then
               Move("LAY_DOGS_MAX_2.8", Betname);
               Sim.Place_Bet(Bet_Name         => Betname,
                             Market_Id        => Market.Marketid,
                             Side             => Lay,
                             Runner_Name      => Runner.Runnernamestripped,
                             Selection_Id     => Price.Selectionid,
                             Size             => Lay_Stake,
                             Price            => Bet_Price_Type(Price.Layprice),
                             Bet_Persistence  => Persist,
                             Bet_Placed       => Price.Pricets,
                             Bet              => Laybet ) ;
               Log("insert Bet " & Laybet.To_String );
               Laybet.Insert;
               Update_Betwon_To_Null.Set("BETID", Laybet.Betid);
               Update_Betwon_To_Null.Execute; 
            --   Has_Placed(D2_8) := True;
            end if;
          end loop;
          T.Commit;
        exception
          when Sql.Duplicate_Index =>
             T.Rollback;
             Log("Duplicate_Index on Bet " & Laybet.To_String );
        end;
        return;
      end if;


      if Is_Data_Collector then
        for Price of Price_List loop
         Priceshistory_Data := (
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
         Priceshistory_List.Append(Priceshistory_Data);
        end loop;
      end if;

      exit Poll_Loop when Market.Status(1..4) /= "OPEN";

      delay 0.05;

    end loop Poll_Loop;

    if Is_Data_Collector then
      -- insert all the records now, in Priceshistory
      Log("start insert records into Priceshistory:" & Priceshistory_List.Length'Img);
      for Priceshistory_Data of Priceshistory_List loop
        begin
          T.Start;  -- try save as many in the list as possible
          Priceshistory_Data.Insert;
          T.Commit;
        exception
          when Sql.Duplicate_Index =>
             T.Rollback;
             Log("Duplicate_Index on Priceshistory " & Priceshistory_Data.To_String );
        end;
      end loop;
      Log("stop insert record into Priceshistory");
    end if;
  end Run;
  ---------------------------------------------------------------------
  use type Sql.Transaction_Status_Type;
------------------------------ main start -------------------------------------

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
    --notify markets_fetcher that we are free
      Data := (Free => 1, Name => This_Process.Name , Node => This_Process.Node);
      Bot_Messages.Send(Markets_Fetcher, Data);

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
        when Bot_Messages.Market_Notification_Message    =>
          --notfy markets_fetcher that we are busy
          Data := (Free => 0, Name => This_Process.Name , Node => This_Process.Node);
          Bot_Messages.Send(Markets_Fetcher, Data);
          Run(Bot_Messages.Data(Msg));
        when others =>
          Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Rpc.Keep_Alive(OK);
        if not OK then
          Rpc.Login;
        end if;
    end;
    Now := Calendar2.Clock;

    --restart every day
    Is_Time_To_Exit := Now.Hour = 01 and then
                     ( Now.Minute = 00 or Now.Minute = 01) ; -- timeout = 2 min

    exit Main_Loop when Is_Time_To_Exit;

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
end Poll_GH_Market;

