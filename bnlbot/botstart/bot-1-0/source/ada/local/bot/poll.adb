--with Text_Io;
with Sattmate_Exception;
with Sattmate_Types; use Sattmate_Types;
with Bot_Types; use Bot_Types;
with Sql;
with General_Routines; use General_Routines;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Sattmate_Calendar; use Sattmate_Calendar;
with Bot_Messages;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Rpc;
with Lock ;
with Posix;
with Ini;
with Logging; use Logging;
with Ada.Environment_Variables;
with Process_IO;
with Core_Messages;
with Table_Amarkets;
with Table_Aevents;
with Table_Aprices;
with Table_Abets;
with Table_Arunners;

with Bot_Svn_Info;
with Bet;
with Config;

procedure Poll is
  package EV renames Ada.Environment_Variables;

  use type Rpc.Result_Type;

  Me : constant String := "Poll.";

  Timeout  : Duration := 120.0;
  My_Lock  : Lock.Lock_Type;

  Msg      : Process_Io.Message_Type;
  Find_Plc_Market,
  Update_Betwon_To_Null : Sql.Statement_Type;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line : Command_Line_Configuration;

--  Global_Size : Bet_Size_type := 30.0;
--  Global_Fav_Max_Price : Back_Price_Type := 1.15;
--  Global_2nd_Min_Price : Back_Price_Type := 7.0;
  Now : Sattmate_Calendar.Time_Type;
--  Global_Max_Loss_Per_Day : Float_8 := -500.0;
--  Global_Max_Turns_Not_Started_Race    : Integer_4 := 17;  --17*30s -> 8.5 min

