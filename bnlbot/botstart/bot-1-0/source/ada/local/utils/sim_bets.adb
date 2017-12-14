with Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Environment_Variables;
with Ada.Containers;
with Ada.Containers.Doubly_Linked_Lists;
--with Text_Io;
--with Gnat.Command_Line; use Gnat.Command_Line;
---with GNAT.Strings;

with Sim;
--with Utils; use Utils;
with Types ; use Types;
with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
with Price_Histories;
with Bets;
with Calendar2;  use Calendar2;
with Logging; use Logging;
--with Bot_System_Number;


procedure Sim_Bets is

  package Ev renames Ada.Environment_Variables;


  Bet_List : Bets.Lists.List;
  --  Config           : Command_Line_Configuration;

  --  IA_Back_At_Back_Price : aliased Integer := 50;
  --  IA_Lay_At_Back_Price  : aliased Integer := 100;
  --  IA_Max_Lay_Price      : aliased Integer := 200;

  --  Lay_Size  : Float_8 := 30.0;
  --  Back_Size : Float_8 := 1500.0;

  --type Bet_Status_Type is (No_Bet_Laid, Bet_Laid);
  --Bet_Status : Bet_Status_Type := No_Bet_Laid;

  --    Global_Min_Backprice1     : constant Float_8 := 1.31;
  --    Global_Max_Backprice1     : constant Float_8 := 1.36;
  --    Global_Min_Backprice2     : constant Float_8 := 2.5;
  --    Global_Max_Backprice2     : constant Float_8 := 10.0;
  --    Global_Lay_At_Backprice   : constant Float_8 := 1.25;
  --    Global_Lay_Size           : constant Float_8 := 110.0;
  --    Global_Back_Size          : constant Float_8 := 100.0;

  Global_Back_Size : Fixed_Type := 30.0;
  Empty_Market     : constant Marketid_Type := (others => ' ');



  Start           : Calendar2.Time_Type := Calendar2.Clock;

  function "<" (Left,Right : Price_Histories.Price_History_Type) return Boolean is
  begin
    return Left.Backprice < Right.Backprice;
  end "<";
  --------------------------------------------
  package Backprice_Sorter is new Price_Histories.Lists.Generic_Sorting("<");

  type Best_Runners_Array_Type is array (1..4) of Price_Histories.Price_History_Type ;
  Best_Runners      : Best_Runners_Array_Type := (others => Price_Histories.Empty_Data);

  --------------------------------------------

  Enough_Runners : Boolean := False;
  use type Ada.Containers.Count_Type;
  Price : Price_Histories.Price_History_Type;

  Day      : Time_Type := (2016,03,19,00,00,00,000);
  End_Date : Time_Type := (2017,08,20,00,00,00,000);
  One_Day  : Interval_Type := (1,0,0,0,0);


  type Place_Of_Next_Type is new Integer range 2 .. 4 ;
  type Place_Of_Runner_Type is new Integer range 1 .. 3 ;
  type Strategy_Type is record
    Betname           : Types.String_Object;
    Marketid          : Marketid_Type := (others => ' ');
    Leader_At_Max     : Fixed_Type := 0.0;
    Next_At_Min       : Fixed_Type := 0.0;
    Place_Of_Next     : Place_Of_Next_Type:= Place_Of_Next_Type'First;
    Place_Of_Runner   : Place_Of_Runner_Type:= Place_Of_Runner_Type'First;
    Ts_Of_Fulfill     : Calendar2.Time_Type := Calendar2.Time_Type_First;
    Backprice_Matched : Fixed_Type := 0.0;
    Profit            : Fixed_Type := 0.0;
    Num_Matched       : Integer_4 := 0;
    Num_Unmatched     : Integer_4 := 0;
    Num_Wins          : Integer_4 := 0;
    Num_Lost          : Integer_4 := 0;
  end record;

  package Strategy_List_Pack is new Ada.Containers.Doubly_Linked_Lists(Strategy_Type, "=");
  --------------------------------------------------------------------------------
  procedure Load_Strategies(Strategy_List : out Strategy_List_Pack.List) is
  begin
    Strategy_List.Append(Strategy_Type'(Betname         => Create("SIM_PLC_1.10_7.0_1"),
                                        Marketid        => (others            => ' '),
                                        Leader_At_Max   => 1.10,
                                        Next_At_Min     => 7.0,
                                        Place_Of_Next   => 2,
                                        Place_Of_Runner => 1,
                                        Backprice_Matched => 0.0,
                                        Profit            => 0.0,
                                        Num_Matched       => 0,
                                        Num_Unmatched     => 0,
                                        Num_Lost          => 0,
                                        Num_Wins          => 0,
                                        Ts_Of_Fulfill   => Calendar2.Time_Type_First)
                        );
    --Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.25_12.0_1"),
    --                                    Marketid        => (others => ' '),
    --                                    Leader_At_Max   => 1.25,
    --                                    Next_At_Min     => 12.0,
    --                                    Place_Of_Next   => 2,
    --                                    Place_Of_Runner => 1,
    --                                    Backprice_Matched => 0.0,
    --                                    Profit            => 0.0,
    --                                    Profit_102        => 0.0,
    --                                    Profit_103        => 0.0,
    --                                    Profit_104        => 0.0,
    --                                    Num_Lost          => 0,
    --                                    Num_Wins          => 0,
    --                                    Num_Matched       => 0,
    --                                    Ts_Of_Fulfill   => Calendar2.Time_Type_First)
    --                           );
    --Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.10_7.0_2"),
    --                                    Marketid        => (others => ' '),
    --                                    Leader_At_Max   => 1.10,
    --                                    Next_At_Min     => 7.0,
    --                                    Place_Of_Next   => 2,
    --                                    Place_Of_Runner => 2,
    --                                    Backprice_Matched => 0.0,
    --                                    Profit            => 0.0,
    --                                    Profit_102        => 0.0,
    --                                    Profit_103        => 0.0,
    --                                    Profit_104        => 0.0,
    --                                    Num_Matched       => 0,
    --                                    Num_Lost          => 0,
    --                                    Num_Wins          => 0,
    --                                    Ts_Of_Fulfill   => Calendar2.Time_Type_First)
    --                           );
    --Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.25_12.0_2"),
    --                                    Marketid        => (others => ' '),
    --                                    Leader_At_Max   => 1.25,
    --                                    Next_At_Min     => 12.0,
    --                                    Place_Of_Next   => 2,
    --                                    Place_Of_Runner => 2,
    --                                    Backprice_Matched => 0.0,
    --                                    Profit            => 0.0,
    --                                    Profit_102        => 0.0,
    --                                    Profit_103        => 0.0,
    --                                    Profit_104        => 0.0,
    --                                    Num_Lost          => 0,
    --                                    Num_Wins          => 0,
    --                                    Num_Matched       => 0,
    --                                    Ts_Of_Fulfill   => Calendar2.Time_Type_First)
    --                           );
    --Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.10_7.0_3"),
    --                                    Marketid        => (others => ' '),
    --                                    Leader_At_Max   => 1.10,
    --                                    Next_At_Min     => 7.0,
    --                                    Place_Of_Next   => 2,
    --                                    Place_Of_Runner => 3,
    --                                    Backprice_Matched => 0.0,
    --                                    Profit            => 0.0,
    --                                    Profit_102        => 0.0,
    --                                    Profit_103        => 0.0,
    --                                    Profit_104        => 0.0,
    --                                    Num_Matched       => 0,
    --                                    Num_Lost          => 0,
    --                                    Num_Wins          => 0,
    --                                    Ts_Of_Fulfill   => Calendar2.Time_Type_First)
    --                           );
    --Strategy_List.Append(Strategy_Type'(Betname         => Repository_Types.Create("SIM_PLC_1.25_12.0_3"),
    --                                    Marketid        => (others => ' '),
    --                                    Leader_At_Max   => 1.25,
    --                                    Next_At_Min     => 12.0,
    --                                    Place_Of_Next   => 2,
    --                                    Place_Of_Runner => 3,
    --                                    Backprice_Matched => 0.0,
    --                                    Profit            => 0.0,
    --                                    Profit_102        => 0.0,
    --                                    Profit_103        => 0.0,
    --                                    Profit_104        => 0.0,
    --                                    Num_Lost          => 0,
    --                                    Num_Wins          => 0,
    --                                    Num_Matched       => 0,
    --                                    Ts_Of_Fulfill   => Calendar2.Time_Type_First)
    --                           );
    --declare            --1234567890123456789
    --  Templ : String := "SIM_PLC_1.90_60.0_1";
    --begin
    --  for Leader_Int in 1 ..2 loop
    --     for Leader_First_Fraction in 0 .. 9 loop
    --        for Next_At_10 in 2 .. 9 loop
    --          for Runner_Postion in 1 .. 3 loop
    --            Templ(9) := Leader_Int'Img(2);
    --            Templ(11) := Leader_First_Fraction'Img(2);
    --            Templ(14) := Next_At_10'Img(2);
    --            Templ(19) := Runner_Postion'Img(2);
    --            Strategy_List.Append(
    --                  Strategy_Type'(
    --                       Betname         => Repository_Types.Create(Templ),
    --                       Marketid        => (others => ' '),
    --                       Leader_At_Max   => Fixed_Type'Value(Templ(9..12)),
    --                       Next_At_Min     => Fixed_Type'Value(Templ(14..17)),
    --                       Place_Of_Next   => 4,
    --                       Place_Of_Runner => Place_Of_Runner_Type'Value(Templ(19..19)),
    --                       Backprice_Matched => 0.0,
    --                       Profit            => 0.0,
    --                       Profit_102        => 0.0,
    --                       Profit_103        => 0.0,
    --                       Profit_104        => 0.0,
    --                       Num_Matched       => 0,
    --                       Num_Lost          => 0,
    --                       Num_Wins          => 0,
    --                       Ts_Of_Fulfill   => Calendar2.Time_Type_First
    --                  )
    --            );
    --
    --          end loop;
    --        end loop;
    --     end loop;
    --  end loop;
    --end;

  end Load_Strategies;
  -------------------------------------------------------------


  procedure Treat_For_Place(Best_Runners : in Best_Runners_Array_Type;
                            Strategy     : in out Strategy_Type;
                            Bet_List     : in out Bets.Lists.List ) is
    High_Index,
    Runner_Index : Integer := 0;
    Bet : Bets.Bet_Type;
  begin
      if Strategy.Marketid = Empty_Market then
        --check the strategy againt the Best_Runners
        High_Index := Integer(Strategy.Place_Of_Next);
        if Best_Runners(1).Backprice <= Strategy.Leader_At_Max and then
            Best_Runners(High_Index).Backprice >= Strategy.Next_At_Min
        then
          Strategy.Marketid := Best_Runners(1).Marketid;     -- mark strategy as fulfilled, when and with what marketid
          Strategy.Ts_Of_Fulfill := Best_Runners(1).Pricets;
          Runner_Index := Integer(Strategy.Place_Of_Runner);
          Strategy.Backprice_Matched := Sim.Get_Place_Price(Win_Data => Best_Runners(1)).Backprice;

          if Strategy.Backprice_Matched > Fixed_Type(1.0) then
            Strategy.Ts_Of_Fulfill := Calendar2.Time_Type_First; -- so we do not bet again with this strategy on this market
            Strategy.Num_Matched := Strategy.Num_Matched +1;
            Move(Strategy.Betname.Upper_Case, Bet.Betname);
            Bet.Marketid     := Sim.Win_Place_Map(Best_Runners(1).Marketid);
            Bet.Selectionid  := Best_Runners(Runner_Index).Selectionid;
            Bet.Size         := Global_Back_Size;
            Bet.Price        := Best_Runners(Runner_Index).Backprice;
            Bet.Sizematched  := Global_Back_Size;
            Bet.Pricematched := Best_Runners(Runner_Index).Backprice;
            Bet.Betplaced    := Best_Runners(Runner_Index).Pricets;
            Bet.Startts      := Best_Runners(Runner_Index).Pricets;  -- correct date anyway
            Bet_List.Append(Bet);
          else
            -- still mark as strategy mached - it only gets 1 shot
            Strategy.Num_Unmatched := Strategy.Num_Unmatched +1;
          end if;
        end if;
      end if;

  end Treat_For_Place;




  Strategy_List : Strategy_List_Pack.List;


  ---------------------------------------------------------------------------
