--
-- Prints equity for a give bet. Simulates the bets, and writes equity to stdoud
-- to be plotted with actual outcome perhaps equity.gpl
--

with Text_Io;
pragma Warnings(Off,Text_io);
with Sattmate_Calendar;
with Gnat.Command_Line; use Gnat.Command_Line;
with Sattmate_Types;    use Sattmate_Types;
with Gnat.Strings;
with Races;
with Logging;               use Logging;
with Sattmate_Exception;
--with Hitrates;

procedure Sim_Equity_Total is
--  Not_Implemented,
   Bad_Animal,
   Bad_Bet_Type,
   Bad_Name_Type : exception;

   Eol : Boolean := False;
   Sa_Par_Bet_Type     : aliased Gnat.Strings.String_Access;
--   Sa_Par_Favorite_By   : aliased Gnat.Strings.String_Access;
   Sa_Par_Db_Name       : aliased Gnat.Strings.String_Access;
--   Sa_Par_Price         : aliased Gnat.Strings.String_Access;
--   Sa_Par_Delta         : aliased Gnat.Strings.String_Access;
--   Sa_Par_Max_Daily_Loss    : aliased Gnat.Strings.String_Access;
--   Sa_Par_Max_Profit_Factor : aliased Gnat.Strings.String_Access;
   Sa_Par_Stop_Date         : aliased Gnat.Strings.String_Access;
   Sa_Par_Start_Date        : aliased Gnat.Strings.String_Access;

   Sa_Saldo             : aliased Gnat.Strings.String_Access;
   Sa_Size              : aliased Gnat.Strings.String_Access;
   Sa_Animal            : aliased Gnat.Strings.String_Access;
   Sa_Bet_Name          : aliased Gnat.Strings.String_Access;
   Ba_Quiet             : aliased Boolean;

   Config : Command_Line_Configuration;

   Race_List : Races.Race_Package.List_Type := Races.Race_Package.Create;
   Race      : Races.Race_Type;

   Global_Animal     : Races.Animal_Type;
   Global_Bet_Name   : Races.Bet_Name_Type;
--   Global_Graph_Type : Races.Graph_Type;
   Global_Bet_Type   : Races.Bet_Type_Type;

   Race_Profit,
   Global_Profit,
   Global_Daily_Profit      : Races.Profit_Type            := 0.0;
   Global_Saldo,
   Global_Start_Saldo       : Races.Saldo_Type             := 0.0;
   pragma Warnings(Off,Global_Start_Saldo);
   Global_Max_Daily_Loss    : Races.Max_Daily_Loss_Type    := 0.0;
   Global_Max_Profit_Factor : Races.Max_Profit_Factor_Type := 0.0;
   Global_Bet_Laid          : Boolean                      := False;
   Global_Size              : Races.Size_Type              := 0.0;

   Global_Bet_Won                : Boolean := False;

   Global_Favorite_By         : Float_8 := 0.0;


   use type Races.Profit_Type;
   use type Races.Saldo_Type;
   use type Races.Delta_Price_Type;
   use type Races.Back_Price_Type;
   use type Sattmate_Calendar.Time_Type;
   use type Sattmate_Calendar.Interval_Type;
   use type Races.Max_Daily_Loss_Type;
   use type Races.Price_Type;
   use type Races.Min_Price_Type;

   use type Races.Max_Profit_Factor_Type;


   Global_Last_Loss  : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   Global_Race_Date  : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   Global_Start_Date : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   Global_Stop_Date  : Sattmate_Calendar.Time_Type :=  Sattmate_Calendar.Time_Type_First;
   Global_Back_Price : Races.Back_Price_Type;
   Global_Delta_Price : Races.Delta_Price_Type;

   Global_Min_Price : Races.Min_Price_Type;
   Global_Max_Price : Races.Max_Price_Type;

   type Max_Price_Index_Type   is range 1 .. 25;  -- use integers only
   type Min_Price_Index_Type   is range 1 .. 25;  -- use integers only

