with Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Environment_Variables;
with Ada.Containers;
with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;

with Sim;
with Utils; use Utils;
with Types ; use Types;
with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
--with Price_Histories;
with Bets;
with Calendar2;  use Calendar2;
with Logging; use Logging;
--with Bot_System_Number;
with Markets;
with Runners;
--with Prices;
with Price_Histories;

procedure Sim_Back_In_Play is

  package EV renames Ada.Environment_Variables;
  Betname_Already_Exists : exception;
  Commission : constant := 0.0 / 100.0;
  Cmd_Line   : Command_Line_Configuration;

  SA_Max_Leader_Back_Price      : aliased Gnat.Strings.String_Access;
  SA_Min_2nd_Back_Price         : aliased Gnat.Strings.String_Access;
  SA_Animal                     : aliased Gnat.Strings.String_Access;

  Global_Max_Leader_Back_Price   : Float_8 := 0.0;
  Global_Min_2nd_Back_Price      : Float_8 := 0.0;
  --Global_Lay_Size                : Bet_Size_Type := 30.0;
  Global_Back_Size               : Bet_Size_Type := 30.0;
  Global_Animal                  : Animal_Type := Horse; --default
  --num_bets=${num_bets} \
  --first_bet=${first_bet} \
  --place_num=${place_num} \
  --max_back_price=${max_back} \
  --max_lay_price_delta=${max_lay_delta} > ./${name}.log 2>&1 &
  Betname_Exists             : Sql.Statement_Type;

  Start             : Calendar2.Time_Type := Calendar2.Clock;
  Global_Bet_Suffix : String_Object;

  --    --------------------------------------------

--    function "<" (Left, Right : Prices.Price_Type) return Boolean is
--    begin
--      return Left.Backprice < Right.Backprice;
--    end "<";
--    --------------------------------------------
--
--    package Backprice_Sorter is new Prices.Lists.Generic_Sorting ("<");
--    type Best_Runners_Array_Type is array (1 .. 26) of Prices.Price_Type ;
--    Best_Runners      : Best_Runners_Array_Type := (others => Prices.Empty_Data);
--------------------------------------------
  function "<" (Left, Right : Price_Histories.Price_History_Type) return Boolean is
  begin
    return Left.Backprice < Right.Backprice;
  end "<";
  --------------------------------------------
  package Backprice_Sorter is new Price_Histories.Lists.Generic_Sorting ("<");
  type Best_Runners_Array_Type is array (1 .. 10) of Price_Histories.Price_History_Type ;
  Best_Runners : Best_Runners_Array_Type := (others => Price_Histories.Empty_Data);

  -------------------------------------
  function Check_Betname_Exists (Betname : String) return Boolean is
    Eos : Boolean := False;
    T   : Sql.Transaction_Type;
  begin
    T.Start;
    Betname_Exists.Prepare ("select 'a' from ABETS where BETNAME=:BETNAME");
    Betname_Exists.Set ("BETNAME", Betname);
    Betname_Exists.Open_Cursor;
    Betname_Exists.Fetch (Eos);
    Betname_Exists.Close_Cursor;
    T.Commit;
    return not Eos;
  end Check_Betname_Exists;

  --------------------------------------------------
