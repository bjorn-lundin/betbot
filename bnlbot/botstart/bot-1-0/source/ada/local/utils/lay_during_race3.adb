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
with Price_Histories;
with Bets;
with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;
with Calendar2;  use Calendar2;
with Logging; use Logging;
with Markets;
with Runners;
with Bot_Svn_Info;
with Ini;


procedure Lay_During_Race3 is

  package Ev renames Ada.Environment_Variables;
  Global_Bet_List : Bets.Lists.List;

  Lay_Size  : Bet_Size_Type := 30.0;
  Back_Size : Bet_Size_Type := 30.0;

  type Bet_Status_Type is (No_Bet_Laid, Bet_Laid);
  Lay_bet_Status : Bet_Status_Type := No_Bet_Laid;
  Back_bet_Status : Bet_Status_Type := No_Bet_Laid;

   --------------------------------------------------------------------------

  function "<" (Left,Right : Price_Histories.Price_History_Type) return Boolean is
  begin
    return Left.Backprice < Right.Backprice;
  end "<";
  --------------------------------------------
  package Backprice_Sorter is new Price_Histories.Lists.Generic_Sorting("<");

  type Best_Runners_Array_Type is array (1..4) of Price_Histories.Price_History_Type;


  procedure Treat_Lay(List         : in     Price_Histories.Lists.List ;
                      Market       : in     Markets.Market_Type;
                      WR           : in     Price_Histories.Price_History_Type ;
                      BRA          : in     Best_Runners_Array_Type ;
                      Old_Bra      : in     Best_Runners_Array_Type ;
                      Status       : in out Bet_Status_Type;
                      Bet_List     : in out Bets.Lists.List) is
    pragma Unreferenced(List);
   -- pragma Unreferenced(BRA);
   -- pragma Unreferenced(Old_bra);
    Bet : Bets.Bet_Type;
    Runner : Runners.Runner_Type;
    Name : Betname_Type := (others => ' ');
    Idx : Integer := 0;
  begin
    case Status is
      when No_Bet_Laid =>
        -- check for bet already laid for this runner on this market
        for B of Bet_List loop
          if B.Selectionid = WR.Selectionid and then
             B.Marketid    = WR.Marketid and then
             B.Side(1..3)  = "LAY" then
               return ;
          end if;
        end loop;


        for I in Bra'Range loop
          if Bra(I).Layprice >= Fixed_Type(5.0) + old_Bra(I).Layprice and then
             Old_Bra(I).Layprice < Fixed_Type(30.0) then
            Idx := I;
            exit;
          end if;
        end loop;

        if Idx = 0 then
          return;
        end if;

        -- make sure no bet in the air, waiting for 1 second
        if Bra(Idx).Backprice >= Fixed_Type(1.0)and then
          Bra(Idx).Layprice  >= Fixed_Type(1.0) and then
          Bra(Idx).Backprice <= Fixed_Type(100.0) and then
          Bra(Idx).Layprice  <= Fixed_Type(50.0) then

          Runner.Selectionid := Bra(Idx).Selectionid;
          Move("WIN_LAY_5.0_30.0", Name);
          Bet := Bets.Create(Name   => Name,
                             Side   => Lay,
                             Size   => Lay_Size,
                             Price  => Price_Type(50.0),
                             Placed => Bra(Idx).Pricets,
                             Runner => Runner,
                             Market => Market);
          Status          := Bet_Laid;
          Bet_List.Append(Bet);
        end if;

      when Bet_Laid    =>
        -- make sure the WR here is the same as got the bet laid
        for B of Bet_List loop
          if B.Selectionid =  WR.Selectionid then
            if WR.Pricets >  B.Betplaced + (0,0,0,1,0) then -- 1 second later at least, time for BF delay
              if WR.Layprice <= B.Price and then -- Laybet so yes '<=' NOT '>='
               WR.Layprice >  Fixed_Type(1.0) and then -- sanity
               WR.Backprice >  Fixed_Type(1.0) then -- sanity
                 B.Status(1..20) := "MATCHED             "; --Matched
                 B.Pricematched := WR.Layprice;
                 B.Check_Outcome;
                 B.Insert;
                 exit;
              end if;
            end if;
          end if;
        end loop;
    end case;
  end Treat_Lay;

  --------------------------------------------------------------------------
  procedure Treat_Back(List         : in     Price_Histories.Lists.List ;
                       Market       : in     Markets.Market_Type;
                       BRA          : in     Best_Runners_Array_Type ;
                       Status       : in out Bet_Status_Type;
                       Bet_List     : in out Bets.Lists.List;
                       Back_1_At    : in Fixed_Type;
                       Back_2_At    : in Fixed_Type) is
    pragma Unreferenced(List);
    Bet : Bets.Bet_Type;
    use type Price_Histories.Price_History_Type;
    Runner : Runners.Runner_Type;
    Name : Betname_Type := (others => ' ');
  begin
    case Status is
      when No_Bet_Laid =>
        -- check for bet already laid for this runner on this market
        for B of Bet_List loop
          if B.Selectionid = Bra(1).Selectionid and then
             B.Marketid    = Bra(1).Marketid and then
             B.Side(1..4)  = "BACK" then
               return ;
          end if;
        end loop;

        if Bra(1).Backprice <= Back_1_At and then
          Bra(2).Backprice >= Back_2_At and then
          Bra(2).Backprice < Fixed_Type(10_000.0) then  -- so it exists

          Runner.Selectionid := Bra(1).Selectionid;

          Move("WIN_BACK_" & F8_Image(Back_1_At) & "_" & F8_Image(Back_2_At), Name);
          Bet := Bets.Create(Name   => Name,
                             Side   => Back,
                             Size   => Back_Size,
                             Price  => Price_Type(Bra(1).Backprice),
                             Placed => Bra(1).Pricets,
                             Runner => Runner,
                             Market => Market);

          Status          := Bet_Laid;
          Bet_List.Append(Bet);
        end if;

      when Bet_Laid  =>
        for B of Bet_List loop
          if B.Selectionid = Bra(1).Selectionid then
            if Bra(1).Pricets     >  B.Betplaced + (0,0,0,1,0) then -- 1 second later at least, time for BF delay
              if Bra(1).Backprice >= B.Price and then -- Backbet so yes '>=' NOT '<='
                Bra(1).Layprice  > Fixed_Type(1.0) and then -- sanity
                Bra(1).Backprice >  Fixed_Type(1.0) and then -- sanity
                B.Status(1)  = 'U' then -- sanity
                  B.Status(1..20) := "MATCHED             "; --Matched
                  B.Pricematched :=  Bra(1).Backprice;
                  B.Check_Outcome;
                  B.Insert;
                  exit;
              end if;
            end if;
          end if;
        end loop;

    end case;
  end Treat_Back;
  --------------------------------------------------------------------------

  Best_Runners      : Best_Runners_Array_Type := (others => Price_Histories.Empty_Data);
  Old_Best_Runners      : Best_Runners_Array_Type := (others => Price_Histories.Empty_Data);
  Worst_Runner      : Price_Histories.Price_History_Type := Price_Histories.Empty_Data;

  procedure Sort_Array(List : in out Price_Histories.Lists.List ;
                       BRA  :    out Best_Runners_Array_Type;
                       WR   :    out Price_Histories.Price_History_Type ) is

    Price             : Price_Histories.Price_History_Type;
  begin
      -- ok find the runner with lowest backprice:
      Backprice_Sorter.Sort(List);

      Price.Backprice := 10_000.0;
      BRA := (others => Price);
      WR.Layprice := 10_000.0;

      declare
        Idx : Integer := 0;
      begin
        for Tmp of List loop
          if Tmp.Status(1..6) = "ACTIVE" and then
             Tmp.Backprice > Fixed_Type(1.0) and then
             Tmp.Layprice < Fixed_Type(1_000.0)  then
            Idx := Idx +1;
            exit when Idx > BRA'Last;
            BRA(Idx) := Tmp;
          end if;
        end loop;
      end ;

      for Tmp of List loop
        if Tmp.Status(1..6) = "ACTIVE" and then
           Tmp.Backprice > Fixed_Type(1.0) and then
           Tmp.Layprice < Fixed_Type(1_000.0) and then
           Tmp.Selectionid /= BRA(1).Selectionid and then
           Tmp.Selectionid /= BRA(2).Selectionid then

          WR := Tmp;
        end if;
      end loop;

     -- for i in BRA'range loop
     --   Log("Best_Runners(i)" & i'Img & " " & BRA(i).To_String);
     -- end loop;
     -- Log("Worst_Runner " & WR.To_String);

  end Sort_Array;
  ---------------------------------------------------------------

  Start_Date   : constant Calendar2.Time_Type := (2016,03,16,0,0,0,0);
  One_Day      : constant Calendar2.Interval_Type := (1,0,0,0,0);
  Current_Date : Calendar2.Time_Type := Start_Date;
  Stop_Date    : constant  Calendar2.Time_Type := (2018,03,01,0,0,0,0);
  T            : Sql.Transaction_Type;
  Cmd_Line         : Command_Line_Configuration;
  Sa_Logfilename   : aliased Gnat.Strings.String_Access;

begin
  Define_Switch
    (Cmd_Line,
     Sa_Logfilename'Access,
     Long_Switch => "--logfile=",
     Help        => "name of log file");

  Getopt (Cmd_Line);  -- process the command line

  if not Ev.Exists("BOT_NAME") then
    Ev.Set("BOT_NAME","lay_during_race3");
  end if;

  Logging.Open(Ev.Value("BOT_HOME") & "/log/" & Sa_Logfilename.all & ".log");
  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
  Log("main", "Connect Db");
  Sql.Connect
    (Host     => Ini.Get_Value("database_home", "host", ""),
     Port     => Ini.Get_Value("database_home", "port", 5432),
     Db_Name  => Ini.Get_Value("database_home", "name", ""),
     Login    => Ini.Get_Value("database_home", "username", ""),
     Password =>Ini.Get_Value("database_home", "password", ""));
  Log("main", "db Connected");


  loop
    T.Start;
    Sim.Fill_Data_Maps(Current_Date, Bot_Types.Horse);
    Log("start process");

    declare
      Cnt : Integer := 0;
    begin
      for Market of Sim.Market_With_Data_List loop
        Cnt := Cnt + 1;
     --   Log( F8_Image(Fixed_Type(Cnt)*100.0/ Fixed_Type(Sim.Market_Id_With_Data_List.Length)) & " %");
        Back_bet_Status := No_Bet_Laid;
        Lay_Bet_Status := No_Bet_Laid;
        -- list of timestamps in this market
        declare
          Timestamp_To_Prices_History_Map : Sim.Timestamp_To_Prices_History_Maps.Map :=
                        Sim.Marketid_Timestamp_To_Prices_History_Map(Market.Marketid);

          Back_1_At , Back_2_At: Fixed_Type  ;
        begin
          Loop_Ts : for Timestamp of Sim.Marketid_Pricets_Map(Market.Marketid) loop
            Back_1_At := 1.26;
            Loop_1 : loop
              Back_1_At := Back_1_At - 0.01;
              Back_2_At := 11.0;

              Loop_2 : loop
                Back_2_At := Back_2_At - 1.0;
                declare
                  List : Price_Histories.Lists.List := Timestamp_To_Prices_History_Map(Timestamp.To_String);
                begin
                  --Best_Runners := (others => Price_Histories.Empty_Data);
                  --Worst_Runner := Price_Histories.Empty_Data;
                  Log("in loop", Timestamp.To_String & "_" & F8_Image(Back_1_At) & "_" & F8_Image(Back_2_At));

                  Sort_Array(List => List,
                             Bra  => Best_Runners,
                             Wr   => Worst_Runner);

                  Treat_Back(List          => List,
                             Market        => Market,
                             Bra           => Best_Runners,
                             Status        => Back_Bet_Status,
                             Bet_List      => Global_Bet_List,
                             Back_1_At     => Back_1_At,
                             Back_2_At     => Back_1_At);

                    Treat_Lay(List          => List,
                              Market        => Market,
                              Bra           => Best_Runners,
                              Old_bra       => Old_best_Runners,
                              Wr            => Worst_Runner,
                              Status        => Lay_Bet_Status,
                              Bet_List      => Global_Bet_List);
                    Old_Best_Runners := Best_Runners;

                end;
                exit Loop_Ts when Lay_Bet_Status = Bet_Laid and then Back_Bet_Status = Bet_Laid;
                exit Loop_2 when Back_2_At = 1.0;
              end loop loop_2;
              exit Loop_1 when Back_1_At = 1.0;
            end loop loop_1;

          end loop loop_Ts; --  Timestamp
        end;
      end loop;  -- marketid
    end;

    Log("num bets laid" & Global_Bet_List.Length'Img);

    for Bet of Global_Bet_List loop
      Bet.Insert;
    end loop;

    Current_Date := Current_Date + One_Day;
    exit when Current_Date = Stop_Date;

    Global_Bet_List.Clear;
    T.Commit;
  end loop;

  Sql.Close_Session;    -- no need for db anymore

exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Lay_During_Race3;