begin

   Define_Switch
     (Config,
      Sa_Animal'Access,
      "-a:",
      Long_Switch => "--animal=",
      Help        => "type of animal, 'hound' or 'horse'");

   Define_Switch
     (Config,
      Sa_Bet_Name'Access,
      "-b:",
      Long_Switch => "--bet_name=",
      Help        => "'winner' or 'place'");


   Define_Switch
     (Config,
      Sa_Par_Bet_Type'Access,
      "-c:",
      Long_Switch => "--bet_type=",
      Help        => "'lay or back or lay_favorite'");

   Define_Switch
     (Config,
      Sa_Par_Db_Name'Access,
      "-D:",
      Long_Switch => "--db_name=",
      Help        => "database name");

--   Define_Switch
--    (Config,
--      Sa_Par_Delta'Access,
--      "-d:",
--      Long_Switch => "--delta=",
--      Help        => "price delta");

   Define_Switch
     (Config,
      Sa_Par_Start_Date'Access,
      "-e:",
      Long_Switch => "--start_date=",
      Help        => "when the simulation starts yyyy-mm-dd, 2013-02-25");

   Define_Switch
     (Config,
      Sa_Par_Stop_Date'Access,
      "-f:",
      Long_Switch => "--stop_date=",
      Help        => "when the simulation stops yyyy-mm-dd, 2013-02-25");

--   Define_Switch
--     (Config,
--      Sa_Par_Favorite_By'Access,
--      "-F:",
--      Long_Switch => "--favorite_by=",
--      Help        => "min odds diff to 2nd fav");
--
--   Define_Switch
--     (Config,
--      Sa_Par_Max_Daily_Loss'Access,
--      "-g:",
--      Long_Switch => "--max_daily_loss=",
--      Help        => "loose no more than this per day");
--
--   Define_Switch
--     (Config,
--      Sa_Par_Max_Profit_Factor'Access,
--      "-g:",
--      Long_Switch => "--max_profit_factor=",
--      Help        => "Stop when won more than this times size per day");



--   Define_Switch
--    (Config,
--      Sa_Graph_Type'Access,
--      "-g:",
--      Long_Switch => "--graph_type=",
--      Help        => "type of graph, 'Weekly', 'Four_Weeks', 'Eight_Weeks', 'Twenty_Six_Weeks', 'Fifty_Two_Weeks', 'Seventy_Eight_Weeks'  or 'One_Hundred_And_Four_Weeks'");

--   Define_Switch
--     (Config,
--      Sa_Par_Price'Access,
--      "-p:",
--      Long_Switch => "--price=",
--      Help        => "price");

   Define_Switch
     (Config,
      Ba_Quiet'Access,
      "-q",
      Long_Switch => "--quiet",
      Help        => "no log output");

   Define_Switch
     (Config,
      Sa_Saldo'Access,
      "-s:",
      Long_Switch => "--saldo=",
      Help        => "starting saldo");

   Define_Switch
     (Config,
      Sa_Size'Access,
      "-z:",
      Long_Switch => "--size=",
      Help        => "size of bet");

   Getopt (Config);  -- process the command line
   --   Display_Help (Config);

   begin
      Logging.Set_Quiet (Ba_Quiet);

      if Sa_Animal.all = "hound" then
         Global_Animal := Races.Hound;
      elsif Sa_Animal.all = "horse" then
         Global_Animal := Races.Horse;
      else
         raise Bad_Animal with "Not supported animal: '" & Sa_Animal.all & "'";
      end if;


      if Sa_Par_Bet_Type.all = "lay" then
         Global_Bet_Type := Races.Lay;
      elsif Sa_Par_Bet_Type.all = "back" then
         Global_Bet_Type := Races.Back;
      elsif Sa_Par_Bet_Type.all = "lay_favorite" then
         Global_Bet_Type := Races.Lay_Favorite;
      else
         raise Bad_Bet_Type with "Not supported Bettype: '" & Sa_Par_Bet_Type.all & "'";
      end if;


      if Sa_Bet_Name.all = "winner" then
         Global_Bet_Name := Races.Winner;
      elsif Sa_Bet_Name.all = "place" then
         Global_Bet_Name := Races.Place;
      else
         raise Bad_Name_Type with "Not supported bet name: '" & Sa_Bet_Name.all & "'";
      end if;

