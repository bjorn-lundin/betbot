with Ada.Environment_Variables;
with Ada.Directories;
with Ada.Streams.Stream_IO;
with Logging; use Logging;
with Stacktrace;
with Bot_System_Number;
with Calendar2; use Calendar2;
with Utils; use Utils;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Bot_Svn_Info;
with Text_Io;
with Sql;

package body Sim is

  package EV renames Ada.Environment_Variables;
  package AD renames Ada.Directories;

  Select_Prices_In_One_Market,
  Select_Race_Winner_In_One_Market,
  Select_Pricets_In_A_Market,
  Select_All_Win_Markets,
  Select_Pricets_For_Market : Sql.Statement_Type;

  Select_All_Markets_Horse : Sql.Statement_Type;
  Select_All_Markets_Hound : Sql.Statement_Type;

  Select_Get_Win_Market : Sql.Statement_Type;
  Select_Get_Place_Market : Sql.Statement_Type;

  Current_Market : Markets.Market_Type := Markets.Empty_Data;
  Global_Price_During_Race_List : Price_Histories.Lists.List;

  Global_Current_Pricets: Calendar2.Time_Type := Calendar2.Time_Type_First ;
  package Pricets_List_Pack is new Ada.Containers.Doubly_Linked_Lists(Calendar2.Time_Type);
  Pricets_List : Pricets_List_Pack.List;

  Object : constant String := "Sim.";
  Min_Num_Samples : constant Ada.Containers.Count_Type := 50;

  use type Ada.Containers.Count_Type;

  Select_Sampleids_In_One_Market : Sql.Statement_Type;
  Select_Sampleids_In_One_Market_2 : Sql.Statement_Type;

  ----------------------------------------------------------

  function Is_Race_Winner(Runner               : Runners.Runner_Type;
                          Marketid             : Marketid_Type)
         return Boolean is
  begin
    return Is_Race_Winner(Runner.Selectionid, Marketid);
  end Is_Race_Winner;

  function Is_Race_Winner(Selectionid          : Integer_4;
                          Marketid             : Marketid_Type)
         return Boolean is
    Service : constant String := "Is_Race_Winner";
  begin
     Log("Is_Race_Winner" & Selectionid'Img & " " & Marketid );

    -- Marketid_Winner_Map.Element((Marketid)) is a list of winning Arunners
     for R of Winners_Map.Element(Marketid) loop
       if Selectionid = R.Selectionid then
         return True;
       end if;
     end loop;
     return False;
  exception
    when Constraint_Error =>
      Log(Object & Service, "Key not in map '" & Marketid & "'");
      return False;
  end Is_Race_Winner;

  ----------------------------------------------------------
  procedure Get_Market_Prices(Market_Id  : in     Marketid_Type;
                              Market     : in out Markets.Market_Type;
                              Animal     : in     Animal_Type;
                              Price_List : in out Prices.Lists.List;
                              In_Play    :    out Boolean) is
    Service : constant String := "Get_Market_Prices";
    --Eos : Boolean := False;
    use type Markets.Market_Type;
    --Price_During_Race_Data : Price_Histories.Price_History_Type;
    Price_Data : Prices.Price_Type;
   -- T : Sql.Transaction_Type;
    Start,
    Stop,
    Ts : Calendar2.Time_Type := Calendar2.Time_Type_First ;
  begin
   -- Log(Object & Service, "start");
    In_Play := True;
    -- Log(Object & Service, "Marketid '" & Market_Id & "' Current_Market = Table_Amarkets.Empty_Data " & Boolean'image(Current_Market = Table_Amarkets.Empty_Data));
    -- trigg for a new market
    if Current_Market = Markets.Empty_Data then
       --reset the fifo for ny race
      Log(Object & Service, "clear Fifo");
      for i in Num_Runners_Type loop
        Fifo(i).Clear;
      end loop;
      Global_Current_Pricets := Calendar2.Time_Type_First ;
      Pricets_List.Clear;
      Global_Price_During_Race_List.Clear;
      Log(Object & Service, "set Current_Market");
      Current_Market := Market;
      Log(Object & Service, "start Read_Marketid '" & Market_Id & "'");
      Sim.Read_Marketid(Marketid => Market_Id, Animal => Animal, List => Global_Price_During_Race_List) ;
      Log(Object & Service, "done Read_Marketid '" & Market_Id & "' len" & Global_Price_During_Race_List.Length'Img);
      -- get a list of unique ts in the race in order
      for Item of Global_Price_During_Race_List loop
        if Item.Pricets /= Ts then
          Pricets_List.Append(Item.Pricets);
          Ts := Item.Pricets;
          --set first value for next loop in else below
          if Global_Current_Pricets = Calendar2.Time_Type_First then
            Global_Current_Pricets := Item.Pricets ; -- start of this race
            Start := Item.Pricets;
          end if;
        end if;
        Stop := Item.Pricets;
      end loop;
      Log(Object & Service, "len Pricets_List" & Pricets_List.Length'Img & "start/stop " & Start.To_String & "/" & Stop.To_String);
    else
      if not Pricets_List.Is_Empty then
        Global_Current_Pricets := Pricets_List.First_Element;
        Pricets_List.Delete_First;
      else
        Move("CLOSED",Market.Status);
        Log(Object & Service, "reset Current_Market");
        Current_Market := Markets.Empty_Data;
       -- Log(Object & Service, "stop 1");
        return;
      end if;
    end if;

    -- optimization :
    -- 1 remove used entries
    -- 2 exit when done

    declare
      Have_Been_Inside : Boolean := False;
    begin
      for Race_Data of Global_Price_During_Race_List loop
       -- Log(Object & Service, "testing for Price_Data " & Global_Current_Pricets.To_String & "---" & Race_Data.To_String );
        if Race_Data.Pricets = Global_Current_Pricets then
          Have_Been_Inside := True;
          Price_Data := (
             Marketid     => Race_Data.Marketid,
             Selectionid  => Race_Data.Selectionid,
             Pricets      => Race_Data.Pricets,
             Status       => Race_Data.Status,
             Totalmatched => Race_Data.Totalmatched,
             Backprice    => Race_Data.Backprice,
             Layprice     => Race_Data.Layprice,
             Ixxlupd      => Race_Data.Ixxlupd,
             Ixxluts      => Race_Data.Ixxluts
          );
          Price_List.Append(Price_Data);
          --Log(Object & Service, "appended Price_Data " & Price_Data.To_String);

        elsif Have_Been_Inside then
          exit;
        end if;
      end loop;
    end;
    Move("OPEN",Market.Status);

  --  Log(Object & Service, "stop 2");

  end Get_Market_Prices;

  ----------------------------------------------------------------------
  procedure Place_Bet (Bet_Name         : in     Betname_Type;
                       Market_Id        : in     Marketid_Type;
                       Side             : in     Bet_Side_Type;
                       Runner_Name      : in     Runnername_Type;
                       Selection_Id     : in     Integer_4;
                       Size             : in     Bet_Size_Type;
                       Price            : in     Bet_Price_Type;
                       Bet_Persistence  : in     Bet_Persistence_Type;
                       Bet_Placed       : in     Calendar2.Time_Type := Calendar2.Time_Type_First;
                       Bet              :    out Bets.Bet_Type) is
    pragma Unreferenced(Bet_Persistence);

    Execution_Report_Status        : String (1..50)  :=  (others => ' ') ;
    Execution_Report_Error_Code    : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Status      : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Error_Code  : String (1..50)  :=  (others => ' ') ;
    Order_Status                   : String (1..50)  :=  (others => ' ') ;

    Bet_Id : Integer_8 := 0;
    Now : Calendar2.Time_Type := Calendar2.Clock;
    Side_String   : Bet_Side_String_Type := (others => ' ');
    Market : Markets.Market_Type;
    Eos : Boolean := False;
    Local_Bet_Placed  :  Calendar2.Time_Type := Bet_Placed;
  begin
    if Local_Bet_Placed = Calendar2.Time_Type_First then
      Local_Bet_Placed := Now;
    end if;

    Move(Side'Img, Side_String);
    Market.Marketid := Market_Id;
    Market.Read(Eos);
    Bet_Id := Integer_8(Bot_System_Number.New_Number(Bot_System_Number.Betid));
    Move( "EXECUTION_COMPLETE", Order_Status);
    Move( "SUCCESS", Execution_Report_Status);
    Move( "SUCCESS", Execution_Report_Error_Code);
    Move( "SUCCESS", Instruction_Report_Status);
    Move( "SUCCESS", Instruction_Report_Error_Code);

    Bet := (
      Betid          => Bet_Id,
      Marketid       => Market_Id,
      Betmode        => Bot_Mode(Simulation),
      Powerdays      => 0,
      Selectionid    => Selection_Id,
      Reference      => (others => '-'),
      Size           => Float_8(Size),
      Price          => Float_8(Price),
      Side           => Side_String,
      Betname        => Bet_Name,
      Betwon         => False,
      Profit         => 0.0,
      Status         => Order_Status, -- ??
      Exestatus      => Execution_Report_Status,
      Exeerrcode     => Execution_Report_Error_Code,
      Inststatus     => Instruction_Report_Status,
      Insterrcode    => Instruction_Report_Error_Code,
      Startts        => Market.Startts,
      Betplaced      => Local_Bet_Placed,
      Pricematched   => Float_8(Price),
      Sizematched    => Float_8(Size),
      Runnername     => Runner_Name,
      Fullmarketname => Market.Marketname,
      Svnrevision    => Bot_Svn_Info.Revision,
      Ixxlupd        => (others => ' '), --set by insert
      Ixxluts        => Now              --set by insert
    );
  end Place_Bet;
  -----------------------------------------------------------------------

  procedure Filter_List(Price_List, Avg_Price_List : in out Prices.Lists.List; Alg : Algorithm_Type := None)  is
  begin
    case Alg is
      when None =>
        Avg_Price_List := Price_List.Copy;
        return;
      when Avg =>
        --Log ("Filter_List : start Price_List.Length" & Price_List.Length'Img);
        for s of Price_List loop
        -- find my index in the array
          Num_Run: for i in Num_Runners_Type'range loop

            if S.Selectionid = Fifo(i).Selectionid then
              -- insert elements at bottom and remove from top
              -- check if list needs trim
              loop
                exit when Fifo(i).One_Runner_Sample_List.Length <= Min_Num_Samples;
                Fifo(i).One_Runner_Sample_List.Delete_First;
              end loop;
              -- append the new value
              Fifo(i).One_Runner_Sample_List.Append(s);

              if Fifo(i).One_Runner_Sample_List.Length >= Min_Num_Samples then
              -- recalculate the avg values
                declare
                  Backprice,Layprice : Float_8 := 0.0;
                  Sample : Prices.Price_Type;
                  Cnt : Natural := 0;
                begin
                  for s2 of Fifo(i).One_Runner_Sample_List loop
                    Backprice := Backprice + S2.Backprice;
                    Layprice := Layprice + S2.Layprice;
                    Sample := S2; -- save some data
                    Cnt := Cnt +1 ;
                  --  Log ("Filter_List Cnt : " & Cnt'Img & Sample.To_String );
                  end loop;
                  Sample.Backprice := Backprice / Float_8(Fifo(i).One_Runner_Sample_List.Length);
                  Sample.Layprice := Layprice / Float_8(Fifo(i).One_Runner_Sample_List.Length);
                  Avg_Price_List.Append(Sample);
                 -- Log ("Filter_List : avg " & Sample.To_String );
                end;
              end if;
              exit Num_Run;
            end if;
          end loop Num_Run;
        end loop;
      end case;
   -- Log ("Filter_List : done" );
  end Filter_List;
  -------------------------------

  procedure Clear(F : in out Fifo_Type) is
  begin
    F.Selectionid    := 0;
    F.Avg_Lay_Price  := 0.0;
    F.Avg_Back_Price := 0.0;
    F.In_Use         := False;
    F.Index          := Num_Runners_Type'first;
    F.One_Runner_Sample_List.Clear;
  end Clear;


  procedure Read_Marketid (Marketid : in Marketid_Type;
                           Animal   : in Animal_Type;
                           List     : out Price_Histories.Lists.List) is
  --  Service : constant String := "Read_Marketid";
    Prices_History_Data : Price_Histories.Price_History_Type;
    Filename : String := "markets/" & "win_" & Marketid & ".dat";
    T : Sql.Transaction_Type;
    Eos : Boolean := False;
    package Serializer is new Disk_Serializer(Price_Histories.Lists.List,Animal);
  begin

    if not Serializer.File_Exists(Filename) then
    --  Log(Object & Service, "Filename '" & Filename & "' does NOT exist. Read from DB and create");
      T.Start;
      Select_Sampleids_In_One_Market.Prepare(
        "select * " &
        "from APRICESHISTORY " &
        "where MARKETID = :MARKETID " &
        "order by PRICETS" ) ;

      Select_Sampleids_In_One_Market.Set("MARKETID", Marketid);
      Select_Sampleids_In_One_Market.Open_Cursor;
      loop
        Select_Sampleids_In_One_Market.Fetch(Eos);
        exit when Eos;
        Prices_History_Data := Price_Histories.Get(Select_Sampleids_In_One_Market);
        List.Append(Prices_History_Data);
      end loop;
      Select_Sampleids_In_One_Market.Close_Cursor;
      T.Commit;

      Serializer.Write_To_Disk(List, Filename);
    else
      Serializer.Read_From_Disk(List, Filename);
    end if;

  end Read_Marketid;
  -------------------------------------------------------------------------


  procedure Read_Marketid_Selectionid(Marketid    : in     Marketid_Type;
                                      Selectionid : in     Integer_4;
                                      Animal     : in     Animal_Type;
                                      List        :    out Price_Histories.Lists.List) is
  --  Service : constant String := "Read_Marketid";
    Price_History_Data : Price_Histories.Price_History_Type;
    Filename : String := "markets_selid/" & "win_" & Marketid & "_" & Trim(Selectionid'Img) & ".dat";
    T : Sql.Transaction_Type;
    Eos : Boolean := False;
    package Serializer is new Disk_Serializer(Price_Histories.Lists.List,Animal);
  begin

    if not Serializer.File_Exists(Filename) then
    --  Log(Object & Service, "Filename '" & Filename & "' does NOT exist. Read from DB and create");
      T.Start;
      Select_Sampleids_In_One_Market_2.Prepare(
        "select * " &
        "from APRICESHISTORY " &
        "where MARKETID = :MARKETID " &
        "and SELECTIONID = :SELECTIONID " &
        "order by PRICETS" ) ;

      Select_Sampleids_In_One_Market_2.Set("MARKETID", Marketid);
      Select_Sampleids_In_One_Market_2.Set("SELECTIONID", Selectionid);

      Select_Sampleids_In_One_Market_2.Open_Cursor;
      loop
        Select_Sampleids_In_One_Market_2.Fetch(Eos);
        exit when Eos;
        Price_History_Data := Price_Histories.Get(Select_Sampleids_In_One_Market_2);
        List.Append(Price_History_Data);
      end loop;
      Select_Sampleids_In_One_Market_2.Close_Cursor;
      T.Commit;
      Serializer.Write_To_Disk(List, Filename);
    else
      Serializer.Read_From_Disk(List, Filename);
    end if;

  end Read_Marketid_Selectionid;
  -------------------------------------------------------------------------

  procedure Create_Runner_Data(Price_List : in Prices.Lists.List;
                               Alg        : in Algorithm_Type;
                               Is_Winner  : in Boolean;
                               Is_Place   : in Boolean ) is
    F : Text_Io.File_Type;
    Indicator : String(1..3) := (others => ' ');
    Placement : String(1..3) := (others => ' ');
  begin
    case Alg is
      when None => Indicator := "nor";
      when Avg  => Indicator := "avg";
    end case;
    -- many runners 1 value only

    if Is_Winner then
      Placement  := "win";
    elsif Is_Place then
      Placement  := "plc";
    else
      Placement  := "los";
    end if;

    for Runner of Price_List loop
      declare
        Filename : String := Skip_All_Blanks(Ev.Value("BOT_SCRIPT") & "/plot/race_price_runner_data/" &
                                                      Runner.Marketid & "_" &
                                                      Runner.Selectionid'Img & "_" &
                                                      Indicator & "_" &
                                                      Placement & ".dat");
      begin
        if not AD.Exists(Filename) then
          Text_Io.Create(F, Text_Io.Out_File,    Filename);
        else
          Text_Io.Open  (F, Text_Io.Append_File, Filename);
        end if;
        Text_IO.Put_Line(F, Runner.Pricets.To_String & " | " &
                            Runner.Marketid & " | " &
                            Runner.Selectionid'Img & " | " &
                            Trim(Runner.Status) & " | " &
                            F8_Image(Runner.Backprice) & " | " &
                            F8_Image(Runner.Layprice) );
        Text_Io.Close(F);
      end;
    end loop;
  end Create_Runner_Data;
  -----------------------------------------------------------------

  function Get_Win_Market(Place_Market_Id : Marketid_Type) return Markets.Market_Type is
    T             : Sql.Transaction_Type;
    Winner_Market : Markets.Market_Type;
    Eos           : Boolean := False;
  begin
    T.Start;
    Select_Get_Win_Market.Prepare(
      "select MW.* from AMARKETS MW, AMARKETS MP " &
      "where MW.EVENTID = MP.EVENTID " &
      "and MW.STARTTS = MP.STARTTS " &
      "and MP.MARKETID = :PLACEMARKETID " &
      "and MP.MARKETTYPE = 'PLACE' " &
      "and MW.MARKETTYPE = 'WIN' ");

    Select_Get_Win_Market.Set("PLACEMARKETID",Place_Market_Id);
    Select_Get_Win_Market.Open_Cursor;
    Select_Get_Win_Market.Fetch(Eos);
    if not Eos then
      Winner_Market := Markets.Get(Select_Get_Win_Market);
    end if;
    Select_Get_Win_Market.Close_Cursor;
    T.Commit;
    Log(Object & "Get_Win_Market", "plc= '" & Place_Market_Id & "' win = '" & Winner_Market.Marketid & "'");

    return Winner_Market;
  end Get_Win_Market;
  -----------------------------------------------------------------

  function Get_Place_Market(Winner_Market_Id : Marketid_Type) return Markets.Market_Type is
    T            : Sql.Transaction_Type;
    Place_Market : Markets.Market_Type;
    Eos          : Boolean := False;
  begin
    T.Start;
    Select_Get_Place_Market.Prepare(
      "select MW.* from AMARKETS MW, AMARKETS MP " &
      "where MW.EVENTID = MP.EVENTID " &
      "and MW.STARTTS = MP.STARTTS " &
      "and MW.MARKETID = :WINMARKETID " &
      "and MP.NUMWINNERS = 3 " &
      "and MP.MARKETTYPE = 'PLACE' " &
      "and MW.MARKETTYPE = 'WIN' ");

    Select_Get_Place_Market.Set("WINMARKETID",Winner_Market_Id);
    Select_Get_Place_Market.Open_Cursor;
    Select_Get_Place_Market.Fetch(Eos);
    if not Eos then
      Place_Market := Markets.Get(Select_Get_Place_Market);
    end if;
    Select_Get_Place_Market.Close_Cursor;
    T.Commit;
    --Log(Object & "Get_Place_Market", "plc= '" & Place_Market.Marketid & "' win = '" & Winner_Market_Id & "'");

    return Place_Market;
  end Get_Place_Market;
  -----------------------------------------------------------------

  procedure Create_Bet_Data(Bet : in Bets.Bet_Type) is
    F : Text_Io.File_Type;
    Indicator : String(1..3) := (others => ' ');
    Odds_Market : Markets.Market_Type ;
  begin
    case Bet.Betwon is
      when True  => Indicator := "won";
      when False => Indicator := "bad";
    end case;

    Log(Object & "Create_Bet_Data", Bet.To_String);
    Log(Object & "Create_Bet_Data", "odds= '" & Odds_Market.Marketid & "'");
    if Position(Bet.Betname, "PLC") > Integer(0) then
      Log(Object & "Create_Bet_Data", "was in PLC");
      Odds_Market := Get_Win_Market(Bet.Marketid);
    elsif Position(Bet.Betname, "WIN") > Integer(0) then
      Log(Object & "Create_Bet_Data", "was in WIN");
      Odds_Market.Marketid := Bet.Marketid;
    else
      Log(Object & "Create_Bet_Data", "was in neither WIN nor PLC");
      Odds_Market.Marketid := Bet.Marketid;
    end if;
    Log(Object & "Create_Bet_Data", "odds= '" & Odds_Market.Marketid & "'");

    declare
      Filename : String := Skip_All_Blanks(Ev.Value("BOT_SCRIPT") & "/plot/race_price_runner_data/" &
                                                    Odds_Market.Marketid & "_" &
                                                    Lower_Case(Bet.Betname) & "_" &
                                                    Indicator & ".dat");
    begin
      if not AD.Exists(Filename) then
        Text_Io.Create(F, Text_Io.Out_File,    Filename);
      else
        Text_Io.Open  (F, Text_Io.Out_File, Filename);
      end if;
      Text_IO.Put_Line(F, Bet.Betplaced.To_String & " | " &
                          Bet.Marketid & " | " &
                          Bet.Selectionid'Img & " | " &
                          Bet.Side & " | " &
                          F8_Image(Bet.Pricematched) & " | " &
                          F8_Image(Bet.Sizematched) & " | " &
                          F8_Image(50.0) );
      Text_Io.Close(F);
    end;


  end Create_Bet_Data;
  --------------------------------------------------------------------------------------------
-- start lay_during_race2
  -------------------------------------------------------------------------
  procedure Read_All_Markets(Date   : in     Calendar2.Time_Type;
                             Animal : in     Animal_Type;
                             List   :    out Markets_Pack.List) is
  --  Service  : constant String := "Read_All_Markets";
    T        : Sql.Transaction_Type;
    Eos,Eos2 : Boolean := False;
    Filename : String := Date.String_Date_ISO & "/all_market_ids.dat";
    Marketid : Marketid_Type := (others => ' ');
    package Serializer is new Disk_Serializer(Markets_Pack.List,Animal);
    Market : Markets.Market_Type;
  begin
    List.Clear;
    if not Serializer.File_Exists(Filename) then
      T.Start;
      case Animal is
        when Horse =>
          Select_All_Markets_Horse.Prepare (
            "select M.MARKETID,STARTTS " &
              "from APRICESHISTORY H, AMARKETS M " &
              "where true " &
              "and H.MARKETID = M.MARKETID " &
            --  "and M.MARKETTYPE in ('WIN') " &
              "and M.MARKETTYPE in ('PLACE', 'WIN') " &
              "and M.STARTTS::date = :DATE " &
              "group by M.STARTTS " &
              "order by M.STARTTS ");
          Select_All_Markets_Horse.Set ("DATE", Date.String_Date_ISO );
          Select_All_Markets_Horse.Open_Cursor;
          loop
            Select_All_Markets_Horse.Fetch (Eos);
            exit when Eos;
            Select_All_Markets_Horse.Get (1, Marketid);
            Market.Marketid := Marketid;
            Market.Read (Eos2); -- must exist, just read id
            List.Append (Market);
          end loop;
          Select_All_Markets_Horse.Close_Cursor;

        when Hound =>
          Select_All_Markets_Hound.Prepare (
            "select M.MARKETID " &
              "from AMARKETS M " &
              "where true " &
            --  "and M.MARKETTYPE in ('WIN') " &
              "and M.MARKETTYPE in ('PLACE', 'WIN') " &
              "and M.STARTTS::date = :DATE " &
              "order by M.STARTTS");
          Select_All_Markets_Hound.Set ("DATE", Date.String_Date_ISO );
          Select_All_Markets_Hound.Open_Cursor;
          loop
            Select_All_Markets_Hound.Fetch (Eos);
            exit when Eos;
            Select_All_Markets_Hound.Get (1, Marketid);
            Market.Marketid := Marketid;
            Market.Read (Eos2); -- must exist, just read id
            List.Append (Market);
          end loop;
          Select_All_Markets_Hound.Close_Cursor;
        when Human => null;
      end case;
      T.Commit;
      Serializer.Write_To_Disk(List, Filename);
      Log("wrote to disk");
    else
      Log("read from disk");
      Serializer.Read_From_Disk(List, Filename);
    end if;
  end Read_All_Markets;
  -------------------------------------------------------------------------

  procedure Fill_Marketid_Pricets_Map (Market_With_Data_List      : in     Markets_Pack.List;
                                       Date                       : in     Calendar2.Time_Type;
                                       Animal                     : in     Animal_Type;
                                       Marketid_Pricets_Map       :    out Marketid_Pricets_Maps.Map) is
    Eos          : Boolean := False;
    Pricets_List : Timestamp_Pack.List;
    Filename     : String := Date.String_Date_ISO & "/marketid_pricets_map.dat";
    Ts           : Calendar2.Time_Type := Calendar2.Time_Type_First;
    T : Sql.Transaction_Type;
    package Serializer is new Disk_Serializer(Marketid_Pricets_Maps.Map,Animal);
  begin
    Marketid_Pricets_Map.Clear;
    if not Serializer.File_Exists(Filename) then
      T.Start;
      Select_Pricets_In_A_Market.Prepare(
        "select distinct(PRICETS) " &
        "from APRICESHISTORY " &
        "where MARKETID = :MARKETID " &
        "and STATUS <> 'REMOVED' "  &
        "order by PRICETS"  ) ;
      for Market of Market_With_Data_List loop
        Select_Pricets_In_A_Market.Set("MARKETID", Market.Marketid) ;
        Select_Pricets_In_A_Market.Open_Cursor;
        Pricets_List.Clear;
        loop
          Select_Pricets_In_A_Market.Fetch(Eos);
          exit when Eos;
          Select_Pricets_In_A_Market.Get(1,Ts);
          Pricets_List.Append(Ts);
        end loop;
        Select_Pricets_In_A_Market.Close_Cursor;
        Marketid_Pricets_Map.Insert(Market.Marketid, Pricets_List);
      end loop;
      T.Commit;

      Serializer.Write_To_Disk(Marketid_Pricets_Map, Filename);
    else
      Serializer.Read_From_Disk(Marketid_Pricets_Map, Filename);
    end if;

  end Fill_Marketid_Pricets_Map;
  -------------------------------------------------------------
  -------------------------------------------------------------

--    procedure Fill_Winners_Map (Market_List : in     Markets.Lists.List;
--                                Animal      : in     Animal_Type;
--                                Winners_Map :    out Marketid_Winner_Maps.Map ) is
--      Eos             : Boolean := False;
--      Filename : String := "all_winners_map.dat";
--      Runner_Data : Runners.Runner_Type;
--      Runner_List : Runners.Lists.List;
--      T : Sql.Transaction_Type;
--      package Serializer is new Disk_Serializer(Marketid_Winner_Maps.Map, Animal);
--    begin
--      Winners_Map.Clear;
--      if not Serializer.File_Exists(Filename) then
--        T.Start;
--        Select_Race_Winner_In_One_Market.Prepare(
--          "select * " &
--          "from ARUNNERS " &
--          "where MARKETID = :MARKETID " &
--          "and STATUS = 'WINNER' ") ;
--        for Market of Market_List loop
--          Runner_List.Clear;
--          Select_Race_Winner_In_One_Market.Set("MARKETID", Market.Marketid) ;
--          Select_Race_Winner_In_One_Market.Open_Cursor;
--          loop
--            Select_Race_Winner_In_One_Market.Fetch(Eos);
--            exit when Eos;
--            Runner_Data := Runners.Get(Select_Race_Winner_In_One_Market);
--            Runner_List.Append(Runner_Data);
--          end loop;
--          Select_Race_Winner_In_One_Market.Close_Cursor;
--          Winners_Map.Insert(Market.Marketid, Runner_List);
--        end loop;
--        T.Commit;
--        Serializer.Write_To_Disk(Winners_Map, Filename);
--      else
--        Serializer.Read_From_Disk(Winners_Map, Filename);
--      end if;
--    end Fill_Winners_Map;

  -------------------------------------------------------------

  procedure Fill_Winners_Map (Market_With_Data_List    : in     Markets_Pack.List;
                              Date                     : in     Calendar2.Time_Type;
                              Animal                   : in     Animal_Type;
                              Winners_Map              :    out Marketid_Winner_Maps.Map ) is
    Eos             : Boolean := False;
    Filename : String := Date.String_Date_ISO & "/winners_map.dat";
    Runner_Data : Runners.Runner_Type;
    Runner_List : Runners.Lists.List;
    T : Sql.Transaction_Type;
    package Serializer is new Disk_Serializer(Marketid_Winner_Maps.Map, Animal);
  begin
    Winners_Map.Clear;
    if not Serializer.File_Exists(Filename) then
      T.Start;
      Select_Race_Winner_In_One_Market.Prepare(
        "select * " &
        "from ARUNNERS " &
        "where MARKETID = :MARKETID " &
        "and STATUS = 'WINNER' ") ;
      for Market of Market_With_Data_List loop
        Runner_List.Clear;
        Select_Race_Winner_In_One_Market.Set("MARKETID", Market.Marketid) ;
        Select_Race_Winner_In_One_Market.Open_Cursor;
        loop
          Select_Race_Winner_In_One_Market.Fetch(Eos);
          exit when Eos;
          Runner_Data := Runners.Get(Select_Race_Winner_In_One_Market);
          Runner_List.Append(Runner_Data);
        end loop;
        Select_Race_Winner_In_One_Market.Close_Cursor;
        Winners_Map.Insert(Market.Marketid, Runner_List);
      end loop;
      T.Commit;

      Serializer.Write_To_Disk(Winners_Map, Filename);
    else
      Serializer.Read_From_Disk(Winners_Map, Filename);
    end if;
  end Fill_Winners_Map;

  -------------------------------------------------------------

  procedure Fill_Prices_Map (Market_With_Data_List    : in     Markets_Pack.List;
                             Date                     : in     Calendar2.Time_Type;
                             Animal                   : in     Animal_Type;
                             Prices_Map               :    out Marketid_Prices_Maps.Map ) is
    Eos             : Boolean := False;
    Filename : String := Date.String_Date_ISO & "/prices_map.dat";
    Price_Data : Prices.Price_Type;
    Price_List : Prices.Lists.List;
    T : Sql.Transaction_Type;
    package Serializer is new Disk_Serializer (Marketid_Prices_Maps.Map, Animal);
  begin
    Prices_Map.Clear;
    if not Serializer.File_Exists(Filename) then
      T.Start;
      Select_Prices_In_One_Market.Prepare(
        "select * " &
        "from APRICES " &
        "where MARKETID = :MARKETID " &
        "order by SELECTIONID") ;
      for Market of Market_With_Data_List loop
        Price_List.Clear;
        Select_Prices_In_One_Market.Set("MARKETID", Market.Marketid) ;
        Select_Prices_In_One_Market.Open_Cursor;
        loop
          Select_Prices_In_One_Market.Fetch(Eos);
          exit when Eos;
          Price_Data := Prices.Get(Select_Prices_In_One_Market);
          Price_List.Append(Price_Data);
        end loop;
        Select_Prices_In_One_Market.Close_Cursor;
        Prices_Map.Insert(Market.Marketid, Price_List);
      end loop;
      T.Commit;

      Serializer.Write_To_Disk(Prices_Map, Filename);
    else
      Serializer.Read_From_Disk(Prices_Map, Filename);
    end if;
  end Fill_Prices_Map;
  -----------------------------------------

  procedure Fill_Marketid_Runners_Pricets_Map (
                                               Market_With_Data_List                    : in     Markets_Pack.List;
                                               Marketid_Pricets_Map                     : in     Marketid_Pricets_Maps.Map;
                                               Date                                     : in     Calendar2.Time_Type;
                                               Animal                                   : in     Animal_Type;
                                               Marketid_Timestamp_To_Apriceshistory_Map :    out Marketid_Timestamp_To_Prices_History_Maps.Map) is
    Eos       : Boolean := False;
    Apriceshistory_List    : Price_Histories.Lists.List;
    Price_History_Data    : Price_Histories.Price_History_Type;
    T : Sql.Transaction_Type;
    Cnt             : Integer := 0;
    Timestamp_To_Apriceshistory_Map : Timestamp_To_Prices_History_Maps.Map;
    Filename : String := Date.String_Date_ISO & "/marketid_timestamp_to_apriceshistory_map.dat";
    package Serializer is new Disk_Serializer(Marketid_Timestamp_To_Prices_History_Maps.Map, Animal);
  begin
    Marketid_Timestamp_To_Apriceshistory_Map.Clear;
    if not Serializer.File_Exists(Filename) then
      T.Start;
      Select_Pricets_For_Market.Prepare(
        "select * " &
        "from APRICESHISTORY " &
        "where MARKETID = :MARKETID " &
        "and PRICETS = :PRICETS " &
        "and STATUS <> 'REMOVED' "  &
        "order by SELECTIONID"  ) ;
      for Market of Market_With_Data_List loop
        Cnt := Cnt + 1;
        Log("marketid '" & Market.Marketid & "' " & Cnt'Img & "/" & Market_With_Data_List.Length'Img );
        --Marketid_Pricets_Maps(Marketid) is a list of pricets
        for Pricets of Marketid_Pricets_Map(Market.Marketid) loop
          -- do rest here with marketid and pricets
          Select_Pricets_For_Market.Set("MARKETID", Market.Marketid) ;
          Select_Pricets_For_Market.Set("PRICETS", Pricets) ;
          Select_Pricets_For_Market.Open_Cursor;
          loop
            Select_Pricets_For_Market.Fetch(Eos);
            exit when Eos;
            Price_History_Data := Price_Histories.Get(Select_Pricets_For_Market);
            Apriceshistory_List.Append(Price_History_Data);
          end loop;
          Select_Pricets_For_Market.Close_Cursor;
          --Log("Insert Market.Marketid & _ & Pricets.To_String '" & Market.Marketid & "_" & Pricets.To_String & "'");
          Timestamp_To_Apriceshistory_Map.Insert(Pricets.To_String, Apriceshistory_List);
          Apriceshistory_List.Clear;
        end loop;
        Marketid_Timestamp_To_Apriceshistory_Map.Insert(Market.Marketid, Timestamp_To_Apriceshistory_Map);
        Timestamp_To_Apriceshistory_Map.Clear;
      end loop;  -- Market_With_Data_List
      T.Commit;

      Serializer.Write_To_Disk(Marketid_Timestamp_To_Apriceshistory_Map, Filename);
    else
      Serializer.Read_From_Disk(Marketid_Timestamp_To_Apriceshistory_Map, Filename);
    end if;
  end Fill_Marketid_Runners_Pricets_Map;
  -------------------------------------------------------------------


  procedure Fill_Win_Place_Map (Date          : in     Calendar2.Time_Type;
                                Animal        : in     Animal_Type;
                                Win_Place_Map :    out Win_Place_Maps.Map) is
    T: Sql.Transaction_Type;
    Eos : Boolean := False;
    Place_Marketid,
    Win_Marketid    : Marketid_Type := (others => ' ');
    Filename : String := Date.String_Date_ISO & "/win_place_map.dat";
    package Serializer is new Disk_Serializer(Win_Place_Maps.Map, Animal);
  begin
    Win_Place_Map.Clear;
    if not Serializer.File_Exists(Filename) then
      T.Start;
      Select_All_Win_Markets.Prepare (
        "select distinct(M.MARKETID) " &
        "from APRICESHISTORY RP, AMARKETS M " &
        "where RP.MARKETID = M.MARKETID " &
        "and M.MARKETTYPE = 'WIN' " &
        "and STARTTS::date = :DATE " &
        "order by M.MARKETID");

      Select_All_Win_Markets.Set("DATE", Date.String_Date_ISO) ;
      Select_All_Win_Markets.Open_Cursor;
      loop
        Select_All_Win_Markets.Fetch(Eos);
        exit when Eos;
        Select_All_Win_Markets.Get(1,Win_Marketid);
        Place_Marketid := Get_Place_Market(Win_Marketid).Marketid;
        Win_Place_Map.Insert(Win_Marketid,Place_Marketid);
      end loop;
      Select_All_Win_Markets.Close_Cursor;
      T.Commit;
      Serializer.Write_To_Disk(Win_Place_Map, Filename);
    else
      Serializer.Read_From_Disk(Win_Place_Map, Filename);
    end if;

  end Fill_Win_Place_Map;
  -------------------------------------------------------------------

  package body Disk_Serializer is
    --------------------------------------------------------
    Ani : String := Lower_Case(Animal'Img);
    Path : String := Ev.Value("BOT_HISTORY") & "/data/streamed_objects/" & Ani & "/";
    --Path : String := "/mnt/samsung1gb/data/streamed_objects/";

    function File_Exists(Filename : String) return Boolean is
     -- Service : constant String := "File_Exists";
      File_On_Disk : String := Path & Filename;
      File_Exists  : Boolean := AD.Exists(File_On_Disk) ;
      Dir          : String := Ad.Containing_Directory(File_On_Disk);
      Dir_Exists   : Boolean := AD.Exists(Dir) ;
      use type AD.File_Size;
    begin
      if not Dir_Exists then
        Ad.Create_Directory(Dir);
      end if;
    --  Log(Object & Service, "Exists: " & Exists'Img);
      if File_Exists then
        File_Exists := AD.Size (File_On_Disk) > 5;
      end if;
      return File_Exists;
    end File_Exists;
    ---------------------------------------------------------------
    procedure Write_To_Disk (Container : in Data_Type; Filename : in String) is
      File   : Ada.Streams.Stream_IO.File_Type;
      Stream : Ada.Streams.Stream_IO.Stream_Access;
      File_On_Disk : String := Path & Filename;
    --  Service : constant String := "Write_To_Disk";
    begin
    --  Log(Object & Service, "write to file '" & Filename & "'");
      Ada.Streams.Stream_IO.Create
          (File => File,
           Name => File_On_Disk,
           Mode => Ada.Streams.Stream_IO.Out_File);
      Stream := Ada.Streams.Stream_IO.Stream (File);
      Data_Type'Write(Stream, Container);
      Ada.Streams.Stream_IO.Close(File);
    --  Log(Object & Service, "Stream written to file " & Filename);
    end Write_To_Disk;
    --------------------------------------------------------
    procedure Read_From_Disk (Container : in out Data_Type; Filename : in String) is
      File   : Ada.Streams.Stream_IO.File_Type;
      Stream : Ada.Streams.Stream_IO.Stream_Access;
      File_On_Disk : String := Path & Filename;
    --  Service : constant String := "Read_From_Disk";
    begin
     -- Log(Object & Service, "read from file '" & Filename & "'");
      Ada.Streams.Stream_IO.Open
          (File => File,
           Name => File_On_Disk,
           Mode => Ada.Streams.Stream_IO.In_File);
      Stream := Ada.Streams.Stream_IO.Stream (File);
      Data_Type'Read(Stream, Container);
      Ada.Streams.Stream_IO.Close(File);
    --  Log(Object & Service, "Stream read from file " & Filename);
    end Read_From_Disk;
    --------------------------------------------------------
  end Disk_Serializer;
  ----------------------------------------------------------

  procedure Fill_Data_Maps (Date   : in Calendar2.Time_Type;
                            Animal : in Animal_Type) is
  begin
    Log("fill maps with Date " & Date.String_Date_ISO & " for animal " &  Animal'Img);
    Log("fill list with all valid marketids" );
    Read_All_Markets(Date, Animal, Market_With_Data_List);
    Log("Found:" & Market_With_Data_List.Length'Img );

    Log("fill map with all pricets for a marketid ");
    Fill_Marketid_Pricets_Map(Market_With_Data_List, Date, Animal, Marketid_Pricets_Map);
    Log("Found:" & Marketid_Pricets_Map.Length'Img );

    Log("fill map with map of timestamp list for all marketids ");
    Fill_Marketid_Runners_Pricets_Map (Market_With_Data_List,
                                       Marketid_Pricets_Map,
                                       Date,
                                       Animal,
                                       Marketid_Timestamp_To_Prices_History_Map) ;
    Log("Found:" & Marketid_Timestamp_To_Prices_History_Map.Length'Img );

    Log("fill map winners ");
    Fill_Winners_Map(Market_With_Data_List, Date, Animal, Winners_Map );
    Log("Found:" & Winners_Map.Length'Img );

    Log("fill map Prices_Map ");
    Fill_Prices_Map(Market_With_Data_List, Date, Animal, Prices_Map );
    Log("Found:" & Prices_Map.Length'Img );

    Log("fill map Win/Place markets ");
    Fill_Win_Place_Map(Date, Animal, Win_Place_Map);
    Log("Found:" & Win_Place_Map.Length'Img );
  end Fill_Data_Maps;
  ------------------------------------------------------------------


  function Get_Place_Price(Win_Data : Price_Histories.Price_History_Type) return Price_Histories.Price_History_Type is
    Place_Marketid : Marketid_Type := (others => ' ');
  begin
    Place_Marketid := Win_Place_Map(Win_Data.Marketid);
    --Log("Get_Place_Price '" & Place_Marketid & "'");
    if Place_Marketid /= Marketid_Type'(others => ' ') then
      declare
        Timestamp_To_Apriceshistory_Map : Timestamp_To_Prices_History_Maps.Map :=
                      Marketid_Timestamp_To_Prices_History_Map(Place_Marketid);
      begin
        for Timestamp of Marketid_Pricets_Map(Place_Marketid) loop
          declare
            List : Price_Histories.Lists.List :=
                      Timestamp_To_Apriceshistory_Map(Timestamp.To_String);
          begin
            for Data of reverse List loop
              if Data.Selectionid = Win_Data.Selectionid and then
                 Data.Pricets <= Win_Data.Pricets then
                   return Data;
              end if;
            end loop;
          end;
        end loop;
      end;
    end if;
    return Price_Histories.Empty_Data;
  exception
    when E: Constraint_Error =>
      Stacktrace.Tracebackinfo(E);
      return Price_Histories.Empty_Data;
  end Get_Place_Price;

  ------------------------------------------------------------------
end Sim ;