begin

  if not Ev.Exists("BOT_NAME") then
    Ev.Set("BOT_NAME","sim_bets");
  end if;
  Logging.Open(Ev.Value("BOT_HOME") & "/log/" & Ev.Value("BOT_NAME") & ".log");

  Log ("Connect db");
  Sql.Connect
    (Host     => "192.168.1.20",
     Port     => 5432,
     Db_Name  => "bnl",
     Login    => "bnl",
     Password => "bnl");
  Log ("Connected to db");

  Load_Strategies(Strategy_List);

  Day_Loop : loop

    exit Day_Loop when Day >  End_Date;
    Sim.Fill_Data_Maps(Day,Horse);
    Log("start process date " & Day.To_String);

    declare
      Cnt    : Integer := 0;
      Is_Win : Boolean := True;
      --  Bet : Bets.Bet_Type;
    begin
      Log("num markets " & Day.To_String & " " & Sim.Market_With_Data_List.Length'Img);

      Loop_Market : for Market of Sim.Market_With_Data_List loop
        Is_Win := Market.Markettype(1..3) = "WIN";

        if Is_Win then
          Log("Treat market " & Market.To_String );
          Cnt := Cnt + 1;
          -- list of timestamps in this market
          for Strategy of Strategy_List loop
            Strategy.Marketid := Empty_Market;
            Strategy.Ts_Of_Fulfill := Calendar2.Time_Type_First;
          end loop;

          declare
            Timestamp_To_Apriceshistory_Map : Sim.Timestamp_To_Prices_History_Maps.Map :=
              Sim.Marketid_Timestamp_To_Prices_History_Map(Market.Marketid);
            --   Bet_Placed : Boolean := False;
            First                           : Boolean := True;
          begin
            Loop_Timestamp : for Timestamp of Sim.Marketid_Pricets_Map(Market.Marketid) loop
              --Log("Treat marketid '" & Market.Marketid & "' pricets " & Timestamp.To_String);
              declare
                List : Price_Histories.Lists.List :=
                  Timestamp_To_Apriceshistory_Map(Timestamp.To_String);
              begin
                if First then
                  Enough_Runners := List.Length >= 8;
                  First := False;
                  if not Enough_Runners then
                    exit Loop_Timestamp;  -- too few runners
                  end if;
                end if;

                --Current_Market_Of_Sample := List.First_Element;
                --if Current_Market_Of_Sample.Marketid /= Old_Market_Of_Sample.Marketid then
                --  Log("Treat marketid '" & Current_Market_Of_Sample.Marketid & "' " &
                --      "pricets " & Current_Market_Of_Sample.Pricets.To_String);
                --  Old_Market_Of_Sample := Current_Market_Of_Sample;
                --end if;

                Backprice_Sorter.Sort(List);
                Price.Backprice := 10_000.0;
                Best_Runners := (others => Price);

                declare
                  Idx : Integer := 0;
                begin
                  for Tmp of List loop
                    Idx := Idx +1;
                    exit when Idx > Best_Runners'Last;
                    Best_Runners(Idx) := Tmp;
                  end loop;
                end ;

                --do something here
                for Strategy of Strategy_List loop
                  if Strategy.Marketid /= Empty_Market and then
                     Strategy.Ts_Of_Fulfill > Calendar2.Time_Type_First then
                    Treat_For_Place(Best_Runners, Strategy, Bet_List);
                  end if;
                end loop;


              end;
              exit Loop_Market when False;
            end loop Loop_Timestamp; --  Timestamp
          end;
        end if; -- Is_Win
      end loop Loop_Market;  -- marketid

    end;
    Log("num bets laid" & Bet_List.Length'Img);

    declare
      --        Profit, Sum, Sum_Winners, Sum_Losers  : array (Side_Type'range) of Float_8   := (others => 0.0);
      --        Winners, Losers, Unmatched, Strange   : array (Side_Type'range) of Integer_4 := (others => 0);
      T : Sql.Transaction_Type;
    begin
      T.Start;
      for Bet of Bet_List loop
        --Bet.Betid := Integer_8(Bot_System_Number.New_Number(Bot_System_Number.Betid));
        Bet.Insert;
      end loop;
      T.Commit;

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

    Bet_List.Clear;
    Day := Day + One_Day;

  end loop Day_Loop;
  Sql.Close_Session;
  Log("Started : " & Start.To_String);
  Log("Done : " & Calendar2.Clock.To_String);
  Logging.Close;


exception
  when E: others =>
    Stacktrace.Tracebackinfo(E);
end Sim_Bets ;
