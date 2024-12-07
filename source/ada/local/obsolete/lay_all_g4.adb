
with Types ; use Types;
with Stacktrace;
with Sql;
with Text_Io;
with Table_Arunners;
with Table_Aprices;
with Table_Amarkets;
with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;
with Calendar2; use Calendar2;
with Logging; use Logging;
--with General_Routines; use General_Routines;

with Simple_List_Class;
pragma Elaborate_All(Simple_List_Class);

procedure Lay_All_G4 is
   Price : Table_Aprices.Data_Type;
   Price_List : Table_Aprices.Aprices_List_Pack.List_Type := Table_Aprices.Aprices_List_Pack.Create;
   
   Market : Table_Amarkets.Data_Type;
   Market_List : Table_Amarkets.Amarkets_List_Pack.List_Type := Table_Amarkets.Amarkets_List_Pack.Create;
   
   Runner : Table_Arunners.Data_Type;

   package Day_Pkg is new Simple_List_Class(Calendar2.Time_Type);
   Day_List : Day_Pkg.List_Type := Day_Pkg.Create;
   
   Bad_Data
   -- , Bad_Input 
   : exception;

   T                       : Sql.Transaction_Type;
--   Select_Markets_In_A_Day              : Sql.Statement_Type;
   Select_Day              : Sql.Statement_Type;
   Select_Markets_In_A_Day : Sql.Statement_Type;

   Start_Date            : Calendar2.Time_Type := Calendar2.Time_Type_First;
   Stop_Date             : Calendar2.Time_Type := Calendar2.Time_Type_Last;
   Some_Day             : Calendar2.Time_Type := Calendar2.Time_Type_First;
   

   Eos                   : Boolean := False;

   Config                : Command_Line_Configuration;

   Sa_Par_Start_Date     : aliased Gnat.Strings.String_Access;
   Sa_Par_Stop_Date      : aliased Gnat.Strings.String_Access;
   Sa_Par_Market_Type    : aliased Gnat.Strings.String_Access;
   
   IA_Max_Daily_Loss     : aliased Integer := 0;
   IA_Min_Num_Runners    : aliased Integer := 7;
   Ia_Min_Odds           : aliased Integer := 8;
   Ia_Max_Odds           : aliased Integer := 1000;

   Total_Profit, 
   Daily_Profit, 
   Market_Profit, 
   Profit :            Float_8 := 0.0;

   Lay_Size : Float_8 := 30.0;


   type Outcome_Type is (Laybet_Won, Laybet_Lost, No_Bet_Laid);
   Outcome : Outcome_Type := No_Bet_Laid;

   type Stats_Type is record
     Hits   : Integer_4 := 0;
     Profit : Float_8   := 0.0;
   end record ;

   Stats : array (Outcome_Type'range) of Stats_Type;

--   Cnt,Cur : Integer := 0;

begin
    Define_Switch
      (Config      => Config,
       Output      => Sa_Par_Start_Date'access,
       Long_Switch => "--start_date=",
       Help        => "when the data move starts yyyy-mm-dd, inclusive");

    Define_Switch
      (Config      => Config,
       Output      => Sa_Par_Stop_Date'access,
       Long_Switch => "--stop_date=",
       Help        => "when the data move stops yyyy-mm-dd, inclusive");

    Define_Switch
      (Config      => Config,
       Output      => Ia_Max_Odds'access,
       Long_Switch => "--max_odds=",
       Help        => "Max odds to accept, inclusive, to place the bet");

    Define_Switch
      (Config      => Config,
       Output      => Ia_Min_Odds'access,
       Long_Switch => "--min_odds=",
       Help        => "Min odds to accept, inclusive, to place the bet");

    Define_Switch
      (Config      => Config,
       Output      => IA_Max_Daily_Loss'access,
       Long_Switch => "--max_daily_loss=",
       Help        => "profit for a day may NOT be lower than this");
       
    Define_Switch
      (Config      => Config,
       Output      => IA_Min_Num_Runners'access,
       Long_Switch => "--min_num_runners=",
       Help        => "least num runners in a race");
       
    Define_Switch
      (Config      => Config,
       Output      => Sa_Par_Market_Type'access,
       Long_Switch => "--market_type=",
       Help        => "WIN or PLACE");
       
       
    Getopt (Config);  -- process the command line

    if Sa_Par_Start_Date.all = "" or else
      Sa_Par_Market_Type.all = "" or else
      Sa_Par_Stop_Date.all = "" then
      Display_Help (Config);
      return;
    end if;

    Start_Date := Calendar2.To_Time_Type (Sa_Par_Start_Date.all, "00:00:00:000");
    Stop_Date  := Calendar2.To_Time_Type (Sa_Par_Stop_Date.all, "23:59:59:999");
--   Start_Date := Start_Date - Calendar2.Interval_Type'(1,0,0,0,0); --remove a day first
--   Stop_Date  := Stop_Date  - Calendar2.Interval_Type'(1,0,0,0,0); --remove a day first


    Log ("params: " & 
         "start_date=" &  Calendar2.String_Date_And_Time(Start_Date) & " " &
         "stop_date=" &  Calendar2.String_Date_And_Time(Stop_Date) & " " &
         "max_odds=" & Ia_Max_Odds'Img & " " &
         "min_odds=" & Ia_Min_Odds'Img );


    Log ("Connect db");
    Sql.Connect
     (Host     => "localhost",
      Port     => 5432,
      Db_Name  => "nono",
      Login    => "bnl",
      Password => "bnl");

      
    T.Start;

--    Select_Markets_In_A_Day.Prepare (
--          "select P.* " &
--          "from AMARKETS M, AEVENTS E, APRICES P " &
--          "where M.STARTTS >= :START " &
--          "and M.STARTTS <= :STOP " &
--          "and M.EVENTID = E.EVENTID " &
--          "and M.MARKETID = P.MARKETID " &
--          "and P.LAYPRICE >= :MIN_ODDS " &
--          "and P.LAYPRICE <= :MAX_ODDS " &
--          "and M.MARKETTYPE = 'WIN' " &
--          "and M.NUMRUNNERS >= 10 " &
--          "and E.EVENTTYPEID = 7 " &
--          "and E.COUNTRYCODE in ('GB','IE') " &
--          "order by M.STARTTS, M.MARKETID");
--    Select_Markets_In_A_Day.Set("MIN_ODDS", Integer_4(Ia_Min_Odds));
--    Select_Markets_In_A_Day.Set("MAX_ODDS", Integer_4(Ia_Max_Odds));
--    Select_Markets_In_A_Day.Set_Timestamp("START", Start_date);
--    Select_Markets_In_A_Day.Set_Timestamp("STOP",  Stop_date);

    Select_Day.Prepare (
          "select distinct(M.STARTTS::date) " &
          "from AMARKETS M, AEVENTS E " &
          "where M.STARTTS >= :START " &
          "and M.STARTTS <= :STOP " &
          "and M.EVENTID = E.EVENTID " &
          "and M.MARKETTYPE = :MARKET_TYPE " &
--          "and M.NUMRUNNERS >= 10 " &
          "and E.EVENTTYPEID = 7 " &
          "and E.COUNTRYCODE in ('GB','IE') " &
          "order by M.STARTTS::date");
          
    Select_Day.Set_Timestamp("START", Start_date);
    Select_Day.Set_Timestamp("STOP",  Stop_date);
    Select_Day.Set("MARKET_TYPE",  Sa_Par_Market_Type.all );
    
    
    Select_Day.Open_Cursor;
    loop
      Select_Day.Fetch(Eos);
      exit when Eos;
      Select_Day.Get_Date(1, Some_Day);
      Some_Day.Hour := 0;
      Some_Day.Minute := 0;
      Some_Day.Second := 0;
      Some_Day.Millisecond := 0;
      Day_List.Insert_At_Tail(Some_Day);
    end loop;    
    Select_Day.Close_Cursor;
   
    Loop_Day :  while not Day_List.Is_Empty loop
      Day_List.Remove_From_Head(Some_Day);
      Daily_Profit := 0.0;

      Select_Markets_In_A_Day.Prepare (
            "select M.* " &
            "from AMARKETS M, AEVENTS E " &
            "where M.STARTTS >= :START " &
            "and M.STARTTS <= :STOP " &
            "and M.EVENTID = E.EVENTID " &
            "and M.MARKETTYPE = :MARKET_TYPE " &
--            "and M.NUMRUNNERS >=  " &
            "and E.EVENTTYPEID = 7 " &
            "and E.COUNTRYCODE in ('GB','IE') " &
            "order by M.STARTTS, M.MARKETID");
            
      Select_Markets_In_A_Day.Set("MARKET_TYPE",  Sa_Par_Market_Type.all );
      Select_Markets_In_A_Day.Set_Timestamp("START", Some_Day);
      Some_Day.Hour := 23;
      Some_Day.Minute := 59;
      Some_Day.Second := 59;
      Some_Day.Millisecond := 999;
      Select_Markets_In_A_Day.Set_Timestamp("STOP",  Some_Day);
  
  --      Text_IO.Put_Line(Text_IO.Standard_Error,"--------------------------");
  
      Table_Amarkets.Read_List(Select_Markets_In_A_Day,Market_List);
  
      Loop_Markets_In_A_Day : while not Market_List.Is_Empty loop
        Market_List.Remove_From_Head(Market);
        Market_Profit := 0.0;
        Price := Table_Aprices.Empty_Data;
        Price.Marketid := Market.Marketid;
        Price.Read_I1_Marketid(List => Price_List, Order => True);
        
        Loop_Market : while not Price_List.Is_Empty loop
          Price_List.Remove_From_Head(Price);
        
          Runner := Table_Arunners.Empty_Data;
          Runner.Marketid    := Price.Marketid;
          Runner.Selectionid := Price.Selectionid;
          Table_Arunners.Read(Runner, Eos);
          if Eos then
            raise Bad_Data with "eos on runner " & Table_Arunners.To_String(Runner);
          else
            if Integer(Price.Layprice) < Ia_Min_Odds or 
               Integer(Price.Layprice) > Ia_Max_Odds then
              Outcome := No_Bet_Laid;
            elsif Integer(Market.Numrunners) < IA_Min_Num_Runners then
              Outcome := No_Bet_Laid;              
            elsif Integer(Daily_Profit) < IA_Max_Daily_Loss then
              Outcome := No_Bet_Laid;              
            elsif Runner.Status(1..6) = "WINNER" then
              Outcome := Laybet_Lost;
            elsif Runner.Status(1..5) = "LOSER" then
              Outcome := Laybet_Won;
            else
              Outcome := No_Bet_Laid;          
            end if;
          end if;
       
          case Outcome is
             when No_Bet_Laid => Profit := 0.0;
             when Laybet_Won  => Profit := Lay_Size;
             when Laybet_Lost => Profit := - Lay_Size * (Price.Layprice -1.0)  ;
          end case;
          
          Market_Profit := Market_Profit + Profit;
          
          Stats(Outcome).Hits := Stats(Outcome).Hits + 1;
          Stats(Outcome).Profit := Stats(Outcome).Profit + Profit;
       
        end loop Loop_Market;
        
        if Market_Profit > 0.0 then
          Market_Profit := Market_Profit * 0.935;
        end if;  
        
        Text_IO.Put_Line("Market " & Market.Marketid & " | " &
                         F8_Image(Market_Profit) );
        
        Daily_Profit := Daily_Profit + Market_Profit; 
      end loop Loop_Markets_In_A_Day;
        
      Text_IO.Put_Line("Day " & Calendar2.String_Date(Some_Day) & " | " &
                                F8_Image(Daily_Profit) );
  
      
      Total_Profit := Total_Profit + Daily_Profit;
      
    end loop Loop_Day  ;
    T.Commit ;

   Sql.Close_Session;

   for i in Outcome_Type'range loop
     Log(i'Img & " hits " & Stats(i).Hits'Img & " profit " & Integer_4(Stats(i).Profit)'Img);
   end loop;
   Log("Total profit = " & Integer_4(Total_Profit)'Img);
exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Lay_All_G4;
