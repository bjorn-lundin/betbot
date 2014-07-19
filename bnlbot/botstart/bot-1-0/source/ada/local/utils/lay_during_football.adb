
with Types ; use Types;
with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
--with Text_Io;
with Table_Araceprices;
with Table_Arunners;
with Table_Amarkets;
with Table_Aevents;
--with Gnat.Command_Line; use Gnat.Command_Line;
--with GNAT.Strings;
with Calendar2;  use Calendar2;
with Logging; use Logging;
--with General_Routines; use General_Routines;

--with Simple_List_Class;
--pragma Elaborate_All(Simple_List_Class);

procedure Lay_During_Football is

   Prices : Table_Araceprices.Data_Type;
   Runner : Table_Arunners.Data_Type;
   
   type Runners_Type_Type is (Home,  Away, Draw);
   
   type V_Back_Type is array(1..5) of Float_8 ;
   
   type Runners_Type is record
     Runner :  Table_Arunners.Data_Type;
     Back_Price : Float_8:= 0.0;
     Lay_Price  : Float_8:= 0.0;
     V_Back     : V_Back_Type := (others => 0.0);
     A_Back     : Float_8 := 0.0;
     V_Lay      : V_Back_Type := (others => 0.0);
     A_Lay      : Float_8 := 0.0;
     A2_Back    : Float_8 := 0.0;
     A2_Lay     : Float_8 := 0.0;
   end record;
   
   Runners : array(Runners_Type_Type'range) of Runners_Type;

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

--   Config           : Command_Line_Configuration;

   Is_For_Plot : aliased Boolean := False;
--   Ia_Other_Team_Min_Back_Odds : aliased Integer;
 --  Ia_Draw_Min_Back_Odds : aliased Integer;
 --  IA_Min_Minutes_Into_Game : aliased Integer;
 --  SA_Back_At_Price         : aliased Gnat.Strings.String_Access;
--   SA_Lay_At_Price          : aliased Gnat.Strings.String_Access; 

   Global_Back_At_Price           : Float_8 := 2.50;
   Global_Back_At_Price2          : Float_8 := 3.0;


   Global_Back_Price              : Float_8 :=   0.0;
   Global_Back_Size               : Float_8 := 100.0;
   Global_Lay_Size                : Float_8 :=  30.0;
--   Global_Lay_Price              : Float_8 :=  0.0;

   Income, Stake: Float_8 := 0.0;

   type Bet_Status_Type is (Bet_Laid, Bad_Bet, Back_Bet_Won, Lay_Bet_Won, Back_Bet_Lost, Lay_Bet_Lost, No_Bet_Laid);
   Bet_Status : Bet_Status_Type := No_Bet_Laid;

   type Stats_Type is record
     Hits : Integer_4 := 0;
     Profit : Float_8 := 0.0;
   end record ;
   Profit, Global_Profit : Float_8 := 0.0;

--   OK_Starting_Price : Boolean := False;
--   First_Loop        : Boolean := True;

   Stats : array (Bet_Status_Type'range) of Stats_Type;
--   Cnt : Integer_4 := 0;
   
   Current_Game_Time, 
   Game_Start : Calendar2.Time_Type := Calendar2.Time_Type_First; 

------------------------------------------------------------------
   procedure Fix_Average(R : in out Runners_Type ) is
   begin
     R.A2_Back := R.A_Back;
     R.A2_Lay  := R.A_Lay;
          
     R.V_Back(5) := R.V_Back(4); 
     R.V_Back(4) := R.V_Back(3); 
     R.V_Back(3) := R.V_Back(2); 
     R.V_Back(2) := R.V_Back(1); 
     R.V_Back(1) := R.Back_Price; 
     
     R.A_Back := 0.0;
     for i in R.V_Back'range loop
       R.A_Back := R.A_Back + R.V_Back(i);
     end loop;
     R.A_Back := R.A_Back / Float_8(R.V_Back'Length);  

     R.V_Lay(5) := R.V_Lay(4); 
     R.V_Lay(4) := R.V_Lay(3); 
     R.V_Lay(3) := R.V_Lay(2); 
     R.V_Lay(2) := R.V_Lay(1); 
     R.V_Lay(1) := R.Lay_Price; 
     
     R.A_Lay := 0.0;
     for i in R.V_Lay'range loop
       R.A_Lay := R.A_Lay + R.V_Lay(i);
     end loop;
     R.A_Lay := R.A_Lay / Float_8(R.V_Lay'Length);  
     
   end Fix_Average;

------------------------------------------------------------------   
--   function To_String(R : Runners_Type ) return String is
--   begin
--     return Table_Arunners.To_String(R.Runner) & " " &
--     "Back_Price = " & F8_Image(R.Back_Price) & " " &
--     "Lay_Price = " & F8_Image(R.Lay_Price) & " " &
--     "A_Back = " & F8_Image(R.A_Back) & " " &
--     "V_Back = " & F8_Image(R.V_Back(1)) & "," &
--                   F8_Image(R.V_Back(2)) & "," &
--                   F8_Image(R.V_Back(3)) & "," & 
--                   F8_Image(R.V_Back(4)) & "," & 
--                   F8_Image(R.V_Back(5));     
--   end To_String;
begin
--  Define_Switch
--    (Config      => Config,
--     Output      => Is_For_Plot'access,
--     Long_Switch => "--plot",
--     Help        => "Minimizes debug output ");
--     
--  Define_Switch
--    (Config      => Config,
--     Output      => Ia_Min_Minutes_Into_Game'access,
--     Long_Switch => "--min_minutes=",
--     Help        => "Min minutes into game ");
--
--  Define_Switch
--    (Config      => Config,
--     Output      => Ia_Other_Team_Min_Back_Odds'access,
--     Long_Switch => "--other_min_back=",
--     Help        => "Min odds for other team at back time ");
--     
--  Define_Switch
--    (Config      => Config,
--     Output      => Ia_Draw_Min_Back_Odds'access,
--     Long_Switch => "--draw_min_back=",
--     Help        => "Min odds for draw at back time ");
--     
--  Define_Switch
--    (Config      => Config,
--     Output      => Sa_Back_At_Price'access,
--     Long_Switch => "--back_at_price=",
--     Help        => "Back the runner at this price(Back)");
--
--  Define_Switch
--    (Config      => Config,
--     Output      => IA_Max_Lay_Price'access,
--     Long_Switch => "--max_lay_price=",
--     Help        => "Runner cannot have higer price that this when layed (Lay)");

--  Getopt (Config);  -- process the command line
--
--     if Ia_Other_Team_Min_Back_Odds = 0 or else
--       Ia_Draw_Min_Back_Odds = 0 or else
--       Sa_Back_At_Price.all = "" then
--       Display_Help (Config);
--       return;
--     end if;

--  Global_Back_At_Price := Float_8'Value(SA_Back_At_Price.all);

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
      "order by M1.STARTTS " );
  
--  Select_All_Markets.Prepare ("select distinct(RP.MARKETID) " &
--                      "from ARACEPRICES RP, AMARKETS M " &
--                      "where M.MARKETID = RP.MARKETID " &
--                      "and M.MARKETTYPE = 'MATCH_ODDS' " &
--                      "order by RP.MARKETID");
                      
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
        "and M.TOTALMATCHED >= 100000 " &
        "order by RP_DRAW.PRICETS" );

  Select_All_Markets.Open_Cursor;
  
  Select_All_Markets_Loop : loop
    Select_All_Markets.Fetch(Eos);
    exit Select_All_Markets_Loop when Eos;
    Select_All_Markets.Get("MARKETID", Data.Marketid); -- Get a new market
--    Log("|Start market|" & Data.Marketid);      

--    Cnt := 0; --reset
    Runner := Table_Arunners.Empty_Data;
    Market.Marketid := Data.Marketid;
    
    Table_Amarkets.Read(Market, Eos);
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
        Runners(i).Runner := Table_Arunners.Get(Select_Race_Runners_In_One_Market);
--        Log("Runners(" & i'Img & ").Runner" & Table_Arunners.To_String(Runners(i).Runner));
        if i /=  Runners_Type_Type'last then
          i := Runners_Type_Type'Succ(I);
        end if;  
      end loop;
    end ;
    Select_Race_Runners_In_One_Market.Close_Cursor;
--    return;  
    if not Eos then          -- Must find market
      Select_Prices_For_All_Runners_In_One_Market.Set("MARKETID", Data.Marketid);
      Select_Prices_For_All_Runners_In_One_Market.Set("HOME_SELECTIONID", Runners(Home).Runner.Selectionid);
      Select_Prices_For_All_Runners_In_One_Market.Set("AWAY_SELECTIONID", Runners(Away).Runner.Selectionid);
      Select_Prices_For_All_Runners_In_One_Market.Set("DRAW_SELECTIONID", Runners(Draw).Runner.Selectionid);
      Select_Prices_For_All_Runners_In_One_Market.Open_Cursor; 
      
      Bet_Status := No_Bet_Laid;
      Game_Start := Calendar2.Time_Type_First;
      
      Game_Loop : loop -- get a new market/odds combo
        Select_Prices_For_All_Runners_In_One_Market.Fetch(Eos3);         
        exit Game_Loop when Eos3;
--        Cnt := Cnt +1;
        
        Select_Prices_For_All_Runners_In_One_Market.Get("HOMEBACK", Runners(Home).Back_Price);
        Select_Prices_For_All_Runners_In_One_Market.Get("HOMELAY",  Runners(Home).Lay_Price);
        Fix_Average(Runners(Home));
        
        Select_Prices_For_All_Runners_In_One_Market.Get("AWAYBACK", Runners(Away).Back_Price);
        Select_Prices_For_All_Runners_In_One_Market.Get("AWAYLAY",  Runners(Away).Lay_Price);
        Fix_Average(Runners(Away));
        
        Select_Prices_For_All_Runners_In_One_Market.Get("DRAWBACK", Runners(Draw).Back_Price);
        Select_Prices_For_All_Runners_In_One_Market.Get("DRAWLAY",  Runners(Draw).Lay_Price);
        Fix_Average(Runners(Draw));
        
        Select_Prices_For_All_Runners_In_One_Market.Get_Timestamp("PRICETS", Current_Game_Time);
        if Game_Start = Calendar2.Time_Type_First then 
          Game_Start := Current_Game_Time;
        end if;      
        
        if     Current_Game_Time - Game_Start > (0,0,10,0,0) and then
               Runners(Home).Lay_Price >= 0.0 and then
               Runners(Home).Back_Price >= 1.0 and then
               Global_Back_At_Price -0.1 <= Runners(Home).A_Back and then  
               Runners(Home).A_Back <= Global_Back_At_Price + Float_8(0.1) and then  
               
               Global_Back_At_Price2 -0.2 <= Runners(Home).A2_Back and then  
               Runners(Home).A2_Back <= Global_Back_At_Price2 + Float_8(0.2) and then  
               
               Runners(Home).A_Back / Runners(Home).A_Lay >= 0.9 then  
                  
          Bet_Status := Bet_Laid;
          Runner := Runners(Home).Runner;
          Global_Back_Price :=  Runners(Home).Back_Price;          
          exit Game_Loop;
        elsif Current_Game_Time - Game_Start > (0,0,10,0,0) and then
                  Runners(Away).Lay_Price >= 0.0 and then
                  Runners(Away).Back_Price >= 1.0 and then
                  Global_Back_At_Price -0.1 <= Runners(Away).A_Back and then  
                  Runners(Away).A_Back <= Global_Back_At_Price + Float_8(0.1) and then  
                  
                  Global_Back_At_Price2 -0.2 <= Runners(Away).A2_Back and then  
                  Runners(Away).A2_Back <= Global_Back_At_Price2 + Float_8(0.2) and then  
                  
                  Runners(Away).A_Back / Runners(Away).A_Lay >= 0.9 then    
          Bet_Status := Bet_Laid;
          Runner := Runners(Away).Runner;         
          Global_Back_Price :=  Runners(Away).Back_Price;
          exit Game_Loop;
--        elsif Current_Game_Time - Game_Start > (0,1,20,0,0) and then 
--              Current_Game_Time - Game_Start < (0,1,40,0,0) and then
--              Runners(Home).A_Back > Float_8(Ia_Other_Team_Min_Back_Odds) and then
--              Runners(Away).A_Back > Float_8(Ia_Draw_Min_Back_Odds) and then
--              
--              Runners(Draw).Back_Price >= 1.0 and then
--              Runners(Draw).A_Back <= Global_Back_At_Price then  
--          Bet_Status := Bet_Laid;
--          Runner := Runners(Draw).Runner;         
--          Global_Back_Price :=  Runners(Draw).Back_Price;
--          exit Game_Loop;
        end if;
        -------------------------------------------------      
      end loop Game_Loop;
     
      
      if Bet_Status = Bet_Laid then
        if not Eos then
          if Runner.Status(1..6) = "WINNER" then
            Bet_Status := Back_Bet_Won;
          elsif Runner.Status(1..5) = "LOSER" then
            Bet_Status := Back_Bet_Lost;
          else
            Bet_Status := Bad_Bet;
           -- Log("CHANGE_1-BET_NOT_LAID: " & Table_Araceprices.To_String(Prices));
          end if;
        else
          Bet_Status := Bad_Bet;
          -- Log("CHANGE_2-BET_NOT_LAID: " & Table_Araceprices.To_String(Prices));
        end if;
      end if;
      
      case Bet_Status is
         when Bet_Laid | No_Bet_Laid| Bad_Bet  =>    -- no bet at all
           Income := 0.0;
           Stake  := 0.0;
           Profit := 0.0;
           
         when Back_Bet_Won =>  -- A winning back bet
           Income := 0.935 * ( Global_Back_Price - 1.0) * Global_Back_Size;
           Stake  := 0.0;
           Profit := Income;
         when Back_Bet_Lost =>  -- A losing back bet
           Income := 0.0;
           Stake  := Global_Back_Size;
           Profit := - Stake;
--          Log(" Current_Game_Time - Game_Start = " &         
--            String_Interval(Interval     => Current_Game_Time - Game_Start ,
--                            Days         => False,
--                            Hours        => True,
--                            Minutes      => True,
--                            Seconds      => False,
--                            Milliseconds => False));
--          Log("Home " & To_String(Runners(Home))); 
--          Log("Draw " & To_String(Runners(Draw))); 
--          Log("Away " & To_String(Runners(Away))); 
          declare
            Evt : Table_Aevents.Data_Type;
            Eos : Boolean := False;
          begin
            Evt.Eventid := Market.Eventid;
            Table_Aevents.Read(Evt,Eos);
            Log(Table_Amarkets.To_String(Market));
            Log(Table_Aevents.To_String(Evt));
          end ;          
           
         when Lay_Bet_Won =>  -- A winning lay bet
           Income := 0.935 * Global_Lay_Size;
           Stake  := 0.0;
           Profit := Income;
           Log(Bet_Status'Img & "         " & Table_Araceprices.To_String(Prices));
           
         when Lay_Bet_Lost =>  -- A losing lay bet
           Income := 0.0;
           Stake  := Global_Lay_Size * (Prices.Layprice - 1.0);
           Profit := - Stake;
           Log(Bet_Status'Img & "        " & Table_Araceprices.To_String(Prices));
           
      end case;
      Stats(Bet_Status).Hits := Stats(Bet_Status).Hits + 1;
      Stats(Bet_Status).Profit := Stats(Bet_Status).Profit + Profit;
    
      Global_Profit := Global_Profit + Profit;
      if Bet_Status /= No_Bet_Laid then
        Log("|" & 
            Runner.Marketid & "|" &  
            Runner.Selectionid'Img & "|" & 
            String_Date_Time_ISO (Date => Market.Startts, T => " ", TZ => "") & "|" & 
            Integer_4(Global_Profit)'Img & "|" & 
            Bet_Status'Img & "|" & 
            F8_Image(Global_Back_Price));
      end if;
      Select_Prices_For_All_Runners_In_One_Market.Close_Cursor; 
    end if;  
  end loop Select_All_Markets_Loop;
  Select_All_Markets.Close_Cursor;
  T.Commit ;

  Sql.Close_Session;
  if not Is_For_Plot then
    Log("Total profit = " & Integer_4(Global_Profit)'Img);
    for i in Bet_Status_Type'range loop
      Log(i'Img & Stats(i).Hits'Img & Integer_4(Stats(i).Profit)'Img);
    end loop;
--    Log("used --min_minutes=" & IA_Min_Minutes_Into_Game'Img &
--      " --back_at_price=" & SA_Back_At_Price.all & 
--      " --draw_min_back=" & Ia_Draw_Min_Back_Odds'Img & 
--      " --other_min_back=" & Ia_Other_Team_Min_Back_Odds'Img 
--      );
  end if;  
       
exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Lay_During_Football;