--      if Sa_Graph_Type.all = "daily" then
--         Global_Graph_Type := Races.Daily;
--      if Sa_Graph_Type.all = "weekly" then
--         Global_Graph_Type := Races.Weekly;
--      elsif Sa_Graph_Type.all = "four_weeks" then
--         Global_Graph_Type := Races.Four_Weeks;
--      elsif Sa_Graph_Type.all = "eight_weeks" then
--         Global_Graph_Type := Races.Eight_Weeks;
--      elsif Sa_Graph_Type.all = "twenty_six_weeks" then
--         Global_Graph_Type := Races.Twenty_Six_Weeks;
--      elsif Sa_Graph_Type.all = "fifty_two_weeks" then
--         Global_Graph_Type := Races.Fifty_Two_Weeks;
--      elsif Sa_Graph_Type.all = "seventy_eight_weeks" then
--         Global_Graph_Type := Races.Seventy_Eight_Weeks;
--      elsif Sa_Graph_Type.all = "one_hundred_and_four_weeks" then
--         Global_Graph_Type := Races.One_Hundred_And_Four_Weeks;
--      else
--         raise Bad_Graph_Type with "Not supported graph type: '" & Sa_Graph_Type.all & "'";
--      end if;

      Global_Size              := Races.Size_Type'Value (Sa_Size.all);
      Global_Saldo             := Races.Saldo_Type'Value (Sa_Saldo.all);
      Global_Start_Saldo       := Global_Saldo;
--      Global_Back_Price        := Races.Back_Price_Type'Value (Sa_Par_Price.all);
--      Global_Delta_Price       := Races.Delta_Price_Type'Value (Sa_Par_Delta.all);
--      Global_Favorite_By       := Float_8'Value(Sa_Par_Favorite_By.all);
--      Global_Max_Profit_Factor := Races.Max_Profit_Factor_Type'Value(Sa_Par_Max_Profit_Factor.all);
--      Global_Max_Daily_Loss    := Races.Max_Daily_Loss_Type'Value(Sa_Par_Max_Daily_Loss.all);

   exception
      when Constraint_Error =>
         Display_Help (Config);
         return;
   end;

   Global_Start_Date := Sattmate_Calendar.To_Time_Type (Sa_Par_Start_Date.all, "00:00:00:000");
   Global_Stop_Date  := Sattmate_Calendar.To_Time_Type (Sa_Par_Stop_Date.all, "23:59:59:999");

--   case Global_Graph_Type is
----      when Races.Daily =>       Global_Start_Date := Global_Stop_Date;
--      when Races.Weekly                     => Global_Start_Date := Global_Stop_Date - (  1 * 7 - 1, 0, 0, 0, 0);
--      when Races.Four_Weeks                 => Global_Start_Date := Global_Stop_Date - (  4 * 7 - 1, 0, 0, 0, 0);
--      when Races.Eight_Weeks                => Global_Start_Date := Global_Stop_Date - (  8 * 7 - 1, 0, 0, 0, 0);
--      when Races.Twenty_Six_Weeks           => Global_Start_Date := Global_Stop_Date - ( 26 * 7 - 1, 0, 0, 0, 0);
--      when Races.Fifty_Two_Weeks            => Global_Start_Date := Global_Stop_Date - ( 52 * 7 - 1, 0, 0, 0, 0);
--      when Races.Seventy_Eight_Weeks        => Global_Start_Date := Global_Stop_Date - ( 78 * 7 - 1, 0, 0, 0, 0);
--      when Races.One_Hundred_And_Four_Weeks => Global_Start_Date := Global_Stop_Date - (104 * 7 - 1, 0, 0, 0, 0);
--   end case;