--  Global_Enabled,
  Ok,
  Is_Time_To_Exit : Boolean := False;
  Cfg : Config.Config_Type;
  -------------------------------------------------------------

  -------------------------------------------------------------
  procedure Run(Market_Notification : in     Bot_Messages.Market_Notification_Record) is
    Market    : Table_Amarkets.Data_Type;
    Event     : Table_Aevents.Data_Type;
    Price_List : Table_Aprices.Aprices_List_Pack.List_Type := Table_Aprices.Aprices_List_Pack.Create;
    Price,Tmp : Table_Aprices.Data_Type;
    In_Play   : Boolean := False;
    Best_Runners : array (1..2) of Table_Aprices.Data_Type := (others => Table_Aprices.Empty_Data);
    Eol,Eos : Boolean := False;
    type Market_Type is (Win, Place);
    Markets : array (Market_Type'range) of Table_Amarkets.Data_Type;
    Bet_Name : Bet_Name_Type := (others => ' ');
    Found_Place : Boolean := True;
    T : Sql.Transaction_Type;
    Current_Turn_Not_Started_Race : Integer_4 := 0;

  begin
    Log(Me & "Run", "Treat market: " &  Market_Notification.Market_Id);

    Market.Marketid := Market_Notification.Market_Id;

    Move("HORSES_WIN_BACK_FINISH_1.10_7.0", Bet_Name);
    if Bet.Profit_Today(Bet_Name) < Cfg.Max_Loss_Per_Day then
      Log(Me & "Run", "lost too much today, max loss is " & F8_Image(Cfg.Max_Loss_Per_Day));
      return;
    end if;

    Table_Amarkets.Read(Market, Eos);
    if not Eos then
      if  Market.Markettype(1..3) /= "WIN"  then
        Log(Me & "Run", "not a WIN market: " &  Market_Notification.Market_Id);
        return;
      else
        Event.Eventid := Market.Eventid;
        Table_Aevents.Read(Event, Eos);
        if not Eos then
          if Event.Eventtypeid /= Integer_4(7) then
            Log(Me & "Run", "not a HORSE market: " &  Market_Notification.Market_Id);
            return;
          elsif not Cfg.Country_Is_Ok(Event.Countrycode) then
--          elsif Event.Countrycode(1..2) /= "GB" then
            Log(Me & "Run", "not an country,  market: " &  Market_Notification.Market_Id);
            return;
          end if;
        else
          Log(Me & "Run", "no event found");
          return;
        end if;
      end if;
    else
      Log(Me & "Run", "no market found");
      return;
    end if;
    Markets(Win):= Market;

    T.Start;
      Find_Plc_Market.Prepare(
        "select MP.* from AMARKETS MW, AMARKETS MP " &
        "where MW.EVENTID = MP.EVENTID " &
        "and MW.STARTTS = MP.STARTTS " &
        "and MW.MARKETID = :WINMARKETID " &
        "and MP.MARKETTYPE = 'PLACE' " &
        "and MW.MARKETTYPE = 'WIN' " &
        "and MP.STATUS = 'OPEN'" ) ;

      Find_Plc_Market.Set("WINMARKETID", Markets(Win).Marketid);
      Find_Plc_Market.Open_Cursor;
      Find_Plc_Market.Fetch(Eos);
      if not Eos then
        Markets(Place) := Table_Amarkets.Get(Find_Plc_Market);
        if Markets(Win).Startts /= Markets(Place).Startts then
           Log(Me & "Make_Bet", "Wrong PLACE market found, give up");
           Found_Place := False;
        end if;
      else
        Log(Me & "Make_Bet", "no PLACE market found");
        Found_Place := False;
      end if;
      Find_Plc_Market.Close_Cursor;
    T.Commit;

    -- do the poll
    Poll_Loop : loop
      Table_Aprices.Aprices_List_Pack.Remove_All(Price_List);
      Rpc.Get_Market_Prices(Market_Id  => Market_Notification.Market_Id,
                            Market     => Market,
                            Price_List => Price_List,
                            In_Play    => In_Play);

      exit when Market.Status(1..4) /= "OPEN";

      if not In_Play then
        if Current_Turn_Not_Started_Race >= Cfg.Max_Turns_Not_Started_Race then
           Log(Me & "Make_Bet", "Market took too long time to start, give up");
           exit Poll_Loop;
        else
          Current_Turn_Not_Started_Race := Current_Turn_Not_Started_Race +1;
          delay 30.0; -- no need for heavy polling before start of race
        end if;
      else
        delay 0.05; -- to avoid more than 20 polls/sec
      end if;

      -- ok find the runner with lowest backprice:
      Price.Backprice := 10000.0;
      Table_Aprices.Aprices_List_Pack.Get_First(Price_List,Tmp,Eol);
      loop
        exit when Eol;
        if Tmp.Status(1..6) = "ACTIVE" and then
           Tmp.Backprice < Price.Backprice then
          Price := Tmp;
        end if;
        Table_Aprices.Aprices_List_Pack.Get_Next(Price_List,Tmp,Eol);
      end loop;
      Best_Runners(1) := Price;
      -- find #2
      Price.Backprice := 10000.0;
      Table_Aprices.Aprices_List_Pack.Get_First(Price_List,Tmp,Eol);
      loop
        exit when Eol;
        if Tmp.Status(1..6) = "ACTIVE" and then
           Tmp.Backprice < Price.Backprice and then
           Tmp.Selectionid /= Best_Runners(1).Selectionid then
          Price := Tmp;
        end if;
        Table_Aprices.Aprices_List_Pack.Get_Next(Price_List,Tmp,Eol);
      end loop;
      Best_Runners(2) := Price;

      for i in Best_Runners'range loop
        Log("Best_Runners(i) " & i'Img & Table_Aprices.To_String(Best_Runners(i)));
      end loop;

      if Best_Runners(1).Backprice <= Float_8(Cfg.Fav_Max_Price) and then
         Best_Runners(1).Backprice >= Float_8(1.0) and then
         Best_Runners(2).Backprice >= Float_8(Cfg.Second_Fav_Min_Price) then
        Log("Place bet on " & Table_Aprices.To_String(Best_Runners(1)));

        declare
          Bet : Table_Abets.Data_Type;
--          Market_Id : Market_Id_Type := (others => ' ');
          Runner : Table_Arunners.Data_Type;
--          Runner_Name : Runner_Name_Type := (others => ' ');
          Eos : Boolean := False;
        begin
        Log("Found_Place " & Found_Place'Img );

          if Found_Place and then Markets(Place).Numwinners >= Integer_4(3) then
            declare
              PBB : Bot_Messages.Place_Back_Bet_Record;
              Receiver : Process_Io.Process_Type := ((others => ' '),(others => ' '));
            begin
              Move("HORSES_PLC_BACK_FINISH_1.10_7.0_1", PBB.Bet_Name);
              Move(Markets(Place).Marketid, PBB.Market_Id);
              Move("1.01", PBB.Price);
              Move("0.0", PBB.Size); -- set by receiver's ini-file
              PBB.Selection_Id := Best_Runners(1).Selectionid;
              Move("bet_placer_1", Receiver.Name);
              Log("ping '" &  Trim(Receiver.Name) & "' with bet '" & Trim(PBB.Bet_Name) & "' sel.id:" &  PBB.Selection_Id'Img );
              Bot_Messages.Send(Receiver, PBB);
            end;
--            declare
--              PBB : Bot_Messages.Place_Back_Bet_Record;
--              Receiver : Process_Io.Process_Type := ((others => ' '),(others => ' '));
--            begin
--              Move("HORSES_PLC_BACK_FINISH_1.15_7.0_2", PBB.Bet_Name);
--              Move(Markets(Place).Marketid, PBB.Market_Id);
--              Move("1.01", PBB.Price);
--              Move("0.0", PBB.Size); -- set by receiver's ini-file
--              PBB.Selection_Id := Best_Runners(2).Selectionid;
--              Move("bet_placer_2", Receiver.Name);
--              Log("ping '" &  Trim(Receiver.Name) & "' with bet '" & Trim(PBB.Bet_Name) & "' sel.id:" &  PBB.Selection_Id'Img );
--              Bot_Messages.Send(Receiver, PBB);
--            end;
          end if;

          -- fix som missing fields first
          Runner.Marketid := Markets(Win).Marketid;
          Runner.Selectionid := Best_Runners(1).Selectionid;
          Table_Arunners.Read(Runner, Eos);
          if not Eos then
            Bet.Runnername := Runner.Runnername;
          else
            Log(Me & "Make_Bet", "no runnername found");
          end if;

          -- the LEADER as WIN at the price

          Rpc.Place_Bet (Bet_Name         => Bet_Name,
                         Market_Id        => Markets(Win).Marketid,
                         Side             => Back,
                         Runner_Name      => Runner.Runnername,
                         Selection_Id     => Best_Runners(1).Selectionid,
                         Size             => Cfg.Size,
                         Price            => 1.01,
                         Bet_Persistence  => Persist,
                         Bet              => Bet);

          T.Start;
            Bet.Startts := Markets(Win).Startts;
            Bet.Fullmarketname := Markets(Win).Marketname;
            Table_Abets.Insert(Bet);
            Log(Me & "Make_Bet", General_Routines.Trim(Bet_Name) & " inserted bet: " & Table_Abets.To_String(Bet));
            if General_Routines.Trim(Bet.Exestatus) = "SUCCESS" then
              Update_Betwon_To_Null.Prepare("update ABETS set BETWON = null where BETID = :BETID");
              Sql.Set(Update_Betwon_To_Null,"BETID", Bet.Betid);
              Sql.Execute(Update_Betwon_To_Null);
            end if;
          T.Commit;
        end ;
        exit Poll_Loop;
      end if;
    end loop Poll_Loop;
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

  Logging.Open(EV.Value("BOT_HOME") & "/log/poll.log");

  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  Cfg := Config.Create(Ev.Value("BOT_HOME") & "/" & Sa_Par_Inifile.all);
  Log(Cfg.To_String);
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

  if Cfg.Enabled then
    Cfg.Enabled := Ev.Value("BOT_MACHINE_ROLE") = "PROD";
  end if;

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
        when Bot_Messages.Market_Notification_Message    =>
          if Cfg.Enabled then
            Run(Bot_Messages.Data(Msg));
          else
            Log(Me, "Poll is not eanbled in poll.ini");
          end if;
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
    Now := Sattmate_Calendar.Clock;

    --restart every day
    Is_Time_To_Exit := Now.Hour = 05 and then
                     ( Now.Minute = 02 or Now.Minute = 03) ; -- timeout = 2 min

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
  when E: others => Sattmate_Exception.Tracebackinfo(E);
    Log(Me, "Close Db");
    Sql.Close_Session;
    Log(Me, "Closed log and die");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
end Poll;

