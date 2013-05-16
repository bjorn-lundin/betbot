with Text_Io;
with Sattmate_Calendar;
with Gnat.Command_Line; use Gnat.Command_Line;
with Sattmate_Types;    use Sattmate_Types;
with Gnat.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Races;
with Logging;               use Logging;
with Gnat.Os_Lib;
with Ada.Characters.Latin_1;
with Sattmate_Exception;
with General_Routines;       use General_Routines;
with Hitrates;

procedure Simulator3 is
--  Not_Implemented,
   Bad_Animal,
   Bad_Bet_Type,
   Bad_Graph_Type, Bad_Name_Type : exception;

   Eol : Boolean := False;
   Sa_Par_Bet_Type     : aliased Gnat.Strings.String_Access;

   Sa_Par_Db_Name       : aliased Gnat.Strings.String_Access;
   Sa_Par_Price         : aliased Gnat.Strings.String_Access;
   Sa_Par_Delta         : aliased Gnat.Strings.String_Access;
   Sa_Graph_Type        : aliased Gnat.Strings.String_Access;
   Sa_Stop_Date         : aliased Gnat.Strings.String_Access;
   Sa_Saldo             : aliased Gnat.Strings.String_Access;
   Sa_Size              : aliased Gnat.Strings.String_Access;
   Sa_Animal            : aliased Gnat.Strings.String_Access;
   --   Sa_Max_Daily_Loss    : aliased Gnat.Strings.String_Access;
   Sa_Bet_Name          : aliased Gnat.Strings.String_Access;
   Ba_Quiet             : aliased Boolean;

   Config : Command_Line_Configuration;

   Race_List : Races.Race_Package.List_Type := Races.Race_Package.Create;
   Race      : Races.Race_Type;

   Global_Animal     : Races.Animal_Type;
   Global_Bet_Name   : Races.Bet_Name_Type;
   Global_Graph_Type : Races.Graph_Type;
   Global_Bet_Type   : Races.Bet_Type_Type;

   Global_Profit            : Races.Profit_Type            := 0.0;
   Global_Min_Saldo,
   Global_Max_Saldo,
   Global_Saldo,
   Global_Start_Saldo       : Races.Saldo_Type             := 0.0;
   pragma Warnings(Off,Global_Start_Saldo);
   Global_Max_Daily_Loss    : Races.Max_Daily_Loss_Type    := 0.0;
   Global_Max_Profit_Factor : Races.Max_Profit_Factor_Type := 0.0;
   Global_Bet_Laid          : Boolean                      := False;
   Global_Size              : Races.Size_Type              := 0.0;

   Global_Num_Races_Daily,
   Global_Num_Bets_Daily,
   Global_Num_Bets_Won_Daily,
   Global_Num_Races,
   Global_Num_Bets,
   Global_Num_Bets_Won           : Integer_4 := 0;
   Global_Bet_Won                : Boolean := False;


   Global_Avg_Price,
   Global_Sum_Price              : Races.Price_Type := 0.0;

   Actual_Hitrate, Needed_Hitrate : Float_8 := 0.0;


   use type Races.Saldo_Type;
   use type Races.Delta_Price_Type;
   use type Races.Back_Price_Type;
   use type Sattmate_Calendar.Time_Type;
   use type Sattmate_Calendar.Interval_Type;
   use type Races.Max_Daily_Loss_Type;
   use type Races.Price_Type;

   Global_Last_Loss  : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   Global_Race_Date  : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   Global_Start_Date : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   Global_Stop_Date  : Sattmate_Calendar.Time_Type :=  Sattmate_Calendar.Time_Type_First;

--   type Max_Price_Index_Type   is range 1 .. 25;  -- use integers only
--   type Min_Price_Index_Type   is range 1 .. 25;  -- use integers only
--   type Back_Price_Index_Type  is range 10 .. 10; -- will divide by 10
--   type Delta_Price_Index_Type is range 1 .. 9;  -- will divide by 10

   Global_Back_Price : Races.Back_Price_Type;
   Global_Delta_Price : Races.Delta_Price_Type;

   Filename     : Unbounded_String := Null_Unbounded_String;
   Fil          : Unbounded_String := Null_Unbounded_String;
   Data_Dir     : Unbounded_String := Null_Unbounded_String;
   Fil_Gpi      : Unbounded_String := Null_Unbounded_String;
   Contents_Gpi : Unbounded_String := Null_Unbounded_String;

   Target_Dat : Text_Io.File_Type;
   Target_Gpi : Text_Io.File_Type;

   Global_Directory_Separator : String (1 .. 1);

   The_Variant : Races.Variant_Type :=  Races.Variant_Type'First;
   Max_Daily_Loss : Races.Max_Daily_Loss_Type_Type := Races.Max_Daily_Loss_Type_Type'first;


