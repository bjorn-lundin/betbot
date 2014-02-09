
with Sattmate_Types ; use Sattmate_Types;
with Sattmate_Exception;
with Sql;
with Text_Io;
with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;
--with Sattmate_Calendar; use Sattmate_Calendar;
--with Logging; use Logging;
--with General_Routines; use General_Routines;

with Table_Amarkets;
with Table_Aprices;
with Table_Arunners;

procedure Lay_Football is
   
   type Result_Type is (Home, Draw, Away);   
   Prices_Match_Odds : array (Result_Type'range) of Table_Aprices.Data_Type;
   Got_Data : array (Result_Type'range) of Boolean := (others => False);
   
   Market : Table_Amarkets.Data_Type;
   Runner : Table_Arunners.Data_Type;

   Prices_Any_Unquoted : Table_Aprices.Data_Type ;
                       
   Prices_Any_Unquoted_List : Table_Aprices.Aprices_List_Pack.List_Type :=
                                            Table_Aprices.Aprices_List_Pack.Create;
   T : Sql.Transaction_Type;
   Select_Any_Unquoted,
   Select_Match_Odds : Sql.Statement_Type;

   Eos,
   Eos2             : Boolean := False;
   Config           : Command_Line_Configuration;

   Sa_Par_Country_Code   : aliased Gnat.Strings.String_Access;
   Sa_Par_Market_Type    : aliased Gnat.Strings.String_Access;
   Sa_Par_Min_Odds       : aliased Gnat.Strings.String_Access;
   Sa_Par_Max_Odds       : aliased Gnat.Strings.String_Access;
   
   Min_Odds, Max_Odds    : Float_8 := 0.0;
   Global_Profit, Profit : Float_8 := 0.0;
   
   Lay_Size  : Float_8 := 30.0;   
   Commission : Float_8 := 0.065;
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
     Output      => Sa_Par_Max_Odds'access,
     Long_Switch => "--max_odds=",
     Help        => "Max odds to accept, inclusive, to place the bet");
     
  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Min_Odds'access,
     Long_Switch => "--min_odds=",
     Help        => "Min odds to accept, inclusive, to place the bet");
     
  Getopt (Config);  -- process the command line

  if Sa_Par_Min_Odds.all = "" or else 
    Sa_Par_Max_Odds.all = "" or else 
    Sa_Par_Market_Type.all = "" then
    Display_Help (Config);
    return;
  end if;

  Min_Odds := Float_8'Value(Sa_Par_Min_Odds.all);
  Max_Odds := Float_8'Value(Sa_Par_Max_Odds.all);

  Sql.Connect
    (Host     => "localhost",
     Port     => 5432,
     Db_Name  => "nono",
     Login    => "bnl",
     Password => "bnl");

  T.Start;
    if Sa_Par_Country_Code.all = "YY" then -- any country
      Select_Any_Unquoted.Prepare (
         "select " &
         " P.* " &
         "from " &
         "  AMARKETS M, AEVENTS E, ARUNNERS R, APRICES P " &
         "where " &
         "  M.EVENTID = E.EVENTID " &
         "  and M.MARKETID = R.MARKETID " &
         "  and P.MARKETID = R.MARKETID " &
         "  and P.SELECTIONID = R.SELECTIONID " &
         "  and E.EVENTTYPEID = 1 " &
         "  and M.MARKETTYPE = :MARKETTYPE " &
         "  and R.RUNNERNAME = 'Any Unquoted' " &
         "order by " &
         "  M.MARKETID, " &
         "  M.STARTTS ");
      Select_Any_Unquoted.Set("MARKETTYPE", Sa_Par_Market_Type.all);
    else -- specific country
      Select_Any_Unquoted.Prepare (
         "select " &
         " P.* " &
         "from " &
         "  AMARKETS M, AEVENTS E, ARUNNERS R, APRICES P " &
         "where " &
         "  M.EVENTID = E.EVENTID " &
         "  and M.MARKETID = R.MARKETID " &
         "  and P.MARKETID = R.MARKETID " &
         "  and P.SELECTIONID = R.SELECTIONID " &
         "  and E.EVENTTYPEID = 1 " &
         "  and E.COUNTRYCODE = :COUNTRYCODE " &
         "  and M.MARKETTYPE = :MARKETTYPE " &
         "  and R.RUNNERNAME = 'Any Unquoted' " &
         "order by " &
         "  M.MARKETID, " &
         "  M.STARTTS ");
      Select_Any_Unquoted.Set("COUNTRYCODE", Sa_Par_Country_Code.all);
      Select_Any_Unquoted.Set("MARKETTYPE", Sa_Par_Market_Type.all);
    end if;
    
    Table_Aprices.Read_List(Select_Any_Unquoted, Prices_Any_Unquoted_List);

    Select_Match_Odds.Prepare( 
          "select R.RUNNERNAME, P.* " & 
          "from APRICES P, ARUNNERS R, AMARKETS M " &
          "where M.EVENTID = :EVENTID " &
          "and M.MARKETTYPE = 'MATCH_ODDS' " &
          "and M.MARKETID = R.MARKETID " &
          "and P.MARKETID = R.MARKETID " &
          "and P.SELECTIONID = R.SELECTIONID " &
          "order by R.SORTPRIO"  ) ;

    Loop_All : while not Table_Aprices.Aprices_List_Pack.Is_Empty(Prices_Any_Unquoted_List) loop
      Table_Aprices.Aprices_List_Pack.Remove_From_Head(Prices_Any_Unquoted_List, Prices_Any_Unquoted);    

      Market.Marketid := Prices_Any_Unquoted.Marketid;
      Table_Amarkets.Read(Market, Eos2);
      -- get the corresponding MATCH_ODDS market - linked via eventid
      Select_Match_Odds.Set("EVENTID", Market.Eventid);
      
      Got_Data := (others => False);
      Select_Match_Odds.Open_Cursor;
      Odds_List_Loop : loop
        Select_Match_Odds.Fetch(Eos);
        exit when Eos or else Eos2;
        Runner.Runnername := (others => ' ');
        Select_Match_Odds.Get("RUNNERNAME", Runner.Runnername); 
        if Runner.Runnername(1..8) = "The Draw" then
          Prices_Match_Odds(Draw) := Table_Aprices.Get(Select_Match_Odds);
          Got_Data(Draw) := True;
        else
          if not Got_Data(Home) then
            Prices_Match_Odds(Home) := Table_Aprices.Get(Select_Match_Odds);        
            Got_Data(Home) := True;
          else
            Prices_Match_Odds(Away) := Table_Aprices.Get(Select_Match_Odds);
            Got_Data(Away) := True;
          end if;
        end if;
      end loop Odds_List_Loop;      
      Select_Match_Odds.Close_Cursor;
      
    --        Log(Table_Amarkets.To_String(Market));
    --        Log("Home " & Table_Aprices.To_String(Prices_Match_Odds(Home)));
    --        Log("away " & Table_Aprices.To_String(Prices_Match_Odds(Away)));
    --        Log("draw " & Table_Aprices.To_String(Prices_Match_Odds(Draw)));
      
      if Got_Data(Home) and then Prices_Match_Odds(Home).Layprice <= Min_Odds and then
                                 Prices_Match_Odds(Home).Layprice > 0.0       and then
         Got_Data(Away) and then Prices_Match_Odds(Away).Layprice <= Min_Odds and then
                                 Prices_Match_Odds(Away).Layprice > 0.0       and then
         Prices_Any_Unquoted.Layprice  <= Max_Odds then
         
         Runner := Table_Arunners.Empty_Data;
         Runner.Marketid := Prices_Any_Unquoted.Marketid;
         Runner.Selectionid := Prices_Any_Unquoted.Selectionid;
         Table_Arunners.Read(Runner, Eos);
                   
         if Runner.Status(1..5) = "LOSER" then
           -- bet won
           Profit := Lay_Size * (1.0 - Commission);            

         elsif Runner.Status(1..6) = "WINNER" then
           -- bet lost
           Profit := -Lay_Size * (Prices_Any_Unquoted.Layprice - 1.0);
         else
           Profit := 0.0;
         end if;                        
      end if;           
      Global_Profit := Global_Profit + Profit;                   
    end loop Loop_All;
  T.Commit ;

  Sql.Close_Session;
  Text_Io.Put_Line(
      (Sa_Par_Min_Odds.all & "|" &
       Sa_Par_Max_Odds.all & "|" &
       Integer_4(Global_Profit)'Img));  
exception
   when E: others =>
      Sattmate_Exception.Tracebackinfo(E);
end Lay_Football;
