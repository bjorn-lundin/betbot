--with Ada.Strings; use Ada.Strings;
--with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Environment_Variables;

with Sim;
with Types ; use Types;
with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
--with Text_Io;
with Price_Histories; use Price_Histories;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Calendar2;  use Calendar2;
with Logging; use Logging;
with Markets;
with Bot_Svn_Info;
with Ini;
--with Ada.Text_IO;
--with Ada.Containers.Hashed_Maps;
--with Ada.Strings.Hash;
with Probabilities;


procedure Do_Stats_1 is
 -- use type Ada.Containers.Count_Type;

  package Ev renames Ada.Environment_Variables;

--    subtype Key is String(1..7);
--
--    package Odds_Maps is new Ada.Containers.Hashed_Maps
--      (Key,
--       Natural,
--       Ada.Strings.Hash,
--       "=",
--       "=");

  --------------------------------------------------------------------------

  function "<" (Left,Right : Price_Histories.Price_History_Type) return Boolean is
  begin
    return Left.Backprice < Right.Backprice;
  end "<";
  --------------------------------------------
  package Backprice_Sorter is new Price_Histories.Lists.Generic_Sorting("<");

  type Best_Runners_Array_Type is array (1..12) of Price_Histories.Price_History_Type;


  procedure Treat(Market           : in out Markets.Market_Type;
                  Bra              : in Best_Runners_Array_Type ;
                  Max_Leader_Price : in Price_Type;
                  Done             : out Boolean) is

    Probability : Probabilities.Probabilities_Type;
    Place_Marketid : Marketid_Type := (others => ' ');
    Placemarket_Exists : Boolean := False;
  begin
    Done := False;
    -- remove runners from local-BRA that already are betted on
    for I in Bra'Range loop
      if Fixed_Type(1.0) <  Bra(1).Backprice and then  -- sanity
         Max_Leader_Price <=  Bra(1).Backprice then
         Done := True;

        begin
          Place_Marketid :=  Sim.Win_Place_Map(Bra(1).Marketid);
          Placemarket_Exists := True;
        exception
          when others => Place_Marketid := "notexisting" ;
        end;

        declare
          Wonrace    : Boolean := False;
          Placedrace : Boolean := False;
        begin
          Wonrace := Sim.Is_Race_Winner(Selectionid => Bra(1).Selectionid, Marketid => Bra(1).Marketid);
          if Placemarket_Exists then
            Placedrace :=Sim.Is_Race_Winner(Selectionid => Bra(1).Selectionid, Marketid => Place_Marketid);
          end if;
          Probability := (Marketid     => Bra(1).Marketid,
                            Selectionid  => Bra(1).Selectionid,
                            R1           => Bra(1).Backprice,
                            R2           => Bra(2).Backprice,
                            R3           => Bra(3).Backprice,
                            R4           => Bra(4).Backprice,
                            Distance     => Market.Distance,
                            Distancename => Market.Distance_Name,
                            Wonrace      => Wonrace,
                            Placedrace   => Placedrace,
                            Svnrevision  => 0,
                            Ixxlupd      => (others => ' '),
                            Ixxluts      => Calendar2.Clock);
          Probability.Insert;
        end;
      end if;
    end loop;

  end Treat;
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
          Tmp.Layprice < Fixed_Type(1_000.0)  then
          Idx := Idx +1;
          exit when Idx > Bra'Last;
          Bra(Idx) := Tmp;
        end if;
      end loop;
    end ;

  end Sort_Array;
  -- pragma Unreferenced (Sort_Array);
  ---------------------------------------------------------------

  Start_Date          : constant Calendar2.Time_Type := (2016,03,16,0,0,0,0);
  One_Day             : constant Calendar2.Interval_Type := (1,0,0,0,0);
  Current_Date        :          Calendar2.Time_Type := Start_Date;
  Stop_Date           : constant Calendar2.Time_Type := (2018,08,01,0,0,0,0);
  T                   :          Sql.Transaction_Type;
  Cmd_Line            :          Command_Line_Configuration;
  Sa_Logfilename      : aliased  Gnat.Strings.String_Access;
  Sa_Max_Leader_Price : aliased  Gnat.Strings.String_Access;
  Max_Leader_Price    :          Price_Type := 0.0;

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

  Getopt (Cmd_Line);  -- process the command line

  if not Ev.Exists("BOT_NAME") then
    Ev.Set("BOT_NAME","lay_losers_1");
  end if;

  Logging.Open(Ev.Value("BOT_HOME") & "/log/" & Sa_Logfilename.all & ".log");
  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);
  Log("main", "params start");
  Log("main", "Sa_Max_Leader_Price" & Sa_Max_Leader_Price.all);
  Log("main", "params stop");

  Max_Leader_Price := Price_Type'Value(Sa_Max_Leader_Price.all);

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
        if Market.Markettype(1..3) = "WIN" and then
          Market.Marketname_Ok then

          Cnt := Cnt + 1;
          -- list of timestamps in this market
          declare
            Timestamp_To_Prices_History_Map : Sim.Timestamp_To_Prices_History_Maps.Map :=
                                                Sim.Marketid_Timestamp_To_Prices_History_Map(Market.Marketid);
            Done : Boolean := False;
          begin
            Loop_Ts : for Timestamp of Sim.Marketid_Pricets_Map(Market.Marketid) loop
              declare
                List     : Price_Histories.Lists.List := Timestamp_To_Prices_History_Map(Timestamp.To_String);
                Bra      : Best_Runners_Array_Type := (others => Price_Histories.Empty_Data);
              begin

                Sort_Array(List => List, Bra => Bra);
                Treat(Market           => Market,
                      Bra              => Bra,
                      Max_Leader_Price => Max_Leader_Price,
                      Done             => Done);

                exit Loop_Ts when Done;
              end;
            end loop Loop_Ts; --  Timestamp
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
end Do_Stats_1;
