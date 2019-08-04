with Ada.Strings; use Ada.Strings;
--with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Environment_Variables;

with Sim;
with Utils; use Utils;
with Types ; use Types;
with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
--with Text_Io;
with Price_Histories; use Price_Histories;
with Bets;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Calendar2;  use Calendar2;
with Logging; use Logging;
with Markets;
with Runners;
with Bot_Svn_Info;
with Ini;
--with Ada.Text_IO;
with Ada.Containers.Hashed_Maps;
with Ada.Strings.Hash;

procedure Back_During_Race_7 is
  use type Ada.Containers.Count_Type;

  package Ev renames Ada.Environment_Variables;

  Bet_Size           : Bet_Size_Type := 30.0;

  --   type Odds_Record is record
  --      Back_Num : Natural := 0;
  --      Lay_Num : Natural := 0;
  --   end record;

  --type Bet_Status_Type is (No_Bet_Laid, Bet_Laid, Bet_Matched);
  --Commission : Fixed_Type  := 0.065;

  subtype Key is String(1..7);

  package Odds_Maps is new Ada.Containers.Hashed_Maps
    (Key,
     Natural,
     Ada.Strings.Hash,
     "=",
     "=");

  --------------------------------------------------------------------------

  function "<" (Left,Right : Price_Histories.Price_History_Type) return Boolean is
  begin
    return Left.Backprice < Right.Backprice;
  end "<";
  --------------------------------------------
  package Backprice_Sorter is new Price_Histories.Lists.Generic_Sorting("<");

  type Best_Runners_Array_Type is array (1..12) of Price_Histories.Price_History_Type;

  ----------------------------------------------------------------


  function Place_Timestamp(Place_Marketid: Marketid_Type; Wts : Calendar2.Time_Type) return Calendar2.Time_Type is
  begin
    pragma Warnings(Off);
      Loop_Ts2 : for Timestamp of Sim.Marketid_Pricets_Map(Place_Marketid) loop
        if Timestamp > Wts then
          return Timestamp;
        end If;
      end loop Loop_Ts2; --  Timestamp
    pragma Warnings(On);
  end Place_Timestamp;

  ----------------------------------------------------------------


  procedure Treat_Back(Market           : in     Markets.Market_Type;
                       Bra              : in     Best_Runners_Array_Type ;
                       Max_Leader_Price : in     Price_Type;
                       Delta_Price      : in     Price_Type;
                       Name             : in     Betname_Type;
                       Bet_List         : in out Bets.Lists.List) is
    Bet            : Bets.Bet_Type;
    Runner         : Runners.Runner_Type;
    Localname      : Betname_Type := Name;
    Place_Market   : Markets.Market_Type;
  begin
    if Bet_List.Length = 0 then -- ie no previous bet in this race
      --  Log("Treat_Lay", I'Img & " " & Bra(I).To_String);
      --  Log("Treat_Lay", " 1 " & Bra(1).To_String);

      if Bra(4).Selectionid > Integer_4(0) and then  -- sanity
        Bra(4).Backprice    >= Fixed_Type(1.0) and then  -- sanity
      --Bra(3).Layprice     >= Fixed_Type(1.0) and then  -- sanity
      -- Bra(3).Layprice     <= Fixed_Type(Five * Bra(3).Backprice) and then -- not too big difference allowed
        Bra(4).Backprice    >= Bra(1).Backprice + Fixed_Type(Delta_Price) and then
        Bra(1).Backprice    <= Max_Leader_Price and then
        Bra(1).Backprice    > Fixed_Type(1.0) then  -- sanity

        for J in 1 .. 4 loop -- back 4 first runners winner market
          Runner.Selectionid := Bra(J).Selectionid;
          Runner.Marketid := Bra(J).Marketid;

          Localname(23) := '_';
          Localname(24) := J'Img(2);

          Bet := Bets.Create(Name   => Localname,
                             Side   => Back,
                             Size   => Bet_Size,
                             Price  => Price_Type(Bra(J).Backprice),
                             Placed => Bra(J).Pricets,
                             Runner => Runner,
                             Market => Market);
          Bet_List.Append(Bet);
          --Log("Bet_laid-WIN-BACK", Bet.To_String);
        end loop;

        --          for J in 1 .. 4 loop -- lay 4 first runners winners market
        --            Runner.Selectionid := Bra(J).Selectionid;
        --            Runner.Marketid := Bra(J).Marketid;
        --
        --            Localname(1..3) := "WIL";
        --            Localname(23) := '_';
        --            Localname(24) := J'Img(2);
        --
        --            Bet := Bets.Create(Name   => Localname,
        --                               Side   => Lay,
        --                               Size   => Bet_Size,
        --                               Price  => Price_Type(Bra(J).Layprice),
        --                               Placed => Bra(J).Pricets,
        --                               Runner => Runner,
        --                               Market => Market);
        --            Bet_List.Append(Bet);
        --            -- Log("Bet_laid-WIN_LAY", Bet.To_String);
        --          end loop;
        declare
          Matching_Betplaced : Calendar2.Time_Type := Time_Type_First;
         -- Matching_Price     : Back_Price_Type     := Place_Timestamp(Bra(1).Pricets);

        begin
          Place_Market.Marketid := Sim.Win_Place_Map(Market.Marketid);
          Place_Market.Startts := Market.Startts;

          Matching_Betplaced  := Place_Timestamp(Place_Market.Marketid, Bra(1).Pricets);


          Move("To Be Placed", Place_Market.Marketname);

          for J in 1 .. 4 loop -- back 4 first runners place market
            Runner.Selectionid := Bra(J).Selectionid;
            Runner.Marketid := Place_Market.Marketid;

            Localname(1..3) := "PLC";
            Localname(23) := '_';
            Localname(24) := J'Img(2);

            Bet := Bets.Create(Name   => Localname,
                               Side   => Back,
                               Size   => Bet_Size,
                               Price  => Price_Type(Bra(J).Backprice),
                               Placed => Matching_Betplaced,
                               Runner => Runner,
                               Market => Place_Market);
            Move("winprice - not placeprice!", Bet.Reference);
            Bet_List.Append(Bet);
            --  Log("Bet_laid-PLC_BACK", Bet.To_String);
          end loop;
        exception
          when others => null;
        end;
      end if;
    end if;

    -- Try To check outcome
    for B of Bet_List loop
      begin
        if B.Status(1) = 'U' then
          B.Profit := Sim.Rewards_Map(B.Marketid)(B.Selectionid)(B.Betplaced.To_String);
          if B.Profit > Fixed_Type(0.0) then
            Move("MATCHED",B.Status);
          end if;
        end if;
      end;
      B.Insert;
    end loop;

    --    for B of Local_Bet_List loop
    --      Bet_List.Append(B);
    --      end loop;
  end Treat_Back;
  -- pragma Unreferenced (Treat_Lay);


  procedure Sort_Array(List : in out Price_Histories.Lists.List ;
                       Bra  : in out Best_Runners_Array_Type ) is

    Price             : Price_Histories.Price_History_Type;
  begin
    -- ok find the runner with lowest backprice:
    Backprice_Sorter.Sort(List);

    Price.Backprice := 10_000.0;
    Bra := (others => Price);

    declare
      Idx : Integer := 0;
    begin
      for Tmp of List loop
        if Tmp.Status(1..6) = "ACTIVE" and then
          Tmp.Backprice > Fixed_Type(1.0) and then
          Tmp.Layprice < Fixed_Type(1_000.1)  then
          Idx := Idx +1;
          exit when Idx > Bra'Last;
          Bra(Idx) := Tmp;
        end if;
      end loop;
    end ;

  end Sort_Array;
  -- pragma Unreferenced (Sort_Array);


  function Distance_Left(Market       : in out Markets.Market_Type;
                         Start_Time   : Calendar2.Time_Type;
                         Current_Time : Calendar2.Time_Type) return Integer_4 is
    Total_Distance   : Integer_4 := 0;
    Covered_Distance : Integer_4 := 0;
    Total_Time       : Integer_4 := 0;
  begin

    Total_Distance := Market.Distance;
    Total_Time := Sim.Racetime_Map(Market.Marketname);

    Covered_Distance := Total_Distance * (To_Seconds(Current_Time-Start_Time) / Total_Time);
    return Covered_Distance;

  end Distance_Left;

  ---------------------------------------------------------------

  Start_Date          : constant Calendar2.Time_Type := (2016,03,16,0,0,0,0);
  One_Day             : constant Calendar2.Interval_Type := (1,0,0,0,0);
  Current_Date        :          Calendar2.Time_Type := Start_Date;
  Stop_Date           : constant Calendar2.Time_Type := (2018,08,01,0,0,0,0);
  T                   :          Sql.Transaction_Type;
  Cmd_Line            :          Command_Line_Configuration;
  Sa_Logfilename      : aliased  Gnat.Strings.String_Access;
  Sa_Max_Leader_Price : aliased  Gnat.Strings.String_Access;
  Sa_Delta_Price      : aliased  Gnat.Strings.String_Access;
  Sa_Max_Distance_Left : aliased  Gnat.Strings.String_Access;

  Max_Leader_Price     : Price_Type;
  Delta_Price          : Price_Type;
  Max_Distance_Left    : Integer_4;

begin
  Define_Switch
    (Cmd_Line,
     Sa_Logfilename'Access,
     Long_Switch => "--logfile=",
     Help        => "name of log file");

  Define_Switch
    (Cmd_Line,
     Sa_Max_Leader_Price'Access,
     Long_Switch => "--max_leader_price=",
     Help        => "leader's back price must be lower that this");

  Define_Switch
    (Cmd_Line,
     Sa_Delta_Price'Access,
     Long_Switch => "--delta=",
     Help        => "diff between #1 and #4");

  Define_Switch
    (Cmd_Line,
     Sa_Max_Distance_Left'Access,
     Long_Switch => "--max_distance_left=",
     Help        => "well, what is says");


  Getopt (Cmd_Line);  -- process the command line

  if not Ev.Exists("BOT_NAME") then
    Ev.Set("BOT_NAME","bdr2");
  end if;

  --  Logging.Open(Ev.Value("BOT_HOME") & "/log/" & Sa_Logfilename.all & ".log");
  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);
  Log("main", "params start");
  Log("main", "Sa_Max_Leader_Price" & Sa_Max_Leader_Price.all);
  Log("main", "Sa_Max_Distance_Left" & Sa_Max_Distance_Left.all);
  Log("main", "Sa_Delta_Price" & Sa_Delta_Price.all);
  Log("main", "params stop");

  Max_Leader_Price := Price_Type'Value(Sa_Max_Leader_Price.all);
  Max_Distance_Left        := Integer_4'Value(Sa_Max_Distance_Left.all);
  Delta_Price        := Price_Type'Value(Sa_Delta_Price.all);

  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");

  Log("main", "Connect Db " &
        Ini.Get_Value("database_home", "host", "")  & " " &
        Ini.Get_Value("database_home", "port", 5432)'Img & " " &
        Ini.Get_Value("database_home", "name", "") & " " &
        Ini.Get_Value("database_home", "username", "") & " " &
        Ini.Get_Value("database_home", "password", "")
     );

  Sql.Connect
    (Host     => Ini.Get_Value("database_home", "host", ""),
     Port     => Ini.Get_Value("database_home", "port", 5432),
     Db_Name  => Ini.Get_Value("database_home", "name", ""),
     Login    => Ini.Get_Value("database_home", "username", ""),
     Password => Ini.Get_Value("database_home", "password", ""));
  Log("main", "db Connected");

  Date_Loop : loop
    T.Start;
    Log("start fill maps");
    Sim.Fill_Data_Maps(Current_Date, Bot_Types.Horse);
    Log("start process maps");
    T.Commit;

    declare
      Cnt       : Integer := 0;
    begin
      Market_Loop : for Market of Sim.Market_With_Data_List loop
        T.Start;
        if Market.Markettype(1..3) = "WIN"
          and then Market.Marketname_Ok2
        then

          Log("main", "Treat " & Market.To_String);
          Cnt := Cnt + 1;
          -- list of timestamps in this market
          declare
            Timestamp_To_Prices_History_Map : Sim.Timestamp_To_Prices_History_Maps.Map :=
                                                Sim.Marketid_Timestamp_To_Prices_History_Map(Market.Marketid);
            Bet_List                        : Bets.Lists.List;
            Start_Time                      : Calendar2.Time_Type := Calendar2.Time_Type_Last;
          begin
            Loop_Ts : for Timestamp of Sim.Marketid_Pricets_Map(Market.Marketid) loop

              declare
                List     : Price_Histories.Lists.List := Timestamp_To_Prices_History_Map(Timestamp.To_String);
                Bra      : Best_Runners_Array_Type := (others => Price_Histories.Empty_Data);
                Name     : Betname_Type := (others => ' ');
                Num      : String(1..5) := (others => ' ');
                Tail     : String(1..6) := "___Pln"; -- for 'plain'
              begin


                if Delta_Price < 10.0 then
                  Num := "0" & F8_Image(Fixed_Type(Delta_Price));
                elsif  Delta_Price < 100.0 then
                  Num := F8_Image(Fixed_Type(Delta_Price));
                end if;


                --                  if Utils.Position(S => Market.Marketname, Match => "Hrd") > Integer(0) then
                --                    Tail := "___Hrd";
                --                  elsif Utils.Position(S => Market.Marketname, Match => "Chs") > Integer(0) then
                --                    Tail := "___Chs";
                --                  end if;
                Move("WIN_F7_" &
                       F8_Image(Fixed_Type(Max_Leader_Price)) & "_" &
                       Num & "_" &
                       Trim(Max_Distance_Left'Img) & Tail, Name);


                Sort_Array(List => List, Bra  => Bra);

                if Start_Time = Calendar2.Time_Type_Last then
                  Start_Time := Bra(1).Pricets;
                end if;

                if Distance_Left(Market, Start_Time,Bra(1).Pricets) < Max_Distance_Left then

                  Treat_Back(Market            => Market,
                             Bra               => Bra,
                             Max_Leader_Price  => Max_Leader_Price,
                             Delta_Price       => Delta_Price,
                             Name              => Name,
                             Bet_List          => Bet_List);
                  exit Loop_Ts;
                end if;


              end;
            end loop Loop_Ts; --  Timestamp
            --Bets.Sum_Laybets(Bet_List, -12_000.0);
          end;
        end if; -- Market_type(1..3) = WIN
        T.Commit;
      end loop Market_Loop;
    end;

    --Sim.Delete_Shared_Mem(Current_Date, Bot_Types.Horse);

    Current_Date := Current_Date + One_Day;
    exit when Current_Date = Stop_Date;

  end loop Date_Loop;

  Sql.Close_Session;

exception
  when E: others =>
    Stacktrace.Tracebackinfo(E);
    Sql.Close_Session;
end Back_During_Race_7;