----   if Global_Start_Date < Sattmate_Calendar.Time_Type'(2013, 01, 30, 0, 0, 0, 0) then
--   if Global_Start_Date < Sattmate_Calendar.Time_Type'(2011, 01, 01, 0, 0, 0, 0) then
--      Log ("start date outside range, " & Global_Graph_Type'Img & " " &
--           Sattmate_Calendar.String_Date (Global_Start_Date) & " " &
--           Sattmate_Calendar.String_Date (Global_Stop_Date )
--          );
--      return;
--   end if;
--
--   Log ("graph/startdate/stopdate, " & Global_Graph_Type'Img & " " &
--           Sattmate_Calendar.String_Date (Global_Start_Date) & " " &
--           Sattmate_Calendar.String_Date (Global_Stop_Date )
--          );
----   return;


   Global_Start_Date.Hour        := 0;
   Global_Start_Date.Minute      := 0;
   Global_Start_Date.Second      := 0;
   Global_Start_Date.Millisecond := 0;

   Races.Get_Database_Data
     (Race_List  => Race_List,
      Db_Name    => Sa_Par_Db_Name.all,
      Bet_Type   => Global_Bet_Name,
      Animal     => Global_Animal,
      Start_Date => Global_Start_Date,
      Stop_Date  => Global_Stop_Date);


       favorite_by_loop : for f in 0 .. 3 loop
         Text_Io.Put_Line (Text_Io.Standard_Error, Sattmate_Calendar.String_Date_And_Time(Milliseconds => True) & " " & f'img & "/5");
         Max_Daily_Loss_loop : for l in 0 .. 6 loop
           Max_Profit_Factor_loop : for p in 0 .. 5 loop
             Global_Favorite_By := Float_8(f) ; -- /10.0;
             Global_Max_Daily_Loss := Races.Max_Daily_Loss_Type(-l) * 100.0;
             Global_Max_Profit_Factor := Races.Max_Profit_Factor_Type(p) ; -- / 10.0;

             -- new type of simulation, reset dates
             Global_Last_Loss := Sattmate_Calendar.Time_Type_First;
             Global_Race_Date := Sattmate_Calendar.Time_Type_First;

                --         Race.Show_Runners;
             case Global_Bet_Type is
                when Races.Lay =>
                  Max_Price_Loop_1 : for Max_Price in Max_Price_Index_Type'range loop
                     Min_Price_Loop_1 : for Min_Price in Min_Price_Index_Type'range loop
                     if integer(Min_Price) < integer (Max_Price) then
                        Global_Saldo        := Races.Saldo_Type'Value (Sa_Saldo.all);
                        Global_Profit       := 0.0;
                        Race_Profit         := 0.0;
                        Log ("start simulation, saldo =  " & Integer (Global_Saldo)'Img);
                        Races.Race_Package.Get_First (Race_List, Race, Eol);
                        loop
                           exit when Eol;
                           Log ("---  main loop start " &  Race.Market.Marketid'Img &
                                " saldo :" & Integer (Global_Saldo)'Img & " -----------------");
                           -- reset the daily profit when new day is treated
                           if Global_Race_Date.Day  /= Race.Market.Eventdate.Day or else
                             Global_Race_Date.Month /= Race.Market.Eventdate.Month or else
                             Global_Race_Date.Year  /=  Race.Market.Eventdate.Year then
                              Global_Race_Date := Race.Market.Eventdate;
                              Global_Daily_Profit := 0.0;
                              Log ("main loop , race date = " & Sattmate_Calendar.String_Date (Global_Race_Date));
                           end if;

                           Race.Make_Lay_Bet
                             (Animal            => Global_Animal,
                              Bet_Name          => Global_Bet_Name,
                              Bet_Laid          => Global_Bet_Laid,
                              Profit            => Global_Daily_Profit,
                              Min_From_Leader   => Integer_4(Global_Favorite_By),
                              Saldo             => Global_Saldo,
                              Last_Loss         => Global_Last_Loss,
                              Max_Daily_Loss    => Global_Max_Daily_Loss,
                              Max_Profit_Factor => Global_Max_Profit_Factor,
                              Size              => Global_Size,
                              Min_Price         => Races.Min_Price_Type(Min_Price),
                              Max_Price         => Races.Max_Price_Type(Max_Price));

                           if Global_Bet_Laid then
                              Log ("---  main loop saldo after bet laid :" & Integer (Global_Saldo)'Img & " -----------------");
                              Race.Check_Result
                                (Profit    => Race_Profit,
                                 Saldo     => Global_Saldo,
                                 Last_Loss => Global_Last_Loss,
                                 Bet_Won   => Global_Bet_Won,
                                 Bet_Type  => Global_Bet_Type);
                              -- if bet is laid, race.price is updated with the actual price of the bet in make_back_bet
                              Global_Daily_Profit := Global_Daily_Profit + Race_Profit;
                              Global_Profit := Global_Profit + Race_Profit;

                           end if;

                           Races.Race_Package.Get_Next (Race_List, Race, Eol);
                        end loop;
                        if Global_Saldo > Global_Start_Saldo then
                          Print (Max_Price'img & " | " &
                                 Min_Price'img & " | " &
                                 Global_Favorite_By'img & " | " &
                                 Global_Max_Daily_Loss'img & " | " &
                                 Global_Max_Profit_Factor'img & " | " &
                                 integer'image(integer(Max_Price)) & " | " &
                                 integer'image(integer(Min_Price)) & " | " &
                                 integer'image(integer(Global_Favorite_By)) & " | " &
                                 integer'image(integer(Global_Max_Daily_Loss)) & " | " &
                                 integer'image(integer(Global_Max_Profit_Factor)) & " | " &
                                 integer'image(integer(Global_Saldo)) );
                        end if;
                      end if;
                    end loop Min_Price_Loop_1;
                  end loop Max_Price_Loop_1;

                when Races.Lay_Favorite =>
                   Max_Price_Loop : for Max_Price in Max_Price_Index_Type'range loop
                     Min_Price_Loop : for Min_Price in Min_Price_Index_Type'range loop
                       if integer(Min_Price) < integer (Max_Price) then
                         Global_Min_Price := 2.0;
                         Global_Saldo        := Races.Saldo_Type'Value (Sa_Saldo.all);
                         Global_Profit       := 0.0;
                         Race_Profit         := 0.0;

                         Log ("start simulation, saldo =  " & Integer (Global_Saldo)'Img);
                         Races.Race_Package.Get_First (Race_List, Race, Eol);
                         loop
                            exit when Eol;
                            Log ("---  main loop start " &  Race.Market.Marketid'Img &
                                   " saldo :" & Integer (Global_Saldo)'Img & " -----------------");
                            -- reset the daily profit when new day is treated
                            if Global_Race_Date.Day  /= Race.Market.Eventdate.Day or else
                               Global_Race_Date.Month /= Race.Market.Eventdate.Month or else
                               Global_Race_Date.Year  /=  Race.Market.Eventdate.Year then
                                 Global_Race_Date := Race.Market.Eventdate;
                                 Global_Daily_Profit := 0.0;
                                 Log ("main loop , race date = " & Sattmate_Calendar.String_Date (Global_Race_Date));
                            end if;

                            Race.Make_Lay_Favorite_Bet
                              (Animal            => Global_Animal,
                               Bet_Name          => Global_Bet_Name,
                               Bet_Laid          => Global_Bet_Laid,
                               Profit            => Global_Daily_Profit,
                               Min_From_Leader   => Integer_4(Global_Favorite_By),
                               Saldo             => Global_Saldo,
                               Last_Loss         => Global_Last_Loss,
                               Max_Daily_Loss    => Global_Max_Daily_Loss,
                               Max_Profit_Factor => Global_Max_Profit_Factor,
                               Size              => Global_Size,
                               Min_Price         => Races.Min_Price_Type(Min_Price),
                               Max_Price         => Races.Max_Price_Type(Max_Price));

                            if Global_Bet_Laid then
                               Log ("---  main loop saldo after bet laid :" & Integer (Global_Saldo)'Img & " -----------------");
                               Race.Check_Result
                                  (Profit    => Race_Profit,
                                   Saldo     => Global_Saldo,
                                   Last_Loss => Global_Last_Loss,
                                   Bet_Won   => Global_Bet_Won,
                                   Bet_Type  => Global_Bet_Type);
                                -- if bet is laid, race.price is updated with the actual price of the bet in make_back_bet
                               Global_Profit := Global_Profit + Race_Profit;
                            end if;

                            Races.Race_Package.Get_Next (Race_List, Race, Eol);
                         end loop;

                         if Global_Saldo > Global_Start_Saldo then
                            Print (Max_Price'img & " | " &
                                   Min_Price'img & " | " &
                                   Global_Favorite_By'img & " | " &
                                   Global_Max_Daily_Loss'img & " | " &
                                   Global_Max_Profit_Factor'img & " | " &
                                   integer'image(integer(Max_Price)) & " | " &
                                   integer'image(integer(Min_Price)) & " | " &
                                   integer'image(integer(Global_Favorite_By)) & " | " &
                                   integer'image(integer(Global_Max_Daily_Loss)) & " | " &
                                   integer'image(integer(Global_Max_Profit_Factor)) & " | " &
                                   integer'image(integer(Global_Saldo)) );
                         end if;
                       end if;
                     end loop Min_Price_Loop;
                   end loop Max_Price_Loop;


                when Races.Back =>
                   price_loop : for bp in 1 .. 10 loop
                     delta_loop : for d in 0 .. 9 loop
                       Global_Saldo        := Races.Saldo_Type'Value (Sa_Saldo.all);
                       Global_Daily_Profit := 0.0;
                       Race_Profit         := 0.0;

                       Log ("start simulation, saldo =  " & Integer (Global_Saldo)'Img);
                       Races.Race_Package.Get_First (Race_List, Race, Eol);

                       loop
                          exit when Eol;
                          Log ("---  main loop start " &  Race.Market.Marketid'Img &
                               " saldo :" & Integer (Global_Saldo)'Img & " -----------------");
                          -- reset the daily profit when new day is treated
                          if Global_Race_Date.Day   /= Race.Market.Eventdate.Day or else
                            Global_Race_Date.Month /= Race.Market.Eventdate.Month or else
                            Global_Race_Date.Year  /=  Race.Market.Eventdate.Year then
                              Global_Race_Date := Race.Market.Eventdate;
                              Global_Daily_Profit := 0.0;
                             Log ("main loop , race date = " & Sattmate_Calendar.String_Date (Global_Race_Date));
                          end if;

                          Race.Make_Back_Bet
                            (Animal            => Global_Animal,
                             Bet_Name          => Global_Bet_Name,
                             Bet_Laid          => Global_Bet_Laid,
                             Profit            => Global_Daily_Profit,
                             Saldo             => Global_Saldo,
                             Last_Loss         => Global_Last_Loss,
                             Max_Daily_Loss    => Global_Max_Daily_Loss,
                             Max_Profit_Factor => Global_Max_Profit_Factor,
                             Favorite_By       => Global_Favorite_By,
                             Size              => Global_Size,
                             Back_Price        => Global_Back_Price,
                             Delta_Price       => Global_Delta_Price);

                          if Global_Bet_Laid then
                             Race.Check_Result
                               (Profit    => Race_Profit,
                                Saldo     => Global_Saldo,
                                Last_Loss => Global_Last_Loss,
                                Bet_Won   => Global_Bet_Won,
                                Bet_Type  => Global_Bet_Type);
                             -- if bet is laid, race.price is updated with the actual price of the bet in make_back_bet
                             Global_Daily_Profit := Global_Daily_Profit + Race_Profit;
     --                        Print (Sattmate_Calendar.String_Date_ISO (Race.Market.Eventdate) & " " & Sattmate_Calendar.String_Time (Race.Market.Eventdate) & " | " &
     --                               integer'image(integer(Global_Saldo)) & " | " &
     --                               integer'image(integer(Race_Profit)));
                          end if;
                          Races.Race_Package.Get_Next (Race_List, Race, Eol);
                       end loop;

                       if Global_Saldo > Global_Start_Saldo then
                         Print (Global_Back_Price'img & " | " &
                                Global_Delta_Price'img & " | " &
                                Global_Favorite_By'img & " | " &
                                Global_Max_Daily_Loss'img & " | " &
                                Global_Max_Profit_Factor'img & " | " &
                                integer'image(integer(Global_Back_Price)) & " | " &
                                integer'image(integer(Global_Delta_Price)) & " | " &
                                integer'image(integer(Global_Favorite_By)) & " | " &
                                integer'image(integer(Global_Max_Daily_Loss)) & " | " &
                                integer'image(integer(Global_Max_Profit_Factor)) & " | " &
                                integer'image(integer(Global_Saldo)) );
                       end if;
                     end loop delta_loop;
                   end loop price_loop;
                end case;

           end loop Max_Profit_Factor_loop;
        end loop Max_Daily_Loss_loop;
      end loop favorite_by_loop;


exception
   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);
end Sim_Equity_Total;
