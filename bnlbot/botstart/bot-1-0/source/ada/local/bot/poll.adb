with Ada.Exceptions;
with Ada.Command_Line;
with Stacktrace;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Sql;
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
with Table_Apricesfinish;
with Table_Abalances;
with Bot_Svn_Info;
with Bet;
with Config;
with Utils; use Utils;

procedure Poll is
  package EV renames Ada.Environment_Variables;
  use type Rpc.Result_Type;

  Me              : constant String := "Poll.";
  Timeout         : Duration := 120.0;
  My_Lock         : Lock.Lock_Type;
  Msg             : Process_Io.Message_Type;
  Find_Plc_Market : Sql.Statement_Type;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line        : Command_Line_Configuration;
  Now             : Calendar2.Time_Type;
  Ok,
  Is_Time_To_Exit : Boolean := False;
  Cfg : Config.Config_Type;
  -------------------------------------------------------------
  -- type-of-bet_bet-number_placement-in-race-at-time-of-bet
  type Bet_Type is (Back_1_1,  Back_1_1_Marker,
                    Back_2_1,  Back_2_1_Marker,
                    Back_3_1,  Back_3_1_Marker,
                    Back_4_1,  Back_4_1_Marker,
                    Back_5_1,  Back_5_1_Marker,
                    Back_6_1,  Back_6_1_Marker,
                    Back_7_1,  Back_7_1_Marker,
                    Back_8_1,  Back_8_1_Marker,
                    Lay_1_1,   Lay_1_2,
                    Lay_2_1,   Lay_2_2,
                    Lay_3_1,   Lay_3_2,
                    Lay_4_1,   Lay_4_2,
                    Lay_5_2,   Lay_5_3, Lay_5_4);

  type Allowed_Type is record
    Bet_Name          : Bet_Name_Type := (others => ' ');
    Bet_Size          : Bet_Size_Type := 0.0;
    Is_Allowed_To_Bet : Boolean       := False;
    Has_Betted        : Boolean       := False;
    Max_Loss_Per_Day  : Bet_Size_Type := 0.0;
  end record;

  Bets_Allowed : array (Bet_Type'range) of Allowed_Type;

  --------------------------------------------------------------
                        
  procedure Send_Lay_Bet(Selectionid   : Integer_4;
                         Main_Bet      : Bet_Type;
                         Max_Price     : Max_Lay_Price_Type;
                         Market_Id     : Market_Id_Type;
                         Receiver      : Process_Io.Process_Type) is

    PLB             : Bot_Messages.Place_Lay_Bet_Record;
    Did_Bet : array(1..1) of Boolean := (others => False);
  begin

    declare
      -- only bet on allowed days 
      Now : Time_Type := Clock;
      Day : Week_Day_Type := Week_Day_Of(Now);
    begin
      if not Cfg.Allowed_Days(Day) then
        Log("No bet layed, bad weekday" );
        return;
      end if;
    end;
  
    PLB.Bet_Name := Bets_Allowed(Main_Bet).Bet_Name;
    Move(Market_Id, PLB.Market_Id);
    Move(F8_Image(Float_8(Max_Price)), PLB.Price); --abs max
    PLB.Selection_Id := Selectionid;

    if not Bets_Allowed(Main_Bet).Has_Betted and then
           Bets_Allowed(Main_Bet).Is_Allowed_To_Bet then
      Move(F8_Image(Float_8(Bets_Allowed(Main_Bet).Bet_Size)), PLB.Size);
      Bot_Messages.Send(Receiver, PLB);
      Bets_Allowed(Main_Bet).Has_Betted := True;
      Did_Bet(1) := True;
    end if;


    if Did_Bet(1) then
      Log("Send_Lay_Bet called with " &
         " Selectionid=" & Selectionid'Img &
         " Main_Bet=" & Main_Bet'Img &
         " Market_Id= '" & Market_Id & "'" &
         " Receiver= '" & Receiver.Name & "'");
    end if;

    -- just to save time between logs
    if Did_Bet(1) then
      Log("pinged '" &  Trim(Receiver.Name) & "' with bet '" & Trim(PLB.Bet_Name) & "' sel.id:" &  PLB.Selection_Id'Img );
    end if;

  end Send_Lay_Bet;
                        
  --------------------------------------------------------------
  
  procedure Send_Bet(Selectionid                         : Integer_4;
                     Main_Bet, Marker_Bet                : Bet_Type;
                     Place_Market_Id                     : Market_Id_Type;
                     Receiver, Receiver_Marker           : Process_Io.Process_Type) is

    PBB             : Bot_Messages.Place_Back_Bet_Record;
    PBB_Marker      : Bot_Messages.Place_Back_Bet_Record;
    Did_Bet : array(1..2) of Boolean := (others => False);
  begin

    declare
      -- only bet on allowed days 
      Now : Time_Type := Clock;
      Day : Week_Day_Type := Week_Day_Of(Now);
    begin
      if not Cfg.Allowed_Days(Day) then
        Log("No bet layed, bad weekday" );
        return;
      end if;
    end;
  
    PBB.Bet_Name := Bets_Allowed(Main_Bet).Bet_Name;
    Move(Place_Market_Id, PBB.Market_Id);
    Move("1.01", PBB.Price);
    PBB.Selection_Id := Selectionid;

    if not Bets_Allowed(Main_Bet).Has_Betted and then
           Bets_Allowed(Main_Bet).Is_Allowed_To_Bet then
      Move(F8_Image(Float_8(Bets_Allowed(Main_Bet).Bet_Size)), PBB.Size);
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
      Bot_Messages.Send(Receiver_Marker, PBB_Marker);
      Bets_Allowed(Marker_Bet).Has_Betted := True;
      Did_Bet(2) := True;
    end if;

    if Did_Bet(1) or else Did_Bet(2) then
      Log("Send_Bet called with " &
         " Selectionid=" & Selectionid'Img &
         " Main_Bet=" & Main_Bet'Img &
         " Marker_Bet=" & Marker_Bet'Img &
         " Place_Market_Id= '" & Place_Market_Id & "'" &
         " Receiver= '" & Receiver.Name & "'" &
         " Receiver_Marker= '" & Receiver_Marker.Name & "'" );
    end if;

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
    --------------------------------------------
    function "<" (Left,Right : Table_Aprices.Data_Type) return Boolean is
    begin
      return Left.Backprice < Right.Backprice;
    end "<";
    --------------------------------------------
    package Backprice_Sorter is new  Table_Aprices.Aprices_List_Pack2.Generic_Sorting("<");  
    
    Price_Finish      : Table_Apricesfinish.Data_Type;
    Price_Finish_List : Table_Apricesfinish.Apricesfinish_List_Pack2.List;
    Price             : Table_Aprices.Data_Type;
    Has_Been_In_Play,
    In_Play           : Boolean := False;
    Best_Runners      : array (1..4) of Table_Aprices.Data_Type := (others => Table_Aprices.Empty_Data);
    Worst_Runner      : Table_Aprices.Data_Type := Table_Aprices.Empty_Data;
    
    Eos               : Boolean := False;
    type Market_Type is (Win, Place);
    Markets           : array (Market_Type'range) of Table_Amarkets.Data_Type;
    Found_Place       : Boolean := True;
    T                 : Sql.Transaction_Type;
    Current_Turn_Not_Started_Race : Integer_4 := 0;
    Betfair_Result    : Rpc.Result_Type := Rpc.Result_Type'first;
    Saldo             : Table_Abalances.Data_Type;
    Is_Data_Collector : Boolean := EV.Value("BOT_USER") = "dry" ;
  begin
    Log(Me & "Run", "Treat market: " &  Market_Notification.Market_Id);
    Market.Marketid := Market_Notification.Market_Id;

    --set values from cfg
    for i in Bets_Allowed'range loop
      Bets_Allowed(i).Bet_Size   := Cfg.Size;
      Bets_Allowed(i).Has_Betted := False;
      Bets_Allowed(i).Max_Loss_Per_Day := Bet_Size_Type(Cfg.Max_Loss_Per_Day);

      -- marker bets are always 30 :-
      if Ada.Strings.Fixed.Index(i'Img, "MARKER") > Natural(0) then
        Bets_Allowed(i).Bet_Size := 30.0;
      end if;
      if Ada.Strings.Fixed.Index(i'Img, "LAY") > Natural(0) then
        Bets_Allowed(i).Bet_Size := 1.0; -- make sure not accepted
      end if;
    end loop;
    -- override Bet_Size for some bets
    Bets_Allowed(Back_2_1).Bet_Size := 250.0;
    Bets_Allowed(Back_3_1).Bet_Size := 250.0;
    Bets_Allowed(Back_4_1).Bet_Size :=   0.0;
    Bets_Allowed(Back_5_1).Bet_Size :=   0.0;
    Bets_Allowed(Back_6_1).Bet_Size :=   0.0;
    Bets_Allowed(Back_7_1).Bet_Size :=  50.0;
    Bets_Allowed(Back_8_1).Bet_Size :=  50.0;


    Move("HORSES_PLC_BACK_FINISH_1.10_7.0_1",     Bets_Allowed(Back_1_1).Bet_Name);
    Move("HORSES_PLC_BACK_FINISH_1.25_12.0_1",    Bets_Allowed(Back_2_1).Bet_Name);
    Move("HORSES_PLC_BACK_FINISH_1.40_50.0_1",    Bets_Allowed(Back_3_1).Bet_Name);
    Move("HORSES_PLC_BACK_FINISH_1.50_50.0_1",    Bets_Allowed(Back_4_1).Bet_Name);
    Move("HORSES_PLC_BACK_FINISH_1.60_50.0_1",    Bets_Allowed(Back_5_1).Bet_Name);
    Move("HORSES_PLC_BACK_FINISH_1.90_50.0_1",    Bets_Allowed(Back_6_1).Bet_Name);
    Move("HORSES_PLC_BACK_FINISH_1.10_20.0_1",    Bets_Allowed(Back_7_1).Bet_Name);
    Move("HORSES_PLC_BACK_FINISH_1.10_30.0_1",    Bets_Allowed(Back_8_1).Bet_Name);
    Move("HORSES_WIN_LAY_FINISH_100_200_1",       Bets_Allowed(Lay_1_1).Bet_Name);
    Move("HORSES_WIN_LAY_FINISH_100_300_1",       Bets_Allowed(Lay_1_2).Bet_Name);
    Move("HORSES_WIN_LAY_FINISH_80_150_1",        Bets_Allowed(Lay_2_1).Bet_Name);
    Move("HORSES_WIN_LAY_FINISH_80_250_1",        Bets_Allowed(Lay_2_2).Bet_Name);
    Move("HORSES_WIN_LAY_FINISH_110_150_1",       Bets_Allowed(Lay_3_1).Bet_Name);
    Move("HORSES_WIN_LAY_FINISH_110_250_1",       Bets_Allowed(Lay_3_2).Bet_Name);
    Move("HORSES_WIN_LAY_FINISH_110_200_1",       Bets_Allowed(Lay_4_1).Bet_Name);
    Move("HORSES_WIN_LAY_FINISH_110_300_1",       Bets_Allowed(Lay_4_2).Bet_Name);
    Move("HORSES_WIN_LAY_FINISH_1.10_30.0_2",     Bets_Allowed(Lay_5_2).Bet_Name);
    Move("HORSES_WIN_LAY_FINISH_1.10_30.0_3",     Bets_Allowed(Lay_5_3).Bet_Name);
    Move("HORSES_WIN_LAY_FINISH_1.10_30.0_4",     Bets_Allowed(Lay_5_4).Bet_Name);

    --markers
    Move("MR_HORSES_PLC_BACK_FINISH_1.10_7.0_1",  Bets_Allowed(Back_1_1_Marker).Bet_Name);
    Move("MR_HORSES_PLC_BACK_FINISH_1.25_12.0_1", Bets_Allowed(Back_2_1_Marker).Bet_Name);
    Move("MR_HORSES_PLC_BACK_FINISH_1.40_50.0_1", Bets_Allowed(Back_3_1_Marker).Bet_Name);
    Move("MR_HORSES_PLC_BACK_FINISH_1.50_50.0_1", Bets_Allowed(Back_4_1_Marker).Bet_Name);
    Move("MR_HORSES_PLC_BACK_FINISH_1.60_50.0_1", Bets_Allowed(Back_5_1_Marker).Bet_Name);
    Move("MR_HORSES_PLC_BACK_FINISH_1.90_50.0_1", Bets_Allowed(Back_6_1_Marker).Bet_Name);
    Move("MR_HORSES_PLC_BACK_FINISH_1.10_20.0_1", Bets_Allowed(Back_7_1_Marker).Bet_Name);
    Move("MR_HORSES_PLC_BACK_FINISH_1.10_30.0_1", Bets_Allowed(Back_8_1_Marker).Bet_Name);
  
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
    
      if Markets(Place).Numwinners < Integer_4(3) then
        exit Poll_Loop;
      end if;   
    
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
      end if;

      --Table_Aprices.Aprices_List_Pack.Remove_All(Price_List);
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
      Worst_Runner.Layprice := 10_000.0;
      
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

      for Tmp of Price_List loop
        if Tmp.Status(1..6) = "ACTIVE" and then
           Tmp.Backprice > Float_8(1.0) and then
           Tmp.Layprice < Float_8(1_000.0) and then 
           Tmp.Selectionid /= Best_Runners(1).Selectionid and then
           Tmp.Selectionid /= Best_Runners(2).Selectionid then
           
          Worst_Runner := Tmp;
        end if;  
      end loop;
      
      for i in Best_Runners'range loop
        Log("Best_Runners(i)" & i'Img & " " & Best_Runners(i).To_String);
      end loop;
      Log("Worst_Runner " & Worst_Runner.To_String);

      if Best_Runners(1).Backprice >= Float_8(1.0) and then
         not Is_Data_Collector and then
         Found_Place and then
         Markets(Place).Numwinners >= Integer_4(3) then

        --------------------------------------------------------------- 
        --MR_HORSES_PLC_BACK_FINISH_1.10_7.0_1
        if Best_Runners(1).Backprice <= Float_8(1.10) and then
           Best_Runners(2).Backprice >= Float_8(7.0) and then
           Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice < Float_8(10_000.0) then  -- so it exists
          -- Back The leader in PLC market...

          Send_Bet(Selectionid     => Best_Runners(1).Selectionid,
                   Main_Bet        => Back_1_1,
                   Marker_Bet      => Back_1_1_Marker,
                   Place_Market_Id => Markets(Place).Marketid,
                   Receiver        => Process_Io.To_Process_Type("bet_placer_010"),
                   Receiver_Marker => Process_Io.To_Process_Type("bet_placer_011"));
        end if;

        --------------------------------------------------------------- 
        --MR_HORSES_PLC_BACK_FINISH_1.25_12.0_1
        -- Back The leader in PLC market again, but different requirements...
        if Best_Runners(1).Backprice <= Float_8(1.25) and then
           Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice >= Float_8(12.0)  then
          -- Back The leader in PLC market...
           Send_Bet(Selectionid     => Best_Runners(1).Selectionid,
                    Main_Bet        => Back_2_1,
                    Marker_Bet      => Back_2_1_Marker,
                    Place_Market_Id => Markets(Place).Marketid,
                    Receiver        => Process_Io.To_Process_Type("bet_placer_020"),
                    Receiver_Marker => Process_Io.To_Process_Type("bet_placer_021"));
        end if;
        
        --------------------------------------------------------------- 
        --MR_HORSES_PLC_BACK_FINISH_1.40_50.0_1
        if Best_Runners(1).Backprice <= Float_8(1.40) and then
           Best_Runners(4).Backprice >= Float_8(50.0) and then
           Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice < Float_8(10_000.0) then  -- so it exists
          -- Back The leader in PLC market...

          Send_Bet(Selectionid     => Best_Runners(1).Selectionid,
                   Main_Bet        => Back_3_1,
                   Marker_Bet      => Back_3_1_Marker,
                   Place_Market_Id => Markets(Place).Marketid,
                   Receiver        => Process_Io.To_Process_Type("bet_placer_030"),
                   Receiver_Marker => Process_Io.To_Process_Type("bet_placer_031"));
        end if;

        --------------------------------------------------------------- 
        ----MR_HORSES_PLC_BACK_FINISH_1.50_50.0_1
        --if Best_Runners(1).Backprice <= Float_8(1.50) and then
        --   Best_Runners(4).Backprice >= Float_8(50.0) and then
        --   Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
        --   Best_Runners(3).Backprice < Float_8(10_000.0) then  -- so it exists
        --  -- Back The leader in PLC market...
        --
        --  Send_Bet(Selectionid     => Best_Runners(1).Selectionid,
        --           Main_Bet        => Back_4_1,
        --           Marker_Bet      => Back_4_1_Marker,
        --           Place_Market_Id => Markets(Place).Marketid,
        --           Receiver        => Process_Io.To_Process_Type("bet_placer_040"),
        --           Receiver_Marker => Process_Io.To_Process_Type("bet_placer_041"));
        --end if;
        
        --------------------------------------------------------------- 
        ----MR_HORSES_PLC_BACK_FINISH_1.60_50.0_1
        --if Best_Runners(1).Backprice <= Float_8(1.60) and then
        --   Best_Runners(4).Backprice >= Float_8(50.0) and then
        --   Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
        --   Best_Runners(3).Backprice < Float_8(10_000.0) then  -- so it exists
        --  -- Back The leader in PLC market...
        --
        --  Send_Bet(Selectionid     => Best_Runners(1).Selectionid,
        --           Main_Bet        => Back_5_1,
        --           Marker_Bet      => Back_5_1_Marker,
        --           Place_Market_Id => Markets(Place).Marketid,
        --           Receiver        => Process_Io.To_Process_Type("bet_placer_050"),
        --           Receiver_Marker => Process_Io.To_Process_Type("bet_placer_051"));
        --end if;

        --------------------------------------------------------------- 
        ----MR_HORSES_PLC_BACK_FINISH_1.90_50.0_1
        --if Best_Runners(1).Backprice <= Float_8(1.90) and then
        --   Best_Runners(4).Backprice >= Float_8(50.0) and then
        --   Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
        --   Best_Runners(3).Backprice < Float_8(10_000.0) then  -- so it exists
        --  -- Back The leader in PLC market...
        --
        --  Send_Bet(Selectionid     => Best_Runners(1).Selectionid,
        --           Main_Bet        => Back_6_1,
        --           Marker_Bet      => Back_6_1_Marker,
        --           Place_Market_Id => Markets(Place).Marketid,
        --           Receiver        => Process_Io.To_Process_Type("bet_placer_060"),
        --           Receiver_Marker => Process_Io.To_Process_Type("bet_placer_061"));
        --end if;
        
        --------------------------------------------------------------- 
        --MR_HORSES_PLC_BACK_FINISH_1.10_20.0_1
        if Best_Runners(1).Backprice <= Float_8(1.10) and then
           Best_Runners(4).Backprice >= Float_8(20.0) and then
           Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice < Float_8(10_000.0) then  -- so it exists
          -- Back The leader in PLC market...

          Send_Bet(Selectionid     => Best_Runners(1).Selectionid,
                   Main_Bet        => Back_7_1,
                   Marker_Bet      => Back_7_1_Marker,
                   Place_Market_Id => Markets(Place).Marketid,
                   Receiver        => Process_Io.To_Process_Type("bet_placer_070"),
                   Receiver_Marker => Process_Io.To_Process_Type("bet_placer_071"));
        end if;
        --------------------------------------------------------------- 
        --MR_HORSES_PLC_BACK_FINISH_1.10_30.0_1
        if Best_Runners(1).Backprice <= Float_8(1.10) and then
           Best_Runners(4).Backprice >= Float_8(30.0) and then
           Best_Runners(2).Backprice < Float_8(10_000.0) and then  -- so it exists
           Best_Runners(3).Backprice < Float_8(10_000.0) then  -- so it exists
          -- Back The leader in PLC market...

          Send_Bet(Selectionid     => Best_Runners(1).Selectionid,
                   Main_Bet        => Back_8_1,
                   Marker_Bet      => Back_8_1_Marker,
                   Place_Market_Id => Markets(Place).Marketid,
                   Receiver        => Process_Io.To_Process_Type("bet_placer_080"),
                   Receiver_Marker => Process_Io.To_Process_Type("bet_placer_081"));
          --lay 2,3,4         
          if Best_Runners(2).Layprice < Float_8(100.0) then        
            Send_Lay_Bet(Selectionid  => Best_Runners(2).Selectionid,
                        Main_Bet    => Lay_5_2,
                        Max_Price   => Max_Lay_Price_Type(Best_Runners(2).Layprice),
                        Market_Id   => Markets(Win).Marketid,
                        Receiver    => Process_Io.To_Process_Type("bet_placer_060"));
          end if;       
                   
          if Best_Runners(3).Layprice < Float_8(100.0) then        
            Send_Lay_Bet(Selectionid  => Best_Runners(3).Selectionid,
                        Main_Bet    => Lay_5_3,
                        Max_Price   => Max_Lay_Price_Type(Best_Runners(3).Layprice),
                        Market_Id   => Markets(Win).Marketid,
                        Receiver    => Process_Io.To_Process_Type("bet_placer_061"));
          end if;       
                        
          if Best_Runners(4).Layprice < Float_8(100.0) then        
            Send_Lay_Bet(Selectionid  => Best_Runners(4).Selectionid,
                          Main_Bet    => Lay_5_4,
                          Max_Price   => Max_Lay_Price_Type(Best_Runners(4).Layprice),
                          Market_Id   => Markets(Win).Marketid,
                          Receiver    => Process_Io.To_Process_Type("bet_placer_050"));
          end if;       
         
        end if;

      end if;
      
      -- laybets
      if Worst_Runner.Layprice <= Float_8(1000.0) and then
         not Is_Data_Collector  then
        --HORSES_WIN_LAY_FINISH_100_200_1
        if Worst_Runner.Backprice <= Float_8(400.0) and then
           Worst_Runner.Backprice >= Float_8(100.0) and then
           Worst_Runner.Layprice <= Float_8(200.0) and then 
           Worst_Runner.Layprice > Float_8(10.0) then 
          -- lay the loser in WIN market...

          Send_Lay_Bet(Selectionid  => Worst_Runner.Selectionid,
                        Main_Bet    => Lay_1_1,
                        Max_Price   => Max_Lay_Price_Type(200.0),
                        Market_Id   => Markets(Win).Marketid,
                        Receiver    => Process_Io.To_Process_Type("bet_placer_101"));
        end if;
         
        --HORSES_WIN_LAY_FINISH_100_300_1
        if Worst_Runner.Backprice <= Float_8(400.0) and then
           Worst_Runner.Backprice >= Float_8(100.0) and then
           Worst_Runner.Layprice <= Float_8(300.0) and then 
           Worst_Runner.Layprice > Float_8(10.0) then 
          -- lay the loser in WIN market...

          Send_Lay_Bet(Selectionid => Worst_Runner.Selectionid,
                        Main_Bet   => Lay_1_2,
                        Max_Price  => Max_Lay_Price_Type(300.0),
                        Market_Id  => Markets(Win).Marketid,
                        Receiver   => Process_Io.To_Process_Type("bet_placer_102"));
        end if;
        
        --HORSES_WIN_LAY_FINISH_80_150_1
        if Worst_Runner.Backprice <= Float_8(400.0) and then
           Worst_Runner.Backprice >= Float_8(80.0) and then
           Worst_Runner.Layprice <= Float_8(150.0) and then 
           Worst_Runner.Layprice > Float_8(10.0) then 
          -- lay the loser in WIN market...

          Send_Lay_Bet(Selectionid => Worst_Runner.Selectionid,
                        Main_Bet   => Lay_2_1,
                        Max_Price  => Max_Lay_Price_Type(150.0),
                        Market_Id  => Markets(Win).Marketid,
                        Receiver   => Process_Io.To_Process_Type("bet_placer_103"));
        end if;
        --HORSES_WIN_LAY_FINISH_80_250_1
        if Worst_Runner.Backprice <= Float_8(400.0) and then
           Worst_Runner.Backprice >= Float_8(100.0) and then
           Worst_Runner.Layprice <= Float_8(250.0) and then 
           Worst_Runner.Layprice > Float_8(10.0) then 
          -- lay the loser in WIN market...

          Send_Lay_Bet(Selectionid => Worst_Runner.Selectionid,
                        Main_Bet   => Lay_2_2,
                        Max_Price  => Max_Lay_Price_Type(250.0),
                        Market_Id  => Markets(Win).Marketid,
                        Receiver   => Process_Io.To_Process_Type("bet_placer_104"));
        end if;
        --HORSES_WIN_LAY_FINISH_110_150_1",
        if Worst_Runner.Backprice <= Float_8(400.0) and then
           Worst_Runner.Backprice >= Float_8(110.0) and then
           Worst_Runner.Layprice <= Float_8(150.0) and then 
           Worst_Runner.Layprice > Float_8(10.0) then 
          -- lay the loser in WIN market...

          Send_Lay_Bet(Selectionid => Worst_Runner.Selectionid,
                        Main_Bet   => Lay_3_1,
                        Max_Price  => Max_Lay_Price_Type(150.0),
                        Market_Id  => Markets(Win).Marketid,
                        Receiver   => Process_Io.To_Process_Type("bet_placer_105"));
        end if;
        --HORSES_WIN_LAY_FINISH_110_250_1      
        if Worst_Runner.Backprice <= Float_8(400.0) and then
           Worst_Runner.Backprice >= Float_8(110.0) and then
           Worst_Runner.Layprice <= Float_8(250.0) and then 
           Worst_Runner.Layprice > Float_8(10.0) then 
          -- lay the loser in WIN market...

          Send_Lay_Bet(Selectionid => Worst_Runner.Selectionid,
                        Main_Bet   => Lay_3_2,
                        Max_Price  => Max_Lay_Price_Type(250.0),
                        Market_Id  => Markets(Win).Marketid,
                        Receiver   => Process_Io.To_Process_Type("bet_placer_106"));
        end if;
        --HORSES_WIN_LAY_FINISH_110_200_1 
        if Worst_Runner.Backprice <= Float_8(400.0) and then
           Worst_Runner.Backprice >= Float_8(110.0) and then
           Worst_Runner.Layprice <= Float_8(200.0) and then 
           Worst_Runner.Layprice > Float_8(10.0) then 
          -- lay the loser in WIN market...

          Send_Lay_Bet(Selectionid => Worst_Runner.Selectionid,
                        Main_Bet   => Lay_4_1,
                        Max_Price  => Max_Lay_Price_Type(200.0),
                        Market_Id  => Markets(Win).Marketid,
                        Receiver   => Process_Io.To_Process_Type("bet_placer_107"));
        end if;
        --HORSES_WIN_LAY_FINISH_110_300_1
        if Worst_Runner.Backprice <= Float_8(400.0) and then
           Worst_Runner.Backprice >= Float_8(110.0) and then
           Worst_Runner.Layprice <= Float_8(300.0) and then 
           Worst_Runner.Layprice > Float_8(10.0) then 
          -- lay the loser in WIN market...

          Send_Lay_Bet(Selectionid => Worst_Runner.Selectionid,
                        Main_Bet   => Lay_4_2,
                        Max_Price  => Max_Lay_Price_Type(300.0),
                        Market_Id  => Markets(Win).Marketid,
                        Receiver   => Process_Io.To_Process_Type("bet_placer_108"));
        end if;
         
      end if;        

      if Markets(Place).Numwinners < Integer_4(3) then
        exit Poll_Loop;
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
end Poll;

