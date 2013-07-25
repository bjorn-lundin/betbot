with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Logging; use Logging;
--with Sattmate_Types; use Sattmate_Types;
with Gnatcoll.Json; use Gnatcoll.Json;
--with Bot_Types; use  Bot_Types;
with Bot_Config; use Bot_Config;
with Bot_System_Number;
with Table_Abets;
with Table_Awinners;
--with Table_Arunners;
with Table_Anonrunners;
with Sql;
with General_Routines;
with Sattmate_Calendar;

with Aws;
with Aws.Client;
with Aws.Response;
with Aws.Headers;
with Aws.Headers.Set;

--with Sattmate_Exception;

pragma Elaborate_All(Aws.Headers);

package body Bet_Handler is

  Suicide,
  No_Such_Field : exception;

  Update_Betwon_To_Null,
  Select_Lost_Today,
  Select_Profit_Today,
  Select_Dry_Run_Bets,
  Select_Real_Bets,
  Select_Runners,
  Select_In_The_Air,
  Select_Exists,
  Select_History,
  Select_Prices : Sql.Statement_Type;

  Me : constant String := "Bet_Handler.";  
  My_Headers : Aws.Headers.List := Aws.Headers.Empty_List;
    
  type Bet_History_Record is record
    Weight     : Float_8 := 0.0;
    Start_Date : Sattmate_Calendar.Time_Type;
    End_Date   : Sattmate_Calendar.Time_Type;
    Profit     : Float_8 := 0.0;
  end record;
  
  type Bet_History_Array is array ( 1 .. 21 ) of Bet_History_Record;
  
  Global_Odds_Table : array(1 .. 350) of Float_8 := (
                       1.01,   1.02,   1.03,   1.04,   1.05,   1.06,   1.07,   1.08,   1.09,
               1.10,   1.11,   1.12,   1.13,   1.14,   1.15,   1.16,   1.17,   1.18,   1.19,
               1.20,   1.21,   1.22,   1.23,   1.24,   1.25,   1.26,   1.27,   1.28,   1.29, 
               1.30,   1.31,   1.32,   1.33,   1.34,   1.35,   1.36,   1.37,   1.38,   1.39,
               1.40,   1.41,   1.42,   1.43,   1.44,   1.45,   1.46,   1.47,   1.48,   1.49,
               1.50,   1.51,   1.52,   1.53,   1.54,   1.55,   1.56,   1.57,   1.58,   1.59, 
               1.60,   1.61,   1.62,   1.63,   1.64,   1.65,   1.66,   1.67,   1.68,   1.69,
               1.70,   1.71,   1.72,   1.73,   1.74,   1.75,   1.76,   1.77,   1.78,   1.79,
               1.80,   1.81,   1.82,   1.83,   1.84,   1.85,   1.86,   1.87,   1.88,   1.89,
               1.90,   1.91,   1.92,   1.93,   1.94,   1.95,   1.96,   1.97,   1.98,   1.99,
               2.00,   2.02,   2.04,   2.06,   2.08,   2.10,   2.12,   2.14,   2.16,   2.18, 
               2.20,   2.22,   2.24,   2.26,   2.28,   2.30,   2.32,   2.34,   2.36,   2.38,
               2.40,   2.42,   2.44,   2.46,   2.48,   2.50,   2.52,   2.54,   2.56,   2.58, 
               2.60,   2.62,   2.64,   2.66,   2.68,   2.70,   2.72,   2.74,   2.76,   2.78,
               2.80,   2.82,   2.84,   2.86,   2.88,   2.90,   2.92,   2.94,   2.96,   2.98, 
               3.00,   3.05,   3.10,   3.15,   3.20,   3.25,   3.30,   3.35,   3.40,   3.45, 
               3.50,   3.55,   3.60,   3.65,   3.70,   3.75,   3.80,   3.85,   3.90,   3.95,
               4.00,   4.10,   4.20,   4.30,   4.40,   4.50,   4.60,   4.70,   4.80,   4.90,
               5.00,   5.10,   5.20,   5.30,   5.40,   5.50,   5.60,   5.70,   5.80,   5.90, 
               6.00,   6.20,   6.40,   6.60,   6.80,   7.00,   7.20,   7.40,   7.60,   7.80,
               8.00,   8.20,   8.40,   8.60,   8.80,   9.00,   9.20,   9.40,   9.60,   9.80,
              10.00,  10.50,  11.00,  11.50,  12.00,  12.50,  13.00,  13.50,  14.00,  14.50, 
              15.00,  15.50,  16.00,  16.50,  17.00,  17.50,  18.00,  18.50,  19.00,  19.50, 
              20.00,  21.00,  22.00,  23.00,  24.00,  25.00,  26.00,  27.00,  28.00,  29.00,
              30.00,  32.00,  34.00,  36.00,  38.00,  40.00,  42.00,  44.00,  46.00,  48.00, 
              50.00,  55.00,  60.00,  65.00,  70.00,  75.00,  80.00,  85.00,  90.00,  95.00,
             100.00, 110.00, 120.00, 130.00, 140.00, 150.00, 160.00, 170.00, 180.00, 190.00, 
             200.00, 210.00, 220.00, 230.00, 240.00, 250.00, 260.00, 270.00, 280.00, 290.00,
             300.00, 310.00, 320.00, 330.00, 340.00, 350.00, 360.00, 370.00, 380.00, 390.00, 
             400.00, 410.00, 420.00, 430.00, 440.00, 450.00, 460.00, 470.00, 480.00, 490.00, 
             500.00, 510.00, 520.00, 530.00, 540.00, 550.00, 560.00, 570.00, 580.00, 590.00, 
             600.00, 610.00, 620.00, 630.00, 640.00, 650.00, 660.00, 670.00, 680.00, 690.00, 
             700.00, 710.00, 720.00, 730.00, 740.00, 750.00, 760.00, 770.00, 780.00, 790.00, 
             800.00, 810.00, 820.00, 830.00, 840.00, 850.00, 860.00, 870.00, 880.00, 890.00,
             900.00, 910.00, 920.00, 930.00, 940.00, 950.00, 960.00, 970.00, 980.00, 990.00, 
            1000.00); 
  
  function Create (Market_Notification : in Bot_Messages.Market_Notification_Record) return Bet_Info_Record is
    Bet_Info : Bet_Info_Record ;
    type Eos_Type is (A_Event, A_Market, A_Runner, A_Price);
    Eos : array(Eos_Type'range) of Boolean := (others => False);
    Max_Idx : Integer := 0;
    T : Sql.Transaction_Type;
    
    Price_List  : Table_Aprices.Aprices_List_Pack.List_Type   := Table_Aprices.Aprices_List_Pack.Create;    
    Runner_List : Table_Arunners.Arunners_List_Pack.List_Type := Table_Arunners.Arunners_List_Pack.Create;
  begin
    T.Start;
 
    Bet_Info.Market.Marketid := Market_Notification.Market_Id;
    Table_Amarkets.Read(Bet_Info.Market, Eos(A_Market));
    
    if not Eos(A_Market) then
      Bet_Info.Event.Eventid := Bet_Info.Market.Eventid;
      Table_Aevents.Read(Bet_Info.Event, Eos(A_Event));      
    else
      raise No_Data with "Market missing: '" & Market_Notification.Market_Id & "'";    
    end if;
    
    if Eos(A_Event) then
      raise No_Data with "Event missing: '" & Market_Notification.Market_Id & "'";    
    end if;
      
    Select_Prices.Prepare( 
      "select * from APRICES where MARKETID=:MARKETID and STATUS = 'ACTIVE' order by BACKPRICE");
    Select_Prices.Set("MARKETID", Bet_Info.Market.Marketid);
    
    Max_Idx := 0;    
    Select_Prices.Set("MARKETID", Bet_Info.Market.Marketid);
    Select_Prices.Open_Cursor; 
    loop
      Select_Prices.Fetch(Eos(A_Price)); 
      exit when Eos(A_Price);
      Max_Idx := Max_Idx +1; 
      Bet_Info.Runner_Array(Max_Idx).Price := Table_Aprices.Get(Select_Prices);
    end loop;
    Select_Prices.Close_Cursor; 
    Bet_Info.Last_Runner := Max_Idx;
    
    if Bet_Info.Last_Runner = 0 then
      raise No_Data with "Prices missing: '" & Market_Notification.Market_Id & "'";    
    end if;    
    
    -- get these in the same order as the prices ...    
    Select_Runners.Prepare("select * from ARUNNERS where MARKETID=:MARKETID and SELECTIONID=:SELECTIONID");
    Select_Runners.Set("MARKETID",Bet_Info.Market.Marketid);
    for i in 1 .. Bet_Info.Last_Runner loop
      Select_Runners.Set("SELECTIONID",Bet_Info.Runner_Array(i).Price.Selectionid );
      Select_Runners.Open_Cursor; 
      Select_Runners.Fetch(Eos(A_Runner)); 
      if not Eos(A_Runner) then
        Bet_Info.Runner_Array(i).Runner := Table_Arunners.Get(Select_Runners);
      else
        raise Bad_Data with "No runner in market '" & Bet_Info.Runner_Array(i).Price.Marketid &
                            "' selectionid " & Bet_Info.Runner_Array(i).Price.Selectionid'Img;
      end if;
      Select_Runners.Close_Cursor; 
    end loop;
    
    T.Commit;
    
    
--    Log(Me & "Create - Last", "------------debug start -----------------");        
--    Table_Aprices.Aprices_List_Pack.Get_First(Bet_Info.Price_List, Price, Eol);
--    loop
--      exit when Eol;
--      Log(Me & "Create - debug Price_List", Table_Aprices.To_String(Price));
--      Table_Aprices.Aprices_List_Pack.Get_Next(Bet_Info.Price_List, Price, Eol);
--    end loop;
--    Log(Me & "Create - Last", "--++--++--++--++--++--++");        
--    Table_Arunners.Arunners_List_Pack.Get_First(Bet_Info.Runner_List, Runner, Eol);
--    loop
--      exit when Eol;
--      Log(Me & "Create - debug Runner_List", Table_Arunners.To_String(Runner));        
--      Table_Arunners.Arunners_List_Pack.Get_Next(Bet_Info.Runner_List, Runner, Eol);
--    end loop;
--    Log(Me & "Create - Last", "--++--++--++--++--++--++");        
--
--    for i in 1 .. Bet_Info.Last_Runner loop
--      Log(Me & "Create - debug Price_Array" ,  i'Img & Table_Aprices.To_String(Bet_Info.Price_Array(i)));
--    end loop;    
--    Log(Me & "Create - Last", "--++--++--++--++--++--++");        
--
--    for i in 1 .. Bet_Info.Last_Runner loop
--      Log(Me & "Create - debug Runner_Array" ,  i'Img & Table_Arunners.To_String(Bet_Info.Runner_Array(i)));
--    end loop;    
--    
--    Log(Me & "Create - Last", "------------debug stop -----------------");        
    
    
    Table_Aprices.Aprices_List_Pack.Release(Price_List);    
    Table_Arunners.Arunners_List_Pack.Release(Runner_List);
    
    return Bet_Info;
  end Create;
  -------------------------------------------------------------------------------
  overriding procedure Finalize (Bet_Info : in out Bet_Info_Record) is
  begin
      null;
--      Log(Me & "Finalize", "Bet_Info Start releasing lists");
      --Table_Arunners.Arunners_List_Pack.Release(Bet_Info.Runner_List);
      --Table_Aprices.Aprices_List_Pack.Release(Bet_Info.Price_List);
--      Log(Me & "Finalize", "Bet_Info Stop releasing lists");
  end Finalize;
  -------------------------------------------------------------------------------
    
  procedure Try_Make_New_Bet (Bet_Info : in out Bet_Info_Record;
                              Bot_Cfg  : in out Bot_Config.Bet_Section_Type;
                              A_Token  : in out Token.Token_Type) is
    -- see if we can make a bet now
      Bet       : Bet_Type := Create(Bet_Info, Bot_Cfg);
      Fulfilled : Boolean  := True;
      Todays_Profit : Profit_Type := 0.0;
      Continue_Betting : Boolean := False; 
      Lost_Today : Boolean := True;
      In_The_Air, Exists : Boolean := True;
  begin
    Log(Me & "Try_Make_New_Bet", "Bet_name " & To_String(Bot_Cfg.Bet_Name) );
    
    Log(Me & "Try_Make_New_Bet", "Market: " & Bet.Bet_Info.Market.Marketid & " " &
                                 "Bet_Type: " &  Bet.Bot_Cfg.Bet_Type'Img & " " &    
                                 "Animal: " &  Bet.Bot_Cfg.Animal'Img  & " " &    
                                 "Country: " &  Bet.Bet_Info.Event.Countrycode & " " &    
                                 "evt-name: " &  Bet.Bet_Info.Event.Eventname);    
    
    
    Exists := Bet.Exists(Dry_Run => False);
    if not Exists then -- check for dry runs as well
      Exists := Bet.Exists(Dry_Run => True);
    end if;
    
    In_The_Air := Bet.In_The_Air(Dry_Run => False);
    if not In_The_Air then -- check for dry runs as well
      In_The_Air := Bet.In_The_Air(Dry_Run => True);
    end if;

    if not In_The_Air then
      if not Exists then
  --      Log(Me & "Try_Make_New_Bet", Bet.To_String);
        Bet.Check_Conditions_Fulfilled(Fulfilled);
        if Fulfilled then
          Todays_Profit := Bet.Profit_Today(Dry_Run => False); 
          
          if abs(Todays_Profit) < Profit_Type(0.001) then --use dry run instead
            Todays_Profit := Bet.Profit_Today(Dry_Run => True); 
          end if;      
          
          Lost_Today :=  Bet.Has_Lost_Today(Dry_Run => False);
          if not Lost_Today then -- check the dryruns too
            Lost_Today :=  Bet.Has_Lost_Today(Dry_Run => True);
          end if;         
          
          -- if we have a loss today, settle with positive result
          if Lost_Today then        
            if Todays_Profit < Bot_Cfg.Max_Daily_Loss then
              -- we have lost enough for today, give up!
              Continue_Betting := False;
              Log (Me & "Try_Make_New_Bet", "GIVE UP! We have too much already will NOT continue.");
          
            elsif Todays_Profit < Profit_Type(0.0) and then Todays_Profit >= Bot_Cfg.Max_Daily_Loss then
              -- we have lost today, and are still in loss. We risk to lose some more, in order to have a chance to be profitable. Keep bettting!
              Continue_Betting := True;
              Log (Me & "Try_Make_New_Bet", "DONT GIVE UP! We have lost today, but will continue.");
            else
              -- we have lost today, but are back on the winning side. Stop bettting, and be happy
              Continue_Betting := False;
              Log (Me & "Try_Make_New_Bet", "We have lost today, but are ok now. Settle with that, Will NOT continue until tomorrow");
            end if;
          else -- we have NOT lost today
            if Todays_Profit >= Bot_Cfg.Max_Daily_Profit then
              -- we have Won enough for today, STOP bettting!
              Continue_Betting := False;
              Log (Me & "Try_Make_New_Bet", "YES !! We have won enough for today, STOP bettting.");
            else
              -- we have won today, but haven't reach our ceiling yet
              Continue_Betting := True;
              Log (Me & "Try_Make_New_Bet", "YES !! We (probably) have won today, but not enough, KEEP bettting.");
            end if;
          end if;        
           
          if Continue_Betting then
            Bet.Make_Dry_Bet;
            if Bet.Enabled then
              if Bet.History_Ok then
      --          Bet.Make_Real_Bet(A_Token);
                 Log(Me & "Try_Make_New_Bet", "would be a real bet here");
              end if; -- history
            end if; -- enabled
          end if;-- continue betting
        end if;-- fulfilled
      else
        Log(Me & "Try_Make_New_Bet", "Bet alredy placed on this market: " & Bet.Bet_Info.Market.Marketid );
      end if;
    else
      Log(Me & "Try_Make_New_Bet", "Bet in the air, wait for it to be settled: " & Bet.Bet_Info.Market.Marketid );
    end if;
  end Try_Make_New_Bet;
    
  -------------------------------------------------------------------------------
    
  procedure Treat_Market(Market_Notification : in     Bot_Messages.Market_Notification_Record;
                         A_Token             : in out Token.Token_Type) is
    Bet_Info : Bet_Info_Record ;
    Eol : Boolean := True;
    Bet_Section : Bet_Section_Type;
    Num_Runners : Integer ;
    use General_Routines;
  begin
  
  
    Bet_Info := Create(Market_Notification);
    Num_Runners := Bet_Info.Last_Runner;
  
  
    Log(Me & "Treat_Market", "start market:" & Market_Notification.Market_Id);
    for i in 1 .. Num_Runners loop  
      Log(Me & "Treat_Market", Bet_Info.Runner_Array(i).Runner.Runnername(1..20) & 
                  " sel.id " & Bet_Info.Runner_Array(i).Runner.Selectionid'Img & " " &       
                     " bck " & F8_Image(Bet_Info.Runner_Array(i).Price.Backprice) &
                     " lay " & F8_Image(Bet_Info.Runner_Array(i).Price.Layprice));
    end loop;
    
    if Num_Runners = 0 then
      Log(Me & "Treat_Market", "0 runners - or mismatch runners/prices, skip market:" & Market_Notification.Market_Id);
      return;
    end if;
    
    Bet_Pack.Get_First(Bot_Config.Config.Bet_Section_List, Bet_Section,Eol);
    loop
      exit when Eol;
      Bet_Info.Try_Make_New_Bet(Bet_Section, A_Token);
      Bet_Pack.Get_Next(Bot_Config.Config.Bet_Section_List, Bet_Section, Eol);
    end loop;
    Log(Me & "Treat_Market", "end market:" & Market_Notification.Market_Id);
  exception 
    when Bad_Data =>
      Log(Me & "Treat_Market", "BAD DATA, skip:" & Market_Notification.Market_Id);    
  end Treat_Market;
  -------------------------------------------------------------------------------
  
--------------------  BET_TYPE start----------------------------------------  

  function Create (Bet_Info : Bet_Info_Record'Class; Bot_Cfg : Bot_Config.Bet_Section_Type) return Bet_Type is
    Tmp : Bet_Type ;
    use General_Routines;
  begin
    Tmp.Bet_Info := Bet_Info_Record(Bet_Info);
    Tmp.Bot_Cfg := Bot_Cfg;
    if Position( Lower_Case(To_String(Tmp.Bot_Cfg.Bet_Name)), "_lay_") > Natural(0) then 
      null;
    elsif Position( Lower_Case(To_String(Tmp.Bot_Cfg.Bet_Name)), "_back_") > Natural(0) then 
      null;
    else
      raise Bad_Data with "bad bet type: '" & Lower_Case(To_String(Tmp.Bot_Cfg.Bet_Name)) & "'";    
    end if;
    return Tmp;
  end Create;
  
  -----------------------------------------------------------------------
  function Enabled(Bet : Bet_Type) return Boolean is 
  begin
    return Bet.Bot_Cfg.Enabled;
  end Enabled;
  -----------------------------------------------------------------------
  
  procedure Check_Conditions_Fulfilled(Bet : in out Bet_Type; Result : in out Boolean) is
    Price_Fav, Price_2nd_Fav : Table_Aprices.Data_Type;
    Min_Num_Animals_Before_Me  : Integer := 0;
    --Tmp_Num_Runners, 
    Num_Runners : Integer := Bet.Bet_Info.Last_Runner;
    Max_Favorite_Odds : Float_8 := 0.0;
    use General_Routines;
  begin
    Result := True;
                                           
    -- some sanity checks
    case Bet.Bet_Info.Event.Eventtypeid is 
      when 7 =>    -- horses
        if Bet.Bot_Cfg.Animal /= Horse then
--          Log(Me & "Check_Conditions_Fulfilled", "wrong animal for this bot should be horse, is " & Bet.Bot_Cfg.Animal'Img);
          Result := False;
          return ; -- wrong animal for this bot
        end if;
      when 4339 => -- hounds
        if Bet.Bot_Cfg.Animal /= Hound then
--          Log(Me & "Check_Conditions_Fulfilled", "wrong animal for this bot should be hound, is " & Bet.Bot_Cfg.Animal'Img);
          Result := False;
          return ; -- wrong animal for this bot
        end if;
      when others => raise Bad_Data with "not supported eventtype:" & Bet.Bet_Info.Event.Eventtypeid'Img; 
    end case;
    
    -- check that the race's WIN/PLACE is what the bot expect
    case Bet.Bot_Cfg.Market_Type is
      when Winner =>
        if Upper_Case(Trim(Bet.Bet_Info.Market.Markettype)) /= "WIN" then
--          Log(Me & "Check_Conditions_Fulfilled", "wrong Markettype for this bot should be: '" &  Bet.Bot_Cfg.Market_Type'Img & "' is '" & Upper_Case(Trim(Bet.Bet_Info.Market.Markettype)) & "'");
          Result := False;
          return ; -- wrong markettype for this bot
        end if;
      when Place =>
        if Upper_Case(Trim(Bet.Bet_Info.Market.Markettype)) /= "PLACE" then
--          Log(Me & "Check_Conditions_Fulfilled", "wrong Markettype for this bot should be: '" &  Bet.Bot_Cfg.Market_Type'Img & "' is '" & Upper_Case(Trim(Bet.Bet_Info.Market.Markettype)) & "'");
          Result := False;
          return ; -- wrong markettype for this bot
        end if;
    end case;
    
    if Num_Runners < Bet.Bot_Cfg.Min_Num_Runners or else
       Num_Runners > Bet.Bot_Cfg.Max_Num_Runners then
    --  Log(Me & "Check_Conditions_Fulfilled", "bad num runners" & Num_Runners'Img & 
    --     " min=" &  Bet.Bot_Cfg.Min_Num_Runners'Img &
    --    " max=" &  Bet.Bot_Cfg.Max_Num_Runners'Img);
      Result := False;
      return;             
    end if;   
    
    -- Allowed country ? 
    --Countries is a ',' separated list of 2 char abbrevations. 
    
    declare
      Countries : String := Upper_Case(To_String(Bet.Bot_Cfg.Countries));
      Cntry : string(1..2) := (others => ' ');
      Index : integer := 1;
      Found : Boolean := False;
    begin
      for i in Countries'range loop
        case Countries(i) is
          when ',' =>
            if Cntry = Bet.Bet_Info.Event.Countrycode then
              Found := True;
              exit;
            end if;
          when others =>
            case Index is
              when 1 =>
                Cntry(1) := Countries(i);
                Index := 2;
              when 2 => 
                Cntry(2) := Countries(i);
                Index := 1;
              when others => raise Bad_Data with "Index = " & Index'Img;
            end case;
        end case;
      end loop;
      -- check also for the last entry (EN,IE)
      if Cntry = Bet.Bet_Info.Event.Countrycode then
        Found := True;
      end if;
      
      if not Found then
    --      Log(Me & "Check_Conditions_Fulfilled", "wrong country for this bot should be in : '" & Countries & "' is '" & Bet.Bet_Info.Event.Countrycode & "'");
          Result := False;
          return ; -- wrong country for this bot
      end if;
    end;
        
    -- check market status --?
    if General_Routines.Trim(Bet.Bet_Info.Market.Status) /= "OPEN" then
      Log(Me & "Check_Conditions_Fulfilled", "Market.Status /= 'OPEN', '" & General_Routines.Trim(Bet.Bet_Info.Market.Status) & "'");
      Result := False;
      return;
    end if;
  
    case Bet.Bot_Cfg.Bet_Type is    
      when Back => -- only check the favorite here 
        Price_Fav     := Bet.Bet_Info.Runner_Array(1).Price;
        Price_2nd_Fav := Bet.Bet_Info.Runner_Array(2).Price;

        -- check price within backprice +- deltaprice
        if  Bet.Bot_Cfg.Back_Price - Bet.Bot_Cfg.Delta_Price <= Price_Fav.Backprice and then
            Price_Fav.Backprice <= Bet.Bot_Cfg.Back_Price + Bet.Bot_Cfg.Delta_Price and then
            Price_Fav.Backprice + Bet.Bot_Cfg.Favorite_By < Price_2nd_Fav.Backprice then
            
          Bet.Bet_Info.Selection_Id := Price_Fav.Selectionid;
          Bet.Bet_Info.Used_Index   := 1; --index in the array of our selection 
        else
          Result := False;
          return;
        end if;

      when Lay =>      
        -- check min_lay_price < price <= max_lay_price
        -- we can not loop for dogs. Check how many turns for horses
        if General_Routines.Trim(Bet.Bet_Info.Market.Markettype) = "WIN" then
          case Bet.Bet_Info.Event.Eventtypeid is 
            when 7    => 
              Min_Num_Animals_Before_Me := 7;  -- always 6 horses before mine ...
              Max_Favorite_Odds := 5.0;
            when 4339 => 
              Min_Num_Animals_Before_Me := 6;                --always last hound
              Max_Favorite_Odds := 1.9;
            when others => raise Bad_Data with "Bad eventtype: " & Bet.Bet_Info.Event.Eventtypeid'Img;
          end case;
        elsif General_Routines.Trim(Bet.Bet_Info.Market.Markettype) = "PLACE" then
          case Bet.Bet_Info.Event.Eventtypeid is 
            when 7    => 
              Min_Num_Animals_Before_Me := Num_Runners ;  -- always many horses before mine ...
              Max_Favorite_Odds := 2.0;
            when 4339 => 
              Min_Num_Animals_Before_Me := 6;                --always last hound
              Max_Favorite_Odds := 1.5;
            when others => raise Bad_Data with "Bad eventtype: " & Bet.Bet_Info.Event.Eventtypeid'Img;
          end case;
        end if;
        -- check favorite odds (i.e. there is a clear favorite)
        if Bet.Bet_Info.Runner_Array(1).Price.Backprice > Max_Favorite_Odds then
     --     Log(Me & "Check_Conditions_Fulfilled", "favorite sucks odds " & Bet.Bet_Info.Runner_Array(1).Price.Backprice'Img & 
     --              " needs to be < " & Max_Favorite_Odds'Img);
          Result := False;
          return;
        end if;
        
        declare
          Was_OK : Boolean := False;
        begin           
          for i in Min_Num_Animals_Before_Me  .. Num_Runners loop           
            if  Bet.Bot_Cfg.Min_Lay_Price < Bet.Bet_Info.Runner_Array(i).Price.Layprice and then
                Bet.Bet_Info.Runner_Array(i).Price.Layprice <= Bet.Bot_Cfg.Max_Lay_Price then
  
              Bet.Bet_Info.Selection_Id := Bet.Bet_Info.Runner_Array(i).Price.Selectionid; -- save the selection
              Bet.Bet_Info.Used_Index   := i; --index in the array of our selection 
              Was_Ok := True;
              -- do not exit here. we want the horse with highest odds that meets the criteria 
            end if;
          end loop;
          if not Was_Ok then
     --       Log(Me & "Check_Conditions_Fulfilled", "Reset done, was not ok, Max_Turns=" & Max_Turns'Img);
            Bet.Bet_Info.Selection_Id := 0; --reset
            Bet.Bet_Info.Used_Index   := 0;  
            Result := False;
          end if;
        end;  
    end case;
    -- neutral place, will be executed in make*bet
    Update_Betwon_To_Null.Prepare("update ABETS set betwon = null where betid = :BETID");

  end Check_Conditions_Fulfilled;
  ------------------------------------------------------------------------------------------------------
  function History_Ok(Bet : Bet_Type) return Boolean is
    History : Bet_History_Array; -- array of 21 days
    use Sattmate_Calendar;
    T : Sql.Transaction_Type;
    Eos : Boolean := False;
    Start_Date, End_Date, Now : Time_Type := Clock; 
    Sum : Float_8 := 0.0;
  begin
    T.Start;
      Select_History.Prepare(
         "select " & 
           "sum(PROFIT) " & 
         "from   " &
           "ABETS " &
         "where " &
           "BETPLACED >= :STARTOFDAY " & 
           "and BETPLACED <= :ENDOFDAY  " &
           "and BETWON is not null " &
           "and BETNAME = :BETNAME ");
           
      -- always set dry-run history           
      Select_History.Set( "BETNAME", "DR_" &  To_String(Bet.Bot_Cfg.Bet_Name));
      
      for i in History'range loop
        Start_Date := Now - (Integer_4(i),0,0,0,0);
        Start_Date.Hour        := 0;
        Start_Date.Minute      := 0;
        Start_Date.Second      := 0;
        Start_Date.MilliSecond := 0;
        
        End_Date := Now   - (Integer_4(i),0,0,0,0);
        End_Date.Hour        := 23;
        End_Date.Minute      := 59;
        End_Date.Second      := 59;
        End_Date.MilliSecond := 999;
        
        History(i).Start_Date := Start_Date;
        History(i).End_Date   := End_Date;
        History(i).Weight := 1.0 / Float_8_Functions.Sqrt(Float_8(i));
        
        Select_History.Set_Timestamp( "STARTOFDAY",Start_Date);
        Select_History.Set_Timestamp( "ENDOFDAY",End_Date);
        Select_History.Open_Cursor;     
        Select_History.Fetch(Eos);     
        Select_History.Close_Cursor;     
        if not Eos then
          Select_History.Get(1, History(i).Profit);
        end if;
      end loop;     
    T.Commit;   
    
    for i in History'range loop
      Log(Me & "History_Ok", "History: " & i'img & " " & integer(History(i).Profit)'img & " weight: " & General_Routines.F8_Image(History(i).Weight) & 
                            " result: "  &   General_Routines.F8_Image(History(i).Weight * History(i).Profit) &
                            " start: " & String_Date_Time_ISO(History(i).Start_Date, " ", "") & 
                            " end: " & String_Date_Time_ISO(History(i).End_Date, " ", "") 
                            );
      Sum := Sum + (History(i).Weight * History(i).Profit);
    end loop;     
    
    Log(Me & "History_Ok", "Sum: " & Sum'Img & " Ok= " & Boolean'Image(Sum >= 0.0) & " - DR_" &  To_String(Bet.Bot_Cfg.Bet_Name));
    return Sum >= 0.0;
    
  end History_Ok;
  
  ------------------------------------------------------------------------------------------------------
  function Profit_Today(Bet : Bet_Type; Dry_Run : Boolean := False) return Profit_Type is
    T : Sql.Transaction_Type;
    Eos : Boolean := False;
    Profit : Float_8 := 0.0;
    use Sattmate_Calendar;
    Start_Date, End_Date : Time_Type := Clock; 
  begin
    T.Start;
      Start_Date.Hour        := 0;
      Start_Date.Minute      := 0;
      Start_Date.Second      := 0;
      Start_Date.MilliSecond := 0;
      
      End_Date.Hour        := 23;
      End_Date.Minute      := 59;
      End_Date.Second      := 59;
      End_Date.MilliSecond := 999;
    
      Select_Profit_Today.Prepare(
        "select " & 
          "sum(PROFIT) " & 
        "from   " &
          "ABETS " &
        "where " &
          "BETPLACED >= :STARTOFDAY " & 
          "and BETPLACED <= :ENDOFDAY  " &
          "and BETWON is not null " &
          "and BETNAME = :BETNAME " );
          
      if Dry_Run then
        Select_Profit_Today.Set( "BETNAME", "DR_" & To_String(Bet.Bot_Cfg.Bet_Name));
      else 
        Select_Profit_Today.Set( "BETNAME", To_String(Bet.Bot_Cfg.Bet_Name));
      end if;
      
      Select_Profit_Today.Set_Timestamp( "STARTOFDAY",Start_Date);
      Select_Profit_Today.Set_Timestamp( "ENDOFDAY",End_Date);
      Select_Profit_Today.Open_Cursor;     
      Select_Profit_Today.Fetch(Eos);     
      Select_Profit_Today.Close_Cursor;     
      if not Eos then
        Select_Profit_Today.Get(1, Profit);
      end if;      
    T.Commit;
    if Dry_Run then
      Log(Me & "Profit_Today",  "DR_" & To_String(Bet.Bot_Cfg.Bet_Name) & " :" & Integer(Profit)'Img);
    else 
      Log(Me & "Profit_Today",  To_String(Bet.Bot_Cfg.Bet_Name) & " :" & Integer(Profit)'Img);
    end if;
    
    return Profit_Type(Profit);
  end Profit_Today;
  ------------------------------------------------------------------------------------------------------
  function Has_Lost_Today(Bet : Bet_Type; Dry_Run : Boolean := False) return Boolean is
    T : Sql.Transaction_Type;
    Eos : Boolean := False;
    use Sattmate_Calendar;
    Start_Date, End_Date : Time_Type := Clock; 
  begin
    T.Start;
      Start_Date.Hour        := 0;
      Start_Date.Minute      := 0;
      Start_Date.Second      := 0;
      Start_Date.MilliSecond := 0;
      
      End_Date.Hour        := 23;
      End_Date.Minute      := 59;
      End_Date.Second      := 59;
      End_Date.MilliSecond := 999;
    
      Select_Lost_Today.Prepare(
        "select " & 
          "'A' " & 
        "from   " &
          "ABETS " &
        "where " &
          "BETPLACED >= :STARTOFDAY " & 
          "and BETPLACED <= :ENDOFDAY  " &
          "and PROFIT < 0.0 " &
          "and BETWON is not null " &
          "and BETNAME = :BETNAME " );
      if Dry_Run then
        Select_Lost_Today.Set( "BETNAME", "DR_" & To_String(Bet.Bot_Cfg.Bet_Name));
      else 
        Select_Lost_Today.Set( "BETNAME", To_String(Bet.Bot_Cfg.Bet_Name));
      end if;
      Select_Lost_Today.Set_Timestamp( "STARTOFDAY",Start_Date);
      Select_Lost_Today.Set_Timestamp( "ENDOFDAY",End_Date);
      Select_Lost_Today.Open_Cursor;     
      Select_Lost_Today.Fetch(Eos);     
      Select_Lost_Today.Close_Cursor;     
    T.Commit;
    if not Eos then
      if Dry_Run then
        Log(Me & "Has_Lost_Today",  "DR_" & To_String(Bet.Bot_Cfg.Bet_Name) & " :" & " HAS lost today");
      else 
        Log(Me & "Has_Lost_Today",  To_String(Bet.Bot_Cfg.Bet_Name) & " :" & " HAS lost today");
      end if;
      return True;
    else
      if Dry_Run then
        Log(Me & "Has_Lost_Today",  "DR_" & To_String(Bet.Bot_Cfg.Bet_Name) & " :" & " HAS NOT lost today");
      else 
        Log(Me & "Has_Lost_Today",  To_String(Bet.Bot_Cfg.Bet_Name) & " :" & " HAS NOT lost today");
      end if;
      return False;
    end if;
  end Has_Lost_Today;  
  
  ------------------------------------------------------------------------------------------------------
--  function To_String(Bet : Bet_Type) return String;
  function Exists(Bet : Bet_Type; Dry_Run : Boolean := False) return Boolean is
    T    : Sql.Transaction_Type;
    Eos  : Boolean := False;
    Abet : Table_Abets.Data_Type;
  begin
    T.Start;
      Select_Exists.Prepare(
         "select * " & 
         "from " &
           "ABETS " &
         "where MARKETID = :MARKETID " & 
           "and BETNAME = :BETNAME ");
      
      if Dry_Run then
        Select_Exists.Set("BETNAME",  "DR_" & To_String(Bet.Bot_Cfg.Bet_Name));
--        Log(Me & "Exists", "name '" &  "DR_" & To_String(Bet.Bot_Cfg.Bet_Name) & "'");
      else 
--        Log(Me & "Exists", "name '" & To_String(Bet.Bot_Cfg.Bet_Name) & "'");
        Select_Exists.Set("BETNAME", To_String(Bet.Bot_Cfg.Bet_Name));
      end if;
  
--      Log(Me & "Exists", "marketid '" & Bet.Bet_Info.Market.Marketid & "'");
      Select_Exists.Set("MARKETID", Bet.Bet_Info.Market.Marketid);
      
      Select_Exists.Open_Cursor;     
      Select_Exists.Fetch( Eos);     
      Select_Exists.Close_Cursor;     
      if not Eos then
        Abet := Table_Abets.Get(Select_Exists);
        Log(Me & "Exists", "Bet does exist " & Table_Abets.To_String(Abet));
      else  
        null;
--        Log(Me & "Exists", "Bet does not exist");
      end if;
    T.Commit;
    return not Eos;
  end Exists;
  ---------------------------------------------------------------
  function In_The_Air(Bet : Bet_Type; Dry_Run : Boolean := False) return Boolean is
    T    : Sql.Transaction_Type;
    Eos  : Boolean := False;
    Abet : Table_Abets.Data_Type;
  begin
    T.Start;
      Select_In_The_Air.Prepare(
         "select * " & 
         "from " &
           "ABETS " &
         "where BETWON is null " & 
           "and BETNAME = :BETNAME ");
      
      if Dry_Run then
        Select_In_The_Air.Set("BETNAME",  "DR_" & To_String(Bet.Bot_Cfg.Bet_Name));
--        Log(Me & "In_The_Air", "name '" &  "DR_" & To_String(Bet.Bot_Cfg.Bet_Name) & "'");
      else 
--        Log(Me & "In_The_Air", "name '" & To_String(Bet.Bot_Cfg.Bet_Name) & "'");
        Select_In_The_Air.Set("BETNAME", To_String(Bet.Bot_Cfg.Bet_Name));
      end if;
  
      
      Select_In_The_Air.Open_Cursor;     
      Select_In_The_Air.Fetch( Eos);     
      Select_In_The_Air.Close_Cursor;     
      if not Eos then
        Abet := Table_Abets.Get(Select_In_The_Air);
        Log(Me & "In_The_Air", "Bet does exist " & Table_Abets.To_String(Abet));
      else  
--        Log(Me & "In_The_Air", "Bet does not exist");
         null;
      end if;
    T.Commit;
    return not Eos;
  end In_The_Air;
  ---------------------------------------------------------------

  procedure Make_Dry_Bet(Bet : in out Bet_Type) is
    Abet : Table_Abets.Data_Type;
    Price : Float_8 := 0.0;
    Pip : Pip_Type ;
    Side         : String (1..4) :=  (others => ' ') ; 
    Bet_Name     : String (1..50) :=  (others => ' ') ;
    Success      : String (1..50) :=  (others => ' ') ;    
    Order_Status : String (1..50) :=  (others => ' ') ;    
    Now          : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;
    Runner_Name  : String (1..50) :=  (others => ' ') ;    
    T : Sql.Transaction_Type;

  begin
  
--  type Data_Type is record
--      Betid :          Integer_8  := 0 ; -- Primary Key
--      Marketid :       String (1..11) := (others => ' ') ; -- non unique index 2
--      Selectionid :    Integer_4  := 0 ; --
--      Reference :      String (1..30) := (others => ' ') ; --
--      Size :           Float_8  := 0.0 ; --
--      Price :          Float_8  := 0.0 ; --
--      Side :           String (1..4) := (others => ' ') ; --
--      Betname :        String (1..50) := (others => ' ') ; --
--      Betwon :         Integer_4  := 0 ; -- non unique index 3
--      Profit :         Float_8  := 0.0 ; --
--      Status :         String (1..50) := (others => ' ') ; --
--      Exestatus :      String (1..50) := (others => ' ') ; --
--      Exeerrcode :     String (1..50) := (others => ' ') ; --
--      Inststatus :     String (1..50) := (others => ' ') ; --
--      Insterrcode :    String (1..50) := (others => ' ') ; --
--      Betplaced :      Time_Type  := Time_Type_First ; --
--      Pricematched :   Float_8  := 0.0 ; --
--      Sizematched :    Float_8  := 0.0 ; --
--      Runnername :     String (1..50) := (others => ' ') ; --
--      Fullmarketname : String (1..200) := (others => ' ') ; --
--      Ixxlupd :        String (1..15) := (others => ' ') ; --
--      Ixxluts :        Time_Type  := Time_Type_First ; --
--  end record;

    Log(Me & "Make_Dry_Bet", "Bet.Bet_Info.Used_Index:" & Bet.Bet_Info.Used_Index'Img);

    case Bet.Bot_Cfg.Bet_Type is
      when Back => 
        Price := Bet.Bet_Info.Runner_Array(Bet.Bet_Info.Used_Index).Price.Backprice;
        Pip.Init(Price);
        Price := Pip.Previous_Price;
      when Lay => 
        Price := Bet.Bet_Info.Runner_Array(Bet.Bet_Info.Used_Index).Price.Layprice;
        Pip.Init(Price);
        Price := Pip.Next_Price;
    end case;
    
    Move( Bet.Bot_Cfg.Bet_Type'Img, Side);
    Move( "DR_" & To_String(Bet.Bot_Cfg.Bet_Name), Bet_Name);
    Move( "SUCCESS", Success);
    Move( "EXECUTION_COMPLETE", Order_Status);
    Move( Bet.Bet_Info.Runner_Array(Bet.Bet_Info.Used_Index).Runner.Runnernamestripped, Runner_Name);
    
    Abet := (
      Betid          => Integer_8(Bot_System_Number.New_Number(Bot_System_Number.Betid)),          
      Marketid       => Bet.Bet_Info.Market.Marketid,       
      Selectionid    => Bet.Bet_Info.Selection_Id,   
      Reference      => (others => '-'),     
      Size           => Float_8(Bet.Bot_Cfg.Bet_Size),
      Price          => Price,         
      Side           => Side,
      Betname        => Bet_Name,       
      Betwon         => False,
      Profit         => 0.0,        
      Status         => Order_Status,         
      Exestatus      => Success,     
      Exeerrcode     => Success,    
      Inststatus     => Success,    
      Insterrcode    => Success,   
      Betplaced      => Now,     
      Pricematched   => Price,  --?
      Sizematched    => Float_8(Bet.Bot_Cfg.Bet_Size),   --?
      Runnername     => Runner_Name,    
      Fullmarketname => Bet.Bet_Info.Market.Marketname,
      Ixxlupd        => (others => ' '), --set by insert       
      Ixxluts        => Now              --set by insert
    );
    
    begin
      T.Start;
        Table_Abets.Insert(Abet);
        Update_Betwon_To_Null.Set("BETID", Abet.Betid);
        Update_Betwon_To_Null.Execute;
      T.Commit;
      Log(Me & "Make_Dry_Bet", "inserted bet: " & Table_Abets.To_String(Abet));      
   exception
      when Sql.Duplicate_Index =>
        T.Rollback;
        Log(Me & "Make_Dry_Bet", "Duplicate_Index: " & Table_Abets.To_String(Abet));      
    end ;
  end Make_Dry_Bet;
  ---------------------------------------------------------------
  procedure Make_Real_Bet(Bet     : in out Bet_Type;
                          A_Token : in out Token.Token_Type) is
    Abet : Table_Abets.Data_Type;
    Price : Float_8 := 0.0;
    Pip : Pip_Type ;
    Side                           : String (1..4)  :=  (others => ' ') ; 
    Bet_Name                       : String (1..50) :=  (others => ' ') ;
    Execution_Report_Status        : String (1..50) :=  (others => ' ') ;    
    Execution_Report_Error_Code    : String (1..50) :=  (others => ' ') ;    
    Instruction_Report_Status      : String (1..50) :=  (others => ' ') ;    
    Instruction_Report_Error_Code  : String (1..50) :=  (others => ' ') ;    
    Tmp_Bet_Id                     : String (1..20) :=  (others => ' ') ;    
    Customer_Reference             : String (1..30) :=  (others => ' ') ;
    Runner_Name                    : String (1..50) :=  (others => ' ') ;    
    Order_Status                   : String (1..50) :=  (others => ' ') ;    
    Size_Matched,
    Average_Price_Matched          : Float := 0.0;
    
    Bet_Id : Integer_8 := 0;
    Now    : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;
    T      : Sql.Transaction_Type;
    
    Answer_Place_Orders : Aws.Response.Data;
    Reply_Place_Orders,
    Query_Place_Orders : JSON_Value := Create_Object; 
    
    Params         : JSON_Value := Create_Object;
    Instruction    : JSON_Value := Create_Object;
    Limit_Order    : JSON_Value := Create_Object;
    Instructions   : JSON_Array := Empty_Array;
    
  begin
  
--  type Data_Type is record
--      Betid :          Integer_8  := 0 ; -- Primary Key
--      Marketid :       String (1..11) := (others => ' ') ; -- non unique index 2
--      Selectionid :    Integer_4  := 0 ; --
--      Reference :      String (1..30) := (others => ' ') ; --
--      Size :           Float_8  := 0.0 ; --
--      Price :          Float_8  := 0.0 ; --
--      Side :           String (1..4) := (others => ' ') ; --
--      Betname :        String (1..50) := (others => ' ') ; --
--      Betwon :         Integer_4  := 0 ; -- non unique index 3
--      Profit :         Float_8  := 0.0 ; --
--      Status :         String (1..50) := (others => ' ') ; --
--      Exestatus :      String (1..50) := (others => ' ') ; --
--      Exeerrcode :     String (1..50) := (others => ' ') ; --
--      Inststatus :     String (1..50) := (others => ' ') ; --
--      Insterrcode :    String (1..50) := (others => ' ') ; --
--      Betplaced :      Time_Type  := Time_Type_First ; --
--      Pricematched :   Float_8  := 0.0 ; --
--      Sizematched :    Float_8  := 0.0 ; --
--      Runnername :     String (1..50) := (others => ' ') ; --
--      Fullmarketname : String (1..200) := (others => ' ') ; --
--      Ixxlupd :        String (1..15) := (others => ' ') ; --
--      Ixxluts :        Time_Type  := Time_Type_First ; --
--  end record;

    case Bet.Bot_Cfg.Bet_Type is
      when Back => 
        Price := Bet.Bet_Info.Runner_Array(Bet.Bet_Info.Used_Index).Price.Backprice;
        Pip.Init(Price);
        Price := Pip.Previous_Price;
      when Lay => 
        Price := Bet.Bet_Info.Runner_Array(Bet.Bet_Info.Used_Index).Price.Layprice;
        Pip.Init(Price);
        Price := Pip.Next_Price;
    end case;
    
    Move( Bet.Bot_Cfg.Bet_Type'Img, Side);
    Move( To_String(Bet.Bot_Cfg.Bet_Name), Bet_Name);
    Move( Bet.Bet_Info.Runner_Array(Bet.Bet_Info.Used_Index).Runner.Runnernamestripped, Runner_Name);
    
    -- prepare the AWS
    Aws.Headers.Set.Reset(My_Headers);
    Aws.Headers.Set.Add (My_Headers, "X-Authentication", A_Token.Get);
    Aws.Headers.Set.Add (My_Headers, "X-Application", Token.App_Key);
    Aws.Headers.Set.Add (My_Headers, "Accept", "application/json");

    Limit_Order.Set_Field (Field_Name => "persistenceType", Field      => "LAPSE");
    Limit_Order.Set_Field (Field_Name => "price",           Field      => Float(Price));
    Limit_Order.Set_Field (Field_Name => "size",            Field      => Float(Bet.Bot_Cfg.Bet_Size));
    
    Instruction.Set_Field (Field_Name => "limitOrder",      Field      => Limit_Order);                            
    Instruction.Set_Field (Field_Name => "orderType",       Field      => "LIMIT");
    Instruction.Set_Field (Field_Name => "side",            Field      => Bet.Bot_Cfg.Bet_Type'Img);
    Instruction.Set_Field (Field_Name => "handicap",        Field      => 0);
    Instruction.Set_Field (Field_Name => "selectionId",     Field      => Integer(Bet.Bet_Info.Selection_Id));
    
    Append (Instructions , Instruction);
             
    Params.Set_Field (Field_Name => "customerRef",          Field      => "some ref to fill in later"); -- what to put here?
    Params.Set_Field (Field_Name => "instructions",         Field      => Instructions);
    Params.Set_Field (Field_Name => "marketId",             Field      => Bet.Bet_Info.Market.Marketid);
    
    Query_Place_Orders.Set_Field (Field_Name => "params",   Field      => Params);
    Query_Place_Orders.Set_Field (Field_Name => "id",       Field      => 15);          -- what to put here?
    Query_Place_Orders.Set_Field (Field_Name => "method",   Field      => "SportsAPING/v1.0/placeOrders");
    Query_Place_Orders.Set_Field (Field_Name => "jsonrpc",  Field      => "2.0");
    
--{
--    "jsonrpc": "2.0",
--    "method": "SportsAPING/v1.0/placeOrders",
--    "params": {
--        "marketId": "' + marketId + '",
--        "instructions": [
--            {
--                "selectionId": "' + str(selectionId) + '",
--                "handicap": "0",
--                "side": "BACK",
--                "orderType": "LIMIT",
--                "limitOrder": {
--                    "size": "0.01",
--                    "price": "1.50",
--                    "persistenceType": "LAPSE"
--                }
--            }
--        ],
--        "customerRef": "test12121212121"
--    },
--    "id": 1
--}

    Log(Me & "Make_Real_Bet", "posting: " & Query_Place_Orders.Write  );
    Answer_Place_Orders := Aws.Client.Post (Url          =>  Token.URL,
                                            Data         =>  Query_Place_Orders.Write,
                                            Content_Type => "application/json",
                                            Headers      =>  My_Headers,
                                            Timeouts     =>  Aws.Client.Timeouts (Each => 30.0));
    Log(Me & "Make_Real_Bet", "Got reply ");
    begin
      if String'(Aws.Response.Message_Body(Answer_Place_Orders)) /= "Post Timeout" then
        Reply_Place_Orders := Read (Strm     => Aws.Response.Message_Body(Answer_Place_Orders),
                                    Filename => "");
      else
        Log(Me & "Make_Real_Bet", "Post Timeout -> Give up placeOrder");
        return;
      end if;      
    exception
      when others =>
         Log(Me & "Make_Real_Bet", "***********************  Bad reply start *********************************");
         Log(Me & "Make_Real_Bet", "Bad reply" & Aws.Response.Message_Body(Answer_Place_Orders));
         Log(Me & "Make_Real_Bet", "***********************  Bad reply stop  ********  -> Give up placeOrders" );
         return;
    end ;       

    -- parse out the reply.
    -- check for API exception/Error first
    declare
       Error, 
       Code, 
       APINGException, 
       Data                      : JSON_Value := Create_Object;
    begin 
      if Reply_Place_Orders.Has_Field("error") then
        --    "error": {
        --        "code": -32099,
        --        "data": {
        --            "exceptionname": "APINGException",
        --            "APINGException": {
        --                "requestUUID": "prdang001-06060844-000842110f",
        --                "errorCode": "INVALID_SESSION_INFORMATION",
        --                "errorDetails": "The session token passed is invalid"
        --                }
        --            },
        --            "message": "ANGX-0003"
        --        }
        Error := Reply_Place_Orders.Get("error");
        if Error.Has_Field("code") then
          Code := Error.Get("code");
          Log(Me & "Make_Real_Bet", "error.code " & Integer(Integer'(Error.Get("code")))'Img);

          if Code.Has_Field("data") then
            Data := Code.Get("data");
            if Data.Has_Field("APINGException") then
              APINGException := Data.Get("APINGException");
              if APINGException.Has_Field("errorCode") then
                Log(Me & "Make_Real_Bet", "APINGException.errorCode " & APINGException.Get("errorCode"));
--                if String'(APINGException.Get("errorCode")) ="INVALID_SESSION_INFORMATION" then
--                  raise Suicide with "INVALID_SESSION_INFORMATION"; -- exit main loop, let cron restart program
                  raise Suicide with String'(APINGException.Get("errorCode")); -- exit main loop, let cron restart program
--                end if;
              else  
                raise No_Such_Field with "APINGException - errorCode";
              end if;          
            else  
              raise No_Such_Field with "Data - APINGException";
            end if;          
          else  
            raise  No_Such_Field with "Code - data";
          end if;          
        else
          raise No_Such_Field with "Error - code";
        end if;          
      end if;   
    end; 
        
    -- ok we have a parsable answer with no formal errors. 
    -- lets look at it
    declare    
      Instruction    : JSON_Value := Create_Object;
      Instructions   : JSON_Array := Empty_Array;
    begin
      -- sanity check, but what to do if fail?
      if Reply_Place_Orders.Has_Field("customerRef") then
        Move( Params.Get("customerRef"), Customer_Reference);
      
        if General_Routines.Trim(Customer_Reference) /= String'(Reply_Place_Orders.Get("customerRef")) then
          Log(Me & "Make_Real_Bet", "expected customerRef '" & Params.Get("customerRef") & 
              "' received customerRef '" & Reply_Place_Orders.Get("customerRef"));
        end if;
      end if;

      if Reply_Place_Orders.Has_Field("marketid") then
        if General_Routines.Trim(Bet.Bet_Info.Market.Marketid) /= String'(Reply_Place_Orders.Get("marketid")) then
          Log(Me & "Make_Real_Bet", "expected marketid '" & General_Routines.Trim(Bet.Bet_Info.Market.Marketid) & 
              "' received marketid '" & Reply_Place_Orders.Get("marketid"));
        end if;
      end if;
      
      if Reply_Place_Orders.Has_Field("status") then
        Move( Reply_Place_Orders.Get("status"), Execution_Report_Status);
      end if;
      if Reply_Place_Orders.Has_Field("errorCode") then
        Move( Reply_Place_Orders.Get("errorCode"), Execution_Report_Error_Code);
      end if;
      if Reply_Place_Orders.Has_Field("instructionReports") then
        Instructions := Reply_Place_Orders.Get("instructionReports");
        Instruction  := Get(Instructions, 1); -- always element 1, since we only have 1
        
        if Instruction.Has_Field("instructionReportStatus") then
          Move(Instruction.Get("instructionReportStatus"), Instruction_Report_Status);
        end if;
        if Instruction.Has_Field("instructionReportErrorCode") then
          Move(Instruction.Get("instructionReportErrorCode"), Instruction_Report_Error_Code);
        end if;
      end if;

      if Reply_Place_Orders.Has_Field("betId") then
        Move( Reply_Place_Orders.Get("betId"), Tmp_Bet_Id );
        if Tmp_Bet_Id(2) = '.' then
          Bet_Id := Integer_8'Value(Tmp_Bet_Id(3 .. Tmp_Bet_Id'Last));
        else           
          Bet_Id := Integer_8'Value(Tmp_Bet_Id);
        end if;       
      end if;
      
      if Reply_Place_Orders.Has_Field("sizeMatched") then
        Size_Matched := Reply_Place_Orders.Get("sizeMatched");
      end if;
      if Reply_Place_Orders.Has_Field("averagePriceMatched") then
        Average_Price_Matched := Reply_Place_Orders.Get("averagePriceMatched");
      end if; 
    end ;   
    
    Abet := (
      Betid          => Bet_Id,          
      Marketid       => Bet.Bet_Info.Market.Marketid,       
      Selectionid    => Bet.Bet_Info.Selection_Id,   
      Reference      => (others => '-'),     
      Size           => Float_8(Bet.Bot_Cfg.Bet_Size),
      Price          => Price,         
      Side           => Side,
      Betname        => Bet_Name,       
      Betwon         => False,
      Profit         => 0.0,        
      Status         => Order_Status, -- ??        
      Exestatus      => Execution_Report_Status,     
      Exeerrcode     => Execution_Report_Error_Code,    
      Inststatus     => Instruction_Report_Status,    
      Insterrcode    => Instruction_Report_Error_Code,   
      Betplaced      => Now,     
      Pricematched   => Float_8(Average_Price_Matched),
      Sizematched    => Float_8(Size_Matched),
      Runnername     => Runner_Name,    
      Fullmarketname => Bet.Bet_Info.Market.Marketname,
      Ixxlupd        => (others => ' '), --set by insert       
      Ixxluts        => Now              --set by insert
    );
    
    begin
      T.Start;
        Table_Abets.Insert(Abet);
        Sql.Set(Update_Betwon_To_Null,"BETID", Abet.Betid);
        Sql.Execute(Update_Betwon_To_Null);
      T.Commit;
    exception
      when Sql.Duplicate_Index =>
        T.Rollback;
        Log(Me & "Make_Real_Bet", "Duplicate_Index: " & Table_Abets.To_String(Abet));      
    end ;
  end Make_Real_Bet;
  
--------------------  BET_TYPE stop----------------------------------------  

--  type Pip_Type is tagged record
--     Wanted_Price  : Float_8 := 0.0;
--     Pip_Price     : Float_8 := 0.0;
--     Lower_Index   : Integer := 0;
--     Upper_Index   : Integer := 0;
--     This_Index    : Integer := 0;
--  end record;
  procedure Init(Pip : in out Pip_Type; Price : Float_8) is
    Local : Pip_Type;
  begin
    Local.Wanted_Price := Price;   
    for i in Global_Odds_Table'range loop
      if Global_Odds_Table(i) >= Price then 
        -- we just passed it
        Local.Lower_Index := i;
        exit;
      end if;
    end loop;
    for i in reverse Global_Odds_Table'range loop
      if Global_Odds_Table(i) <= Price then 
        -- we just passed it
        Local.Upper_Index := i;
        exit;
      end if;
    end loop;
    
    if Price < Global_Odds_Table(Global_Odds_Table'First) then
      Local.Pip_Price := 1.01;
    elsif Price > Global_Odds_Table(Global_Odds_Table'Last) then
      Local.Pip_Price := 1000.0;
    else
      -- always use the upper index (round up)
      Local.This_Index := Local.Upper_Index;
      Local.Pip_Price  := Global_Odds_Table(Local.This_Index);
    end if;  
    Pip := Local;
    Log(Me & "Pip.Init", "Price: " & Price'Img & " became " & Local.Pip_Price'Img & 
                         " Upper_Index " & Local.Upper_Index'Img & 
                         " Upper_Price " & Global_Odds_Table(Local.Upper_Index)'Img  &
                         " Lower_Index " & Local.Lower_Index'Img & 
                         " Lower_Price " & Global_Odds_Table(Local.Lower_Index)'Img  );      
  end Init;
  -------------------------------- 
  function Next_Price(Pip : Pip_Type) return Float_8 is
  begin
    if Pip.This_Index < Global_Odds_Table'Last then 
      return Global_Odds_Table(Pip.This_Index + 1);
    else 
      return Global_Odds_Table( Global_Odds_Table'Last);
    end if;    
  end Next_Price;
  ---------------------------------
  function Previous_Price(Pip : Pip_Type) return Float_8 is
  begin
    if Pip.This_Index > Global_Odds_Table'First then 
      return Global_Odds_Table(Pip.This_Index - 1);
    else 
      return Global_Odds_Table( Global_Odds_Table'First);
    end if;    
  end Previous_Price;
  ---------------------------------
 
  -------------------------------------------------
  procedure Check_Bets is
    use General_Routines;
    Bet_List : Table_Abets.Abets_List_Pack.List_Type := Table_Abets.Abets_List_Pack.Create;
    Bet      : Table_Abets.Data_Type;
    T        : Sql.Transaction_Type; 
    Illegal_Data : Boolean := False;
    Side       : Bet_Type_Type; 
    Winner     : Table_Awinners.Data_Type;
    Runner     : Table_Arunners.Data_Type;
    Non_Runner : Table_Anonrunners.Data_Type;
    type Eos_Type is (AWinner, Arunner, Anonrunner);
    Eos : array (Eos_Type'range) of Boolean := (others => False);
    Selection_In_Winners,Bet_Won : Boolean := False;
    Profit  : Float_8 := 0.0;
  begin
  
    T.Start;
    -- check the dry run bets
    Select_Dry_Run_Bets.Prepare(
      "select * from ABETS where betwon is null and betname like 'DR_%' " &
      "and exists (select 'a' from AWINNERS where AWINNERS.MARKETID = ABETS.MARKETID)" ); -- must have had time to check ...
    Table_Abets.Read_List(Select_Dry_Run_Bets, Bet_List);  
      
    while not Table_Abets.Abets_List_Pack.Is_Empty(Bet_List) loop
      Illegal_Data := False;
      Table_Abets.Abets_List_Pack.Remove_From_Head(Bet_List, Bet);
      Log(Me & "Check_Bets", "Check bet " & Table_Abets.To_String(Bet));
      if Trim(Bet.Side) = "BACK" then
        Side := Back;
      elsif Trim(Bet.Side) = "LAY" then
        Side := Lay;
      else
        Illegal_Data := True;
        Log(Me & "Check_Bets", "Illegal_Data ! side -> " &  Trim(Bet.Side));
      end if;
      if not Illegal_Data then
        -- do we have a non-runner?      
        Runner.Marketid := Bet.Marketid;
        Runner.Selectionid := Bet.Selectionid;
        Table_Arunners.Read(Runner, Eos(Arunner));
        
        if not Eos(Arunner) then
          Non_Runner.Marketid := Runner.Marketid;
          Non_Runner.Name  := Runner.runnernamestripped;
          Table_Anonrunners.Read(Non_Runner, Eos(Anonrunner));
        end if;

        if not Eos(Anonrunner) then
          -- non -runner - void the bet
          Bet.Betwon := True;
          Bet.Profit := 0.0;
          Table_Abets.Update_Withcheck(Bet);
        else -- ok, lets continue        
          Winner.Marketid := Bet.Marketid;
          Winner.Selectionid := Bet.Selectionid;
          Table_Awinners.Read(Winner, Eos(Awinner));
          Selection_In_Winners := not Eos(Awinner);
        
          case Side is
            when Back => Bet_Won := Selection_In_Winners;
            when Lay  => Bet_Won := not Selection_In_Winners;
          end case;
      
          if Bet_Won then
            case Side is     -- Betfair takes 5% provision on winnings
              when Back => Profit := 0.95 * Bet.Size * (Bet.Price - 1.0);
              when Lay  => Profit := 0.95 * Bet.Size;
            end case;
          else -- lost :-(
            case Side is
              when Back => Profit := - Bet.Size;
              when Lay  => Profit := - Bet.Size * (Bet.Price - 1.0);
            end case;
          end if;        
          
          Bet.Betwon := Bet_Won;
          Bet.Profit := Profit;          
          Table_Abets.Update_Withcheck(Bet);
        end if;
      end if; -- Illegal data
    end loop;            
      
    -- check the real bets
    Select_Real_Bets.Prepare(
      "select * from ABETS where betwon is null and betname not like 'DR_%' " & 
      "and exists (select 'a' from AWINNERS where AWINNERS.MARKETID = ABETS.MARKETID)" );
    Table_Abets.Read_List(Select_Dry_Run_Bets, Bet_List);  
    while not Table_Abets.Abets_List_Pack.Is_Empty(Bet_List) loop
      Table_Abets.Abets_List_Pack.Remove_From_Head(Bet_List, Bet);
      -- Call Betfair here ! Profit & Loss
    end loop;            
      
    T.Commit;
    Table_Abets.Abets_List_Pack.Release(Bet_List);  
  end Check_Bets;  
  ------------------------------------------------------------------------------
  procedure Test_Bet is  
    B : Bet_Type;
--    T : Sql.Transaction_Type;
  begin
--    T.Start;
      B.Bot_Cfg.Bet_Name := To_Unbounded_String("HOUNDS_WINNER_BACK_BET_45_07");
      if B.History_Ok then
        Log(Me & "Test", "OK");    
      else  
        Log(Me & "Test", "Not OK");    
      end if;
--    T.Commit;
  end Test_Bet;
  
end Bet_Handler;