begin

   Global_Directory_Separator (1) := Gnat.Os_Lib.Directory_Separator;

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

   Define_Switch
     (Config,
      Sa_Par_Delta'Access,
      "-d:",
      Long_Switch => "--delta=",
      Help        => "price delta");

   Define_Switch
     (Config,
      Sa_Stop_Date'Access,
      "-f:",
      Long_Switch => "--stop_date=",
      Help        => "when the simulation stops dd-MON-yyyy, 25-FEB-2013");

   Define_Switch
     (Config,
      Sa_Graph_Type'Access,
      "-g:",
      Long_Switch => "--graph_type=",
      Help        => "type of graph, 'Weekly', 'Four_Weeks', 'Eight_Weeks', 'Twenty_Six_Weeks', 'Fifty_Two_Weeks', 'Seventy_Eight_Weeks'  or 'One_Hundred_And_Four_Weeks'");

   Define_Switch
     (Config,
      Sa_Par_Price'Access,
      "-p:",
      Long_Switch => "--price=",
      Help        => "price");

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
--      elsif Sa_Bet_Name.all = "place" then
--         Global_Bet_Name := Races.Place;
      else
         raise Bad_Name_Type with "Not supported bet name: '" & Sa_Bet_Name.all & "'";
      end if;

--      if Sa_Graph_Type.all = "daily" then
--         Global_Graph_Type := Races.Daily;
      if Sa_Graph_Type.all = "weekly" then
         Global_Graph_Type := Races.Weekly;
      elsif Sa_Graph_Type.all = "four_weeks" then
         Global_Graph_Type := Races.Four_Weeks;
      elsif Sa_Graph_Type.all = "eight_weeks" then
         Global_Graph_Type := Races.Eight_Weeks;
      elsif Sa_Graph_Type.all = "twenty_six_weeks" then
         Global_Graph_Type := Races.Twenty_Six_Weeks;
      elsif Sa_Graph_Type.all = "fifty_two_weeks" then
         Global_Graph_Type := Races.Fifty_Two_Weeks;
      elsif Sa_Graph_Type.all = "seventy_eight_weeks" then
         Global_Graph_Type := Races.Seventy_Eight_Weeks;
      elsif Sa_Graph_Type.all = "one_hundred_and_four_weeks" then
         Global_Graph_Type := Races.One_Hundred_And_Four_Weeks;
      else
         raise Bad_Graph_Type with "Not supported graph type: '" & Sa_Graph_Type.all & "'";
      end if;

      Global_Size              := Races.Size_Type'Value (Sa_Size.all);
      Global_Saldo             := Races.Saldo_Type'Value (Sa_Saldo.all);
      Global_Start_Saldo       := Global_Saldo;
      Global_Back_Price        := Races.Back_Price_Type'Value (Sa_Par_Price.all);
      Global_Delta_Price       := Races.Delta_Price_Type'Value (Sa_Par_Delta.all);
   exception
      when Constraint_Error =>
         Display_Help (Config);
         return;
   end;

   Global_Stop_Date := Sattmate_Calendar.To_Time_Type (Sa_Stop_Date.all, "23:59:59:999");

   case Global_Graph_Type is
--      when Races.Daily =>       Global_Start_Date := Global_Stop_Date;
      when Races.Weekly                     => Global_Start_Date := Global_Stop_Date - (  1 * 7 - 1, 0, 0, 0, 0);
      when Races.Four_Weeks                 => Global_Start_Date := Global_Stop_Date - (  4 * 7 - 1, 0, 0, 0, 0);
      when Races.Eight_Weeks                => Global_Start_Date := Global_Stop_Date - (  8 * 7 - 1, 0, 0, 0, 0);
      when Races.Twenty_Six_Weeks           => Global_Start_Date := Global_Stop_Date - ( 26 * 7 - 1, 0, 0, 0, 0);
      when Races.Fifty_Two_Weeks            => Global_Start_Date := Global_Stop_Date - ( 52 * 7 - 1, 0, 0, 0, 0);
      when Races.Seventy_Eight_Weeks        => Global_Start_Date := Global_Stop_Date - ( 78 * 7 - 1, 0, 0, 0, 0);
      when Races.One_Hundred_And_Four_Weeks => Global_Start_Date := Global_Stop_Date - (104 * 7 - 1, 0, 0, 0, 0);
   end case;


