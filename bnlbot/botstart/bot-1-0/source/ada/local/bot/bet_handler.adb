
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
with Table_Abalances;
with Sql;
with General_Routines;
with Sattmate_Calendar;

with Aws;
with Aws.Client;
with Aws.Response;
with Aws.Headers;
with Aws.Headers.Set;
with Sattmate_Exception;
--with Process_IO;
with Bot_Svn_Info;
with Rpc;
with Token;

pragma Elaborate_All(Aws.Headers);

package body Bet_Handler is

  Suicide: exception;
--  No_Such_Field : exception;

  Update_Betwon_To_Null,
  Select_Lost_Today,
  Select_Profit_Today,
  Select_Dry_Run_Bets,
  Select_Real_Bets,
  Select_Unsettled_Markets,
  Select_Executable_Bets,
  Select_Ongoing_Markets,
  Select_Runners,
  Select_In_The_Air,
  Select_Exists,
  Select_Prices : Sql.Statement_Type;

  Me : constant String := "Bet_Handler.";
  My_Headers : Aws.Headers.List := Aws.Headers.Empty_List;

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
      T.Rollback;
      Table_Aprices.Aprices_List_Pack.Release(Price_List);
      Table_Arunners.Arunners_List_Pack.Release(Runner_List);
      raise No_Data with "Market missing: '" & Market_Notification.Market_Id & "'";
    end if;

    if Eos(A_Event) then
      T.Rollback;
      Table_Aprices.Aprices_List_Pack.Release(Price_List);
      Table_Arunners.Arunners_List_Pack.Release(Runner_List);
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
      Log(Me & "Create", Table_Aprices.To_String(Bet_Info.Runner_Array(Max_Idx).Price));
    end loop;
    Select_Prices.Close_Cursor;
    Bet_Info.Last_Runner := Max_Idx;
    Log(Me & "Create", "Bet_Info.Last_Runner:" & Bet_Info.Last_Runner'Img);

    if Bet_Info.Last_Runner = 0 then
      T.Rollback;
      Table_Aprices.Aprices_List_Pack.Release(Price_List);
      Table_Arunners.Arunners_List_Pack.Release(Runner_List);
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
        Select_Runners.Close_Cursor;
        T.Rollback;
        Table_Aprices.Aprices_List_Pack.Release(Price_List);
        Table_Arunners.Arunners_List_Pack.Release(Runner_List);
        Log(Me & "Create", "No runner in market '" & Bet_Info.Runner_Array(i).Price.Marketid &
                            "' selectionid " & Bet_Info.Runner_Array(i).Price.Selectionid'Img);

        raise Bad_Data with "No runner in market '" & Bet_Info.Runner_Array(i).Price.Marketid &
                            "' selectionid " & Bet_Info.Runner_Array(i).Price.Selectionid'Img;
      end if;
      Select_Runners.Close_Cursor;
    end loop;

    T.Commit;

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
                              Bot_Cfg  : in out Bot_Config.Bet_Section_Type) is
    -- see if we can make a bet now
    Bet       : Bet_Type := Create(Bet_Info, Bot_Cfg);
    Fulfilled : Boolean  := True;
  begin
    Log(Me & "Try_Make_New_Bet", "Bet_name " & To_String(Bot_Cfg.Bet_Name) );

--    Log(Me & "Try_Make_New_Bet", "Market: " & Bet.Bet_Info.Market.Marketid & " " &
--                                 "Bet_Type: " &  Bet.Bot_Cfg.Bet_Type'Img & " " &
--                                 "Animal: " &  Bet.Bot_Cfg.Animal'Img  & " " &
--                                 "Country: " &  Bet.Bet_Info.Event.Countrycode & " " &
--                                 "evt-name: " &  Bet.Bet_Info.Event.Eventname);

    Bet.Check_Conditions_Fulfilled(Fulfilled);
    if not Fulfilled then
      Log(Me & "Try_Make_New_Bet", "Market: " & Bet.Bet_Info.Market.Marketid & " betting condition NOT fulfilled ");
    else
      Bet.Do_Try;
    end if;

  end Try_Make_New_Bet;

  -------------------------------------------------------------------------------

  procedure Treat_Market(Market_Notification : in     Bot_Messages.Market_Notification_Record) is
    Bet_Info : Bet_Info_Record ;
    Eol : Boolean := True;
    Bet_Section : Bet_Section_Type;
    Num_Runners : Integer ;
    use General_Routines;
  begin
    begin
      Bet_Info := Create(Market_Notification);
    exception
      when E: Bad_Data =>
        Sattmate_Exception.Tracebackinfo(E);
        return;
      when F: No_Data =>
        Sattmate_Exception.Tracebackinfo(F);
        return;
  end ;

    Num_Runners := Bet_Info.Last_Runner;

    Log(Me & "Treat_Market", "Market: " & Bet_Info.Market.Marketid & " " &
                             "Country: " &  Bet_Info.Event.Countrycode & " " &
                             "Bet_Type: " &  Bet_Info.Market.Markettype & " " &
                             "Animal: " &  Bet_Info.Event.Eventtypeid'Img  & " " &
                             "evt-name: " &  Bet_Info.Event.Eventname);

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
      Bet_Info.Try_Make_New_Bet(Bet_Section);
      Bet_Pack.Get_Next(Bot_Config.Config.Bet_Section_List, Bet_Section, Eol);
    end loop;
    Log(Me & "Treat_Market", "end market:" & Market_Notification.Market_Id);
  exception
    when E: Bad_Data =>
        Sattmate_Exception.Tracebackinfo(E);
      Log(Me & "Treat_Market", "BAD DATA, skip:" & Market_Notification.Market_Id);
  end Treat_Market;

--------------------  BET_TYPE start----------------------------------------

  function Create (Bet_Info : Bet_Info_Record'Class; Bot_Cfg : Bot_Config.Bet_Section_Type) return Bet_Type is
    Tmp : Bet_Type ;
    use General_Routines;
  begin
    Tmp.Bet_Info := Bet_Info_Record(Bet_Info);
    Tmp.Bot_Cfg := Bot_Cfg;
    --changes here needs changes in bot_config as well !!!
    if Position( Lower_Case(To_String(Tmp.Bot_Cfg.Bet_Name)), "_back_") > Natural(0) then
      null;
    elsif Position( Lower_Case(To_String(Tmp.Bot_Cfg.Bet_Name)), "_lay_") > Natural(0) then
      null;
    elsif Position( Lower_Case(To_String(Tmp.Bot_Cfg.Bet_Name)), "_greenup_") > Natural(0) then
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

  procedure Do_Try(Bet : in out Bet_Type) is
    -- see if we can make a bet now
      Todays_Profit : Profit_Type := 0.0;
      Continue_Betting : Boolean := False;
      Too_Many_In_The_Air, Exists : Boolean := True;
      Price_Matched : Bet_Price_Type := 0.0;
      Size_Matched : Bet_Size_Type := 0.0;

  begin
    Exists := Bet.Exists;
    Todays_Profit := Bet.Profit_Today;

    if not Exists then
      if Todays_Profit >= Bet.Bot_Cfg.Max_Daily_Profit then
        -- we have Won enough for today, STOP bettting!
        Continue_Betting := False;
        Log (Me & "Do_Try", "YES !! We have won enough for today, STOP bettting.");
      elsif Todays_Profit < Bet.Bot_Cfg.Max_Daily_Loss then
        -- we have lost enough for today, give up!
        Continue_Betting := False;
        Log (Me & "Do_Try", "GIVE UP! We have lost too much eventhough max_daily_num_losses is ok.");
      else
        -- we have won today, but haven't reach our ceiling yet
        Continue_Betting := True;
        Log (Me & "Do_Try", "YES !! We (probably) have won today, but not enough, KEEP bettting.");
      end if;

      -- we need a favorite with odds less than Bet.Bot_Cfg.Race_Favorite_Max_Price
      if Continue_Betting then
        declare
          use General_Routines;
          Favorite_Price : Bet_Price_Type := Bet_Price_Type(Bet.Bet_Info.Runner_Array(1).Price.Backprice);
        begin
          if Favorite_Price > Bet.Bot_Cfg.Race_Favorite_Max_Price then
            Log(Me & "Do_Try", "No clear favorite, best odds= " & F8_Image(Float_8(Favorite_Price)) &
                               " Race_Favorite_Max_Price " & F8_Image(Float_8(Bet.Bot_Cfg.Race_Favorite_Max_Price)));
            Continue_Betting := False;
          end if;
        end;
      end if;

      -- for a given market, the most expensive bet is the one with highest odds.
      -- a bet wiht odds 15 costs something. Another LAY bet on THAT market with odds less than 15 costs nothing.
      -- Because only 1 will win (if we bet on WIN markets)
      Too_Many_In_The_Air := Bet.Num_In_The_Air > Bet.Bot_Cfg.Max_Num_In_The_Air;
      if Too_Many_In_The_Air then
        Continue_Betting := False;
        Log(Me & "Do_Try", "Too many bets in the air discovered , wait for some to be settled, max= " & Bet.Bot_Cfg.Max_Num_In_The_Air'Img);
      end if;

      --before we bet anything, check finances first
      case Bot_Config.Config.System_Section.Bot_Mode is
        when Real =>
          declare
            Betfair_Result : Rpc.Result_Type ;
            Saldo          : Table_Abalances.Data_Type;
            Expected_Exposure_This_Bet : Float_8 := 0.0;
            use type Rpc.Result_Type;
            use General_Routines;
          begin
            Rpc.Get_Balance(Betfair_Result, Saldo);
            if Betfair_Result = Rpc.Ok then
              -- calculate expected exposure for this bet
              Expected_Exposure_This_Bet := Float_8(Bet.Bot_Cfg.Bet_Size * (Bet.Bot_Cfg.Max_Price - Bet_Price_Type(1.0)));
              if Expected_Exposure_This_Bet + abs(Saldo.Exposure) > Bet.Bot_Cfg.Max_Exposure then
                Log(Me & "Do_Try", "check saldo, this bet will create too much exposure, refuse" );
                Log(Me & "Do_Try", "cur/this bet/max" &
                     F8_Image(abs(Saldo.Exposure))  & "/" &
                     F8_Image(Expected_Exposure_This_Bet)  & "/" &
                     F8_Image(Float_8(Bet.Bot_Cfg.Max_Exposure)) );
                Continue_Betting := False;
              end if;
            else
              Log(Me & "Do_Try", "check saldo failed, exit " & Betfair_Result'Img);
              Continue_Betting := False;
            end if;
          end;
        when Simulation => null;
      end case;        
    
      if Continue_Betting then
        if Bet.Enabled then

          Runner_Loop : for i in 1 ..  Bet.Bet_Info.Last_Runner loop

            Bet.Bet_Info.Used_Index := i;     -- used in make_bet
            Bet.Bet_Info.Selection_Id := Bet.Bet_Info.Runner_Array(i).Price.Selectionid;  -- used in make_bet

            --Allow only if i is > than 'Min_Num_Runners_Better_Ranked'

            if Integer_4(i) > Bet.Bot_Cfg.Min_Num_Runners_Better_Ranked then

              case Bet.Bot_Cfg.Green_Up_Mode is
                when Back_First_Then_Lay =>
                  declare
                    use  General_Routines;
                    Back_Price : Bet_Price_Type := Bet_Price_Type(Bet.Bet_Info.Runner_Array(i).Price.Backprice);
                    Back_Size  : Bet_Size_Type  := Bet.Bot_Cfg.Bet_Size ;
                    Lay_Price  : Bet_Price_Type := 0.0;
                    Lay_Size   : Bet_Size_Type  := 0.0;
                    Pip_Lay    : Pip_Type ;
                    Pip_Back   : Pip_Type ;

                  begin
                    if Bet.Bot_Cfg.Min_Price <= Back_Price and then
                       Back_Price <= Bet.Bot_Cfg.Max_Price then
                      Pip_Back.Init(Float_8(Back_Price));
                      Back_Price := Bet_Price_Type(Pip_Back.Previous_Price);  -- make sure we get the Back-bet

                      case Bot_Config.Config.System_Section.Bot_Mode is
                        when Real =>
                          Bet.Make_Bet(A_Bet_Type => Back,
                                       Price => Back_Price, Size => Back_Size,
                                       Price_Matched => Price_Matched, Size_Matched => Size_Matched);
                          -- use the matched back_price
                          Lay_Price := Price_Matched - Bet.Bot_Cfg.Delta_Price;
                          Pip_Lay.Init(Float_8(Lay_Price));
                          Lay_Price := Bet_Price_Type(Pip_Lay.Pip_Price);

                          Lay_Size  := (Back_Size * Back_Price) / Lay_Price;
                          Log(Me & "Do_Try", Bet.Bot_Cfg.Green_Up_Mode'Img & " " &
                                       "Back_Price: " & F8_Image(Float_8(Back_Price)) & " " &
                                       "Back_Size: " & F8_Image(Float_8(Back_Size)) & " " &
                                       "Lay_Price: " & F8_Image(Float_8(Lay_Price)) & " " &
                                       "Lay_Size: " & F8_Image(Float_8(Lay_Size)));

                          if Price_Matched > 0.0 then
                            Bet.Make_Bet(A_Bet_Type => Lay,
                                         Price => Lay_Price, Size => Lay_Size,
                                         Price_Matched => Price_Matched, Size_Matched => Size_Matched);
                          else
                            Log(Me & "Do_Try", "Back bet not matched -> no lay bet made");
                          end if;

                        when Simulation  => raise Suicide with "Green_Up_Mode Back_First_Then_Lay and Simulation does not match";
                            
                      end case;
                    end if;
                  end;
                when Lay_First_Then_Back =>
                  declare
                    use  General_Routines;
                    Lay_Price  : Bet_Price_Type := Bet_Price_Type(Bet.Bet_Info.Runner_Array(i).Price.Layprice);
                    Lay_Size   : Bet_Size_Type  := Bet.Bot_Cfg.Bet_Size ;
                    Back_Price : Bet_Price_Type := 0.0;
                    Back_Size  : Bet_Size_Type  := 0.0;
                    Pip_Lay    : Pip_Type ;
                    Pip_Back   : Pip_Type ;
                  begin

                    if Bet.Bot_Cfg.Min_Price <= Lay_Price and then
                       Lay_Price <= Bet.Bot_Cfg.Max_Price then

                      Pip_Lay.Init(Float_8(Lay_Price));
                      Lay_Price := Bet_Price_Type(Pip_Lay.Next_Price);  -- make sure we get the Lay-bet

                      case Bot_Config.Config.System_Section.Bot_Mode is
                        when Real =>
                          Bet.Make_Bet(A_Bet_Type => Lay,
                                       Price => Lay_Price, Size => Lay_Size,
                                       Price_Matched => Price_Matched, Size_Matched => Size_Matched);

                          if Price_Matched > 0.0 then
                            -- use the matched lay_price
                            Back_Price := Price_Matched + Bet.Bot_Cfg.Delta_Price;
                            Back_Size := Lay_Size - Bet.Bot_Cfg.Delta_Size;
                            if Back_Size < 30.0 then
                              Back_Size := 30.0;
                            end if;

                            Pip_Back.Init(1000.0, Silent => True);
                            loop
                              Back_Price := Bet_Price_Type(Pip_Back.Previous_Price);
                              exit when Back_Size * (Back_Price - Bet_Price_Type(1.0)) <= Size_Matched * (Price_Matched - Bet_Price_Type(1.0));
                              Pip_Back.Init(Float_8(Back_Price), Silent => True);
                            end loop;
                            Log(Me & "Do_Try ",
                                   "Back_Size * (Back_Price - Bet_Price_Type(1.0)) " & F8_Image(Float_8(Back_Size * (Back_Price - Bet_Price_Type(1.0)))) & " " &
                                   "Size_Matched * (Price_Matched - Bet_Price_Type(1.0)) " & F8_Image(Float_8(Size_Matched * (Price_Matched - Bet_Price_Type(1.0)))) & " " &
                                   "Back_Price: " & F8_Image(Float_8(Back_Price)) & " " &
                                   "Back_Size: " & F8_Image(Float_8(Back_Size)) & " " &
                                   "Lay_Price: " & F8_Image(Float_8(Lay_Price)) & " " &
                                   "Price_Matched: " & F8_Image(Float_8(Price_Matched)) & " " &
                                   "Lay_Size: " & F8_Image(Float_8(Lay_Size)) & " " &
                                   "Size_Matched: " & F8_Image(Float_8(Size_Matched)));

                            Bet.Make_Bet(A_Bet_Type => Back,
                                         Price => Back_Price, Size => Back_Size,
                                         Price_Matched => Price_Matched, Size_Matched => Size_Matched);
                          else
                            Log(Me & "Do_Try", "Lay bet not matched -> no back bet made");
                          end if;

                        when Simulation  => raise Suicide with "Green_Up_Mode Lay_First_Then_Back and Simulation does not match";
                      end case;
                    end if;
                  end;
                when None => -- ordinary bets, mostly Simulations  
                  case Bet.Bot_Cfg.Bet_Type is
                    when Back =>
                      declare
                        use  General_Routines;
                        Back_Price : Bet_Price_Type := Bet_Price_Type(Bet.Bet_Info.Runner_Array(i).Price.Backprice);
                        Back_Size  : Bet_Size_Type  := Bet.Bot_Cfg.Bet_Size ;
                        Pip_Back   : Pip_Type ;
                      begin
                        if Bet.Bot_Cfg.Min_Price <= Back_Price and then
                           Back_Price <= Bet.Bot_Cfg.Max_Price then
                          Pip_Back.Init(Float_8(Back_Price));
                          Back_Price := Bet_Price_Type(Pip_Back.Previous_Price);  -- make sure we get the Back-bet
    
                          Bet.Make_Bet(A_Bet_Type => Back,
                                       Price => Back_Price, Size => Back_Size,
                                       Price_Matched => Price_Matched, Size_Matched => Size_Matched);
                        end if;
                      end;
                      
                    when Lay =>
                      declare
                        use  General_Routines;
                        Lay_Price  : Bet_Price_Type := Bet_Price_Type(Bet.Bet_Info.Runner_Array(i).Price.Layprice);
                        Lay_Size   : Bet_Size_Type  := Bet.Bot_Cfg.Bet_Size ;
                        Pip_Lay    : Pip_Type ;
                      begin
                        if Bet.Bot_Cfg.Min_Price <= Lay_Price and then
                           Lay_Price <= Bet.Bot_Cfg.Max_Price then
    
                          Pip_Lay.Init(Float_8(Lay_Price));
                          Lay_Price := Bet_Price_Type(Pip_Lay.Next_Price);  -- make sure we get the Lay-bet
    
                          Bet.Make_Bet(A_Bet_Type => Lay,
                                       Price => Lay_Price, Size => Lay_Size,
                                       Price_Matched => Price_Matched, Size_Matched => Size_Matched);
                        end if;
                      end;
                    when Greenup => raise Suicide with "Bet_Side Greenup and None does not match";
                end case;
              end case;
            else
              Log(Me & "Do_Try", "i:" & i'Img & " Min_Num_Runners_Better_Ranked" & Bet.Bot_Cfg.Min_Num_Runners_Better_Ranked'Img &
                     ". This runner is ranked too high, no bet");
            end if;
          end loop Runner_Loop;
        else
          Log(Me & "Do_Try", "bet disabled " & To_String(Bet.Bot_Cfg.Bet_Name));
        end if; -- enabled
      end if;-- continue betting
    else
      Log(Me & "Do_Try", "Bet alredy placed on this market: " & Bet.Bet_Info.Market.Marketid);
    end if;
  end Do_Try;

  -----------------------------------------------------------------------
  procedure Check_Conditions_Fulfilled(Bet : in out Bet_Type; Result : in out Boolean) is
    Num_Runners : Integer := Bet.Bet_Info.Last_Runner;
    use General_Routines;
  begin
    Result := True;
    Log(Me & "Check_Conditions_Fulfilled", "marketid " &  General_Routines.Trim(Bet.Bet_Info.Market.Marketid ));

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
--        if Upper_Case(Trim(Bet.Bet_Info.Market.Markettype)) /= "PLACE" then
----          Log(Me & "Check_Conditions_Fulfilled", "wrong Markettype for this bot should be: '" &  Bet.Bot_Cfg.Market_Type'Img & "' is '" & Upper_Case(Trim(Bet.Bet_Info.Market.Markettype)) & "'");
          Result := False;
          return ; -- wrong markettype for this bot
--        end if;
    end case;

    if Num_Runners < Bet.Bot_Cfg.Min_Num_Runners or else
       Num_Runners > Bet.Bot_Cfg.Max_Num_Runners then
      Log(Me & "Check_Conditions_Fulfilled", "bad num runners" & Num_Runners'Img &
         " min=" &  Bet.Bot_Cfg.Min_Num_Runners'Img &
        " max=" &  Bet.Bot_Cfg.Max_Num_Runners'Img);
      Result := False;
      return;
    end if;

    if Bet.Bet_Info.Market.Numwinners /= Bet.Bot_Cfg.Num_Winners then
      Log(Me & "Check_Conditions_Fulfilled", "bad num winner" & Bet.Bet_Info.Market.Numwinners'Img &
         " /=" & Bet.Bot_Cfg.Num_Winners'Img);
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
          Log(Me & "Check_Conditions_Fulfilled", "wrong country. OK countries are  : '" & Countries & "' market country is '" & Bet.Bet_Info.Event.Countrycode & "'");
          Result := False;
          return ; -- wrong country for this bot
      end if;
    end;

    -- Allowed day ?
    declare
      use Sattmate_Calendar;
      Race_Day : Week_Day_Type := Week_Day_Of(Bet.Bet_Info.Market.Startts);
    begin
      if not Bet.Bot_Cfg.Allowed_Days(Race_Day) then
        Log(Me & "Check_Conditions_Fulfilled", "No betting allowed on a " & Race_Day'Img );
        Result := False;
        return;
      end if;
    end;

    case Bot_Config.Config.System_Section.Bot_Mode is 
      when Real =>
        -- check market status --?
        if General_Routines.Trim(Bet.Bet_Info.Market.Status) /= "OPEN" then
          Log(Me & "Check_Conditions_Fulfilled", "Market.Status /= 'OPEN', '" & General_Routines.Trim(Bet.Bet_Info.Market.Status) & "'");
          Result := False;
          return;
        end if;
      when Simulation => null; -- simulation has only closed orders ...
    end case;       
  end Check_Conditions_Fulfilled;
  ------------------------------------------------------------------------------------------------------


  ------------------------------------------------------------------------------------------------------
  function Profit_Today(Bet : Bet_Type) return Profit_Type is
    T : Sql.Transaction_Type;
    Eos : Boolean := False;
    Profit : Float_8 := 0.0;
    use Sattmate_Calendar;
    Start_Date, End_Date : Time_Type := Clock;
  begin
    T.Start;
      Start_Date := Bet.Bet_Info.Market.Startts;
      End_Date   := Bet.Bet_Info.Market.Startts;

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
        "from " &
          "ABETS " &
        "where " &
          "STARTTS >= :STARTOFDAY " &
          "and STARTTS <= :ENDOFDAY " &
          "and BETMODE = :BOTMODE " &
          "and BETWON is not null " &
          "and BETNAME = :BETNAME " );

      Select_Profit_Today.Set("BOTMODE", Bot_Mode(Bot_Config.Config.System_Section.Bot_Mode));
      Select_Profit_Today.Set( "BETNAME", To_String(Bet.Bot_Cfg.Bet_Name));

      Select_Profit_Today.Set_Timestamp( "STARTOFDAY",Start_Date);
      Select_Profit_Today.Set_Timestamp( "ENDOFDAY",End_Date);
      Select_Profit_Today.Open_Cursor;
      Select_Profit_Today.Fetch(Eos);
      if not Eos then
        Select_Profit_Today.Get(1, Profit);
      end if;
      Select_Profit_Today.Close_Cursor;
    T.Commit;
    Log(Me & "Profit_Today",  To_String(Bet.Bot_Cfg.Bet_Name) & " :" & Integer(Profit)'Img);

    return Profit_Type(Profit);
  end Profit_Today;
  ------------------------------------------------------------------------------------------------------
  function Num_Losses_Today(Bet : Bet_Type) return Integer_4 is
    T : Sql.Transaction_Type;
    Eos : Boolean := False;
    use Sattmate_Calendar;
    Start_Date, End_Date : Time_Type := Clock;
    Num_Losses : Integer_4 := 0;
  begin
    T.Start;
      Start_Date := Bet.Bet_Info.Market.Startts;
      End_Date := Bet.Bet_Info.Market.Startts;

      Start_Date.Hour        := 0;
      Start_Date.Minute      := 0;
      Start_Date.Second      := 0;
      Start_Date.MilliSecond := 0;

      End_Date.Hour        := 23;
      End_Date.Minute      := 59;
      End_Date.Second      := 59;
      End_Date.MilliSecond := 999;

      Select_Lost_Today.Prepare(
        "select count('a') " &
        "from ABETS " &
        "where STARTTS >= :STARTOFDAY " &
        "and STARTTS <= :ENDOFDAY " &
        "and BETMODE = :BOTMODE " &
        "and PROFIT < 0.0 " &
        "and BETWON is not null " &
        "and BETNAME = :BETNAME " );

      Select_Lost_Today.Set("BOTMODE",  Bot_Mode(Bot_Config.Config.System_Section.Bot_Mode));
      Select_Lost_Today.Set( "BETNAME", To_String(Bet.Bot_Cfg.Bet_Name));
      Select_Lost_Today.Set_Timestamp( "STARTOFDAY",Start_Date);
      Select_Lost_Today.Set_Timestamp( "ENDOFDAY",End_Date);
      Select_Lost_Today.Open_Cursor;
      Select_Lost_Today.Fetch(Eos);
      if not Eos then
        Select_Lost_Today.Get(1, Num_Losses);
      else
        Num_Losses := 0;
      end if;
      Select_Lost_Today.Close_Cursor;
    T.Commit;
    Log(Me & "Num_Losses_Today",  To_String(Bet.Bot_Cfg.Bet_Name) & " :" & " HAS lost" & Num_Losses'Img & " times today: " & Sattmate_Calendar.String_Date(Start_Date));
    return Num_Losses;
  end Num_Losses_Today;

  ------------------------------------------------------------------------------------------------------
--  function To_String(Bet : Bet_Type) return String;
  function Exists(Bet : Bet_Type) return Boolean is
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
         "and SELECTIONID = :SELECTIONID " &
         "and BETMODE = :BOTMODE " &
         "and BETNAME = :BETNAME ");

      Select_Exists.Set("SELECTIONID",  Bet.Bet_Info.Selection_Id);
      Select_Exists.Set("BOTMODE",  Bot_Mode(Bot_Config.Config.System_Section.Bot_Mode));
      Select_Exists.Set("BETNAME",  To_String(Bet.Bot_Cfg.Bet_Name));
      Select_Exists.Set("MARKETID", Bet.Bet_Info.Market.Marketid);

      Select_Exists.Open_Cursor;
      Select_Exists.Fetch( Eos);
      if not Eos then
        Abet := Table_Abets.Get(Select_Exists);
        Log(Me & "Exists", "Bet does already exist " & Table_Abets.To_String(Abet));
      else
        null;
--        Log(Me & "Exists", "Bet does not exist");
      end if;
      Select_Exists.Close_Cursor;
    T.Commit;
    return not Eos;
  end Exists;
  ---------------------------------------------------------------
  function Num_In_The_Air(Bet : Bet_Type) return Integer_4 is
    T    : Sql.Transaction_Type;
    Eos  : Boolean := False;
    Num : Integer_4 := 0;
  begin
    T.Start;
      Select_In_The_Air.Prepare(
         "select count('a') " &
         "from " &
           "ABETS " &
         "where BETWON is null " &
         "and BETMODE = :BOTMODE " &
         "and BETNAME = :BETNAME ");

      Select_In_The_Air.Set("BOTMODE", Bot_Mode(Bot_Config.Config.System_Section.Bot_Mode));
      Select_In_The_Air.Set("BETNAME", To_String(Bet.Bot_Cfg.Bet_Name));

      Select_In_The_Air.Open_Cursor;
      Select_In_The_Air.Fetch(Eos);
      if not Eos then
        Select_In_The_Air.Get(1, Num);
      end if;
      Select_In_The_Air.Close_Cursor;
    T.Commit;
    return Num;
  end Num_In_The_Air;
  ---------------------------------------------------------------

  procedure Make_Bet(Bet           : in out Bet_Type;
                     A_Bet_Type    : in     Bet_Type_Type;
                     Price         : in     Bet_Price_Type;
                     Size          : in     Bet_Size_Type;
                     Price_Matched :    out Bet_Price_Type;
                     Size_Matched  :    out Bet_Size_Type ) is


    A_Token : Token.Token_Type := Rpc.Get_Token;


    Abet : Table_Abets.Data_Type;
    Local_Price : Float_8 := Float_8(Price);

    Side                           : String (1..4)   :=  (others => ' ') ;
    Bet_Name                       : String (1..100) :=  (others => ' ') ;
    Execution_Report_Status        : String (1..50)  :=  (others => ' ') ;
    Execution_Report_Error_Code    : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Status      : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Error_Code  : String (1..50)  :=  (others => ' ') ;
    Tmp_Bet_Id                     : String (1..20)  :=  (others => ' ') ;
    Customer_Reference             : String (1..30)  :=  (others => ' ') ;
    Runner_Name                    : String (1..50)  :=  (others => ' ') ;
    Order_Status                   : String (1..50)  :=  (others => ' ') ;
    L_Size_Matched,
    Average_Price_Matched          : Float := 0.0;
    Powerdays                      : Integer_4 := 0;

    Local_Size :  Bet_Size_Type := Size;


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
    Price_Matched := 0.0;
    Size_Matched := 0.0;

--  type Data_Type is record
--      Betid :    Integer_8  := 0 ; -- Primary Key
--      Marketid :    String (1..11) := (others => ' ') ; -- non unique index 2
--      Botmode :    Integer_4  := 0 ; --
--      Powerdays :    Integer_4  := 0 ; -- non unique index 3
--      Selectionid :    Integer_4  := 0 ; --
--      Reference :    String (1..30) := (others => ' ') ; --
--      Size :    Float_8  := 0.0 ; --
--      Price :    Float_8  := 0.0 ; --
--      Side :    String (1..4) := (others => ' ') ; --
--      Betname :    String (1..100) := (others => ' ') ; -- non unique index 4
--      Betwon :    Boolean  := False ; -- non unique index 5
--      Profit :    Float_8  := 0.0 ; --
--      Status :    String (1..50) := (others => ' ') ; --
--      Exestatus :    String (1..50) := (others => ' ') ; --
--      Exeerrcode :    String (1..50) := (others => ' ') ; --
--      Inststatus :    String (1..50) := (others => ' ') ; --
--      Insterrcode :    String (1..50) := (others => ' ') ; --
--      Startts :    Time_Type  := Time_Type_First ; -- non unique index 6
--      Betplaced :    Time_Type  := Time_Type_First ; -- non unique index 7
--      Pricematched :    Float_8  := 0.0 ; --
--      Sizematched :    Float_8  := 0.0 ; --
--      Runnername :    String (1..50) := (others => ' ') ; --
--      Fullmarketname :    String (1..50) := (others => ' ') ; --
--      Svnrevision :    Integer_4  := 0 ; --
--      Ixxlupd :    String (1..15) := (others => ' ') ; --
--      Ixxluts :    Time_Type  := Time_Type_First ; --
--  end record;

    case A_Bet_Type is
      when Back    => Move("BACK", Side);
      when Lay     =>  Move("LAY", Side);   
      when Greenup => raise Suicide with "bad data GREENUP";      
    end case;

    Move( To_String(Bet.Bot_Cfg.Bet_Name), Bet_Name);
    Move( Bet.Bet_Info.Runner_Array(Bet.Bet_Info.Used_Index).Runner.Runnernamestripped, Runner_Name);

    Log(Me & "Make_Bet", "Side :" & Side & " Botmode: " & Bot_Config.Config.System_Section.Bot_Mode'Img);

    case Bot_Config.Config.System_Section.Bot_Mode is
      when Real =>

        -- prepare the AWS
        Aws.Headers.Set.Reset(My_Headers);
        Aws.Headers.Set.Add (My_Headers, "X-Authentication", A_Token.Get);
        Aws.Headers.Set.Add (My_Headers, "X-Application", A_Token.Get_App_Key);
        Aws.Headers.Set.Add (My_Headers, "Accept", "application/json");

        declare
          Size_String : String := General_Routines.F8_Image(Float_8(Size)); -- 2 decimals only
        begin
          Local_Size := Bet_Size_Type'Value(Size_String); -- to avoid INVALID_BET_SIZE
        end;

        case A_Bet_Type is
          when Back =>
            case Bet.Bot_Cfg.Green_Up_Mode is
              when Back_First_Then_Lay => Limit_Order.Set_Field (Field_Name => "persistenceType", Field => Bet.Bot_Cfg.Back_First_Bet_Persistance'Img);
              when Lay_First_Then_Back => Limit_Order.Set_Field (Field_Name => "persistenceType", Field => Bet.Bot_Cfg.Back_Second_Bet_Persistance'Img);
              when None                => Limit_Order.Set_Field (Field_Name => "persistenceType", Field => Bet.Bot_Cfg.Back_First_Bet_Persistance'Img);
            end case;
            Limit_Order.Set_Field (Field_Name => "price", Field => Float(Local_Price));
            Limit_Order.Set_Field (Field_Name => "size", Field => Float(Local_Size));
          when Lay =>
            case Bet.Bot_Cfg.Green_Up_Mode is
              when Back_First_Then_Lay => Limit_Order.Set_Field (Field_Name => "persistenceType", Field => Bet.Bot_Cfg.Lay_Second_Bet_Persistance'Img);
              when Lay_First_Then_Back => Limit_Order.Set_Field (Field_Name => "persistenceType", Field => Bet.Bot_Cfg.Lay_First_Bet_Persistance'Img);
              when None                => Limit_Order.Set_Field (Field_Name => "persistenceType", Field => Bet.Bot_Cfg.Lay_First_Bet_Persistance'Img);
            end case;
            Limit_Order.Set_Field (Field_Name => "price", Field => Float(Local_Price));
            Limit_Order.Set_Field (Field_Name => "size", Field => Float(Local_Size));
          when Greenup => raise Suicide with "bad data GREENUP";      
        end case;

        Instruction.Set_Field (Field_Name => "limitOrder",  Field => Limit_Order);
        Instruction.Set_Field (Field_Name => "orderType",   Field => "LIMIT");
        Instruction.Set_Field (Field_Name => "side",        Field => General_Routines.Trim(Side));
        Instruction.Set_Field (Field_Name => "handicap",    Field => 0);
        Instruction.Set_Field (Field_Name => "selectionId", Field => Integer( Bet.Bet_Info.Runner_Array(Bet.Bet_Info.Used_Index).Runner.Selectionid));

        Append (Instructions , Instruction);
--      will get INVALID_CUSTOMER_REF from betfair if not unique
--        Params.Set_Field (Field_Name => "customerRef",          Field      => "some ref to fill in later"); -- what to put here?
--        pragma Compile_time_warning(True, "customerRef to keep pair together?");
        Params.Set_Field (Field_Name => "instructions", Field => Instructions);
        Params.Set_Field (Field_Name => "marketId",     Field => Bet.Bet_Info.Market.Marketid);

        Query_Place_Orders.Set_Field (Field_Name => "params", Field => Params);
        case A_Bet_Type is
          when Back    => Query_Place_Orders.Set_Field (Field_Name => "id", Field => 15);          -- what to put here?
          when Lay     => Query_Place_Orders.Set_Field (Field_Name => "id", Field => 15);          -- what to put here?
          when Greenup => raise Suicide with "bad data GREENUP";      
        end case;
--        pragma Compile_time_warning(True, "id to keep pair together?");
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

        Log(Me & "Make_Bet", "posting: " & Query_Place_Orders.Write  );

        Answer_Place_Orders := Aws.Client.Post (Url          =>  Token.URL_BETTING,
                                                Data         =>  Query_Place_Orders.Write,
                                                Content_Type => "application/json",
                                                Headers      =>  My_Headers,
                                                Timeouts     =>  Aws.Client.Timeouts (Each => 30.0));
        begin
          if String'(Aws.Response.Message_Body(Answer_Place_Orders)) /= "Post Timeout" then
            Reply_Place_Orders := Read (Strm     => Aws.Response.Message_Body(Answer_Place_Orders),
                                        Filename => "");
            Log(Me & "Make_Bet", "Got reply: " & Reply_Place_Orders.Write  );
          else
            Log(Me & "Make_Bet", "Post Timeout -> Give up placeOrder");
            return;
          end if;
        exception
          when others =>
             Log(Me & "Make_Bet", "***********************  Bad reply start *********************************");
             Log(Me & "Make_Bet", "Bad reply" & Aws.Response.Message_Body(Answer_Place_Orders));
             Log(Me & "Make_Bet", "***********************  Bad reply stop  ********  -> Give up placeOrders" );
             return;
        end ;

        -- parse out the reply.
        -- check for API exception/Error first

        if RPC.API_Exceptions_Are_Present(Reply_Place_Orders) then
          Log(Me & "Make_Bet", "APINGException is present, return");
          return;
        end if;

-- {
--    "jsonrpc":"2.0",
--    "result":
--            {
--                "status":"SUCCESS",
--                "marketId":"1.110689758",
--                "instructionReports":
--                    [
--                        {
--                             "status":"SUCCESS",
--                             "instruction":
--                                {
--                                   "orderType":"LIMIT",
--                                   "selectionId":6644807,
--                                   "handicap":0.0,
--                                   "side":"BACK",
--                                   "limitOrder":
--                                       {
--                                          "size":30.0,
--                                          "price":2.3,
--                                          "persistenceType":"LAPSE"
--                                        }
--                               },
--                               "betId":"29225429632",
--                               "placedDate":"2013-08-24T12:43:54.000Z",
--                               "averagePriceMatched":2.3399999999999994,
--                               "sizeMatched":30.0
--                        }
--                    ]
--                },
--        "id":15
--}

        -- ok we have a parsable answer with no formal errors.
        -- lets look at it
        declare
          Result           : JSON_Value := Create_Object;
          InstructionsItem : JSON_Value := Create_Object;
          Instructions   : JSON_Array := Empty_Array;
        begin

          if Reply_Place_Orders.Has_Field("result") then
            Result := Reply_Place_Orders.Get("result");
          else
              Log(Me & "Make_Bet", "NO RESULT!!" );
              raise Suicide with "Betfair reply has no result!";
          end if;

          -- sanity check, but what to do if fail?
          if Reply_Place_Orders.Has_Field("customerRef") then
            Move( Params.Get("customerRef"), Customer_Reference);

            if General_Routines.Trim(Customer_Reference) /= String'(Reply_Place_Orders.Get("customerRef")) then
              Log(Me & "Make_Bet", "expected customerRef '" & Params.Get("customerRef") &
                  "' received customerRef '" & Reply_Place_Orders.Get("customerRef"));
            end if;
          end if;

          if Result.Has_Field("marketid") then
            if General_Routines.Trim(Bet.Bet_Info.Market.Marketid) /= String'(Result.Get("marketid")) then
              Log(Me & "Make_Bet", "expected marketid '" & General_Routines.Trim(Bet.Bet_Info.Market.Marketid) &
                  "' received marketid '" & Result.Get("marketid"));
            end if;
          end if;

          if Result.Has_Field("status") then
            Log(Me & "Make_Bet", "got result.status");
            Move( Result.Get("status"), Execution_Report_Status);
          end if;

          if Result.Has_Field("errorCode") then
            Log(Me & "Make_Bet", "got result.errorCode");
            Move( Result.Get("errorCode"), Execution_Report_Error_Code);
          end if;

          if Result.Has_Field("instructionReports") then
            Instructions := Result.Get("instructionReports");
            Log(Me & "Make_Bet", "got result.instructionReports");

            InstructionsItem  := Get(Instructions, 1); -- always element 1, since we only have 1
            Log(Me & "Make_Bet", "got InstructionsItem");

            if InstructionsItem.Has_Field("status") then
              Log(Me & "Make_Bet", "got InstructionsItem.Status");
              Move(InstructionsItem.Get("status"), Instruction_Report_Status);
            end if;

            if InstructionsItem.Has_Field("errorCode") then
              Log(Me & "Make_Bet", "got InstructionsItem.errorCode");
              Move(InstructionsItem.Get("errorCode"), Instruction_Report_Error_Code);
            end if;
          end if;

          if InstructionsItem.Has_Field("instruction") then
            Log(Me & "Make_Bet", "got InstructionsItem.instruction");
            Instruction := InstructionsItem.Get("instruction");
          else
            Log(Me & "Make_Bet", "NO Instruction in Instructions!!" );
            raise Suicide with "Betfair reply has no Instruction!";
          end if;

          -- get selectionid?

          if InstructionsItem.Has_Field("betId") then
            Move( InstructionsItem.Get("betId"), Tmp_Bet_Id );
            Log(Me & "Make_Bet", "got InstructionsItem.betid");
            if Tmp_Bet_Id(2) = '.' then
              Bet_Id := Integer_8'Value(Tmp_Bet_Id(3 .. Tmp_Bet_Id'Last));
            else
              Bet_Id := Integer_8'Value(Tmp_Bet_Id);
            end if;
          end if;

          if InstructionsItem.Has_Field("sizeMatched") then
            Log(Me & "Make_Bet", "got InstructionsItem.sizeMatched");
            L_Size_Matched := InstructionsItem.Get("sizeMatched");
            Size_Matched := Bet_Size_Type(L_Size_Matched);
          end if;

          if abs(Float_8(L_Size_Matched) - Float_8(Bet.Bot_Cfg.Bet_Size)) < 0.0001 then
            Move( "EXECUTION_COMPLETE", Order_Status );
          else
            Move( "EXECUTABLE", Order_Status );
          end if;

          if InstructionsItem.Has_Field("averagePriceMatched") then
            Log(Me & "Make_Bet", "got InstructionsItem.averagePriceMatched");
            Average_Price_Matched := InstructionsItem.Get("averagePriceMatched");
            Price_Matched := Bet_Price_Type(Average_Price_Matched);
          end if;
        end ;

      when Simulation =>
        Bet_Id := Integer_8(Bot_System_Number.New_Number(Bot_System_Number.Betid));
        Move( "EXECUTION_COMPLETE", Order_Status);
        Move( "SUCCESS", Execution_Report_Status);
        Move( "SUCCESS", Execution_Report_Error_Code);
        Move( "SUCCESS", Instruction_Report_Status);
        Move( "SUCCESS", Instruction_Report_Error_Code);
        case A_Bet_Type is
          when Back =>
            Average_Price_Matched := Float(Local_Price);
            L_Size_Matched := Float(Bet.Bot_Cfg.Bet_Size);
            Move( Bet.Bet_Info.Runner_Array(Bet.Bet_Info.Used_Index).Runner.Runnernamestripped, Runner_Name);
          when Lay =>
            Average_Price_Matched := Float(Local_Price);
            L_Size_Matched := Float(Bet.Bot_Cfg.Bet_Size);
            Move( Bet.Bet_Info.Runner_Array(Bet.Bet_Info.Used_Index).Runner.Runnernamestripped, Runner_Name);
          when Greenup => raise Suicide with "bad data GREENUP";      
            
        end case;
        Price_Matched := Bet_Price_Type(Average_Price_Matched);

    end case;

    if General_Routines.Trim(Execution_Report_Status) /= "SUCCESS" then
      Bet_id := Integer_8(Bot_System_Number.New_Number(Bot_System_Number.Betid));
      Log(Me & "Make_Bet", "bad bet, save it for later with dr betid");
    end if;

    Abet := (
      Betid          => Bet_Id,
      Marketid       => Bet.Bet_Info.Market.Marketid,
      Betmode        => Bot_Mode(Bot_Config.Config.System_Section.Bot_Mode),
      Powerdays      => Powerdays,
      Selectionid    => Bet.Bet_Info.Selection_Id,
      Reference      => (others => '-'),
      Size           => Float_8(Local_Size),
      Price          => Local_Price,
      Side           => Side,
      Betname        => Bet_Name,
      Betwon         => False,
      Profit         => 0.0,
      Status         => Order_Status, -- ??
      Exestatus      => Execution_Report_Status,
      Exeerrcode     => Execution_Report_Error_Code,
      Inststatus     => Instruction_Report_Status,
      Insterrcode    => Instruction_Report_Error_Code,
      Startts        => Bet.Bet_Info.Market.Startts,
      Betplaced      => Now,
      Pricematched   => Float_8(Average_Price_Matched),
      Sizematched    => Float_8(L_Size_Matched),
      Runnername     => Runner_Name,
      Fullmarketname => Bet.Bet_Info.Market.Marketname,
      Svnrevision    => Bot_Svn_Info.Revision,
      Ixxlupd        => (others => ' '), --set by insert
      Ixxluts        => Now              --set by insert
    );

    begin
      T.Start;
        Table_Abets.Insert(Abet);
        Log(Me & "Make_Bet", To_String(Bet.Bot_Cfg.Bet_Name) & " inserted bet: " & Table_Abets.To_String(Abet));
        if General_Routines.Trim(Execution_Report_Status) = "SUCCESS" then
          Update_Betwon_To_Null.Prepare("update ABETS set BETWON = null where BETID = :BETID");
          Sql.Set(Update_Betwon_To_Null,"BETID", Abet.Betid);
          Sql.Execute(Update_Betwon_To_Null);
        end if;
      T.Commit;
    exception
      when Sql.Duplicate_Index =>
        T.Rollback;
        Log(Me & "Make_Bet", "Duplicate_Index: " & Table_Abets.To_String(Abet));
    end ;
  end Make_Bet;

--------------------  BET_TYPE stop----------------------------------------

--  type Pip_Type is tagged record
--     Wanted_Price  : Float_8 := 0.0;
--     Pip_Price     : Float_8 := 0.0;
--     Lower_Index   : Integer := 0;
--     Upper_Index   : Integer := 0;
--     This_Index    : Integer := 0;
--  end record;
  procedure Init(Pip : in out Pip_Type; Price : Float_8; Silent : Boolean := False) is
    Local : Pip_Type;
  begin
    if Price < Global_Odds_Table(Global_Odds_Table'First) then
      Local.Pip_Price := 1.01;
    elsif Price > Global_Odds_Table(Global_Odds_Table'Last) then
      Local.Pip_Price := 1000.0;
    end if;

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

    -- always use the upper index (round up)
    Local.This_Index := Local.Upper_Index;
    Local.Pip_Price  := Global_Odds_Table(Local.This_Index);
    Pip := Local;
    if not Silent then
      Log(Me & "Pip.Init", "Price: " & General_Routines.F8_Image(Price) & " became " &
                                     General_Routines.F8_Image(Local.Pip_Price) &
                         " Upper_Index " & Local.Upper_Index'Img &
                         " Upper_Price " & General_Routines.F8_Image(Global_Odds_Table(Local.Upper_Index))  &
                         " Lower_Index " & Local.Lower_Index'Img &
                         " Lower_Price " & General_Routines.F8_Image(Global_Odds_Table(Local.Lower_Index))  );
    end if;                     
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
    Bet,Bet_From_List      : Table_Abets.Data_Type;
    T        : Sql.Transaction_Type;
    Illegal_Data : Boolean := False;
    Side       : Bet_Type_Type;
    Runner     : Table_Arunners.Data_Type;
    type Eos_Type is (Arunner ,
                      Abets);
    Eos        : array (Eos_Type'range) of Boolean := (others => False);
    Selection_In_Winners,
    Bet_Won               : Boolean := False;
    Profit                : Float_8 := 0.0;
    Start_Ts              : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
    Stop_Ts               : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_Last;

    Rpc_Status : Rpc.Result_Type;
    use type Sattmate_Calendar.Time_Type;

  begin
    Log(Me & "Check_Bets", "start");

    T.Start;
    -- check the dry run bets
    Select_Dry_Run_Bets.Prepare(
      "select B.* from ABETS B, AMARKETS M " &
      "where B.MARKETID = M.MARKETID " &
      "and B.BETWON is null " & -- will be not null if updated
      "and B.BETID < 1000000000 " & -- local bet
      "and M.STATUS in ('SUSPENDED','SETTLED','CLOSED') " & -- does 'SETTLED' exist?
--      "and B.IXXLUPD = :BOTNAME " & --only fix my bets, so no rollbacks ...
      "and exists (select 'a' from ARUNNERS where ARUNNERS.MARKETID = B.MARKETID and ARUNNERS.STATUS = 'WINNER')" ); -- must have had time to check ...  
--    Select_Dry_Run_Bets.Set("BOTNAME", Process_IO.This_Process.Name);
    Table_Abets.Read_List(Select_Dry_Run_Bets, Bet_List);
    T.Commit;

    Inner : while not Table_Abets.Abets_List_Pack.Is_Empty(Bet_List) loop
      Illegal_Data := False;
      Table_Abets.Abets_List_Pack.Remove_From_Head(Bet_List, Bet);
      Log(Me & "Check_Bets", "Check bet " & Table_Abets.To_String(Bet));
      if Trim(Bet.Side) = "BACK" then
        Side := Back;
      elsif Trim(Bet.Side(1..3)) = "LAY" then --lay + lay1-lay6
        Side := Lay;
      else
        Illegal_Data := True;
        Log(Me & "Check_Bets", "Illegal_Data ! side -> " &  Trim(Bet.Side));
      end if;
      if not Illegal_Data then
        Runner.Marketid := Bet.Marketid;
        Runner.Selectionid := Bet.Selectionid;
        Table_Arunners.Read(Runner, Eos(Arunner));

        if not Eos(Arunner) then
        -- do we have a non-runner?
          if Runner.Status(1..7) = "REMOVED" then
            -- non -runner - void the bet
            Bet.Betwon := True;
            Bet.Profit := 0.0;
            begin
              T.Start;
              Table_Abets.Update_Withcheck(Bet);
              T.Commit;
            exception
              when Sql.No_Such_Row =>
                T.Rollback; -- let the other one do the update
                exit;
            end ;

          elsif Runner.Status(1..6) = "WINNER" then
          -- this one won
            Selection_In_Winners := True;
          elsif Runner.Status(1..5) = "LOSER" then
          -- this one won
            Selection_In_Winners := False;
          else
            Log(Me & "Check_Bets", "unknown runner status, exit '" & Runner.Status & "'");
            exit Inner;
          end if;
        else
            Log(Me & "Check_Bets", "runner not found ?? " & Table_Arunners.To_String(Runner));
            exit Inner;
        end if;

        case Side is
          when Back    => Bet_Won := Selection_In_Winners;
          when Lay     => Bet_Won := not Selection_In_Winners;
          when Greenup => raise Suicide with "bad data GREENUP";            
        end case;

        if Bet_Won then
          case Side is     -- Betfair takes 5% provision on winnings, but 5% per market,
                           -- so it won't do to calculate per bet. leave that to the sql-script summarising
            when Back    => Profit := 1.0 * Bet.Sizematched * (Bet.Pricematched - 1.0);
            when Lay     => Profit := 1.0 * Bet.Sizematched;
            when Greenup => raise Suicide with "bad data GREENUP";            
          end case;
        else -- lost :-(
          case Side is
            when Back    => Profit := - Bet.Sizematched;
            when Lay     => Profit := - Bet.Sizematched * (Bet.Pricematched - 1.0);
            when Greenup => raise Suicide with "bad data GREENUP";            
          end case;
        end if;

        Bet.Betwon := Bet_Won;
        Bet.Profit := Profit;
        begin
          T.Start;
          Table_Abets.Update_Withcheck(Bet);
          T.Commit;
        exception
          when Sql.No_Such_Row =>
             T.Rollback; -- let the other one do the update
             exit Inner;
        end ;
      end if; -- Illegal data
    end loop Inner;




    -- check the real bets
    T.Start;
    Select_Real_Bets.Prepare(
      "select min(STARTTS) from ABETS where BETWON is null and BETID > 1000000000");

    Select_Real_Bets.Open_Cursor;
    Select_Real_Bets.Fetch(Eos(Abets));
    if not Eos(Abets) then
      Select_Real_Bets.Get_Timestamp(1, Start_Ts);
      Stop_Ts := Start_Ts + (1,0,0,0,0); -- 1 day
--    else
--      Stop_Ts  := Sattmate_Calendar.Clock ; -- now
--      Start_Ts := Stop_Ts - (1,0,0,0,0);    -- 1 day
    end if;
    Select_Real_Bets.Close_Cursor;
    T.Commit;

    if Start_Ts = Sattmate_Calendar.Time_Type_First then
      Eos(Abets) := True;
    end if;
    
    if not Eos(Abets) then
      for i in Cleared_Bet_Status_Type'range loop
        Rpc.Get_Cleared_Bet_Info_List(Bet_Status     => i,
                                      Settled_From   => Start_Ts,
                                      Settled_To     => Stop_Ts,
                                      Betfair_Result => Rpc_Status,
                                      Bet_List       => Bet_List) ;
      end loop;

      while not Table_Abets.Abets_List_Pack.Is_Empty(Bet_List) loop
        Table_Abets.Abets_List_Pack.Remove_From_Head(Bet_List, Bet_From_List);
        -- Call Betfair here ! Profit & Loss
        Bet := Table_Abets.Empty_Data;
        Bet.Betid := Bet_From_List.Betid;
        Table_Abets.Read(Bet,Eos(Abets));
        if not Eos(Abets) then
          Bet.Pricematched := Bet_From_List.Pricematched;
          Bet.Sizematched  := Bet_From_List.Sizematched;
          Bet.Profit       := Bet_From_List.Profit;
          Bet.Status       := Bet_From_List.Status;
          Bet.Betwon       := Bet.Profit >= 0.0;
  
          if Bet.Status(1..6) /= "VOIDED" and then
            Bet.Status(1..9) /= "CANCELLED" and then
            Bet.Status(1..6) /= "LAPSED" and then
            Bet.Status(1..7) /= "SETTLED"  then          
            begin
              T.Start;
              Table_Abets.Update_Withcheck(Bet);
              T.Commit;
              Log(Me & "Check_Bets", "Betid" & Bet.Betid'Img & " updated status to " &  Bet.Status);
            exception
              when Sql.No_Such_Row =>
                 T.Rollback; -- let the other one do the update
                 Log(Me & "Check_Bets", "No_Such_Row!! " & Table_Abets.To_String(Bet));
            end ;
          end if;              
        else
          Log(Me & "Check_Bets", "EOS!! " & Table_Abets.To_String(Bet));
        end if;
      end loop;
    end if;
    Table_Abets.Abets_List_Pack.Release(Bet_List);
    Log(Me & "Check_Bets", "stop");
  end Check_Bets;
  ------------------------------------------------------------------------------

  procedure Check_If_Bet_Accepted is
    T : Sql.Transaction_Type;
    Bet_List : Table_Abets.Abets_List_Pack.List_Type := Table_Abets.Abets_List_Pack.Create;
    Bet      : Table_Abets.Data_Type;
    Avg_Price_Matched : Bet_Price_Type := 0.0;
    Is_Matched,
    Is_Removed        : Boolean        := False;
    Size_Matched      : Bet_Size_Type  := 0.0;
  begin
    Log(Me & "Check_If_Bet_Accepted", "start");
    T.Start;
    -- check the real bets
    Select_Executable_Bets.Prepare(
      "select B.* from ABETS B, AMARKETS M " &
      "where B.MARKETID = M.MARKETID " & -- all bets, until profit and loss are fixed in API-NG
      "and M.STATUS in ('CLOSED','SETTLED','SUSPENDED') " & -- This is not updated!!!
      "and B.BETWON is null " & -- all bets, until profit and loss are fixed in API-NG
      "and B.BETID > 1000000000 " & -- no dry_run bets
--      "and B.IXXLUPD = :BOTNAME " & --only fix my bets, so no rollbacks ...
      "and B.STATUS = 'EXECUTABLE' "); --only not acctepted bets ...

--    Select_Executable_Bets.Set("BOTNAME", Process_IO.This_Process.Name);
    Table_Abets.Read_List(Select_Executable_Bets, Bet_List);

    while not Table_Abets.Abets_List_Pack.Is_Empty(Bet_List) loop
      Table_Abets.Abets_List_Pack.Remove_From_Head(Bet_List, Bet);
      Log(Me & "Check_If_Bet_Accepted", "Check bet " & Table_Abets.To_String(Bet));

      RPC.Bet_Is_Matched(Bet.Betid, Is_Removed, Is_Matched, Avg_Price_Matched, Size_Matched);

      if Is_Matched then
        Log(Me & "Check_If_Bet_Accepted", "update bet " & Table_Abets.To_String(Bet));
        Bet.Status := (others => ' ');
        if Is_Removed then
          Move("EXECUTABLE_NO_MATCH", Bet.Status); --?
        else
          Move("EXECUTION_COMPLETE", Bet.Status);
          Bet.Pricematched := Float_8(Avg_Price_Matched);
          Bet.Sizematched := Float_8(Size_Matched);
        end if;
        Log(Me & "Check_If_Bet_Accepted", "update bet " & Table_Abets.To_String(Bet));
        Table_Abets.Update_Withcheck(Bet);
        Update_Betwon_To_Null.Prepare("update ABETS set BETWON = null where BETID = :BETID");
        Update_Betwon_To_Null.Set("BETID", Bet.Betid);
        Update_Betwon_To_Null.Execute;
      end if;
    end loop;
    T.Commit;

    Table_Abets.Abets_List_Pack.Release(Bet_List);
    Log(Me & "Check_If_Bet_Accepted", "stop");

  end Check_If_Bet_Accepted;
 ---------------------------------------------------------------------------------


  procedure Check_Market_Status is
    T : Sql.Transaction_Type;
    Market_List : Table_Amarkets.Amarkets_List_Pack.List_Type := Table_Amarkets.Amarkets_List_Pack.Create;
    Market      : Table_Amarkets.Data_Type;
    Is_Changed  : Boolean        := False;

  begin
    Log(Me & "Check_Market_Status", "start");
    
    case Bot_Config.Config.System_Section.Bot_Mode is 
      when Real =>
        T.Start;
        Select_Ongoing_Markets.Prepare(
          "select M.* from AMARKETS M " &
          "where M.STATUS <> 'CLOSED' order by M.STARTTS");
        Table_Amarkets.Read_List(Select_Ongoing_Markets, Market_List);
     
        while not Table_Amarkets.Amarkets_List_Pack.Is_Empty(Market_List) loop
          Log(Me & "Check_Market_Status", Table_Amarkets.Amarkets_List_Pack.Get_Count(Market_List)'Img &
          " market left to check");
          Table_Amarkets.Amarkets_List_Pack.Remove_From_Head(Market_List, Market);
          Log(Me & "Check_Market_Status", "checking " & Market.Marketid); --Table_Amarkets.To_String(Market));
          RPC.Market_Status_Is_Changed(Market, Is_Changed);
     
          if Is_Changed then
            Log(Me & "Check_Market_Status", "update market " & Table_Amarkets.To_String(Market));
            Table_Amarkets.Update_Withcheck(Market);
          end if;
        end loop;
        T.Commit;
      when Simulation => null;
    end case;       
    Table_Amarkets.Amarkets_List_Pack.Release(Market_List);
    Log(Me & "Check_Market_Status", "stop");
  end Check_Market_Status;
 ---------------------------------------------------------------------------------

  procedure Check_Unsettled_Markets(Inserted_Winner : in out Boolean) is
    T : Sql.Transaction_Type;
    List_Runner : Table_Arunners.Data_Type;
    Db_Runner : Table_Arunners.Data_Type;
    Runner_List : Table_Arunners.Arunners_List_Pack.List_Type := Table_Arunners.Arunners_List_Pack.Create;
    Market_List : Table_Amarkets.Amarkets_List_Pack.List_Type := Table_Amarkets.Amarkets_List_Pack.Create;

    Market : Table_Amarkets.Data_Type;
    type Eos_Type is ( Arunners);
    Eos : array (Eos_Type'range) of Boolean := (others => False);

  begin
    Log (Me & "Check_Unsettled_Markets", "Check_Unsettled_Markets start");
    Inserted_Winner := False;
    T.Start;
    Select_Unsettled_Markets.Prepare(
      "select * from AMARKETS where MARKETID in ( " &
          "select distinct(M.MARKETID) " &
          "from AMARKETS M, ARUNNERS R " &
          "where M.MARKETID = R.MARKETID " &
          "and M.STATUS in ('SETTLED','CLOSED') " &
          "and R.STATUS in ('', 'NOT_SET_YET') ) " &
      "order by STARTTS" );


      Table_Amarkets.Read_List(Select_Unsettled_Markets, Market_List);

      Market_Loop : while not Table_Amarkets.Amarkets_List_Pack.Is_Empty(Market_List) loop
        Table_Amarkets.Amarkets_List_Pack.Remove_From_Head(Market_List, Market);

        Rpc.Check_Market_Result(Market_Id   => Market.Marketid,
                                Runner_List => Runner_List);

        Runner_Loop : while not Table_Arunners.Arunners_List_Pack.Is_Empty(Runner_List) loop
          Table_Arunners.Arunners_List_Pack.Remove_From_Head(Runner_List, List_Runner);
          Db_Runner := List_Runner;

          Table_Arunners.Read(Db_Runner, Eos(Arunners));
          if Eos(Arunners) then
            Log (Me & "Check_Unsettled_Markets", "missing runner in db !! " & Table_Arunners.To_String(Db_Runner));
          else
            Db_Runner.Status := List_Runner.Status;
            if Db_Runner.Status(1..2) = "WI" then
              Log (Me & "Check_Unsettled_Markets", "Got winner : " & Table_Arunners.To_String(Db_Runner));
              Inserted_Winner := True;
            end if;
            Table_Arunners.Update_Withcheck(Db_Runner);
          end if;

        end loop Runner_Loop;
      end loop Market_Loop;
    Sql.Commit (T);
    Table_Arunners.Arunners_List_Pack.Release(Runner_List);
    Table_Amarkets.Amarkets_List_Pack.Release(Market_List);
    Log (Me & "Check_Unsettled_Markets", "Check_Unsettled_Markets stop");
  exception
    when Sql.Duplicate_Index =>
      Sql.Rollback(T);
      Log (Me & "Check_Unsettled_Markets", "Check_Unsettled_Markets Duplicate index");
      Inserted_Winner := False;
  end Check_Unsettled_Markets;



  procedure Test_Bet is
--    B : Bet_Type;
--    T : Sql.Transaction_Type;
--    OK : Boolean := False;
  begin
    null;
--    T.Start;
 --    T.Commit;
  end Test_Bet;

end Bet_Handler;
