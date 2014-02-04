
with Sattmate_Types ; use Sattmate_Types;
with Sattmate_Exception;
with Sql;
--with Text_Io;
with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;
--with Sattmate_Calendar; use Sattmate_Calendar;
with Logging; use Logging;
--with General_Routines; use General_Routines;

with Table_Amarkets;
with Table_Aprices;
with Table_Arunners;

procedure Lay_Football is
--   Bad_Input : exception;
   
   type Result_Type is (Home, Draw, Away);   
   Prices_Match_Odds : array (Result_Type'range) of Table_Aprices.Data_Type;
   
   Market : Table_Amarkets.Data_Type;
   Runner : Table_Arunners.Data_Type;

   Prices_Any_Unquoted : Table_Aprices.Data_Type ;
                       
   Prices_Any_Unquoted_List : Table_Aprices.Aprices_List_Pack.List_Type :=
                                            Table_Aprices.Aprices_List_Pack.Create;
                                            
   Prices_Match_Odds_List : Table_Aprices.Aprices_List_Pack.List_Type :=
                                            Table_Aprices.Aprices_List_Pack.Create;
   T : Sql.Transaction_Type;
   Select_All,
   Stm_Select_Eventid_Selectionid_O : Sql.Statement_Type;

--   Start_Date       : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
--   Stop_Date        : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
--   Global_Stop_Date : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;

   Data_Ok, Eos              : Boolean := False;
   Config           : Command_Line_Configuration;

   Sa_Par_Market_Type    : aliased Gnat.Strings.String_Access;
--   Sa_Par_Start_Date     : aliased Gnat.Strings.String_Access;
--   Sa_Par_Stop_Date      : aliased Gnat.Strings.String_Access;
   Sa_Par_Min_Odds       : aliased Gnat.Strings.String_Access;
   Sa_Par_Max_Odds       : aliased Gnat.Strings.String_Access;
   
   Min_Odds, Max_Odds    : Float_8 := 0.0;
   Global_Profit, Profit : Float_8 := 0.0;
   
   Lay_Size  : Float_8 := 30.0;   
   Commission : Float_8 := 0.065;

begin
--   Define_Switch
--     (Config      => Config,
--      Output      => Sa_Par_Start_Date'access,
--      Long_Switch => "--start_date=",
--      Help        => "when the data move starts yyyy-mm-dd, inclusive");
--
--   Define_Switch
--     (Config      => Config,
--      Output      => Sa_Par_Stop_Date'access,
--      Long_Switch => "--stop_date=",
--      Help        => "when the data move stops yyyy-mm-dd, inclusive");
      
   Define_Switch
     (Config      => Config,
      Output      => Sa_Par_Market_Type'access,
      Long_Switch => "--market_type=",
      Help        => "what market type");
      
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
--   Start_Date := Sattmate_Calendar.To_Time_Type (Sa_Par_Start_Date.all, "00:00:00:000");
--   Stop_Date  := Sattmate_Calendar.To_Time_Type (Sa_Par_Start_Date.all, "23:59:59:999");
--   Start_Date := Start_Date - Sattmate_Calendar.Interval_Type'(1,0,0,0,0); --remove a day first
--   Stop_Date  := Stop_Date  - Sattmate_Calendar.Interval_Type'(1,0,0,0,0); --remove a day first
--
--   Global_Stop_Date  := Sattmate_Calendar.To_Time_Type (Sa_Par_Stop_Date.all, "23:59:59:999");

   Log ("Connect db");
   Sql.Connect
     (Host     => "localhost",
      Port     => 5432,
      Db_Name  => "nono",
      Login    => "bnl",
      Password => "bnl");

    Main : loop
--      Start_Date := Start_Date + Sattmate_Calendar.Interval_Type'(1,0,0,0,0); --add a day
--      Stop_Date  := Stop_Date  + Sattmate_Calendar.Interval_Type'(1,0,0,0,0); --add a day

--      Log ("Main - treat date " & String_Date(start_date));

      T.Start;
      
      Select_All.Prepare (
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
--         "  and M.MARKETTYPE = 'HALF_TIME_SCORE' " &
         "  and R.RUNNERNAME = 'Any Unquoted' " &
         "order by " &
         "  M.MARKETID, " &
         "  M.STARTTS ");

      Select_All.Set("MARKETTYPE", Sa_Par_Market_Type.all);

      Table_Aprices.Read_List(Select_All, Prices_Any_Unquoted_List);
  
      Stm_Select_Eventid_Selectionid_O.Prepare( "select P.* " & 
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
        Table_Amarkets.Read(Market, Eos);
       
        Stm_Select_Eventid_Selectionid_O.Set("EVENTID", Market.Eventid);
        Table_Aprices.Read_List(Stm_Select_Eventid_Selectionid_O, Prices_Match_Odds_List);
        -- put the match odds in array
        Data_Ok := False;
        if not Table_Aprices.Aprices_List_Pack.Is_Empty(Prices_Match_Odds_List) then
          Data_Ok := True;
          Table_Aprices.Aprices_List_Pack.Remove_From_Head(Prices_Match_Odds_List, Prices_Match_Odds(Home));
        end if;
        
        if Data_Ok and not Table_Aprices.Aprices_List_Pack.Is_Empty(Prices_Match_Odds_List) then
          Table_Aprices.Aprices_List_Pack.Remove_From_Head(Prices_Match_Odds_List, Prices_Match_Odds(Away));
        else 
           Data_Ok := False;       
        end if;
        
        if Data_Ok and not Table_Aprices.Aprices_List_Pack.Is_Empty(Prices_Match_Odds_List) then
          Table_Aprices.Aprices_List_Pack.Remove_From_Head(Prices_Match_Odds_List, Prices_Match_Odds(Draw));
        else 
           Data_Ok := False;       
        end if;
        
        Log(Table_Amarkets.To_String(Market));
        Log("Home " & Table_Aprices.To_String(Prices_Match_Odds(Home)));
        Log("away " & Table_Aprices.To_String(Prices_Match_Odds(away)));
        Log("draw " & Table_Aprices.To_String(Prices_Match_Odds(draw)));
        
        if Data_OK and then 
           Prices_Match_Odds(Home).Layprice <= Min_Odds and then
           Prices_Match_Odds(Away).Layprice <= Min_Odds and then
           Prices_Any_Unquoted.Layprice  <= Max_Odds then
           
           Runner.Marketid := Prices_Any_Unquoted.Marketid;
           Runner.Selectionid := Prices_Any_Unquoted.Selectionid;
           Table_Arunners.Read(Runner, Eos);
           
           
           if Runner.Status(1..5) = "LOSER" then
             -- bet won
             Profit := Lay_Size * (1.0 - Commission);            

           elsif Runner.Status(1..6) = "WINNER" then
             -- bet lost
             Profit := Lay_Size * (Prices_Any_Unquoted.Layprice - 1.0);
           else
             Profit := 0.0;
           end if;             
           
        end if;
           
        Global_Profit := Global_Profit + Profit;          
         
      end loop Loop_All;
      T.Commit ;
      exit;
--      exit Main when     Start_Date.Year  = Global_Stop_Date.Year
--                and then Start_Date.Month = Global_Stop_Date.Month
--                and then Start_Date.Day   = Global_Stop_Date.Day;
   end loop Main;

   Sql.Close_Session;

   Log("Total profit = " & Integer_4(Global_Profit)'Img);  
exception
   when E: others =>
      Sattmate_Exception.Tracebackinfo(E);
end Lay_Football;
