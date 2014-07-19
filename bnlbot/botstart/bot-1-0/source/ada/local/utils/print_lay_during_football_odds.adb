
with Types ; use Types;
with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
with Text_Io;
--with Table_Araceprices;
with Table_Arunners;
with Table_Amarkets;
--with Gnat.Command_Line; use Gnat.Command_Line;
--with GNAT.Strings;
with Calendar2;  use Calendar2;
with Logging; use Logging;
--with General_Routines; use General_Routines;
with Runners;
--with Simple_List_Class;
--pragma Elaborate_All(Simple_List_Class);

procedure Print_Lay_During_Football_Odds is

   
   type Runners_Type_Type is (Home,  Away, Draw);
   subtype Betted_On_Type is Runners_Type_Type range Home .. Away;
   Betted_On : Betted_On_Type := Home;
   Winner : Runners_Type_Type := Home;
   

   
   The_Runners : array(Runners_Type_Type'range) of Runners.Runners_Type;

--    Bad_Input : exception;

   type H_Type is record
     Marketid    : Market_Id_Type := (others => ' ');
     Selectionid : Integer_4 := 0;
   end record;

   Data : H_Type;

   T            : Sql.Transaction_Type;
   Select_All_Markets,
   Select_Race_Runners_In_One_Market,
   Select_Prices_For_All_Runners_In_One_Market : Sql.Statement_Type;

   Eos,
   Eos2,
   Eos3      : Boolean := False;

   Market : Table_Amarkets.Data_Type;
   
   type Bet_Status_Type is (Bet_Laid, No_Bet_Laid);
   Bet_Status : Bet_Status_Type := No_Bet_Laid;
   Back_Odds_Used : Float_8 := 0.0;

--   Config           : Command_Line_Configuration;

--   Is_For_Plot : aliased Boolean := False;
--   Ia_Other_Team_Min_Back_Odds : aliased Integer := 18;
--   Ia_Draw_Min_Back_Odds : aliased Integer := 4;
--   IA_Min_Minutes_Into_Game : aliased Integer;
--   SA_Back_At_Price         : aliased Gnat.Strings.String_Access;


   Max_Global_Back_At_Price           : Float_8 := 2.5;
   Min_Global_Back_At_Price           : Float_8 := 1.2;

   Upper_Bound_Green_Up : Float_8 := 10.0;
   Lower_Bound_Green_Up : Float_8 := 4.0; --Upper_Bound_Green_Up - 1.0;
   
   Global_Back_Size               : Float_8 := 100.0;
   
   F : Text_Io.File_Type;
   Path : constant String := "/home/bnl/bnlbot/botstart/bot-1-0/script/plot/lay_football/match_odds";
   
   Game_Start,
   Current_Game_Time : Calendar2.Time_Type := Calendar2.Time_Type_First; 
   
   A_Bet_Laid : Float_8 := 0.0;
   
   
   type Stats_Type is record
     Hits : Integer_4 := 0;
     Profit : Float_8 := 0.0;
   end record ;
   Profit, Global_Profit : Float_8 := 0.0;
   Stats : array (Bet_Status_Type'range) of Stats_Type;
   
   
 ---------------
begin


--  Log ("Connect db");
  Sql.Connect
    (Host     => "localhost",
     Port     => 5432,
     Db_Name  => "nono",
     Login    => "bnl",
     Password => "bnl");
--  Log ("Connected to db");

  T.Start;
  -- we need order by startts for plots
  Select_All_Markets.Prepare (
      "select M1.MARKETID from AMARKETS M1 " &
      "where M1.MARKETID in ( " &
        "select distinct(RP.MARKETID) " & 
        "from ARACEPRICES RP, AMARKETS M2 " & 
        "where M2.MARKETID = RP.MARKETID " & 
        "and M2.MARKETTYPE = 'MATCH_ODDS' " & 
      ") " &
      "and M1.TOTALMATCHED >= 100000 " &
      "order by M1.STARTTS " );
                      
  Select_Race_Runners_In_One_Market.Prepare( "select * " &
        "from ARUNNERS " &
        "where MARKETID = :MARKETID " &
        "and STATUS <> 'REMOVED' "  &
        "order by SORTPRIO" ) ;

  Select_Prices_For_All_Runners_In_One_Market.Prepare( 
        "select " &
          "RP_DRAW.PRICETS," &
          "RP_DRAW.MARKETID," &
          "R_HOME.RUNNERNAME homename," &
          "R_HOME.STATUS homestatus," &
          "RP_HOME.BACKPRICE homeback," &
          "RP_HOME.LAYPRICE homelay," &
          "R_DRAW.RUNNERNAME drawname," &
          "R_DRAW.STATUS drawstatus," &
          "RP_DRAW.BACKPRICE drawback," &
          "RP_DRAW.LAYPRICE drawlay," &
          "R_AWAY.RUNNERNAME awayname," &
          "R_AWAY.STATUS awaystatus," &
          "RP_AWAY.BACKPRICE awayback," &
          "RP_AWAY.LAYPRICE awaylay " &
        "from " &
          "ARACEPRICES RP_HOME, ARUNNERS R_HOME, " &
          "ARACEPRICES RP_DRAW, ARUNNERS R_DRAW, " &
          "ARACEPRICES RP_AWAY, ARUNNERS R_AWAY, " &
          "AMARKETS M, AEVENTS E " &
        "where RP_DRAW.MARKETID = :MARKETID " &
        "and M.MARKETID = RP_DRAW.MARKETID " &
        "and M.EVENTID = E.EVENTID " &
--        "and E.COUNTRYCODE in ('GB','DE') " &
        "and R_DRAW.MARKETID = RP_DRAW.MARKETID " &
        "and R_DRAW.SELECTIONID = RP_DRAW.SELECTIONID " &
        "and R_DRAW.SELECTIONID = :DRAW_SELECTIONID " &
        "and RP_HOME.MARKETID = RP_DRAW.MARKETID " &
        "and R_HOME.MARKETID = RP_HOME.MARKETID " &
        "and R_HOME.SELECTIONID = RP_HOME.SELECTIONID " &
        "and R_HOME.SELECTIONID = :HOME_SELECTIONID " &
        "and RP_AWAY.MARKETID = RP_DRAW.MARKETID " &
        "and R_AWAY.MARKETID = RP_AWAY.MARKETID " &
        "and R_AWAY.SELECTIONID = RP_AWAY.SELECTIONID " &
        "and R_AWAY.SELECTIONID = :AWAY_SELECTIONID " &
        "and RP_DRAW.PRICETS = RP_HOME.PRICETS " &
        "and RP_DRAW.PRICETS = RP_AWAY.PRICETS " &
        "order by RP_DRAW.PRICETS" );

  Select_All_Markets.Open_Cursor;
  
  Select_All_Markets_Loop : loop
    Select_All_Markets.Fetch(Eos);
    exit Select_All_Markets_Loop when Eos;
    Select_All_Markets.Get("MARKETID", Data.Marketid); -- Get a new market
--    Log("|Start market|" & Data.Marketid);      

--    Cnt := 0; --reset
    Market.Marketid := Data.Marketid;
    
    Market.Read(Eos);
    if Eos then  
      Log("| " & Market.Marketid & " |NOT FOUND !");
    end if;
    
    -- get the runners and thir selection ids
    Eos2 := False;
    Select_Race_Runners_In_One_Market.Set("MARKETID", Data.Marketid);
    Select_Race_Runners_In_One_Market.Open_Cursor;
    declare
      i : Runners_Type_Type := Runners_Type_Type'First;
    begin  
      loop
        Select_Race_Runners_In_One_Market.Fetch(Eos2);
        exit when Eos2;
        The_Runners(i).Runner := Table_Arunners.Get(Select_Race_Runners_In_One_Market);
        --Log("Runners(" & i'Img & ").Runner" & The_Runners(i).Runner.To_String);
        if i /=  Runners_Type_Type'last then
          i := Runners_Type_Type'Succ(I);
        end if;  
      end loop;
    end ;
    Select_Race_Runners_In_One_Market.Close_Cursor;
    if not Eos then          -- Must find market
      Select_Prices_For_All_Runners_In_One_Market.Set("MARKETID", Data.Marketid);
      Select_Prices_For_All_Runners_In_One_Market.Set("HOME_SELECTIONID", The_Runners(Home).Runner.Selectionid);
      Select_Prices_For_All_Runners_In_One_Market.Set("AWAY_SELECTIONID", The_Runners(Away).Runner.Selectionid);
      Select_Prices_For_All_Runners_In_One_Market.Set("DRAW_SELECTIONID", The_Runners(Draw).Runner.Selectionid);
      Select_Prices_For_All_Runners_In_One_Market.Open_Cursor; 
      
      Text_Io.Create(File => F, Name => Path & "/" & Data.Marketid & ".dat");
      Bet_Status := No_Bet_Laid;
      Game_Start := Calendar2.Time_Type_First;
      Back_Odds_Used := 0.0;
      
      Game_Loop : loop -- get a new market/odds combo
        Select_Prices_For_All_Runners_In_One_Market.Fetch(Eos3);         
        exit Game_Loop when Eos3;
        Select_Prices_For_All_Runners_In_One_Market.Get_Timestamp("PRICETS", Current_Game_Time);
        
        Select_Prices_For_All_Runners_In_One_Market.Get("HOMEBACK", The_Runners(Home).Back_Price);
        Select_Prices_For_All_Runners_In_One_Market.Get("HOMELAY",  The_Runners(Home).Lay_Price);
        
        Select_Prices_For_All_Runners_In_One_Market.Get("AWAYBACK", The_Runners(Away).Back_Price);
        Select_Prices_For_All_Runners_In_One_Market.Get("AWAYLAY",  The_Runners(Away).Lay_Price);
        
        Select_Prices_For_All_Runners_In_One_Market.Get("DRAWBACK", The_Runners(Draw).Back_Price);
        Select_Prices_For_All_Runners_In_One_Market.Get("DRAWLAY",  The_Runners(Draw).Lay_Price);
        
        for i in Runners_Type_Type'range loop
          The_Runners(i).Fix_Average(Current_Game_Time);
        end loop;
        
        
        if Game_Start = Calendar2.Time_Type_First then 
          Game_Start := Current_Game_Time;          
        end if;      
        
        case Bet_Status is 
          when No_Bet_Laid =>
          
            if    Current_Game_Time - Game_Start > (0,0,10,0,0) and then
                  Current_Game_Time - Game_Start < (0,1,50,0,0) and then
                  The_Runners(Home).Lay_Price >= 0.0 and then
                  The_Runners(Home).Back_Price >= 1.0 and then
                  Min_Global_Back_At_Price <= The_Runners(Home).A_Back and then  
                  The_Runners(Home).A_Back <= Max_Global_Back_At_Price and then  
                  
                  The_Runners(Home).K_Back <= Float_8(0.0) and then  -- straight or descending slope
                  The_Runners(Home).K_Back_Avg <= Float_8(0.0) and then  -- for a while too
                  
                  The_Runners(Away).A_Back >= Upper_Bound_Green_Up and then
                  The_Runners(Draw).A_Back >= Lower_Bound_Green_Up then
                  
--                  The_Runners(Home).A_Back / The_Runners(Home).A_Lay >= 0.9 then  
                  
              Bet_Status := Bet_Laid;
              A_Bet_Laid := Upper_Bound_Green_Up; -- to point out where it is 
              Betted_On := Home;
              Back_Odds_Used := The_Runners(Home).Back_Price;
              
            elsif Current_Game_Time - Game_Start > (0,0,10,0,0) and then
                  Current_Game_Time - Game_Start < (0,1,50,0,0) and then
                  The_Runners(Away).Lay_Price >= 0.0 and then
                  The_Runners(Away).Back_Price >= 1.0 and then
                  Min_Global_Back_At_Price <= The_Runners(Away).A_Back and then  
                  The_Runners(Away).A_Back <= Max_Global_Back_At_Price and then  
                  
                  The_Runners(Away).K_Back <= Float_8(0.0) and then  -- straight or descending slope
                  The_Runners(Away).K_Back_Avg <= Float_8(0.0) and then  -- for a while too
                                   
                  The_Runners(Home).A_Back >= Upper_Bound_Green_Up and then
                  The_Runners(Draw).A_Back >= Lower_Bound_Green_Up then
                  
--                  The_Runners(Home).A_Back / The_Runners(Home).A_Lay >= 0.9 then  
                  
              Bet_Status := Bet_Laid;
              A_Bet_Laid := Upper_Bound_Green_Up; -- to point out where it is 
              Betted_On :=  Away;
              Back_Odds_Used := The_Runners(Away).Back_Price;
          
--            if    Current_Game_Time - Game_Start > (0,1,20,0,0) and then 
--                  Current_Game_Time - Game_Start < (0,1,40,0,0) and then
--                  The_Runners(Away).A_Back > Float_8(Ia_Other_Team_Min_Back_Odds) and then
--                  The_Runners(Draw).A_Back > Float_8(Ia_Draw_Min_Back_Odds) and then
--                  
--                  The_Runners(Home).Back_Price >= 1.0 and then
--                  The_Runners(Home).A_Back <= Global_Back_At_Price then  
--              Bet_Status := Bet_Laid;
--              A_Bet_Laid := Upper_Bound_Green_Up;
--              
--            elsif Current_Game_Time - Game_Start > (0,1,20,0,0) and then 
--                  Current_Game_Time - Game_Start < (0,1,40,0,0) and then
--                  The_Runners(Home).A_Back > Float_8(Ia_Other_Team_Min_Back_Odds) and then
--                  The_Runners(Draw).A_Back > Float_8(Ia_Draw_Min_Back_Odds) and then
--                  
--                  The_Runners(Away).Back_Price >= 1.0 and then
--                  The_Runners(Away).A_Back <= Global_Back_At_Price then  
--              Bet_Status := Bet_Laid;
--              A_Bet_Laid := Upper_Bound_Green_Up;
--    --        elsif Current_Game_Time - Game_Start > (0,1,20,0,0) and then 
--    --              Current_Game_Time - Game_Start < (0,1,40,0,0) and then
--    --              The_Runners(Home).A_Back > Float_8(Ia_Other_Team_Min_Back_Odds) and then
--    --              The_Runners(Away).A_Back > Float_8(Ia_Draw_Min_Back_Odds) and then
--    --              
--    --              The_Runners(Draw).Back_Price >= 1.0 and then
--    --              The_Runners(Draw).A_Back <= Global_Back_At_Price then  
--    --          Bet_Status := Bet_Laid;
--    --          A_Bet_Laid := Upper_Bound_Green_Up;
            end if;
          when Bet_Laid => null;
        end case;
        
        Text_Io.Put_Line(File => F, Item =>
--            Current_Game_Time.To_String        & "|" & 
            Calendar2.String_Interval(Interval      => (Current_Game_Time - Game_Start), 
                                               Days         => False,
                                               Milliseconds => False
                                               ) & "|" & 
            F8_Image(The_Runners(Home).Back_Price) & "|" & 
            F8_Image(The_Runners(Home).Lay_Price)  & "|" & 
            F8_Image(The_Runners(Home).A_Back)     & "|" & 
            F8_Image(The_Runners(Home).A_Lay)      & "|" & 
            
            F8_Image(The_Runners(Draw).Back_Price) & "|" & 
            F8_Image(The_Runners(Draw).Lay_Price)  & "|" & 
            F8_Image(The_Runners(Draw).A_Back)     & "|" & 
            F8_Image(The_Runners(Draw).A_Lay)      & "|" & 
                        
            F8_Image(The_Runners(Away).Back_Price) & "|" & 
            F8_Image(The_Runners(Away).Lay_Price)  & "|" &        
            F8_Image(The_Runners(Away).A_Back)     & "|" & 
            F8_Image(The_Runners(Away).A_Lay)      & "|" & 
            
            F8_Image(A_Bet_Laid)               & "|" & 
            F8_Image(Lower_Bound_Green_Up)     & "|" & 
            F8_Image(Upper_Bound_Green_Up)  
        );
        
        case  Bet_Status is
          when Bet_Laid    => A_Bet_Laid := 0.0;
          when No_Bet_Laid => null;
        end case;  

      end loop Game_Loop;
      
      Text_Io.Put(File => F, Item => "winner=");
      for i in Runners_Type_Type'range loop
        if The_Runners(i).Runner.Status(1..6) = "WINNER" then 
          Winner := i;
          case i is 
            when Home => Text_Io.Put(File => F, Item => "green");
            when Draw => Text_Io.Put(File => F, Item => "orange");
            when Away => Text_Io.Put(File => F, Item => "red");
          end case;
        end if;
      end loop;
      Text_Io.Put(File => F, Item => " betted-on=");
      case Betted_On is 
        when Home => Text_Io.Put(File => F, Item => "green");
        when Away => Text_Io.Put(File => F, Item => "red");
      end case;
      Text_Io.Put(File => F, Item => " bet-won=" & Boolean'image(Winner=Betted_On) );
      Text_Io.Put(File => F, Item => " used-odds=" & F8_image(Back_Odds_Used) );
     
--      Text_Io.Close (File => F);
      case  Bet_Status is
        when Bet_Laid    => Text_Io.Close (File => F);
        when No_Bet_Laid => Text_Io.Delete(File => F);
      end case;  
      
      case  Bet_Status is
        when Bet_Laid    => 
        if Winner = Betted_On then
          -- Good
           Profit := 0.935 * ( Back_Odds_Used - 1.0) * Global_Back_Size;
        else 
          -- bad
           Profit := -Global_Back_Size;
        end if;          
        when No_Bet_Laid => 
          Profit := 0.0;
      end case;  
      Stats(Bet_Status).Hits := Stats(Bet_Status).Hits + 1;
      Stats(Bet_Status).Profit := Stats(Bet_Status).Profit + Profit;
      
      Global_Profit := Global_Profit + Profit;
      Log("profit for market: " &  Data.Marketid &  Integer_4(Profit)'Img & Integer_4(Global_Profit)'Img);
      
      
      
      Select_Prices_For_All_Runners_In_One_Market.Close_Cursor; 
    end if;  
  end loop Select_All_Markets_Loop;
  Select_All_Markets.Close_Cursor;
  T.Commit ;

  Sql.Close_Session;
  Log("Total profit = " & Integer_4(Global_Profit)'Img);
  for i in Bet_Status_Type'range loop
    Log(i'Img & Stats(i).Hits'Img & Integer_4(Stats(i).Profit)'Img);
  end loop;
  
exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Print_Lay_During_Football_Odds;
