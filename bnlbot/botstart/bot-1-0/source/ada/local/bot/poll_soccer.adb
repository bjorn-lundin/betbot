with Ada.Exceptions;
with Ada.Command_Line;
with Ada.Environment_Variables;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

with Stacktrace;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Sql;
with Calendar2; use Calendar2;
with Rpc;
with Lock ;
with Posix;
with Ini;
with Logging; use Logging;
with Process_IO;
with Core_Messages;
with Markets;
with Prices;
with Price_Histories;
with Bot_Svn_Info;
with Utils; use Utils;
with Bets;
with Runners;
with Tics;

procedure Poll_Soccer is
  package EV renames Ada.Environment_Variables;
  use type Rpc.Result_Type;

  Me              : constant String := "Poll_Market.";
  My_Lock         : Lock.Lock_Type;
  Msg             : Process_Io.Message_Type;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line        : Command_Line_Configuration;
  Now             : Calendar2.Time_Type;
  Ok              : Boolean := False;
  Select_Games_To_Lay_The_Draw,
  Select_Games_To_Back_Home,
  Select_Games_To_Back_Away,
  Select_Markets : Sql.Statement_Type;
  -------------------------------------------------------------
  procedure Back_The_Leader_Home(Market : Markets.Market_Type) is 
    Service     : constant String := "Back_The_Leader_Home";
    T           : Sql.Transaction_Type;
    Eos         : Boolean       := False;
    Selectionid : Integer_4     := 0;
    Betname     : Betname_Type  := (others => ' ');
    Runnername  : Runnername_Type  := (others => ' ');
    Size        : array(Bet_Side_Type'Range) of Bet_Size_Type  := (others => 30.0);
    Price       : array(Bet_Side_Type'Range) of Bet_Price_Type := (others =>  0.0);
    Price_8     : Float_8 := 0.0;
    Match_Directly : Integer_4 := 1;
    Bet         : array(Bet_Side_Type'Range) of Bets.Bet_Type;
    
  begin
    Move("BACK_LEADER_HOME_SOCCER",Betname);
    T.Start;
    Select_Games_To_Back_Home.Prepare(
    "select " &
      "e.eventid, " & 
      "e.eventname, " & 
      "e.countrycode, " & 
      "mmo3.marketid, " &
      "mmo3.markettype, " &
      "mmo3.totalmatched, " &
      "rmo1.selectionid homesel, " &
      "rmo1.runnername homename, " &
      "pmo1.backprice homeback, " &
      "pmo1.layprice homelay, " &
      "rmo3.selectionid drawsel, " &
      "rmo3.runnername drawname, " &
      "pmo3.backprice drawback, " &
      "pmo3.layprice drawlay," &
      "rmo2.selectionid awaysel, " &
      "rmo2.runnername awayname, " &
      "pmo2.backprice awayback, " &
      "pmo2.layprice awaydraw " &
    "from amarkets mmo3, " &  --market3 match_odds 
         "arunners rmo3, " &  --runner3 match odds
         "aprices pmo3, " &   --prices3 match odds
         "amarkets mmo2, " &  --market2 match_odds
         "arunners rmo2, " &  --runner2 match odds 
         "aprices pmo2, " &   --prices2 match odds
         "amarkets mmo1, " &  --market1 match_odds
         "arunners rmo1, " &  --runner1 match odds
         "aprices pmo1, " &   --prices1 match odds
         "aevents e " &       --events
    "where 1=1 " &
    "and mmo3.marketid = :MARKETID " &
    --enough money on game
    "and mmo3.totalmatched > 100000 " &
    "and mmo3.status = 'OPEN' " &
    "and mmo3.betdelay > 0 " & --in play
    -- the_draw
    "and e.eventid = mmo3.eventid " &
    "and pmo3.marketid = mmo3.marketid " &
    "and rmo3.marketid = pmo3.marketid " &
    "and rmo3.selectionid = pmo3.selectionid " &
    "and mmo3.markettype = 'MATCH_ODDS' " &
    "and pmo3.selectionid = rmo3.selectionid " &
    "and rmo3.runnernamenum = '3' " &   -- the_draw 
    "and pmo3.backprice >= 4 " &   -- the_draw 
    -- away team
    "and e.eventid = mmo2.eventid " &
    "and pmo2.marketid = mmo2.marketid " &
    "and rmo2.marketid = pmo2.marketid " &
    "and rmo2.selectionid = pmo2.selectionid " &
    "and mmo2.markettype = 'MATCH_ODDS' " &
    "and pmo2.selectionid = rmo2.selectionid " &
    "and rmo2.runnernamenum = '2' " &   --away
    "and pmo2.backprice >= 10 " &  -- away underdogs
    -- home team
    "and e.eventid = mmo1.eventid " &
    "and pmo1.marketid = mmo1.marketid " &
    "and rmo1.marketid = pmo1.marketid " &
    "and rmo1.selectionid = pmo1.selectionid " &
    "and mmo1.markettype = 'MATCH_ODDS' " &
    "and pmo1.selectionid = rmo1.selectionid " &
    "and rmo1.runnernamenum = '1' " &   --home
    "and pmo1.backprice <= 1.35 " &   -- home favs
    "and pmo1.backprice >= 1.06 " &   -- so we can subtract 0.05 and stil be on legal odds   
    "and abs(pmo1.layprice - pmo1.backprice) <= 0.02  " &-- say 1.10/1.12
    ---- no previous UNMATCHED bets on MATCH_ODDS
    "and not exists ( " &
           "select 'x' from abets " &
           "where abets.marketid = mmo1.marketid " &
           "and abets.sizematched < abets.size " & -- not fully matched
           "and abets.betname = 'BACK_LEADER_HOME_SOCCER') " &
    "order by mmo1.startts, e.eventname");

    Select_Games_To_Back_Home.Set("MARKETID",Market.Marketid);
    Select_Games_To_Back_Home.Open_Cursor;
    Select_Games_To_Back_Home.Fetch(Eos);
    if not Eos then
      Select_Games_To_Back_Home.Get("homesel",Selectionid);
      Select_Games_To_Back_Home.Get("homename",Runnername);
      Select_Games_To_Back_Home.Get("homeback",Price_8);
      Price(Back) := Bet_Price_Type(Price_8);
      
      Log(Me & "Place_Bet", "call Rpc.Place_Bet (Back)");
      Rpc.Place_Bet (Bet_Name         => Betname,
                     Market_Id        => Market.Marketid,
                     Side             => Back,
                     Runner_Name      => Runnername,
                     Selection_Id     => Selectionid,
                     Size             => Size(Back),
                     Price            => Price(Back),
                     Bet_Persistence  => Persist,
                     Match_Directly   => Match_Directly,
                     Bet              => Bet(Back));
                     
      if Bet(Back).Exestatus(1..7)= "FAILURE" then
        Log(Me & "Place_Bet", "FAILURE, wait for next turn");
        Log(Me & "Place_Bet", Bet(Back).To_String);
        T.Commit;
        return;
      end if;
                     
      declare
        Runner : Runners.Runner_Type;
        Eos2 : Boolean := False;
      begin   
        Runner.Marketid := Market.Marketid;
        Runner.Selectionid := Selectionid;
        Runner.Read(Eos2);      
        Bet(Back).Startts       := Market.Startts;
        Bet(Back).Fullmarketname:= Market.Marketname;
        Bet(Back).Runnername    := Runner.Runnername;
      end;
      
      Bet(Back).Insert;
      Bet(Back).Nullify_Betwon;

      Log(Me & "Place_Bet", Utils.Trim(Betname) & " inserted back bet: " & Bet(Back).To_String);
      
      if Integer(Bet(Back).Sizematched) = 0 then
        Log(Me & Service, "try to cancel bet, since not matched, sizematched = 0");
        declare
          Cancel_Succeeded : Boolean := False;
        begin
          Cancel_Succeeded := Rpc.Cancel_Bet(Bet => Bet(Back));
          Log(Me & Service, "Cancel bet" & Bet(Back).Betid'Img & " succeeded: " & Cancel_Succeeded'Img);
          if Cancel_Succeeded then
            Move("CANCELLED", Bet(Back).Status);
            Bet(Back).Update_Withcheck;
          end if;
        end;
      else
      --Backsize * Backprice = Laysize * Layprice
      --Laysize = Backsize * Backprice/Layprice
        Price(Lay):= Price(Back) - Bet_Price_Type(0.05);
        --check price is valid - put it back and forth through tics
        declare 
          Tic : Integer := Tics.Get_Nearest_Higher_Tic_Index(Float_8(Price(Lay)));
        begin
          Price(Lay) := Bet_Price_Type(Tics.Get_Tic_Price(Tic));
        end;  
        
        Size(Lay) := Size(Back) * Price(Back) / Price(Lay);
      
        Log(Me & "Place_Bet", "call Rpc.Place_Bet (Lay)");
        Rpc.Place_Bet (Bet_Name         => Betname,
                       Market_Id        => Market.Marketid,
                       Side             => Lay,
                       Runner_Name      => Runnername,
                       Selection_Id     => Selectionid,
                       Size             => Size(Lay),
                       Price            => Price(Lay),
                       Bet_Persistence  => Persist,
                       Match_Directly   => Match_Directly,
                       Bet              => Bet(Lay));
        declare
          Runner : Runners.Runner_Type;
          Eos2   : Boolean := False;
        begin   
          Runner.Marketid := Market.Marketid;
          Runner.Selectionid := Selectionid;
          Runner.Read(Eos2);      
          Bet(Lay).Startts       := Market.Startts;
          Bet(Lay).Fullmarketname:= Market.Marketname;
          Bet(Lay).Runnername    := Runner.Runnername;
        end;    
        
        Bet(Lay).Insert;
        Bet(Lay).Nullify_Betwon;
        Log(Me & "Place_Bet", Utils.Trim(Betname) & " inserted lay  bet: " & Bet(Lay).To_String);
      end if;
    end if;   
    Select_Games_To_Back_Home.Close_Cursor;
    T.Commit;
  end Back_The_Leader_Home;
  -------------------------------------------------------------
  procedure Back_The_Leader_Away(Market : Markets.Market_Type) is 
    Service     : constant String := "Back_The_Leader_Away";
    T           : Sql.Transaction_Type;
    Eos         : Boolean       := False;
    Selectionid : Integer_4     := 0;
    Betname     : Betname_Type  := (others => ' ');
    Runnername  : Runnername_Type  := (others => ' ');
    Size        : array(Bet_Side_Type'Range) of Bet_Size_Type  := (others => 30.0);
    Price       : array(Bet_Side_Type'Range) of Bet_Price_Type := (others =>  0.0);
    Price_8     : Float_8 := 0.0;
    Match_Directly : Integer_4 := 1;
    Bet         : array(Bet_Side_Type'Range) of Bets.Bet_Type;
    
  begin
    Move("BACK_LEADER_AWAY_SOCCER",Betname);
    T.Start;
    Select_Games_To_Back_Away.Prepare(
    "select " &
      "e.eventid, " & 
      "e.eventname, " & 
      "e.countrycode, " & 
      "mmo3.marketid, " &
      "mmo3.markettype, " &
      "mmo3.totalmatched, " &
      "rmo1.selectionid homesel, " &
      "rmo1.runnername homename, " &
      "pmo1.backprice homeback, " &
      "pmo1.layprice homelay, " &
      "rmo3.selectionid drawsel, " &
      "rmo3.runnername drawname, " &
      "pmo3.backprice drawback, " &
      "pmo3.layprice drawlay," &
      "rmo2.selectionid awaysel, " &
      "rmo2.runnername awayname, " &
      "pmo2.backprice awayback, " &
      "pmo2.layprice awaydraw " &
    "from amarkets mmo3, " &  --market3 match_odds 
         "arunners rmo3, " &  --runner3 match odds
         "aprices pmo3, " &   --prices3 match odds
         "amarkets mmo2, " &  --market2 match_odds
         "arunners rmo2, " &  --runner2 match odds 
         "aprices pmo2, " &   --prices2 match odds
         "amarkets mmo1, " &  --market1 match_odds
         "arunners rmo1, " &  --runner1 match odds
         "aprices pmo1, " &   --prices1 match odds
         "aevents e " &       --events
    "where 1=1 " &
    "and mmo3.marketid = :MARKETID " &
    --enough money on game
    "and mmo3.totalmatched > 100000 " &
    "and mmo3.status = 'OPEN' " &
    "and mmo3.betdelay > 0 " & --in play
    -- the_draw
    "and e.eventid = mmo3.eventid " &
    "and pmo3.marketid = mmo3.marketid " &
    "and rmo3.marketid = pmo3.marketid " &
    "and rmo3.selectionid = pmo3.selectionid " &
    "and mmo3.markettype = 'MATCH_ODDS' " &
    "and pmo3.selectionid = rmo3.selectionid " &
    "and rmo3.runnernamenum = '3' " &   -- the_draw 
    "and pmo3.backprice >= 4 " &   -- the_draw 
    -- away team
    "and e.eventid = mmo2.eventid " &
    "and pmo2.marketid = mmo2.marketid " &
    "and rmo2.marketid = pmo2.marketid " &
    "and rmo2.selectionid = pmo2.selectionid " &
    "and mmo2.markettype = 'MATCH_ODDS' " &
    "and pmo2.selectionid = rmo2.selectionid " &
    "and rmo2.runnernamenum = '2' " &   --away
    "and pmo2.backprice <= 1.35 " &  -- away leader
    "and pmo2.backprice >= 1.06 " &  -- away leader
    "and abs(pmo2.layprice - pmo2.backprice) <= 0.02  " &-- say 1.10/1.12
    -- home team
    "and e.eventid = mmo1.eventid " &
    "and pmo1.marketid = mmo1.marketid " &
    "and rmo1.marketid = pmo1.marketid " &
    "and rmo1.selectionid = pmo1.selectionid " &
    "and mmo1.markettype = 'MATCH_ODDS' " &
    "and pmo1.selectionid = rmo1.selectionid " &
    "and rmo1.runnernamenum = '1' " &   --home
    "and pmo1.backprice >= 10 " &   -- home losers
    ---- no previous UNMATCHED bets on MATCH_ODDS
    "and not exists ( " &
           "select 'x' from abets " &
           "where abets.marketid = mmo1.marketid " &
           "and abets.sizematched < abets.size " & -- not fully matched
           "and abets.betname = 'BACK_LEADER_AWAY_SOCCER') " &
    "order by mmo1.startts, e.eventname");

    Select_Games_To_Back_Away.Set("MARKETID",Market.Marketid);
    Select_Games_To_Back_Away.Open_Cursor;
    Select_Games_To_Back_Away.Fetch(Eos);
    if not Eos then
      Select_Games_To_Back_Away.Get("awaysel",Selectionid);
      Select_Games_To_Back_Away.Get("awayname",Runnername);
      Select_Games_To_Back_Away.Get("awayback",Price_8);
      Price(Back) := Bet_Price_Type(Price_8);
      
      Log(Me & "Place_Bet", "call Rpc.Place_Bet (Back)");
      Rpc.Place_Bet (Bet_Name         => Betname,
                     Market_Id        => Market.Marketid,
                     Side             => Back,
                     Runner_Name      => Runnername,
                     Selection_Id     => Selectionid,
                     Size             => Size(Back),
                     Price            => Price(Back),
                     Bet_Persistence  => Persist,
                     Match_Directly   => Match_Directly,
                     Bet              => Bet(Back));
                     
      if Bet(Back).Exestatus(1..7)= "FAILURE" then
        Log(Me & "Place_Bet", "FAILURE, wait for next turn");
        Log(Me & "Place_Bet", Bet(Back).To_String);
        T.Commit;
        return;
      end if;
                     
      declare
        Runner : Runners.Runner_Type;
        Eos2 : Boolean := False;
      begin   
        Runner.Marketid := Market.Marketid;
        Runner.Selectionid := Selectionid;
        Runner.Read(Eos2);      
        Bet(Back).Startts       := Market.Startts;
        Bet(Back).Fullmarketname:= Market.Marketname;
        Bet(Back).Runnername    := Runner.Runnername;
      end;
      
      Bet(Back).Insert;
      Bet(Back).Nullify_Betwon;

      Log(Me & "Place_Bet", Utils.Trim(Betname) & " inserted back bet: " & Bet(Back).To_String);
      
      if Integer(Bet(Back).Sizematched) = 0 then
        Log(Me & Service, "try to cancel bet, since not matched, sizematched = 0");
        declare
          Cancel_Succeeded : Boolean := False;
        begin
          Cancel_Succeeded := Rpc.Cancel_Bet(Bet => Bet(Back));
          Log(Me & Service, "Cancel bet" & Bet(Back).Betid'Img & " succeeded: " & Cancel_Succeeded'Img);
          if Cancel_Succeeded then
            Move("CANCELLED", Bet(Back).Status);
            Bet(Back).Update_Withcheck;
          end if;
        end;
      else
      --Backsize * Backprice = Laysize * Layprice
      --Laysize = Backsize * Backprice/Layprice
        Price(Lay):= Price(Back) - Bet_Price_Type(0.05);
        --check price is valid - put it back and forth through tics
        declare 
          Tic : Integer := Tics.Get_Nearest_Higher_Tic_Index(Float_8(Price(Lay)));
        begin
          Price(Lay) := Bet_Price_Type(Tics.Get_Tic_Price(Tic));
        end;  
        
        Size(Lay) := Size(Back) * Price(Back) / Price(Lay);
      
        Log(Me & "Place_Bet", "call Rpc.Place_Bet (Lay)");
        Rpc.Place_Bet (Bet_Name         => Betname,
                       Market_Id        => Market.Marketid,
                       Side             => Lay,
                       Runner_Name      => Runnername,
                       Selection_Id     => Selectionid,
                       Size             => Size(Lay),
                       Price            => Price(Lay),
                       Bet_Persistence  => Persist,
                       Match_Directly   => Match_Directly,
                       Bet              => Bet(Lay));
        declare
          Runner : Runners.Runner_Type;
          Eos2   : Boolean := False;
        begin   
          Runner.Marketid := Market.Marketid;
          Runner.Selectionid := Selectionid;
          Runner.Read(Eos2);      
          Bet(Lay).Startts       := Market.Startts;
          Bet(Lay).Fullmarketname:= Market.Marketname;
          Bet(Lay).Runnername    := Runner.Runnername;
        end;    
        
        Bet(Lay).Insert;
        Bet(Lay).Nullify_Betwon;
        Log(Me & "Place_Bet", Utils.Trim(Betname) & " inserted lay  bet: " & Bet(Lay).To_String);
      end if;
    end if;   
    Select_Games_To_Back_Away.Close_Cursor;
    T.Commit;
  end Back_The_Leader_Away;
  -------------------------------------------------------------
  procedure Lay_The_Draw(Market : Markets.Market_Type) is
    Service     : constant String := "Lay_The_Draw";
    T           : Sql.Transaction_Type;
    Eos         : Boolean       := False;
    Selectionid : Integer_4     := 0;
    Betname     : Betname_Type  := (others => ' ');
    Runnername  : Runnername_Type  := (others => ' ');
    Size        : array(Bet_Side_Type'Range) of Bet_Size_Type  := (others => 50.0);
    Price       : array(Bet_Side_Type'Range) of Bet_Price_Type := (others =>  0.0);
    Price_8     : Float_8 := 0.0;
    Match_Directly : Integer_4 := 1;
    Bet         : array(Bet_Side_Type'Range) of Bets.Bet_Type;
    
  begin
    Move("LAY_THE_DRAW",Betname);
    T.Start;
    Select_Games_To_Lay_The_Draw.Prepare(
      "select " &
        "e.eventid, " & 
        "e.eventname, " & 
        "e.countrycode, " & 
        "mcs.startts, " &
        "mcs.marketid, " &        
        "mcs.markettype, " &
        "pcs.backprice, " &
        "mmo3.marketid, " &
        "mmo3.markettype, " &
        "rmo1.runnername, " &
        "pmo1.backprice, " &
        "pmo1.layprice, " &
        "rmo3.selectionid drawsel, " &
        "rmo3.runnername drawname, " &
        "pmo3.backprice drawback, " &
        "pmo3.layprice drawlay, " &
        "rmo2.runnername, " &
        "pmo2.backprice, " &
        "pmo2.layprice " &
      "from aprices pcs, " & 
           "amarkets mcs, " &
           "amarkets mmo3, " & 
           "arunners rmo3, " & 
           "aprices pmo3, " & 
           "amarkets mmo2, " & 
           "arunners rmo2, " & 
           "aprices pmo2, " & 
           "amarkets mmo1, " & 
           "arunners rmo1, " & 
           "aprices pmo1, " & 
           "aevents e " &
      "where 1=1 " &
      "and mmo3.marketid = :MARKETID " &
      -- enough money on game
      "and mmo3.totalmatched > 100000 " &
      "and mmo3.status = 'OPEN' " &
      "and mmo3.betdelay = 0 " &  --not in play
      -- probability for goals
      "and pcs.marketid = mcs.marketid " &
      "and e.eventid = mcs.eventid " &
      "and mcs.markettype = 'CORRECT_SCORE' " &
      "and pcs.selectionid = 1 " & 
      "and pcs.backprice >= 15 " & -- 0-0
      "and pcs.backprice < 1000 " & -- 0-0
      -- the_draw
      "and e.eventid = mmo3.eventid " &
      "and pmo3.marketid = mmo3.marketid " &
      "and rmo3.marketid = pmo3.marketid " &
      "and rmo3.selectionid = pmo3.selectionid " &
      "and mmo3.markettype = 'MATCH_ODDS' " &
      "and pmo3.selectionid = rmo3.selectionid " &
      "and rmo3.runnernamenum = '3' " &   -- the_draw 
      "and pmo3.layprice <= 7 " &   -- the_draw 
      -- away team
      "and e.eventid = mmo2.eventid " &
      "and pmo2.marketid = mmo2.marketid " &
      "and rmo2.marketid = pmo2.marketid " &
      "and rmo2.selectionid = pmo2.selectionid " &
      "and mmo2.markettype = 'MATCH_ODDS' " &
      "and pmo2.selectionid = rmo2.selectionid " &
      "and rmo2.runnernamenum = '2' " &   --away
      "and pmo2.backprice >= 8 " &  -- away underdogs
      -- home team
      "and e.eventid = mmo1.eventid " &
      "and pmo1.marketid = mmo1.marketid " &
      "and rmo1.marketid = pmo1.marketid " &
      "and rmo1.selectionid = pmo1.selectionid " &
      "and mmo1.markettype = 'MATCH_ODDS' " &
   
      "and pmo1.selectionid = rmo1.selectionid " &
      "and rmo1.runnernamenum = '1' " &   --home
      "and pmo1.backprice <= 1.5 " &   -- home favs
      ---- no previous bets on CORRECT_SCORE nor on MATCH_ODDS
      "and not exists ( " & 
          "select 'x' from abets " &
          "where abets.marketid in (mcs.marketid,mmo1.marketid) " &
          "and abets.betname = 'LAY_THE_DRAW') " &
      "order by mcs.startts, e.eventname"
    );     

    Select_Games_To_Lay_The_Draw.Set("MARKETID",Market.Marketid);
    Select_Games_To_Lay_The_Draw.Open_Cursor;
    Select_Games_To_Lay_The_Draw.Fetch(Eos);
    if not Eos then
      Select_Games_To_Lay_The_Draw.Get("drawsel",Selectionid);
      Select_Games_To_Lay_The_Draw.Get("drawname",Runnername);
      Select_Games_To_Lay_The_Draw.Get("drawback",Price_8);
      Price(Back) := Bet_Price_Type(Price_8);
      Select_Games_To_Lay_The_Draw.Get("drawlay",Price_8);
      Price(Lay) := Bet_Price_Type(Price_8);
      
      Log(Me & "Place_Bet", "call Rpc.Place_Bet (lay)");
      Rpc.Place_Bet (Bet_Name         => Betname,
                     Market_Id        => Market.Marketid,
                     Side             => Lay,
                     Runner_Name      => Runnername,
                     Selection_Id     => Selectionid,
                     Size             => Size(Lay),
                     Price            => Price(Lay),
                     Bet_Persistence  => Persist,
                     Match_Directly   => Match_Directly,
                     Bet              => Bet(Lay));

      if Bet(Lay).Exestatus(1..7)= "FAILURE" then
        Log(Me & "Place_Bet", "FAILURE, wait for next turn");
        Log(Me & "Place_Bet", Bet(Lay).To_String);
        T.Commit;
        return;
      end if;

      declare
        Runner : Runners.Runner_Type;
        Eos2   : Boolean := False;
      begin   
        Runner.Marketid := Market.Marketid;
        Runner.Selectionid := Selectionid;
        Runner.Read(Eos2);      
        Bet(Lay).Startts       := Market.Startts;
        Bet(Lay).Fullmarketname:= Market.Marketname;
        Bet(Lay).Runnername    := Runner.Runnername;
      end;                       
                     
      Bet(Lay).Insert;
      Bet(Lay).Nullify_Betwon;
      Log(Me & "Place_Bet", Utils.Trim(Betname) & " inserted lay  bet: " & Bet(Lay).To_String);
      
      if Integer(Bet(Lay).Sizematched) = 0 then
        Log(Me & Service, "try to cancel bet, since not matched, sizematched = 0");
        declare
          Cancel_Succeeded : Boolean := False;
        begin
          Cancel_Succeeded := Rpc.Cancel_Bet(Bet => Bet(Lay));
          Log(Me & Service, "Cancel bet" & Bet(Lay).Betid'Img & " succeeded: " & Cancel_Succeeded'Img);
          if Cancel_Succeeded then
            Move("CANCELLED", Bet(Lay).Status);
            Bet(Lay).Update_Withcheck;
          end if;
        end;
      else
        --Backsize * Backprice = Laysize * Layprice
        --Laysize = Backsize * Backprice/Layprice
        Price(Back) := Price(Lay) * 1.5;
        
        --check price is valid - put it back and forth through tics
        declare 
          Tic : Integer := Tics.Get_Nearest_Higher_Tic_Index(Float_8(Price(Back)));
        begin
          Price(Back) := Bet_Price_Type(Tics.Get_Tic_Price(Tic));
        end;  
        
        Size(Back) := Size(Lay) * Price(Lay) / Price(Back);
        if Size(Back) < 30.0 then
          Size(Back) := 30.0;
        end if;          
        
        Log(Me & "Place_Bet", "call Rpc.Place_Bet (Back)");
        Rpc.Place_Bet (Bet_Name         => Betname,
                       Market_Id        => Market.Marketid,
                       Side             => Back,
                       Runner_Name      => Runnername,
                       Selection_Id     => Selectionid,
                       Size             => Size(Back),
                       Price            => Price(Back),
                       Bet_Persistence  => Persist,
                       Match_Directly   => Match_Directly,
                       Bet              => Bet(Back));                     
                       
        declare
          Runner : Runners.Runner_Type;
          Eos2   : Boolean := False;
        begin   
          Runner.Marketid := Market.Marketid;
          Runner.Selectionid := Selectionid;
          Runner.Read(Eos2);      
          Bet(Back).Startts       := Market.Startts;
          Bet(Back).Fullmarketname:= Market.Marketname;
          Bet(Back).Runnername    := Runner.Runnername;
        end;                      
      
        Bet(Back).Insert;
        Bet(Back).Nullify_Betwon;
        Log(Me & "Place_Bet", Utils.Trim(Betname) & " inserted Back bet: " & Bet(Back).To_String);
      end if;
    end if;   
    Select_Games_To_Lay_The_Draw.Close_Cursor;
    T.Commit;
  end Lay_The_Draw;
  -------------------------------------------------------
  -- (both lay and back)
  function All_Bets_In_Market_Are_Matched(Market : Markets.Market_Type) return Boolean is
    Bet_List : Bets.Lists.List;
    Bet : Bets.Bet_Type;
    T : Sql.Transaction_Type;
    All_Are_Matched : Boolean := True;
    Matched : Boolean := True;
  begin
    Bet.Marketid := Market.Marketid;
    Log("Check if all bets are matched in market " & Market.To_String);
    
    T.Start;
      Bets.Read_Marketid(Bet,Bet_List);    
      for B of Bet_List loop
        if B.Status(1..18) = "EXECUTION_COMPLETE" then 
          Log("Matched " & B.To_String);
        elsif B.Status(1..9) = "CANCELLED" then 
          Log("Cancelled " & B.To_String);
        else
          Matched := B.Is_Matched;
          Log("newly Matched" & Matched'Img & " " & B.To_String);
        end if;
        All_Are_Matched := All_Are_Matched and Matched;
      end loop;
    T.Commit;
    Log("All are matched " & All_Are_Matched'Img);
    return All_Are_Matched;
  exception
    when Sql.No_Such_Row =>
      T.Rollback;
      Log("Sql.No_Such_Row when updating bets in " & Market.To_String); 
      return False;
  end All_Bets_In_Market_Are_Matched;
  ------------------------------------------------------------
  procedure Run(Market : in out Markets.Market_Type) is
    Price_List         : Prices.Lists.List;
    Price_History_List : Price_Histories.Lists.List;
    Price_History_Data : Price_Histories.Price_History_Type;    
    T                 : Sql.Transaction_Type;
    In_Play : Boolean := False;
    pragma Warnings(Off, In_Play);
  begin
    Log(Me & "Run", "Treat market: " &  Market.To_String);
    -- do the poll
    --Price_List.Clear;
    Rpc.Get_Market_Prices(Market_Id  => Market.Marketid,
                          Market     => Market,
                          Price_List => Price_List,
                          In_Play    => In_Play);
                            
    --Priceshistory_List.Clear; --we do insert after every poll here
    begin
      T.Start;
      for Price of Price_List loop
        Price_History_Data := (
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
        declare
          Tmp : Prices.Price_Type;         
          Eos : Boolean := False;
        begin 
          Tmp := Price;
          Tmp.Read(Eos);
          if not Eos then          
            Price.Update;   
          else
            Price.Insert;
          end if;             
        exception
          when Sql.No_Such_Row =>
            Log("No_Such_Row on Prices (1)");
          when Sql.Duplicate_Index =>
            Log("Duplicate_Index on Prices (1)");
        end;       
        Price_History_List.Append(Price_History_Data);
      end loop;
      Log("insert records into Priceshistory:" & Price_History_List.Length'Img);
      for Phd of Price_History_List loop
        Phd.Insert;
      end loop;
      T.Commit;
      
      if All_Bets_In_Market_Are_Matched(Market) then      
        Log(Me & "Back_The_Leader start Market '" & Market.Marketid & "'");
        Back_The_Leader_Home(Market);
        Back_The_Leader_Away(Market);
      end if;
      Log(Me & "Lay_The_Draw start Market '" & Market.Marketid & "'");
      if Market.Marketid /= "1.127351971" then  --Inter v Cagliari
        Lay_The_Draw(Market);
      end if;
      Log(Me & "done strategeies Market '" & Market.Marketid & "'");
      
    exception
      when Sql.Duplicate_Index =>
        T.Rollback;
        Log("Duplicate_Index on Priceshistory (2)" );
      when Sql.No_Such_Row =>
        T.Rollback;
        Log("No_Such_Row on Prices (2)");
    end;       
  end Run;
  ---------------------------------------------------------------------
  procedure Find_Markets is
    Market_List : Markets.Lists.List;
    T           : Sql.Transaction_Type;
  begin 
    T.Start;
      Select_Markets.Prepare(
        "select * from AMARKETS M, AEVENTS E " &
        "where M.EVENTID = E.EVENTID " &
        "and M.MARKETTYPE in ('CORRECT_SCORE','MATCH_ODDS') " &
        "and M.STATUS = 'OPEN' " &
        "and E.EVENTTYPEID = 1 " & --soccer
        "order by M.STARTTS,M.MARKETID ");
      Markets.Read_List(Select_Markets,Market_List);
    T.Commit;
  
    Log("Find_Markets", "Num markets Found" & Market_List.Length'Img );
    for Market of Market_List loop
      Run(Market => Market);
    end loop;  
  
  end Find_Markets;
  -----------------------------------------------------
  
  use type Sql.Transaction_Status_Type;
  Timeout         : Duration := 1.0;
  
  ------------------------------ main start ---------------
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
  Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");
  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("database", "host", ""),
         Port     => Ini.Get_Value("database", "port", 5432),
         Db_Name  => Ini.Get_Value("database", "name", ""),
         Login    => Ini.Get_Value("database", "username", ""),
         Password =>Ini.Get_Value("database", "password", ""));
  Log(Me, "db Connected");
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
        when others =>
          Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Timeout := 42.0;
        Rpc.Keep_Alive(OK);
        if not OK then
          Rpc.Login;
        end if;
        Find_Markets;       
    end;
    Now := Calendar2.Clock;

    --restart every day
    exit Main_Loop when Now.Hour = 01 and then Now.Minute <= 02;

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
end Poll_Soccer;
