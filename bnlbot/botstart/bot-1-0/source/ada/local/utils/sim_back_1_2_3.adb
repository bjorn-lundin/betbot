with Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Environment_Variables;
with Ada.Containers;
--with Text_Io;
with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;

with Sim;
with Utils; use Utils;
with Types ; use Types;
with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
with Price_Histories;
with Bets;
with Calendar2;  use Calendar2;
with Logging; use Logging;
--with Bot_System_Number;
with Markets;
with Runners;


procedure Sim_Back_1_2_3 is

  package EV renames Ada.Environment_Variables;
  Betname_Already_Exists : exception;
  Commission : constant := 0.0/100.0;
  Cmd_Line   : Command_Line_Configuration;

  IA_Num_Bets  : aliased Integer := 50;
  IA_First_Bet : aliased Integer := 100;
  IA_Place_Num : aliased Integer := 200;

  SA_Max_Back_Price      : aliased Gnat.Strings.String_Access;
  SA_Max_Lay_Price_Delta : aliased Gnat.Strings.String_Access;

  Global_Max_Back_Price      : Float_8 := 0.0;
  Global_Max_Lay_Price_Delta : Float_8 := 0.0;
  Global_Lay_Size            : Bet_Size_Type := 30.0;
  Global_Back_Size           : Bet_Size_Type := 30.0;

 --num_bets=${num_bets} \
 --first_bet=${first_bet} \
 --place_num=${place_num} \
 --max_back_price=${max_back} \
 --max_lay_price_delta=${max_lay_delta} > ./${name}.log 2>&1 &
  Global_Has_Checked_Betname_Exists : Boolean := False;
  Betname_Exists : Sql.Statement_Type;

  Start : Calendar2.Time_Type := Calendar2.Clock;

  --------------------------------------------
  function "<" (Left,Right : Price_Histories.Price_History_Type) return Boolean is
  begin
    return Left.Backprice < Right.Backprice;
  end "<";
  --------------------------------------------
  package Backprice_Sorter is new Price_Histories.Lists.Generic_Sorting("<");

  type Best_Runners_Array_Type is array (1 .. 10) of Price_Histories.Price_History_Type ;
  Best_Runners : Best_Runners_Array_Type := (others => Price_Histories.Empty_Data);
  Bet_Suffix     :  String_Object;

  -------------------------------------
  function Check_Betname_Exists (Betname : String) return Boolean is
    Eos : Boolean := False;
  begin
    Betname_Exists.Prepare ("select 'a' from ABETS where BETNAME=:BETNAME");
    Betname_Exists.Set ("BETNAME", Betname);
    Betname_Exists.Open_Cursor;
    Betname_Exists.Fetch (Eos);
    Betname_Exists.Close_Cursor;
    return not Eos;
  end Check_Betname_Exists;


  --------------------------------------------------
  procedure Treat (BR             : in Best_Runners_Array_Type;
                   Market         : in Markets.Market_Type;
                   Num_Bets       : in Integer;
                   First_Bet      : in Integer;
                   Place_Num      : in Integer;
                   Max_Back_Price : in Float_8;
                   Max_Lay_Price  : in Float_8;
                   Bet_Suffix     : in out String_Object) is

    Bet     : Bets.Bet_Type;
    T       : Sql.Transaction_Type;
    Betname : Betname_Type ;
    Runner  : Runners.Runner_Type;
  begin
    Bet_Suffix.Set("");
    Bet_Suffix.Append ("_" & Trim (Num_Bets'Img) & "_" &
                       Trim (First_Bet'Img) & "_" &
                       Trim (Place_Num'Img) & "_" &
                       F8_Image (Max_Back_Price) & "_" &
                       F8_Image (Max_Lay_Price) );


    Move ("BACK" & Bet_Suffix.Fix_String, Betname);
    T.Start;

    if not Global_Has_Checked_Betname_Exists then
      Global_Has_Checked_Betname_Exists := True;
      if Check_Betname_Exists (Betname) then
        T.Commit;
        raise Betname_Already_Exists;
      end if;
    end if;




    if Place_Num <= BR'Last and then BR (Place_Num).Backprice <= Max_Back_Price then
      for I in BR'Range loop
        if I >= First_Bet and then
          I < First_Bet + Num_Bets and then
          BR (I).Backprice <= Max_Back_Price then

          Runner.Selectionid := BR (I).Selectionid;
          Bet := Bets.Create (Name   => Betname,
                              Side   => Back,
                              Size   => Global_Back_Size,
                              Price  => Price_Type (BR (I).Backprice),
                              Placed => BR (I).Pricets,
                              Runner => Runner,
                              Market => Market);
          Bet.Insert_And_Nullify_Betwon;
        end if;
      end loop;
    end if;

    Move ("LAY" & Bet_Suffix.Fix_String, Betname);

    if Place_Num <= BR'Last and then
      BR (Place_Num).Backprice <= Max_Back_Price and then
      BR (Place_Num).Backprice <= Max_Lay_Price then
      for I in BR'Range loop
        if I >= First_Bet and then
          BR (I).Backprice <= Max_Lay_Price and then
          BR (I).Backprice <= Max_Back_Price and then
          I < First_Bet + Num_Bets then

          Runner.Selectionid := BR (I).Selectionid;
          Bet := Bets.Create (Name   => Betname,
                              Side   => Lay,
                              Size   => Global_Lay_Size,
                              Price  => Price_Type (BR (I).Layprice),
                              Placed => BR (I).Pricets,
                              Runner => Runner,
                              Market => Market);
          Bet.Insert_And_Nullify_Betwon;
        end if;
      end loop;
    end if;

    T.Commit;
  end Treat;
  ---------------------------------------------------------

  Enough_Runners : Boolean := False;
  use type Ada.Containers.Count_Type;
  Price : Price_Histories.Price_History_Type;

  Day : Time_Type := (2016,03,19,00,00,00,000);
  End_Date : Time_Type := Clock;
  One_Day : Interval_Type := (1,0,0,0,0);
begin

  if not EV.Exists ("BOT_NAME") then
    EV.Set(Name => "BOT_NAME", Value => "sim_back_1_2_3");
  end if;

 -- Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");

  Define_Switch
     (Cmd_Line,
      IA_Num_Bets'access,
      Long_Switch => "--num_bets=",
      Help        => "num bets to place - from first_bet");

  Define_Switch
     (Cmd_Line,
      IA_First_Bet'access,
      Long_Switch => "--first_bet=",
      Help        => "first runner to place bet on");

  Define_Switch
     (Cmd_Line,
      IA_Place_Num'access,
      Long_Switch => "--place_num=",
      Help        => "The runner checked for odds limits");

  Define_Switch
     (Cmd_Line,
      SA_Max_Back_Price'access,
      Long_Switch => "--max_back_price=",
      Help        => "For backbets check runner 'place_num', max back price for place_num");

  Define_Switch
     (Cmd_Line,
      SA_Max_Lay_Price_Delta'access,
      Long_Switch => "--max_lay_price_delta=",
      Help        => "For laybets check runner 'place_num' for layodds <= max_back_price+max_lay_price_delta " &
                     "and for backodds <= max_back_price");


  Getopt (Cmd_Line);  -- process the command line


  Global_Max_Back_Price      := Float_8'Value(SA_Max_Back_Price.all);
  Global_Max_Lay_Price_Delta := Float_8'Value(SA_Max_Lay_Price_Delta.all);


  Log ("Connect db");
  Sql.Connect
    (Host     => "localhost",
     Port     => 5432,
     Db_Name  => "bnl",
     Login    => "bnl",
     Password => "bnl");
  Log ("Connected to db");


  Day_Loop : loop

    exit Day_Loop when Day >  End_Date;
    Sim.Fill_Data_Maps(Day);
    Log("start process date " & Day.To_String);

    declare
      Cnt : Integer := 0;
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
          declare
            Timestamp_To_Apriceshistory_Map : Sim.Timestamp_To_Prices_History_Maps.Map :=
                                                Sim.Marketid_Timestamp_To_Prices_History_Map (Market.Marketid);
            First : Boolean := True;
          begin
            Loop_Timestamp : for Timestamp of Sim.Marketid_Pricets_Map(Market.Marketid) loop
              --Log("Treat marketid '" & Market.Marketid & "' pricets " & Timestamp.To_String);
              declare
                List : Price_Histories.Lists.List :=
                         Timestamp_To_Apriceshistory_Map (Timestamp.To_String);
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

                Price.Backprice := 10_000.0;
                Best_Runners := (others => Price);

                declare
                  Idx : Integer := 0;
                begin
                  for Tmp of List loop
                    Idx := Idx + 1;
                    exit when Idx > Best_Runners'Last;
                    Best_Runners (Idx) := Tmp;
                  end loop;
                end ;
                Backprice_Sorter.Sort (List);

                --do something here
                Log ("dolog " & Market.Startts.To_String & " - " &
                       Market.Marketid & " - " &
                       Market.Marketname(1..15));

                Treat (BR             => Best_Runners,
                       Market         => Market,
                       Num_Bets       => IA_Num_Bets,
                       First_Bet      => IA_First_Bet,
                       Place_Num      => IA_Place_Num,
                       Max_Back_Price => Global_Max_Back_Price,
                       Max_Lay_Price  => Global_Max_Back_Price + Global_Max_Lay_Price_Delta,
                       Bet_Suffix     => Bet_Suffix);

              end;
              exit Loop_Timestamp ; --when False;
            end loop Loop_Timestamp; --  Timestamp
          end;
        end if; -- Is_Win
      end loop Loop_Market;  -- marketid
    end;

    declare
--        Profit, Sum, Sum_Winners, Sum_Losers  : array (Side_Type'range) of Float_8   := (others => 0.0);
--        Winners, Losers, Unmatched, Strange   : array (Side_Type'range) of Integer_4 := (others => 0);
      T : Sql.Transaction_Type;

      Bet_List : Bets.Lists.List;
      All_Bets : Sql.Statement_Type;
      Runner_List : Runners.Lists.List;
      List_Is_OK : Boolean := True;
    begin
      T.Start;
      All_Bets.Prepare ("select * from ABETS where BETWON is null and BETNAME in (:BACKSUFFIX,:LAYSUFFIX) order by BETPLACED");
      All_Bets.Set("BACKSUFFIX","BACK" & Bet_Suffix.Fix_String);
      All_Bets.Set("LAYSUFFIX","LAY" & Bet_Suffix.Fix_String);
      Bets.Read_List(All_Bets, Bet_List);
      T.Commit;
      Log("num bets laid" & Bet_List.Length'Img);
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
  Log("Started : " & Start.To_String);
  Log("Done : " & Calendar2.Clock.To_String);
  Logging.Close;


exception
   when Betname_Already_Exists  =>
     Sql.Close_Session;
     Log("Betname exists - skip this betname");
     Log("Started : " & Start.To_String);
     Log("Done : " & Calendar2.Clock.To_String);
     Logging.Close;
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Sim_Back_1_2_3 ;