--   if Global_Start_Date < Sattmate_Calendar.Time_Type'(2013, 01, 30, 0, 0, 0, 0) then
   if Global_Start_Date < Sattmate_Calendar.Time_Type'(2011, 01, 01, 0, 0, 0, 0) then
      Log ("start date outside range, " & Global_Graph_Type'Img & " " &
           Sattmate_Calendar.String_Date (Global_Start_Date) & " " &
           Sattmate_Calendar.String_Date (Global_Stop_Date )
          );
      return;
   end if;

   Log ("graph/startdate/stopdate, " & Global_Graph_Type'Img & " " &
           Sattmate_Calendar.String_Date (Global_Start_Date) & " " &
           Sattmate_Calendar.String_Date (Global_Stop_Date )
          );
--   return;


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

   Data_Dir := To_Unbounded_String ("sims");

--   for Bet_Type in Races.Bet_Type_Type'range loop
--      for The_Variant in Races.Variant_Type'range loop
--         for Max_Daily_Loss in Races.Max_Daily_Loss_Type_Type'range loop

            Global_Max_Profit_Factor := Races.Max_Profit_Factor_Type(Races.Variant(The_Variant));
            Global_Max_Daily_Loss := Races.Max_Daily_Loss_Type(Races.Max_Daily_Loss(Max_Daily_Loss));

            -- new type of simulation, reset dates
            Global_Last_Loss := Sattmate_Calendar.Time_Type_First;
            Global_Race_Date := Sattmate_Calendar.Time_Type_First;

            -- what filename to write this to ?
            Filename := To_Unbounded_String
              ("simulation_ada3-" &
               Sa_Animal.all &  "-" &
               Lower_Case (Sa_Graph_Type.all) & "-" &
               Sa_Bet_Name.all & "-" &
               Lower_Case (Global_Bet_Type'Img) & "-" &
               Lower_Case (The_Variant'Img) & "-" &
               Lower_Case (Max_Daily_Loss'Img) & "-" &
               Sattmate_Calendar.String_Date_Iso (Global_Start_Date) & "-" &
               Sa_Stop_Date.all &
               --   Sa_Index.all  & "-" &
               ".dat");

            Fil     := Data_Dir &
            To_Unbounded_String (Global_Directory_Separator) &
            Filename;
            Fil_Gpi := Data_Dir &
            To_Unbounded_String (Global_Directory_Separator) &
            Filename &
            To_Unbounded_String (".gpi");
            Log ("Filename: '" & To_String (Filename) & "'");
            --   begin
            -- create file if not exists
            Text_Io.Create
              (Mode => Text_Io.Out_File,
               Name => To_String (Fil),
               File => Target_Dat);

            Text_Io.Close (Target_Dat);
            --   exception
            --      when others => null;
            --   end;


            --         Race.Show_Runners;
            case Global_Bet_Type is
               when Races.Lay =>
                  for Price in 2 .. 24 loop
--                  for Max_Price in Max_Price_Index_Type'range loop
--                     for Min_Price in Min_Price_Index_Type'range loop
                        Global_Num_Races    := 0;
                        Global_Num_Bets     := 0;
                        Global_Num_Bets_Won := 0;
                        Global_Saldo        := Races.Saldo_Type'Value (Sa_Saldo.all);
                        Global_Profit       := 0.0;
                        Global_Avg_Price    := 0.0;
                        Global_Sum_Price    := 0.0;
                        Global_Min_Saldo    :=  1_000_000_000.0;
                        Global_Max_Saldo    := -1_000_000_000.0;

                        Log ("start simulation, saldo =  " & Integer (Global_Saldo)'Img);
--                        if Integer (Min_Price) < Integer (Max_Price) then

                           Races.Race_Package.Get_First (Race_List, Race, Eol);
                           loop
                              exit when Eol;
                              Global_Num_Races := Global_Num_Races + 1;
                              Log ("---  main loop start " &  Race.Market.Marketid'Img &
                                   " saldo :" & Integer (Global_Saldo)'Img & " -----------------");
                              -- reset the daily profit when new day is treated
                              if Global_Race_Date.Day  /= Race.Market.Eventdate.Day or else
                                Global_Race_Date.Month /= Race.Market.Eventdate.Month or else
                                Global_Race_Date.Year  /=  Race.Market.Eventdate.Year then
                                 Global_Race_Date := Race.Market.Eventdate;
                                 Global_Profit    := 0.0;
                                 Log ("main loop , race date = " & Sattmate_Calendar.String_Date (Global_Race_Date));
                              end if;

                              Race.Make_Lay_Bet
                                (Bet_Laid          => Global_Bet_Laid,
                                 Profit            => Global_Profit,
                                 Saldo             => Global_Saldo,
                                 Last_Loss         => Global_Last_Loss,
                                 Max_Daily_Loss    => Global_Max_Daily_Loss,
                                 Max_Profit_Factor => Global_Max_Profit_Factor,
                                 Size              => Global_Size,
                                 Min_Price         => Races.Min_Price_Type (Price ),
                                 Max_Price         => Races.Max_Price_Type (Price + 1));

                              if Global_Bet_Laid then
                                 Global_Num_Bets := Global_Num_Bets +1;
                                 Log ("---  main loop saldo after bet laid :" & Integer (Global_Saldo)'Img & " -----------------");
                                 Race.Check_Result
                                   (Profit    => Global_Profit,
                                    Saldo     => Global_Saldo,
                                    Last_Loss => Global_Last_Loss,
                                    Bet_Won   => Global_Bet_Won,
                                    Bet_Type  => Global_Bet_Type);
                                 -- if bet is laid, race.price is updated with the actual price of the bet in make_back_bet
                                 Global_Sum_Price := Global_Sum_Price + Race.Price;
                                 if Global_Bet_Won then
                                    Global_Num_Bets_Won := Global_Num_Bets_Won + 1;
                                 end if;
                              end if;
                              if Global_Saldo > Global_Max_Saldo then
                                Global_Max_Saldo := Global_Saldo ;
                              end if;

                              if Global_Saldo < Global_Min_Saldo then
                                Global_Min_Saldo := Global_Saldo ;
                              end if;

                              Races.Race_Package.Get_Next (Race_List, Race, Eol);
                           end loop;
--                        end if; -- min_price < Max_Price
                        Log ("main - Global_Profit : " & Integer (Global_Profit)'Img);

                        Log ("stop simulation, saldo =  " & Integer (Global_Saldo)'Img);

                        if Global_Num_Bets > 0 then
                          Global_Avg_Price := Global_Sum_Price / Races.Price_Type(Global_Num_Bets);
                          Actual_Hitrate := 100.0 * Float_8(Global_Num_Bets_Won)/Float_8(Global_Num_Bets);
                          Needed_Hitrate := 100.0 * Hitrates.Needed_Laybet_Hitrate(Global_Avg_Price,Hitrates.Betfair_Commission);
                        else
                          Global_Avg_Price := 0.0;
                          Actual_Hitrate := 0.0 ;
                          Needed_Hitrate := 0.0;
                        end if;

                        Print (Integer (Price)'Img & " " &
                             Integer (Price)'Img & " " &
                             Global_Num_Races'Img & " " &
                             Global_Num_Bets'Img & " " &
                             Global_Num_Bets_Won'Img & " " &
                             Global_Avg_Price'Img & " " &
                             Actual_Hitrate'Img & " " &
                             Needed_Hitrate'Img & " " &
                             integer'image(integer(Actual_Hitrate - Needed_Hitrate)) & " " &
                             Boolean'Image (Actual_Hitrate > Needed_Hitrate) & " " &
                             integer'image(integer(Global_Min_Saldo)) & " " &
                             integer'image(integer(Global_Saldo)) & " " &
                             integer'image(integer(Global_Max_Saldo)));
                        -- Append To file
                        --         begin
                        -- create file if not exists
                        Text_Io.Open
                          (Mode => Text_Io.Append_File,
                           Name => To_String (Fil),
                           File => Target_Dat);
                        Text_Io.Put_Line
                          (Target_Dat,
                           Integer (Price)'Img & " " &
                           Integer (Price)'Img & " " &
                           Global_Num_Races'Img & " " &
                           Global_Num_Bets'Img & " " &
                           Global_Num_Bets_Won'Img & " " &
                           Global_Avg_Price'Img & " " &
                           Actual_Hitrate'Img & " " &
                           Needed_Hitrate'Img & " " &
                           integer'image(integer(Actual_Hitrate - Needed_Hitrate)) & " " &
                           Boolean'Image (Actual_Hitrate > Needed_Hitrate) & " " &
                           integer'image(integer(Global_Min_Saldo)) & " " &
                           integer'image(integer(Global_Saldo)) & " " &
                           integer'image(integer(Global_Max_Saldo)));
                        Text_Io.Close (Target_Dat);
                        --         exception
                        --            when others => null;
                        --         end;
                        Log ("---  main loop stop " & Race.Market.Marketid'Img &
                             " profit :" & Integer (Global_Profit)'Img & " -----------------");
--                     end loop;
                  end loop;

               when Races.Lay_Favorite =>
                  for Price in 2 .. 24 loop
 --                    for Min_Price in Min_Price_Index_Type'Range loop
                        Global_Num_Races    := 0;
                        Global_Num_Bets     := 0;
                        Global_Num_Bets_Won := 0;
                        Global_Saldo        := Races.Saldo_Type'Value (Sa_Saldo.all);
                        Global_Profit       := 0.0;
                        Global_Avg_Price    := 0.0;
                        Global_Sum_Price    := 0.0;
                        Global_Min_Saldo    :=  1_000_000_000.0;
                        Global_Max_Saldo    := -1_000_000_000.0;

                        Log ("start simulation, saldo =  " & Integer (Global_Saldo)'Img);
                        Races.Race_Package.Get_First (Race_List, Race, Eol);
                        loop
                           exit when Eol;
                           Global_Num_Races := Global_Num_Races + 1;
                           Log ("---  main loop start " &  Race.Market.Marketid'Img &
                                  " saldo :" & Integer (Global_Saldo)'Img & " -----------------");
                           -- reset the daily profit when new day is treated
                           if Global_Race_Date.Day  /= Race.Market.Eventdate.Day or else
                              Global_Race_Date.Month /= Race.Market.Eventdate.Month or else
                              Global_Race_Date.Year  /=  Race.Market.Eventdate.Year then
                                Global_Race_Date := Race.Market.Eventdate;
                                Global_Profit    := 0.0;
                                Log ("main loop , race date = " & Sattmate_Calendar.String_Date (Global_Race_Date));
                           end if;

                           Race.Make_Lay_Favorite_Bet
                             (Bet_Laid          => Global_Bet_Laid,
                              Profit            => Global_Profit,
                              Saldo             => Global_Saldo,
                              Last_Loss         => Global_Last_Loss,
                              Max_Daily_Loss    => Global_Max_Daily_Loss,
                              Max_Profit_Factor => Global_Max_Profit_Factor,
                              Size              => Global_Size,
                              Min_Price         => Races.Min_Price_Type (Price ),
                              Max_Price         => Races.Max_Price_Type (Price + 1));

                           if Global_Bet_Laid then
                              Log ("---  main loop saldo after bet laid :" & Integer (Global_Saldo)'Img & " -----------------");
                              Global_Num_Bets := Global_Num_Bets +1;
                              Race.Check_Result
                                 (Profit    => Global_Profit,
                                  Saldo     => Global_Saldo,
                                  Last_Loss => Global_Last_Loss,
                                  Bet_Won   => Global_Bet_Won,
                                  Bet_Type  => Global_Bet_Type);
                               -- if bet is laid, race.price is updated with the actual price of the bet in make_back_bet
                              Global_Sum_Price := Global_Sum_Price + Race.Price;
                              if Global_Bet_Won then
                                  Global_Num_Bets_Won := Global_Num_Bets_Won + 1;
                              end if;
                           end if;
                           if Global_Saldo > Global_Max_Saldo then
                             Global_Max_Saldo := Global_Saldo ;
                           end if;

                           if Global_Saldo < Global_Min_Saldo then
                             Global_Min_Saldo := Global_Saldo ;
                           end if;
                           Races.Race_Package.Get_Next (Race_List, Race, Eol);
                        end loop;
                        Log ("main - Global_Profit : " & Integer (Global_Profit)'Img);

                        if Global_Num_Bets > 0 then
                          Global_Avg_Price := Global_Sum_Price / Races.Price_Type(Global_Num_Bets);
                          Actual_Hitrate := 100.0 * Float_8(Global_Num_Bets_Won)/Float_8(Global_Num_Bets);
                          Needed_Hitrate := 100.0 * Hitrates.Needed_Laybet_Hitrate(Global_Avg_Price,Hitrates.Betfair_Commission);
                        else
                          Global_Avg_Price := 0.0;
                          Actual_Hitrate := 0.0 ;
                          Needed_Hitrate := 0.0;
                        end if;

                        Log ("stop simulation, saldo =  " & Integer (Global_Saldo)'Img);
                        Print (Integer (Price)'Img & " " &
                             Integer (Price)'Img & " " &
                             Global_Num_Races'Img & " " &
                             Global_Num_Bets'Img & " " &
                             Global_Num_Bets_Won'Img & " " &
                             Global_Avg_Price'Img & " " &
                             Actual_Hitrate'Img & " " &
                             Needed_Hitrate'Img & " " &
                             integer'image(integer(Actual_Hitrate - Needed_Hitrate)) & " " &
                             Boolean'Image (Actual_Hitrate > Needed_Hitrate) & " " &
                             integer'image(integer(Global_Min_Saldo)) & " " &
                             integer'image(integer(Global_Saldo)) & " " &
                             integer'image(integer(Global_Max_Saldo)));
                        -- Append To file
                        --         begin
                        -- create file if not exists
                        Text_Io.Open
                          (Mode => Text_Io.Append_File,
                           Name => To_String (Fil),
                           File => Target_Dat);
                        Text_Io.Put_Line
                          (Target_Dat,
                           Integer (Price)'Img & " " &
                           Integer (Price)'Img & " " &
                           Global_Num_Races'Img & " " &
                           Global_Num_Bets'Img & " " &
                           Global_Num_Bets_Won'Img & " " &
                           Global_Avg_Price'Img & " " &
                           Actual_Hitrate'Img & " " &
                           Needed_Hitrate'Img & " " &
                           integer'image(integer(Actual_Hitrate - Needed_Hitrate)) & " " &
                           Boolean'Image (Actual_Hitrate > Needed_Hitrate) & " " &
                           integer'image(integer(Global_Min_Saldo)) & " " &
                           integer'image(integer(Global_Saldo)) & " " &
                           integer'image(integer(Global_Max_Saldo)));
                        Text_Io.Close (Target_Dat);
                        --         exception
                        --            when others => null;
                        --         end;
                        Log ("---  main loop stop " & Race.Market.Marketid'Img &
                             " profit :" & Integer (Global_Profit)'Img & " -----------------");
--                    end loop;
                 end loop;


               when Races.Back =>
--                  for Back_Price in Back_Price_Index_Type'Range loop
--                     for Delta_Price in Delta_Price_Index_Type'Range loop
                        Text_Io.Open
                          (Mode => Text_Io.Append_File,
                           Name => To_String (Fil),
                           File => Target_Dat);
                        Global_Saldo        := Races.Saldo_Type'Value (Sa_Saldo.all);
                        Global_Profit       := 0.0;
                        Global_Avg_Price    := 0.0;
                        Global_Sum_Price    := 0.0;
                        Global_Num_Bets     := 0;
                        Global_Num_Bets_Won := 0;
                        Global_Num_Races    := 0;
                        Global_Num_Bets_Daily     := 0;
                        Global_Num_Bets_Won_Daily := 0;
                        Global_Num_Races_Daily    := 0;
                        Global_Min_Saldo    :=  1_000_000_000.0;
                        Global_Max_Saldo    := -1_000_000_000.0;

                        Log ("start simulation, saldo =  " & Integer (Global_Saldo)'Img);
                        Races.Race_Package.Get_First (Race_List, Race, Eol);


                        Print (Sattmate_Calendar.String_Date_And_Time (Global_Race_Date) & " " &
                                Global_Back_Price'Img & " " &
                                Global_Delta_Price'Img & " " &
                                Global_Avg_Price'Img & " " &
                                Global_Num_Races'Img & " " &
                                Global_Num_Bets'Img & " " &
                                Global_Num_Bets_Won'Img & " " &
                                Global_Num_Races_Daily'Img & " " &
                                Global_Num_Bets_Daily'Img & " " &
                                Global_Num_Bets_Won_Daily'Img & " " &
                                integer'image(integer(Global_Saldo)));

                        Text_Io.Put_Line
                               (Target_Dat,
                                Sattmate_Calendar.String_Date_And_Time (Global_Race_Date) & " " &
                                Global_Back_Price'Img & " " &
                                Global_Delta_Price'Img & " " &
                                Global_Avg_Price'Img & " " &
                                Global_Num_Races'Img & " " &
                                Global_Num_Bets'Img & " " &
                                Global_Num_Bets_Won'Img & " " &
                                Global_Num_Races_Daily'Img & " " &
                                Global_Num_Bets_Daily'Img & " " &
                                Global_Num_Bets_Won_Daily'Img & " " &
                                integer'image(integer(Global_Saldo)));

                        loop
                           exit when Eol;
                           Global_Num_Races := Global_Num_Races + 1;
                           Global_Num_Races_Daily := Global_Num_Races_Daily + 1;
                           Log ("---  main loop start " &  Race.Market.Marketid'Img &
                                " saldo :" & Integer (Global_Saldo)'Img & " -----------------");
                           -- reset the daily profit when new day is treated
                           if Global_Race_Date.Day   /= Race.Market.Eventdate.Day or else
                             Global_Race_Date.Month /= Race.Market.Eventdate.Month or else
                             Global_Race_Date.Year  /=  Race.Market.Eventdate.Year then
                              Global_Race_Date := Race.Market.Eventdate;
                              Global_Num_Bets_Daily     := 0;
                              Global_Num_Bets_Won_Daily := 0;
                              Global_Num_Races_Daily    := 0;

                              Global_Profit    := 0.0;
                              Log ("main loop , race date = " & Sattmate_Calendar.String_Date (Global_Race_Date));
                           end if;

                           Race.Make_Back_Bet
                             (Bet_Laid          => Global_Bet_Laid,
                              Profit            => Global_Profit,
                              Saldo             => Global_Saldo,
                              Last_Loss         => Global_Last_Loss,
                              Max_Daily_Loss    => Global_Max_Daily_Loss,
                              Max_Profit_Factor => Global_Max_Profit_Factor,
                              Size              => Global_Size,
                              Back_Price        => Global_Back_Price,
                              Delta_Price       => Global_Delta_Price);

                           if Global_Bet_Laid then
                             Global_Num_Bets_Daily := Global_Num_Bets_Daily +1;
                             Global_Num_Bets := Global_Num_Bets +1;
                             Print (Sattmate_Calendar.String_Date_And_Time (Global_Race_Date) & " " &
                                Global_Back_Price'Img & " " &
                                Global_Delta_Price'Img & " " &
                                Global_Avg_Price'Img & " " &
                                Global_Num_Races'Img & " " &
                                Global_Num_Bets'Img & " " &
                                Global_Num_Bets_Won'Img & " " &
                                Global_Num_Races_Daily'Img & " " &
                                Global_Num_Bets_Daily'Img & " " &
                                Global_Num_Bets_Won_Daily'Img & " " &
                                integer'image(integer(Global_Saldo)));

                             Text_Io.Put_Line
                               (Target_Dat,
                                Sattmate_Calendar.String_Date_And_Time (Global_Race_Date) & " " &
                                Global_Back_Price'Img & " " &
                                Global_Delta_Price'Img & " " &
                                Global_Avg_Price'Img & " " &
                                Global_Num_Races'Img & " " &
                                Global_Num_Bets'Img & " " &
                                Global_Num_Bets_Won'Img & " " &
                                Global_Num_Races_Daily'Img & " " &
                                Global_Num_Bets_Daily'Img & " " &
                                Global_Num_Bets_Won_Daily'Img & " " &
                                integer'image(integer(Global_Saldo)));

                              Log ("---  main loop saldo after bet laid :" & Integer (Global_Saldo)'Img & " -----------------");
                              Race.Check_Result
                                (Profit    => Global_Profit,
                                 Saldo     => Global_Saldo,
                                 Last_Loss => Global_Last_Loss,
                                 Bet_Won   => Global_Bet_Won,
                                 Bet_Type  => Global_Bet_Type);
                              -- if bet is laid, race.price is updated with the actual price of the bet in make_back_bet
                              Global_Sum_Price := Global_Sum_Price + Race.Price;

                              Global_Avg_Price := Races.Price_Type(Global_Sum_Price)/Races.Price_Type(Global_Num_Bets);

                              if Global_Bet_Won then
                                 Global_Num_Bets_Won := Global_Num_Bets_Won +1;
                                 Global_Num_Bets_Won_Daily := Global_Num_Bets_Won_Daily +1;
                                 Print (Sattmate_Calendar.String_Date_And_Time (Global_Race_Date) & " " &
                                         Global_Back_Price'Img & " " &
                                         Global_Delta_Price'Img & " " &
                                         Global_Avg_Price'Img & " " &
                                         Global_Num_Races'Img & " " &
                                         Global_Num_Bets'Img & " " &
                                         Global_Num_Bets_Won'Img & " " &
                                         Global_Num_Races_Daily'Img & " " &
                                         Global_Num_Bets_Daily'Img & " " &
                                         Global_Num_Bets_Won_Daily'Img & " " &
                                         integer'image(integer(Global_Saldo)));

                                 Text_Io.Put_Line
                                        (Target_Dat,
                                         Sattmate_Calendar.String_Date_And_Time (Global_Race_Date) & " " &
                                         Global_Back_Price'Img & " " &
                                         Global_Delta_Price'Img & " " &
                                         Global_Avg_Price'Img & " " &
                                         Global_Num_Races'Img & " " &
                                         Global_Num_Bets'Img & " " &
                                         Global_Num_Bets_Won'Img & " " &
                                         Global_Num_Races_Daily'Img & " " &
                                         Global_Num_Bets_Daily'Img & " " &
                                         Global_Num_Bets_Won_Daily'Img & " " &
                                         integer'image(integer(Global_Saldo)));
                              end if;

                           end if;
                           if Global_Saldo > Global_Max_Saldo then
                             Global_Max_Saldo := Global_Saldo ;
                           end if;

                           if Global_Saldo < Global_Min_Saldo then
                             Global_Min_Saldo := Global_Saldo ;
                           end if;

                           Races.Race_Package.Get_Next (Race_List, Race, Eol);
                        end loop;
                        Log ("main - Global_Profit : " & Integer (Global_Profit)'Img);
                        Log ("stop simulation, saldo =  " & Integer (Global_Saldo)'Img);

                        Text_Io.Close (Target_Dat);
                        --         exception
                        --            when others => null;
                        --         end;
                        Log ("---  main loop stop " & Race.Market.Marketid'Img &
                             " profit :" & Integer (Global_Profit)'Img & " -----------------");

--                     end loop;
--                  end loop;
            end case;

            Contents_Gpi :=
              To_Unbounded_String
                ("graph_type='" & Sa_Graph_Type.all & "'" & Ada.Characters.Latin_1.Lf &
                 "animal='" & Sa_Animal.all & "'" & Ada.Characters.Latin_1.Lf &
                 "bet_name='" & Lower_Case (Global_Bet_Type'Img) & "'" & Ada.Characters.Latin_1.Lf &
                 "bet_type='" & Sa_Bet_Name.all & "'" & Ada.Characters.Latin_1.Lf &
                 "variant='" & Lower_Case (The_Variant'Img) & "'" & Ada.Characters.Latin_1.Lf &
                 "index='" & "not_supported" & "'" & Ada.Characters.Latin_1.Lf &
                 "max_daily_loss='" & Lower_Case (Max_Daily_Loss'Img) & "'" & Ada.Characters.Latin_1.Lf &
                 "start_date='" & Sattmate_Calendar.String_Date_Iso (Global_Start_Date) & "'" & Ada.Characters.Latin_1.Lf &
                 "stop_date='" & Sa_Stop_Date.all & "'" & Ada.Characters.Latin_1.Lf &
                 "datafil='" & To_String (Filename) & "'" & Ada.Characters.Latin_1.Lf &
                 "datadir='" & To_String (Data_Dir) & "'");


            Text_Io.Create
              (Mode => Text_Io.Out_File,
               Name => To_String (Fil_Gpi),
               File => Target_Gpi);
            Text_Io.Put_Line (Target_Gpi, To_String (Contents_Gpi));
            Text_Io.Close (Target_Gpi);

--         end loop;
--      end loop;
--   end loop;

exception
   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);
end Simulator3;
