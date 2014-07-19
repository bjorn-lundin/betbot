
with Types ; use Types;
with Bot_Types ; use Bot_Types;

with Stacktrace;
with Sql;
with Text_Io;
with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;
--with Calendar2; use Calendar2;
--with Logging; use Logging;
--with General_Routines; use General_Routines;
with Simple_List_Class;
pragma Elaborate_All(Simple_List_Class);

procedure Lay_Football is
   
  T : Sql.Transaction_Type;
  Select_Any_Unquoted  : Sql.Statement_Type;

  Eos, Eol  : Boolean := False;
  Config           : Command_Line_Configuration;

  Sa_Par_Country_Code   : aliased Gnat.Strings.String_Access;
  Sa_Par_Market_Type    : aliased Gnat.Strings.String_Access;
  Sa_Par_Min_Odds_Score : aliased Gnat.Strings.String_Access;
  Sa_Par_Max_Odds_Score : aliased Gnat.Strings.String_Access;
  Sa_Par_Min_Odds_Match : aliased Gnat.Strings.String_Access;
  Sa_Par_Max_Odds_Match : aliased Gnat.Strings.String_Access;
  Sa_Par_Database       : aliased Gnat.Strings.String_Access;
  Sa_Par_Hostname       : aliased Gnat.Strings.String_Access;
  Sa_Par_Username       : aliased Gnat.Strings.String_Access;
  Sa_Par_Password       : aliased Gnat.Strings.String_Access;
  
  Min_Odds_Score, Max_Odds_Score    : Float_8 := 0.0;
  Min_Odds_Match, Max_Odds_Match    : Float_8 := 0.0;
  
  Match_Odds, Score_Odds : Float_8 := 0.0;
  
  Global_Profit, Profit : Float_8 := 0.0;
  
  Lay_Size  : Float_8 := 30.0;   
  Commission : Float_8 := 0.065;
  type Result_Type is (Winner, Loser, Removed, Not_Set_Yet ,Other, Tot);
  
  Cnt : array (Result_Type'range) of Integer_4 := (others => 0);
  
  type Runner_Info is record
    Runner_Name : Runner_Name_Type := (others => ' ');
    Status      : Status_Type      := (others => ' ');
    Back_Price  : Float_8          := 0.0;
    Lay_Price   : Float_8          := 0.0;      
  end record;
  
  type Runner_Info_Type is (Score, Home, Draw, Away);   
  type Runner_Array is array (Runner_Info_Type'range) of Runner_Info;
  
  type Market_Info is record
    Event_Name      : Event_Name_Type := (others => ' ');
    Match_Market_Id : Market_Id_Type  := (others => ' ');
    Score_Market_Id : Market_Id_Type  := (others => ' ');
    Runner          : Runner_Array;
  end record;
  
  package Info_Pkg is new SImple_List_Class(Market_Info);
  List : Info_Pkg.List_Type := Info_Pkg.Create;
  
  Info : Market_Info;
   --------------------------------------------------------------------------
begin      
  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Market_Type'access,
     Long_Switch => "--market_type=",
     Help        => "what market type");
     
  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Country_Code'access,
     Long_Switch => "--country_code=",
     Help        => "what country of market");
     
  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Max_Odds_Score'access,
     Long_Switch => "--max_odds_score=",
     Help        => "Max odds to accept, inclusive, for the score, to place the bet");
     
  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Min_Odds_Score'access,
     Long_Switch => "--min_odds_score=",
     Help        => "Min odds to accept, inclusive,for the score, to place the bet");

  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Max_Odds_Match'access,
     Long_Switch => "--max_odds_match=",
     Help        => "Max odds to accept, inclusive, for the match, to place the bet");
     
  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Min_Odds_Match'access,
     Long_Switch => "--min_odds_match=",
     Help        => "Min odds to accept, inclusive,for the match, to place the bet");

  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Hostname'access,
     Long_Switch => "--hostname=",
     Help        => "hostname");
     
  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Database'access,
     Long_Switch => "--database=",
     Help        => "database");
     
  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Username'access,
     Long_Switch => "--username=",
     Help        => "username");

  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Password'access,
     Long_Switch => "--password=",
     Help        => "password");

   Getopt (Config);  -- process the command line

  if Sa_Par_Min_Odds_Score.all = "" or else 
    Sa_Par_Max_Odds_Score.all = "" or else 
    Sa_Par_Max_Odds_Match.all = "" or else 
    Sa_Par_Max_Odds_Match.all = "" or else 
    Sa_Par_Market_Type.all = "" then
    Display_Help (Config);
    return;
  end if;

  Min_Odds_Score := Float_8'Value(Sa_Par_Min_Odds_Score.all);
  Max_Odds_Score := Float_8'Value(Sa_Par_Max_Odds_Score.all);
  Max_Odds_Match := Float_8'Value(Sa_Par_Max_Odds_Match.all);
  Min_Odds_Match := Float_8'Value(Sa_Par_Min_Odds_Match.all);

  Sql.Connect
     (Host     => Sa_Par_Hostname.all,
      Port     => 5432,
      Db_Name  => Sa_Par_Database.all,
      Login    => Sa_Par_Username.all,
      Password => Sa_Par_Password.all);

  T.Start;
     
      if Sa_Par_Country_Code.all = "YY" then -- any country
        Select_Any_Unquoted.Prepare (
          "select " &
          "  E.EVENTNAME        EVENTNAME, " &
          "  M_SCORE.STARTTS    SCORE_STARTTS, " &
          "  M_SCORE.MARKETID   SCORE_MARKETID, " &
          "  M_MATCH.MARKETID   MATCH_MARKETID, " &
          "  R_SCORE.RUNNERNAME R_SCORE_RUNNERNAME, " &
          "  R_SCORE.STATUS     R_SCORE_STATUS, " &
          "  P_SCORE.BACKPRICE  P_SCORE_BACKPRICE, " &
          "  P_SCORE.LAYPRICE   P_SCORE_LAYPRICE, " &
          "  R_HOME.RUNNERNAME  R_HOME_RUNNERNAME, " &
          "  R_HOME.STATUS      R_HOME_STATUS, " &
          "  P_HOME.BACKPRICE   P_HOME_BACKPRICE, " &
          "  P_HOME.LAYPRICE    P_HOME_LAYPRICE, " &
          "  R_DRAW.RUNNERNAME  R_DRAW_RUNNERNAME, " &
          "  R_DRAW.STATUS      R_DRAW_STATUS, " &
          "  P_DRAW.BACKPRICE   P_DRAW_BACKPRICE, " &
          "  P_DRAW.LAYPRICE    P_DRAW_LAYPRICE, " &
          "  R_AWAY.RUNNERNAME  R_AWAY_RUNNERNAME, " &
          "  R_AWAY.STATUS      R_AWAY_STATUS, " &
          "  P_AWAY.BACKPRICE   P_AWAY_BACKPRICE, " &
          "  P_AWAY.LAYPRICE    P_AWAY_LAYPRICE " &
          "from " &
          "  AEVENTS  E, " &
          "  AMARKETS M_SCORE, " & 
          "  AMARKETS M_MATCH, " &
          "  ARUNNERS R_SCORE, " &
          "  APRICES  P_SCORE, " &
          "  ARUNNERS R_HOME, " &
          "  APRICES  P_HOME, " &
          "  ARUNNERS R_DRAW, " &
          "  APRICES  P_DRAW, " &
          "  ARUNNERS R_AWAY, " &
          "  APRICES  P_AWAY " &
          "where E.EVENTID          = M_SCORE.EVENTID " &
          "and E.EVENTID            = M_MATCH.EVENTID " &
          "and P_SCORE.MARKETID     = M_SCORE.MARKETID " &
          "and P_SCORE.MARKETID     = R_SCORE.MARKETID " &
          "and P_SCORE.SELECTIONID  = R_SCORE.SELECTIONID " &
          "" &
          "and P_HOME.MARKETID      = M_MATCH.MARKETID " &
          "and P_HOME.MARKETID      = R_HOME.MARKETID " &
          "and P_HOME.SELECTIONID   = (select min(SELECTIONID) from APRICES where SELECTIONID <> 58805 and APRICES.MARKETID = P_HOME.MARKETID) " &
--          "and P_HOME.SELECTIONID   = R_HOME.SELECTIONID " &
--          "and R_HOME.RUNNERNAME    = trim(substring(E.EVENTNAME for position(' v ' in E.EVENTNAME)-1 )) " &
          "" &
          "and P_DRAW.MARKETID      = M_MATCH.MARKETID " &
          "and P_DRAW.MARKETID      = R_DRAW.MARKETID " &
          "and P_DRAW.SELECTIONID   = R_DRAW.SELECTIONID " & 
          "and R_DRAW.RUNNERNAME    = 'The Draw' " & 
          "" &
          "and P_AWAY.MARKETID      = M_MATCH.MARKETID " & 
          "and P_AWAY.MARKETID      = R_AWAY.MARKETID " & 
          "and P_AWAY.SELECTIONID   = (select max(SELECTIONID) from APRICES where SELECTIONID <> 58805 and APRICES.MARKETID = P_AWAY.MARKETID) " &
--          "and P_AWAY.SELECTIONID   = R_AWAY.SELECTIONID " & 
--          "and R_AWAY.RUNNERNAME    = trim(substring(E.EVENTNAME from position(' v ' in E.EVENTNAME)+3 )) " &
          "" &
          "and E.EVENTTYPEID        = 1 " & 
          "and M_SCORE.MARKETTYPE   = :MARKETTYPE " &   
          "and M_MATCH.MARKETTYPE   = 'MATCH_ODDS' " &
          "and R_SCORE.RUNNERNAME = 'Any Unquoted' " &
          "order by " & 
          "  M_SCORE.STARTTS, " &
          "  E.EVENTID ");
  
      else -- specific country
        Select_Any_Unquoted.Prepare (
          "select " &
          "  E.EVENTNAME        EVENTNAME, " &
          "  M_SCORE.STARTTS    SCORE_STARTTS, " &
          "  M_SCORE.MARKETID   SCORE_MARKETID, " &
          "  M_MATCH.MARKETID   MATCH_MARKETID, " &
          "  R_SCORE.RUNNERNAME R_SCORE_RUNNERNAME, " &
          "  R_SCORE.STATUS     R_SCORE_STATUS, " &
          "  P_SCORE.BACKPRICE  P_SCORE_BACKPRICE, " &
          "  P_SCORE.LAYPRICE   P_SCORE_LAYPRICE, " &
          "  R_HOME.RUNNERNAME  R_HOME_RUNNERNAME, " &
          "  R_HOME.STATUS      R_HOME_STATUS, " &
          "  P_HOME.BACKPRICE   P_HOME_BACKPRICE, " &
          "  P_HOME.LAYPRICE    P_HOME_LAYPRICE, " &
          "  R_DRAW.RUNNERNAME  R_DRAW_RUNNERNAME, " &
          "  R_DRAW.STATUS      R_DRAW_STATUS, " &
          "  P_DRAW.BACKPRICE   P_DRAW_BACKPRICE, " &
          "  P_DRAW.LAYPRICE    P_DRAW_LAYPRICE, " &
          "  R_AWAY.RUNNERNAME  R_AWAY_RUNNERNAME, " &
          "  R_AWAY.STATUS      R_AWAY_STATUS, " &
          "  P_AWAY.BACKPRICE   P_AWAY_BACKPRICE, " &
          "  P_AWAY.LAYPRICE    P_AWAY_LAYPRICE " &
          "from " &
          "  AEVENTS  E, " &
          "  AMARKETS M_SCORE, " & 
          "  AMARKETS M_MATCH, " &
          "  ARUNNERS R_SCORE, " &
          "  APRICES  P_SCORE, " &
          "  ARUNNERS R_HOME, " &
          "  APRICES  P_HOME, " &
          "  ARUNNERS R_DRAW, " &
          "  APRICES  P_DRAW, " &
          "  ARUNNERS R_AWAY, " &
          "  APRICES  P_AWAY " &
          "where E.EVENTID          = M_SCORE.EVENTID " &
          "and E.EVENTID            = M_MATCH.EVENTID " &
          "and P_SCORE.MARKETID     = M_SCORE.MARKETID " &
          "and P_SCORE.MARKETID     = R_SCORE.MARKETID " &
          "and P_SCORE.SELECTIONID  = R_SCORE.SELECTIONID " &
          "" &
          "and P_HOME.MARKETID      = M_MATCH.MARKETID " &
          "and P_HOME.MARKETID      = R_HOME.MARKETID " &
          "and P_HOME.SELECTIONID   = (select min(SELECTIONID) from APRICES where SELECTIONID <> 58805 and APRICES.MARKETID = P_HOME.MARKETID) " &
--          "and P_HOME.SELECTIONID   = R_HOME.SELECTIONID " &
--          "and R_HOME.RUNNERNAME    = trim(substring(E.EVENTNAME for position(' v ' in E.EVENTNAME)-1 )) " &
          "" &
          "and P_DRAW.MARKETID      = M_MATCH.MARKETID " &
          "and P_DRAW.MARKETID      = R_DRAW.MARKETID " &
          "and P_DRAW.SELECTIONID   = R_DRAW.SELECTIONID " & 
          "and R_DRAW.RUNNERNAME    = 'The Draw' " & 
          "" &
          "and P_AWAY.MARKETID      = M_MATCH.MARKETID " & 
          "and P_AWAY.MARKETID      = R_AWAY.MARKETID " & 
          "and P_AWAY.SELECTIONID   = (select max(SELECTIONID) from APRICES where SELECTIONID <> 58805 and APRICES.MARKETID = P_AWAY.MARKETID) " &
--          "and P_AWAY.SELECTIONID   = R_AWAY.SELECTIONID " & 
--          "and R_AWAY.RUNNERNAME    = trim(substring(E.EVENTNAME from position(' v ' in E.EVENTNAME)+3 )) " &
          "" &
          "and E.EVENTTYPEID        = 1 " & 
          "and E.COUNTRYCODE        = :COUNTRYCODE " & 
          "and M_SCORE.MARKETTYPE   = :MARKETTYPE " &   
          "and M_MATCH.MARKETTYPE   = 'MATCH_ODDS' " &
          "and R_SCORE.RUNNERNAME   = 'Any Unquoted' " &
          "order by " & 
          "  M_SCORE.STARTTS, " &
          "  E.EVENTID ");
        Select_Any_Unquoted.Set("COUNTRYCODE", Sa_Par_Country_Code.all);
      end if;
     
  Match_Odds := Min_Odds_Match - Float_8(0.1);
  Score_Odds := Min_Odds_Score - Float_8(1.0);
  
  -- Get resultset into list
  
  Select_Any_Unquoted.Set("MARKETTYPE", Sa_Par_Market_Type.all);
  Select_Any_Unquoted.Open_Cursor;
  Odds_List_Loop : loop
    Select_Any_Unquoted.Fetch(Eos);
    exit when Eos;
    Select_Any_Unquoted.Get("EVENTNAME", Info.Event_Name);
    Select_Any_Unquoted.Get("SCORE_MARKETID", Info.Score_Market_Id);
    Select_Any_Unquoted.Get("MATCH_MARKETID", Info.Match_Market_Id);
    Select_Any_Unquoted.Get("R_SCORE_RUNNERNAME", Info.Runner(Score).Runner_Name);
    Select_Any_Unquoted.Get("R_SCORE_STATUS", Info.Runner(Score).Status);
    Select_Any_Unquoted.Get("P_SCORE_BACKPRICE", Info.Runner(Score).Back_Price);
    Select_Any_Unquoted.Get("P_SCORE_LAYPRICE", Info.Runner(Score).Lay_Price);
    
    Select_Any_Unquoted.Get("R_HOME_RUNNERNAME", Info.Runner(Home).Runner_Name);
    Select_Any_Unquoted.Get("R_HOME_STATUS", Info.Runner(Home).Status);
    Select_Any_Unquoted.Get("P_HOME_BACKPRICE", Info.Runner(Home).Back_Price);
    Select_Any_Unquoted.Get("P_Home_Layprice", Info.Runner(Home).Lay_Price);
    
    Select_Any_Unquoted.Get("R_DRAW_RUNNERNAME", Info.Runner(Draw).Runner_Name);
    Select_Any_Unquoted.Get("R_DRAW_STATUS", Info.Runner(Draw).Status);
    Select_Any_Unquoted.Get("P_DRAW_BACKPRICE", Info.Runner(Draw).Back_Price);
    Select_Any_Unquoted.Get("P_DRAW_LAYPRICE", Info.Runner(Draw).Lay_Price);
    
    Select_Any_Unquoted.Get("R_AWAY_RUNNERNAME", Info.Runner(Away).Runner_Name);
    Select_Any_Unquoted.Get("R_AWAY_STATUS", Info.Runner(Away).Status);
    Select_Any_Unquoted.Get("P_AWAY_BACKPRICE", Info.Runner(Away).Back_Price);
    Select_Any_Unquoted.Get("P_AWAY_LAYPRICE", Info.Runner(Away).Lay_Price);
 
    Info_Pkg.Insert_At_Tail(List, Info);
  end loop Odds_List_Loop;      
  Select_Any_Unquoted.Close_Cursor;
  T.Commit ; 
  Sql.Close_Session;
  
  Score_Odds_Loop : loop
    Score_Odds := Score_Odds + Float_8(1.0);
    exit Score_Odds_Loop when Score_Odds > Max_Odds_Score;   
    
    Match_Odds_Loop : loop
      Match_Odds := Match_Odds + Float_8(0.1);
      exit Match_Odds_Loop when Match_Odds > Max_Odds_Match;
    
      Global_Profit := 0.0;
      Cnt := (others => 0);
      Info_Pkg.Get_First(List,Info,Eol);
      List_Loop : loop  
        exit List_Loop when Eol;
        if abs(Info.Runner(Score).Lay_Price - Score_Odds) > Float_8(0.0001) and then  -- at score odds
           abs(Info.Runner(Home).Lay_Price - Info.Runner(Away).Lay_Price) <= Match_Odds and then  -- less than match odds
               Info.Runner(Score).Lay_Price   > Float_8(1.0) and then  --real figures
               Info.Runner(Home).Back_Price  >= Float_8(2.0) and then  -- some fix price
               Info.Runner(Away).Back_Price  >= Float_8(2.0) and then  -- some fix price
               Info.Runner(Home).Back_Price  <= Float_8(7.0) and then  -- some fix price
               Info.Runner(Away).Back_Price  <= Float_8(7.0) then      -- some fix price
           
           Cnt(Tot) := Cnt(Tot) +1;
           if Info.Runner(Score).Status(1..5) = "LOSER" then
             Cnt(Loser) := Cnt(Loser) +1;
             -- bet won
             Profit := Lay_Size * (1.0 - Commission);              
           elsif Info.Runner(Score).Status(1..6) = "WINNER" then
             Cnt(Winner) := Cnt(Winner) +1;
             -- bet lost
             Profit := -Lay_Size * (Info.Runner(Score).Lay_Price - 1.0);
           elsif Info.Runner(Score).Status(1..7) = "REMOVED" then
             Cnt(Removed) := Cnt(Removed) +1;
             -- runner cancelled
             Profit := 0.0;
           elsif Info.Runner(Score).Status(1..11) = "NOT_SET_YET" then
             Cnt(Not_Set_Yet) := Cnt(Not_Set_Yet) +1;
             -- runner cancelled
             Profit := 0.0;
           else
             -- dont know
             Cnt(Other) := Cnt(Other) +1;
             Profit := 0.0;
           end if;                        
           Global_Profit := Global_Profit + Profit;                            
        end if;   
      Info_Pkg.Get_Next(List,Info,Eol);
      end loop List_Loop;  
      Text_Io.Put_Line(F8_Image(Match_Odds) & "|" &
                       F8_Image(Score_Odds) & "|" &
                       Integer_4(Global_Profit)'Img & "|" &  
                       Cnt(Tot)'Img & "|" &  
                       Cnt(Loser)'Img & "|" &  
                       Cnt(Winner)'Img & "|" &  
                       Cnt(Removed)'Img & "|" &  
                       Cnt(Not_Set_Yet)'Img & "|" &  
                       Cnt(Other)'Img);
    end loop Match_Odds_Loop;
    Match_Odds := Min_Odds_Match - Float_8(0.1);
    Text_Io.Put_Line("");
  end loop Score_Odds_Loop;    
  Info_Pkg.Release(List);
exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Lay_Football;
