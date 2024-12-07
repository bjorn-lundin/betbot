with Ada.Exceptions;
with Ada.Command_Line;
with Stacktrace;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Sql;
--with General_Routines; use General_Routines;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Calendar2; use Calendar2;
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
--with Table_Abets;
--with Table_Arunners;
with Table_Apricesfinish;
with Table_Abalances;
with Bot_Svn_Info;
with Bet;
with Config;
with Utils; use Utils;

procedure Poll_Place is
  package EV renames Ada.Environment_Variables;
  use type Rpc.Result_Type;

  Me : constant String := "Poll.";
  Timeout  : Duration := 120.0;
  My_Lock  : Lock.Lock_Type;
  Msg      : Process_Io.Message_Type;
  --Find_Plc_Market : Sql.Statement_Type;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line : Command_Line_Configuration;

  Now : Calendar2.Time_Type;
  Ok,
  Is_Time_To_Exit : Boolean := False;
  Cfg : Config.Config_Type;
  -------------------------------------------------------------
  -- type-of-bet_bet-number_placement-in-race-at-time-of-bet
  type Bet_Type is (Back_1_1, Back_1_1_Marker,
                    Back_2_1, Back_2_1_Marker,
                    Back_3_1, Back_3_1_Marker,
                    Back_4_1, Back_4_1_Marker,
                    Back_5_1, Back_5_1_Marker,
                    Back_6_1, Back_6_1_Marker,
                    Back_7_1, Back_7_1_Marker);

  type Allowed_Type is record
    Bet_Name          : Bet_Name_Type := (others => ' ');
    Bet_Size          : Bet_Size_Type := 0.0;
    Is_Allowed_To_Bet : Boolean := False;
    Has_Betted        : Boolean := False;
    Max_Loss_Per_Day  : Bet_Size_Type := 0.0;
  end record;

  Bets_Allowed : array (Bet_Type'range) of Allowed_Type;

  --------------------------------------------------------------
  function To_Pio_Name(S : String ) return Process_Io.Name_Type is
    P :  Process_Io.Name_Type := (others => ' ');
  begin
    Move(S,P);
    return P;
  end To_Pio_Name;

  --------------------------------------------------------------
  procedure Send_Bet(Selectionid                         : Integer_4;
                     Main_Bet, Marker_Bet                : Bet_Type;
                     Place_Market_Id                     : Market_Id_Type;
                     Receiver_Name, Receiver_Marker_Name : Process_Io.Name_Type) is

    PBB             : Bot_Messages.Place_Back_Bet_Record;
    Receiver        : Process_Io.Process_Type := ((others => ' '),(others => ' '));
    PBB_Marker      : Bot_Messages.Place_Back_Bet_Record;
    Receiver_Marker : Process_Io.Process_Type := ((others => ' '),(others => ' '));
    Did_Bet : array(1..2) of Boolean := (others => False);
  begin
    return;
    pragma Compile_Time_Warning(True, "poll on PLACE are NOT allowed not place bets!");
    PBB.Bet_Name := Bets_Allowed(Main_Bet).Bet_Name;
    Move(Place_Market_Id, PBB.Market_Id);
    Move("1.01", PBB.Price);
    PBB.Selection_Id := Selectionid;

    if not Bets_Allowed(Main_Bet).Has_Betted and then
           Bets_Allowed(Main_Bet).Is_Allowed_To_Bet then
      Move(F8_Image(Float_8(Bets_Allowed(Main_Bet).Bet_Size)), PBB.Size);
      Move(Receiver_Name, Receiver.Name);
      Bot_Messages.Send(Receiver, PBB);
      Bets_Allowed(Main_Bet).Has_Betted := True;
      Did_Bet(1) := True;
    end if;

    --marker
    if not Bets_Allowed(Marker_Bet).Has_Betted and then
           Bets_Allowed(Marker_Bet).Is_Allowed_To_Bet then
      PBB_Marker := PBB;
      PBB_Marker.Bet_Name := Bets_Allowed(Marker_Bet).Bet_Name;
      Move(F8_Image(Float_8(Bets_Allowed(Marker_Bet).Bet_Size)), PBB_Marker.Size);
      Move(Receiver_Marker_Name , Receiver_Marker.Name);
      Bot_Messages.Send(Receiver_Marker, PBB_Marker);
      Bets_Allowed(Marker_Bet).Has_Betted := True;
      Did_Bet(2) := True;
    end if;

    Log("Send_Bet called with " &
         " Selectionid=" & Selectionid'Img &
         " Main_Bet=" & Main_Bet'Img &
         " Marker_Bet=" & Marker_Bet'Img &
         " Place_Market_Id= '" & Place_Market_Id & "'" &
         " Receiver_Name= '" & Receiver_Name & "'" &
         " Receiver_Marker_Name= '" & Receiver_Marker_Name & "'" );

    -- just to save time between logs
    if Did_Bet(1) then
      Log("pinged '" &  Trim(Receiver.Name) & "' with bet '" & Trim(PBB.Bet_Name) & "' sel.id:" &  PBB.Selection_Id'Img );
    end if;

    if Did_Bet(2) then
      Log("pinged '" &  Trim(Receiver_Marker.Name) & "' with bet '" & Trim(PBB_Marker.Bet_Name) & "' sel.id:" &  PBB_Marker.Selection_Id'Img );
    end if;
  end Send_Bet;

  -------------------------------------------------------------------------------------------------------------------

  procedure Run(Market_Notification : in Bot_Messages.Market_Notification_Record) is
    Market    : Table_Amarkets.Data_Type;
    Event     : Table_Aevents.Data_Type;
    Price_List : Table_Aprices.Aprices_List_Pack2.List;

    function "<" (Left,Right : Table_Aprices.Data_Type) return Boolean is
    begin
      return Left.Backprice < Right.Backprice;
    end "<";

    package Backprice_Sorter is new  Table_Aprices.Aprices_List_Pack2.Generic_Sorting("<");  
    
    Price_Finish      : Table_Apricesfinish.Data_Type;
    Price_Finish_List : Table_Apricesfinish.Apricesfinish_List_Pack2.List;

    Price : Table_Aprices.Data_Type;
    Has_Been_In_Play,
    In_Play   : Boolean := False;
    Best_Runners : array (1..4) of Table_Aprices.Data_Type := (others => Table_Aprices.Empty_Data);
    Eos : Boolean := False;
    type Market_Type is (Win, Place);
    Markets : array (Market_Type'range) of Table_Amarkets.Data_Type;
    Found_Place : Boolean := True;
    T : Sql.Transaction_Type;
    Current_Turn_Not_Started_Race : Integer_4 := 0;
    Betfair_Result : Rpc.Result_Type := Rpc.Result_Type'first;
    Saldo : Table_Abalances.Data_Type;

    Is_Data_Collector : Boolean := EV.Value("BOT_USER") = "dry" ;

  begin
    Log(Me & "Run", "Treat market: " &  Market_Notification.Market_Id);

    --set values from cfg
    for i in Bets_Allowed'range loop
      Bets_Allowed(i).Bet_Size   := Cfg.Size;
      Bets_Allowed(i).Has_Betted := False;
      Bets_Allowed(i).Max_Loss_Per_Day := Bet_Size_Type(Cfg.Max_Loss_Per_Day);

      -- marker bets are always 30 :-
      if Ada.Strings.Fixed.Index(i'Img, "MARKER") > Natural(0) then
        Bets_Allowed(i).Bet_Size := 30.0;
      end if;

    end loop;

    Market.Marketid := Market_Notification.Market_Id;

    Move("DR_HORSES_PLC_BACK_FINISH_1.10_7.0_5",     Bets_Allowed(Back_1_1).Bet_Name);
    Move("DR_HORSES_PLC_BACK_FINISH_1.25_12.0_5",    Bets_Allowed(Back_2_1).Bet_Name);
    Move("DR_HORSES_PLC_BACK_FINISH_1.40_30.0_5",    Bets_Allowed(Back_5_1).Bet_Name);    
    Move("DR_HORSES_PLC_BACK_FINISH_1.50_30.0_5",    Bets_Allowed(Back_6_1).Bet_Name);
    Move("DR_HORSES_PLC_BACK_FINISH_1.30_15.0_5",    Bets_Allowed(Back_4_1).Bet_Name);
    
    Move("DR_HORSES_PLC_BACK_FINISH_1.30_20.0_5", Bets_Allowed(Back_7_1).Bet_Name);
    Move("DR_HORSES_PLC_BACK_FINISH_1.50_20.0_5", Bets_Allowed(Back_3_1).Bet_Name);

    --markers
    Move("MR_HORSES_PLC_BACK_FINISH_1.10_7.0_5",  Bets_Allowed(Back_1_1_Marker).Bet_Name);
    Move("MR_HORSES_PLC_BACK_FINISH_1.25_12.0_5", Bets_Allowed(Back_2_1_Marker).Bet_Name);
    Move("MR_HORSES_PLC_BACK_FINISH_1.50_20.0_5", Bets_Allowed(Back_3_1_Marker).Bet_Name);
    Move("MR_HORSES_PLC_BACK_FINISH_1.30_15.0_5", Bets_Allowed(Back_4_1_Marker).Bet_Name);
    Move("MR_HORSES_PLC_BACK_FINISH_1.40_30.0_5", Bets_Allowed(Back_5_1_Marker).Bet_Name);
    Move("MR_HORSES_PLC_BACK_FINISH_1.50_30.0_5", Bets_Allowed(Back_6_1_Marker).Bet_Name);
    Move("MR_HORSES_PLC_BACK_FINISH_1.30_20.0_5", Bets_Allowed(Back_7_1_Marker).Bet_Name);

    -- check if ok to bet and set bet size
    for i in Bets_Allowed'range loop
      if 0.0 < Bets_Allowed(i).Bet_Size and then Bets_Allowed(i).Bet_Size < 1.0 then
        -- to have the size = a portion of the saldo.
        Rpc.Get_Balance(Betfair_Result => Betfair_Result, Saldo => Saldo);
        Bets_Allowed(i).Bet_Size := Bets_Allowed(i).Bet_Size * Bet_Size_Type(Saldo.Balance);
        if Bets_Allowed(i).Bet_Size < 30.0 then
          Log(Me & "Run", "Bet_Size too small, set to 30.0, was " & F8_Image(Float_8( Bets_Allowed(i).Bet_Size)) & " " & Table_Abalances.To_String(Saldo));
          Bets_Allowed(i).Bet_Size := 30.0;
        end if;
      end if;
      Log(Me & "Run", "Bet_Size " & F8_Image(Float_8( Bets_Allowed(i).Bet_Size)) & " " & Table_Abalances.To_String(Saldo));

      if -5.0 < Bets_Allowed(i).Max_Loss_Per_Day and then Bets_Allowed(i).Max_Loss_Per_Day < 0.0 then
        Bets_Allowed(i).Max_Loss_Per_Day := Bets_Allowed(i).Max_Loss_Per_Day * Bets_Allowed(i).Bet_Size;
      end if;

      Bets_Allowed(i).Is_Allowed_To_Bet := Bet.Profit_Today(Bets_Allowed(i).Bet_Name) >= Float_8(Bets_Allowed(i).Max_Loss_Per_Day);
      Log(Me & "Run", Trim(Bets_Allowed(i).Bet_Name) & " max allowed loss set to " & F8_Image(Float_8(Bets_Allowed(i).Max_Loss_Per_Day)));
      if not Bets_Allowed(i).Is_Allowed_To_Bet then
        Log(Me & "Run", Trim(Bets_Allowed(i).Bet_Name) & " has lost too much today, max loss is " & F8_Image(Float_8(Bets_Allowed(i).Max_Loss_Per_Day)));
      end if;
    end loop;

    for i in Bets_Allowed'range loop
      if Ada.Strings.Fixed.Index(i'Img, "MARKER") > Natural(0) then
        Bets_Allowed(i).Is_Allowed_To_Bet := False;
      end if;
    end loop;


    Table_Amarkets.Read(Market, Eos);
    if not Eos then
      if  Market.Markettype(1..3) /= "PLA"  then
        Log(Me & "Run", "not a PLACE market: " &  Market_Notification.Market_Id);
        return;
      else
        Event.Eventid := Market.Eventid;
        Table_Aevents.Read(Event, Eos);
        if not Eos then
          if Event.Eventtypeid /= Integer_4(7) then
            Log(Me & "Run", "not a HORSE market: " &  Market_Notification.Market_Id);
            return;
          elsif not Cfg.Country_Is_Ok(Event.Countrycode) then
            Log(Me & "Run", "not an OK country,  market: " &  Market_Notification.Market_Id);
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
    Markets(Place):= Market;

    -- do the poll
    Poll_Loop : loop
      if Is_Data_Collector then
        for Price of Price_List loop
         Price_Finish := (
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
         Price_Finish_List.Append(Price_Finish);
        end loop;
      else 
        exit Poll_Loop; -- don't waste cpu on not data collectors       
      end if;

      if Markets(Place).Numwinners < Integer_4(3) then
        exit Poll_Loop;
      end if;     
      
      Price_List.Clear;
      Rpc.Get_Market_Prices(Market_Id  => Market_Notification.Market_Id,
                            Market     => Market,
                            Price_List => Price_List,
                            In_Play    => In_Play);

      exit Poll_Loop when Market.Status(1..4) /= "OPEN";

      if not Has_Been_In_Play then
        -- toggle the first time we see in-play=true
        -- makes us insensible to Betfair toggling bug
        Has_Been_In_Play := In_Play;
      end if;

      if not Has_Been_In_Play then
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
      Backprice_Sorter.Sort(Price_List);

      Price.Backprice := 10_000.0;
      Best_Runners := (others => Price);
      
      declare
        Idx : Integer := 0;
      begin
        for Tmp of Price_List loop
          if Tmp.Status(1..6) = "ACTIVE" then
            Idx := Idx +1;
            exit when Idx > Best_Runners'Last;
            Best_Runners(Idx) := Tmp;
          end if;
        end loop;
      end ;      

      for i in Best_Runners'range loop
        Log("Best_Runners(i)" & i'Img & " " & Table_Aprices.To_String(Best_Runners(i)));
      end loop;

      if Best_Runners(1).Backprice >= Float_8(1.0) and then
         not Is_Data_Collector and then
         Found_Place and then
         Markets(Place).Numwinners >= Integer_4(3) then

        if Best_Runners(1).Backprice <= Float_8(1.10) and then
           Best_Runners(2).Backprice >= Float_8(7.0) and then
           Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice < Float_8(10_000.0) then  -- so it exists
          -- Back The leader in PLC market...

          Send_Bet(Selectionid          => Best_Runners(1).Selectionid,
                   Main_Bet             => Back_1_1,
                   Marker_Bet           => Back_1_1_Marker,
                   Place_Market_Id      => Markets(Place).Marketid,
                   Receiver_Name        => To_Pio_Name("bet_placer_10"),
                   Receiver_Marker_Name => To_Pio_Name("bet_placer_11"));
        end if;

        -- Back The leader in PLC market again, but different requirements...
        if Best_Runners(1).Backprice <= Float_8(1.25) and then
           Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice >= Float_8(12.0)  then
          -- Back The leader in PLC market...
           Send_Bet(Selectionid          => Best_Runners(1).Selectionid,
                    Main_Bet             => Back_2_1,
                    Marker_Bet           => Back_2_1_Marker,
                    Place_Market_Id      => Markets(Place).Marketid,
                    Receiver_Name        => To_Pio_Name("bet_placer_20"),
                    Receiver_Marker_Name => To_Pio_Name("bet_placer_21"));
        end if;

        -- Back The leader in PLC market again, but different requirements...
        if Best_Runners(1).Backprice <= Float_8(1.50) and then
           Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(4).Backprice >= Float_8(20.0) then

           Send_Bet(Selectionid          => Best_Runners(1).Selectionid,
                    Main_Bet             => Back_3_1,
                    Marker_Bet           => Back_3_1_Marker,
                    Place_Market_Id      => Markets(Place).Marketid,
                    Receiver_Name        => To_Pio_Name("bet_placer_30"),
                    Receiver_Marker_Name => To_Pio_Name("bet_placer_31"));
        end if;

        if Best_Runners(1).Backprice <= Float_8(1.30) and then
           Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(4).Backprice >= Float_8(15.0) then

           Send_Bet(Selectionid          => Best_Runners(1).Selectionid,
                    Main_Bet             => Back_4_1,
                    Marker_Bet           => Back_4_1_Marker,
                    Place_Market_Id      => Markets(Place).Marketid,
                    Receiver_Name        => To_Pio_Name("bet_placer_40"),
                    Receiver_Marker_Name => To_Pio_Name("bet_placer_41"));
        end if;

        if Best_Runners(1).Backprice <= Float_8(1.40) and then
           Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(4).Backprice >= Float_8(30.0) then

           Send_Bet(Selectionid          => Best_Runners(1).Selectionid,
                    Main_Bet             => Back_5_1,
                    Marker_Bet           => Back_5_1_Marker,
                    Place_Market_Id      => Markets(Place).Marketid,
                    Receiver_Name        => To_Pio_Name("bet_placer_50"),
                    Receiver_Marker_Name => To_Pio_Name("bet_placer_51"));
        end if;

        if Best_Runners(1).Backprice <= Float_8(1.50) and then
           Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(4).Backprice >= Float_8(30.0) then

           Send_Bet(Selectionid          => Best_Runners(1).Selectionid,
                    Main_Bet             => Back_6_1,
                    Marker_Bet           => Back_6_1_Marker,
                    Place_Market_Id      => Markets(Place).Marketid,
                    Receiver_Name        => To_Pio_Name("bet_placer_60"),
                    Receiver_Marker_Name => To_Pio_Name("bet_placer_61"));
        end if;

        if Best_Runners(1).Backprice <= Float_8(1.30) and then
           Best_Runners(4).Backprice >= Float_8(20.0) and then
           Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice < Float_8(10_000.0) then  -- so it exists
          -- Back The leader in PLC market...

          Send_Bet(Selectionid          => Best_Runners(1).Selectionid,
                   Main_Bet             => Back_7_1,
                   Marker_Bet           => Back_7_1_Marker,
                   Place_Market_Id      => Markets(Place).Marketid,
                   Receiver_Name        => To_Pio_Name("bet_placer_70"),
                   Receiver_Marker_Name => To_Pio_Name("bet_placer_71"));
        end if;

      end if;

    end loop Poll_Loop;

    if Is_Data_Collector then
      -- insert all the records now, in pricefinish
      Log("start insert records into Pricefinish:" & Price_Finish_List.Length'Img);
      begin
        T.Start;
        for Price_Finish of Price_Finish_List loop
          Price_Finish.Insert;        
        end loop;
        T.Commit;
      exception
        when Sql.Duplicate_Index =>
           Price_Finish_List.Clear;
           T.Rollback;
      end;
      Log("stop insert record into Pricefinish");
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

  Logging.Open(EV.Value("BOT_HOME") & "/log/poll_place.log");

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
            Log(Me, "Poll is not enabled in poll.ini");
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
end Poll_Place;