--    procedure Winners_Price_And_Distance (BR     : in Best_Runners_Array_Type;
--                                          Market : in Markets.Market_Type ) is --prints the winners odds and distance to 2nd
--      Runner_List : Runners.Lists.List;
--     -- List_Is_OK  : Boolean := True;
--      W           : Prices.Price_Type;
--      R           : Runners.Runner_Type;
--      Index       : Integer := 0;
--    begin
--
--    --  Text_Io.Put_Line ("Market:" & Market.to_string);
--      Runner_List := Sim.Winners_Map (Market.Marketid);
--    ---  Text_Io.Put_Line ("list found");
--
--      Outer: for Winner of Runner_List loop
--     -- Text_Io.Put_Line ("winner:" & Winner.To_String);
--        Inner : for idx in BR'Range loop
--     --     Text_Io.Put_Line ("idx:" & Idx'img);
--            Text_Io.Put_Line ("idx:" & Idx'Img & "|selid:" & Br(Idx).Selectionid'img & "|backodds:" & F8_Image(Br(Idx).Backprice));
--          if Winner.Selectionid = Br(Idx).Selectionid then
--            R := Winner;
--            Index := Idx;
--            exit Outer;
--          end if;
--        end loop Inner;
--      end loop Outer;
--      if Index = 0 then
--        Text_Io.Put_Line ("NO WINNER IN Market:" & Market.to_string);
--        return;
--      end if;
--      for Idx in BR'Range loop
--        if R.Selectionid = Br (Idx).Selectionid then
--          W :=  Br (Idx);
--          exit;
--        end if;
--      end loop;
--
--      Text_Io.Put_Line ("Marketid:" & Market.Marketid & "|" &
--                          "Winner_index:" & Index'Img & "|" &
--                          "Winnerodds_Back:" & F8_Image (W.Backprice) & "|" &
--                          "Winnerodds_Lay:" & F8_Image (W.Layprice ) & "|" &
--                          "Leaderodds_Back:" & F8_Image (BR (1).Backprice ) & "|" &
--                          "Leaderodds_Lay:" & F8_Image (BR (1).Layprice ) & "|" &
--                          "Win_Odds_Back-Fav_Odds_Back:" & Utils.F8_Image (BR (Index).Backprice - BR (1).Backprice) );
--
--
--    end Winners_Price_And_Distance;
--    pragma Unreferenced(Winners_Price_And_Distance);
  --------------------------------------------------

  procedure Treat (BR                    : in     Best_Runners_Array_Type;
                   Market                : in     Markets.Market_Type;
                   Max_Leader_Back_Price : in     Float_8;
                   Min_2nd_Back_Price    : in     Float_8;
                   Bet_Suffix            : in     String_Object;
                   Placed_Bet            : in out Boolean;
                   Bet                   : in out Bets.Bet_Type) is

    T            : Sql.Transaction_Type;
    Betname      : Betname_Type ;
    Runner       : Runners.Runner_Type;
    Place_Market : Markets.Market_Type;

  begin
    Placed_Bet := False;
    Move ("BACK" & Bet_Suffix.Fix_String, Betname);
    T.Start;

    if BR (1).Backprice >  Float_8 (1.0) and then
      BR (1).Layprice   >  Float_8 (1.0) and then
      BR (1).Backprice  <=  Max_Leader_Back_Price and then
      BR (2).Backprice  >=  Min_2nd_Back_Price and then
      BR (1).Backprice  < 10_000.0 then

      Runner.Selectionid := BR (1).Selectionid;
      declare
        Eos : Boolean := False;
      begin
        Place_Market.Marketid := Sim.Win_Place_Map (Market.Marketid);
        Place_Market.Read (Eos);
        if Eos then
          Log ("EOS read placemarket " & Place_Market.To_String );
          return;
        end if;
      exception
        when others =>
          Log ("no placemarket " & Place_Market.To_String );
          return;
      end;

      Bet := Bets.Create (Name   => Betname,
                          Side   => Back,
                          Size   => Global_Back_Size,
                          Price  => Price_Type (1.01), --Price_Type (BR (1).Backprice),
                          Placed => BR (1).Pricets,
                          Runner => Runner,
                          Market => Place_Market);
      Bet.Insert_And_Nullify_Betwon;
      Placed_Bet := True;
    end if;

--      Move ("LAY" & Bet_Suffix.Fix_String, Betname);
--
--      if Place_Num <= BR'Last and then
--        BR (Place_Num).Backprice <= Max_Back_Price and then
--        BR (Place_Num).Layprice <= Max_Lay_Price then
--        for I in BR'Range loop
--          if I >= First_Bet and then
--            BR (I).Backprice <  10_000.0 and then
--            BR (I).Layprice  <= Max_Lay_Price and then
--            BR (I).Backprice >  Float_8(1.0) and then
--            BR (I).Layprice  >  Float_8(1.0) and then
--            I < First_Bet + Num_Bets then
--
--            Runner.Selectionid := BR (I).Selectionid;
--            Bet := Bets.Create (Name   => Betname,
--                                Side   => Lay,
--                                Size   => Global_Lay_Size,
--                                Price  => Price_Type (BR (I).Layprice),
--                                Placed => BR (I).Pricets,
--                                Runner => Runner,
--                                Market => Market);
--            Bet.Insert_And_Nullify_Betwon;
--          end if;
--        end loop;
--      end if;

    T.Commit;
  end Treat;
  ---------------------------------------------------------

  --  Enough_Runners : Boolean := False;
  use type Ada.Containers.Count_Type;
  Price : Price_Histories.Price_History_Type;
  --Price   : Prices.Price_Type;

  Day      : Time_Type     := (2016, 3, 31, 00, 00, 00, 000);
  End_Date : Time_Type     := (2017, 3, 16, 00, 00, 00, 000);
  One_Day  : Interval_Type := (1, 0, 0, 0, 0);
begin

  if not EV.Exists ("BOT_NAME") then
    EV.Set (Name => "BOT_NAME", Value => "sim_back_in_play");
  end if;

  -- Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");

  Define_Switch
    (Cmd_Line,
     SA_Max_Leader_Back_Price'Access,
     Long_Switch => "--max_leader_back_price=",
     Help        => "max back price for leader");

  Define_Switch
    (Cmd_Line,
     SA_Min_2nd_Back_Price'Access,
     Long_Switch => "--min_2nd_back_price=",
     Help        => "min price for the second runner");

  Define_Switch
    (Cmd_Line,
     SA_Animal'Access,
     Long_Switch => "--animal=",
     Help        => "horse|hound|human");


  Getopt (Cmd_Line);  -- process the command line

  Global_Max_Leader_Back_Price := Float_8'Value (SA_Max_Leader_Back_Price.all);
  Global_Min_2nd_Back_Price    := Float_8'Value (SA_Min_2nd_Back_Price.all);

  if SA_Animal.all = "horse" then
    Global_Animal := Horse;
  elsif SA_Animal.all = "hound" then
    Global_Animal := Hound;
  elsif SA_Animal.all = "human" then
    Global_Animal := Human;
  else
    Log ("bad animal: '" & SA_Animal.all & "'");
    return;
  end if;


  Log ("Connect db");

  case Global_Animal is
    when Horse =>
      Sql.Connect
        (Host     => "localhost",
         Port     => 5432,
         Db_Name  => "bnl",
         Login    => "bnl",
         Password => "bnl");
      Log ("Connected to bnl");
    when Hound =>
      Sql.Connect
        (Host     => "localhost",
         Port     => 5432,
         Db_Name  => "ghd",
         Login    => "bnl",
         Password => "bnl");
      Log ("Connected to ghd");
    when Human =>
      null;
  end case;

  declare
    Betname    : Betname_Type := (others => ' ');
  begin
    Global_Bet_Suffix.Append ("_" &
                                F8_Image (Global_Max_Leader_Back_Price) & "_" &
                                F8_Image (Global_Min_2nd_Back_Price) );
--      Move ("LAY" & Global_Bet_Suffix.Fix_String, Betname);
--      if Check_Betname_Exists (Betname) then
--        raise Betname_Already_Exists;
--      end if;
    Move ("BACK_PLC" & Global_Bet_Suffix.Fix_String, Betname);
    if Check_Betname_Exists (Betname) then
      raise Betname_Already_Exists;
    end if;
  end;

  Day_Loop : loop
    exit Day_Loop when Day > End_Date;
    Sim.Fill_Data_Maps (Day, Animal => Global_Animal);
    Log ("start process date " & Day.To_String);

    declare
      Cnt            : Integer := 0;
      Is_Win         : Boolean := True;
      Matched        : Boolean := False;
      Did_Bet        : Boolean := False;
      Eos            : Boolean := False;
      Time_Placed    : Calendar2.Time_Type := Calendar2.Time_Type_First;
      Bet            : Bets.Bet_Type;
      Place_Marketid : Marketid_Type := (others => ' ');
    begin
      Log ("num markets " & Day.To_String & " " & Sim.Market_With_Data_List.Length'Img);

      Loop_Market : for Market of Sim.Market_With_Data_List loop
        Is_Win := Market.Markettype (1 .. 3) = "WIN";
        Time_Placed := Calendar2.Time_Type_First;
        Matched     := False;
        Did_Bet     := False;
        Bet         := Bets.Empty_Data;

        if Is_Win then
          begin
            Place_Marketid := Sim.Win_Place_Map (Market.Marketid);
          exception
            when others =>
              Is_Win := False;
              Log ("Treat market " & Market.To_String & " had no palce market -> skipping");
          end;
        end if;



        if Is_Win then
          Log ("Treat market " & Market.To_String & " num timestamps" &
                 Sim.Marketid_Pricets_Map (Market.Marketid).Length'Img);
          Cnt := Cnt + 1;
          -- list of timestamps in this market
          declare
            Timestamp_To_Apriceshistory_Map : Sim.Timestamp_To_Prices_History_Maps.Map :=
                                                Sim.Marketid_Timestamp_To_Prices_History_Map (Market.Marketid);
           -- First_Time                      : Boolean := True;
          begin
            Loop_Timestamp : for Timestamp of Sim.Marketid_Pricets_Map (Market.Marketid) loop
              Log ("Treat marketid '" & Market.Marketid & "' pricets " & Timestamp.To_String);
              declare
                List : Price_Histories.Lists.List :=
                         Timestamp_To_Apriceshistory_Map (Timestamp.To_String);
              begin

--                  if First_Time then
--                    First_Time := False;
--                    if List.Length <= 7 then
--                      Log ("marketid '" & Market.Marketid & "' list too short" & List.Length'img);
--                      return;
--                    end if;
--                  end if;

                Price.Backprice := 10_000.0;
                Best_Runners := (others => Price);

                Backprice_Sorter.Sort (List);
                declare
                  Idx : Integer := 0;
                begin
                  for Tmp of List loop
                    Idx := Idx + 1;
                    exit when Idx > Best_Runners'Last;
                    Best_Runners (Idx) := Tmp;
                  end loop;
                end ;
                if not Did_Bet then
                  Treat (BR                    => Best_Runners,
                         Market                => Market,
                         Max_Leader_Back_Price => Global_Max_Leader_Back_Price,
                         Min_2nd_Back_Price    => Global_Min_2nd_Back_Price,
                         Bet_Suffix            => Global_Bet_Suffix,
                         Placed_Bet            => Did_Bet,
                         Bet                   => Bet);
                end if;
                if Did_Bet and then Time_Placed = Calendar2.Time_Type_First then
                  Time_Placed := Timestamp;
                  Log ("did bet at " & Timestamp.To_String);
                end if;

                if Did_Bet and then
                  Time_Placed > Calendar2.Time_Type_First then
                  --get market times here for place

                  declare
                    Timestamps_For_Place_Market_Map : Sim.Timestamp_To_Prices_History_Maps.Map :=
                                                        Sim.Marketid_Timestamp_To_Prices_History_Map (Place_Marketid);
                  begin
                    Loop_Timestamp2 : for Place_Timestamp of Sim.Marketid_Pricets_Map (Place_Marketid) loop
                      --             Log ("Treat marketid '" & Market.Marketid & "' pricets " & Timestamp.To_String);
                      declare
                        List2       : Price_Histories.Lists.List :=
                                        Timestamps_For_Place_Market_Map (Place_Timestamp.To_String);
                        T           : Sql.Transaction_Type;
                      begin
                        for Price of List2 loop
                          if Time_Placed + (0, 0, 0, 1, 0) <= Place_Timestamp and then
                            Place_Timestamp <= Time_Placed + (0, 0, 0, 2, 0) then

                            Log ("within time_placed2 +1 and time_placed2 +2 ");

                            if Price.Selectionid = Best_Runners (1).Selectionid and then
                              Best_Runners (1).Backprice >= Bet.Price then
                              Matched := True;
                              T.Start;
                              Bet.Read (Eos);
                              if not Eos then
                                Bet.Pricematched := Price.Backprice;
                                Move ("MATCHED", Bet.Status);
                                Bet.Update_And_Nullify_Betwon;
                                Log ("main", "Matched " & Bet.To_String );
                              end if;
                              T.Commit;
                            end if;
                          end if;
                        end loop;
                      end;
                    end loop Loop_Timestamp2;

                    -- Log ("main", "Matched " & Matched'Img  );
                    -- Log ("main", "Time_Placed > Calendar2.Time_Type_First and then Timestamp > Time_Placed + (0, 0, 0, 2, 0) "
                    --      & Boolean'Image(Time_Placed > Calendar2.Time_Type_First and then Timestamp > Time_Placed + (0, 0, 0, 2, 0))  );
                    -- Log ("main", "Timestamp " & Timestamp.To_String & " Time_Placed " & Time_Placed.To_String);


                    exit Loop_Timestamp when Matched or else
                      (Time_Placed > Calendar2.Time_Type_First and then Timestamp > Time_Placed + (0, 0, 0, 2, 0));

                  end;
                end if;
              end;
            end loop Loop_Timestamp;
          exception
            when Constraint_Error =>
              Log ("main", "Timestamp not in map: Constraint_Error caught "  );
          end;
        end if; -- Is_Win
      end loop Loop_Market;  -- marketid
    end;

    declare
      --        Profit, Sum, Sum_Winners, Sum_Losers  : array (Side_Type'range) of Float_8   := (others => 0.0);
      --        Winners, Losers, Unmatched, Strange   : array (Side_Type'range) of Integer_4 := (others => 0);
      T           : Sql.Transaction_Type;
      Bet_List    : Bets.Lists.List;
      All_Bets    : Sql.Statement_Type;
      Runner_List : Runners.Lists.List;
      List_Is_OK  : Boolean := True;
    begin
      T.Start;
      All_Bets.Prepare ("select * from ABETS where BETWON is null and BETNAME in (:BACKSUFFIX,:LAYSUFFIX) order by BETPLACED");
      All_Bets.Set ("BACKSUFFIX", "BACK" & Global_Bet_Suffix.Fix_String);
      All_Bets.Set ("LAYSUFFIX", "LAY" & Global_Bet_Suffix.Fix_String);
      Bets.Read_List (All_Bets, Bet_List);
      T.Commit;
      Log ("num bets laid" & Bet_List.Length'Img);
      for Bet of Bet_List loop
        Log ("check winner for bet" & Bet.To_String);
        Runner_List.Clear;
        List_Is_OK := True;
        begin
          Runner_List := Sim.Winners_Map (Bet.Marketid);
        exception
          when Constraint_Error =>
            Runner_List.Clear;
            List_Is_OK := False;
        end;
        if List_Is_Ok then
          for Winner of Runner_List loop
            -- pragma Compile_Time_Warning(True, "Fix matching");
            Bet.Pricematched := Bet.Price; -- yes -fake until coded better
            if Bet.Side = "BACK" then
              if Winner.Selectionid = Bet.Selectionid then
                -- is winner
                Bet.Betwon := True;
                Bet.Profit := (1.0 - Commission) * Bet.Sizematched * (Bet.Pricematched - 1.0);
              else
                Bet.Betwon := False;
                Bet.Profit := -Bet.Sizematched;
              end if;
            else
              if Winner.Selectionid = Bet.Selectionid then
                -- is loser
                Bet.Betwon := False;
                Bet.Profit := -(1.0 - Commission) * Bet.Sizematched * (Bet.Pricematched - 1.0);
              else
                Bet.Betwon := True;
                Bet.Profit := Bet.Sizematched;
              end if;
            end if;
          end loop;
          begin
            T.Start;
            Bet.Update_Withcheck;
            T.Commit;
          exception
            when Sql.No_Such_Row =>
              Log ("NO_SUCH_ROW " & Bet.To_String);
              T.Rollback;
          end;
        end if; -- List_Is_Ok
      end loop;

      --        for i in Side_Type'range loop
      --          Sum(i) := Sum_Winners(i) + Sum_Losers(i) ;
      --          Log("RESULT day       : " & Day.To_String & " " & i'Img );
      --          Log("RESULT Winners   : " & Winners(i)'Img & " " & Integer_4(Sum_Winners(i))'Img );
      --          Log("RESULT Losers    : " & Losers(i)'Img  & " " & Integer_4(Sum_Losers(i))'Img);
      --          Log("RESULT Unmatched : " & Unmatched(i)'Img  & " " & Unmatched(i)'Img);
      --          Log("RESULT Strange   : " & Strange(i)'Img  & " " & Strange(i)'Img);
      --          Log("RESULT Sum       : " & Integer_4(Sum(i))'Img );
      --        end loop;
      --        Log(" Min_Backprice1:" & Global_Min_Backprice1'Img &
      --            " Max_Backprice1:" & Global_Max_Backprice1'Img &
      --            " Min_Backprice2:" & Global_Min_Backprice2'Img &
      --            " Max_Backprice2:" & Global_Max_Backprice2'Img);
      --
      --        Log(" GT:" &  Integer(Sum(Back) + Sum(Lay))'Img);
    end ;

    Day := Day + One_Day;

  end loop Day_Loop;
  Sql.Close_Session;
  Log ("Started : " & Start.To_String);
  Log ("Done : " & Calendar2.Clock.To_String);
  Logging.Close;

exception
  when Betname_Already_Exists  =>
    Sql.Close_Session;
    Log ("Betname exists - skip this betname");
    Log ("Started : " & Start.To_String);
    Log ("Done : " & Calendar2.Clock.To_String);
    Logging.Close;
  when E : others =>
    Stacktrace.Tracebackinfo (E);
end Sim_Back_In_Play ;

