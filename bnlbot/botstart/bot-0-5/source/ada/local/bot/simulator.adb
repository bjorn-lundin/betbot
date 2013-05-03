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

procedure Simulator is
--  Not_Implemented,
   Bad_Animal,
   --   Bad_Bet_Type,
   Bad_Graph_Type, Bad_Name_Type : exception;

   Eol : Boolean := False;

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

   Global_Profit            : Races.Profit_Type            := 0.0;
   Global_Saldo             : Races.Saldo_Type             := 0.0;
   Global_Max_Daily_Loss    : Races.Max_Daily_Loss_Type    := 0.0;
   Global_Max_Profit_Factor : Races.Max_Profit_Factor_Type := 0.0;
   Global_Bet_Laid          : Boolean                      := False;
   Global_Size              : Races.Size_Type              := 0.0;

   use type Races.Saldo_Type;
   use type Races.Delta_Price_Type;
   use type Races.Back_Price_Type;
   use type Sattmate_Calendar.Time_Type;
   use type Sattmate_Calendar.Interval_Type;
   use type Races.Max_Daily_Loss_Type;

   Global_Last_Loss  : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   Global_Race_Date  : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   Global_Start_Date : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   Global_Stop_Date  : Sattmate_Calendar.Time_Type :=  Sattmate_Calendar.Time_Type_First;

   type Max_Price_Index_Type   is range 1 .. 25;  -- use integers only
   type Min_Price_Index_Type   is range 1 .. 25;  -- use integers only
   type Back_Price_Index_Type  is range 1 .. 100; -- will divide by 10
   type Delta_Price_Index_Type is range 1 .. 10;  -- will divide by 10

   Filename     : Unbounded_String := Null_Unbounded_String;
   Fil          : Unbounded_String := Null_Unbounded_String;
   Data_Dir     : Unbounded_String := Null_Unbounded_String;
   Fil_Gpi      : Unbounded_String := Null_Unbounded_String;
   Contents_Gpi : Unbounded_String := Null_Unbounded_String;

   Target_Dat : Text_Io.File_Type;
   Target_Gpi : Text_Io.File_Type;

   Global_Directory_Separator : String (1 .. 1);
begin

   Global_Directory_Separator (1) := Gnat.Os_Lib.Directory_Separator;

   Define_Switch
     (Config,
      Sa_Graph_Type'Access,
      "-g:",
      Long_Switch => "--graph_type=",
      Help        => "type of graph, 'daily', 'quadweekly' or 'octaweekly'");

   Define_Switch
     (Config,
      Sa_Stop_Date'Access,
      "-f:",
      Long_Switch => "--stop_date=",
      Help        => "when the simulation stops dd-MON-yyyy, 25-FEB-2013");

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
      Ba_Quiet'Access,
      "-q",
      Long_Switch => "--quiet",
      Help        => "no log output");

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
      elsif Sa_Graph_Type.all = "quadweekly" then
         Global_Graph_Type := Races.Quad_Weekly;
      elsif Sa_Graph_Type.all = "octaweekly" then
         Global_Graph_Type := Races.Octa_Weekly;
      else
         raise Bad_Graph_Type with "Not supported graph type: '" & Sa_Graph_Type.all & "'";
      end if;

      Global_Size              := Races.Size_Type'Value (Sa_Size.all);
      Global_Saldo             := Races.Saldo_Type'Value (Sa_Saldo.all);
   exception
      when Constraint_Error =>
         Display_Help (Config);
         return;
   end;

   Global_Stop_Date := Sattmate_Calendar.To_Time_Type (Sa_Stop_Date.all, "23:59:59:999");

   case Global_Graph_Type is
--      when Races.Daily =>       Global_Start_Date := Global_Stop_Date;
      when Races.Weekly      => Global_Start_Date := Global_Stop_Date - ( 6, 0, 0, 0, 0);
      when Races.Quad_Weekly => Global_Start_Date := Global_Stop_Date - (27, 0, 0, 0, 0);
      when Races.Octa_Weekly => Global_Start_Date := Global_Stop_Date - (55, 0, 0, 0, 0);
   end case;


   if Global_Start_Date < Sattmate_Calendar.Time_Type'(2013, 01, 30, 0, 0, 0, 0) then
      Log ("start date outside range, " & Global_Graph_Type'Img & " " &
           Sattmate_Calendar.String_Date (Global_Start_Date) & " " &
           Sattmate_Calendar.String_Date (Global_Stop_Date )
          );
      return;
   end if;

   Global_Start_Date.Hour        := 0;
   Global_Start_Date.Minute      := 0;
   Global_Start_Date.Second      := 0;
   Global_Start_Date.Millisecond := 0;

   Races.Get_Database_Data
     (Race_List  => Race_List,
      Bet_Type   => Global_Bet_Name,
      Animal     => Global_Animal,
      Start_Date => Global_Start_Date,
      Stop_Date  => Global_Stop_Date);

   Data_Dir := To_Unbounded_String ("sims");

   for Bet_Type in Races.Bet_Type_Type'range loop
      for The_Variant in Races.Variant_Type'range loop
         for Max_Daily_Loss in Races.Max_Daily_Loss_Type_Type'range loop

            Global_Max_Profit_Factor := Races.Max_Profit_Factor_Type(Races.Variant(The_Variant));
            Global_Max_Daily_Loss := Races.Max_Daily_Loss_Type(Races.Max_Daily_Loss(Max_Daily_Loss));

            -- new type of simulation, reset dates
            Global_Last_Loss := Sattmate_Calendar.Time_Type_First;
            Global_Race_Date := Sattmate_Calendar.Time_Type_First;

            -- what filename to write this to ?
            Filename := To_Unbounded_String
              ("simulation_ada1-" &
               Sa_Animal.all &  "-" &
               Lower_Case (Sa_Graph_Type.all) & "-" &
               Sa_Bet_Name.all & "-" &
               Lower_Case (Bet_Type'Img) & "-" &
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
            case Bet_Type is
            when Races.Lay =>
               for Max_Price in Max_Price_Index_Type'range loop
                  for Min_Price in Min_Price_Index_Type'range loop
                     Global_Saldo  := Races.Saldo_Type'Value (Sa_Saldo.all);
                     Global_Profit := 0.0;
                     Log ("start simulation, saldo =  " & Integer (Global_Saldo)'Img);
                     if Integer (Min_Price) < Integer (Max_Price) then
                        Races.Race_Package.Get_First (Race_List, Race, Eol);
                        loop
                           exit when Eol;
                           Log ("---  main loop start " &  Race.Market.Market_Id'Img &
                                " saldo :" & Integer (Global_Saldo)'Img & " -----------------");
                           -- reset the daily profit when new day is treated
                           if Global_Race_Date.Day  /= Race.Market.Event_Date.Day or else
                             Global_Race_Date.Month /= Race.Market.Event_Date.Month or else
                             Global_Race_Date.Year  /=  Race.Market.Event_Date.Year then
                              Global_Race_Date := Race.Market.Event_Date;
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
                              Min_Price         => Races.Min_Price_Type (Min_Price),
                              Max_Price         => Races.Max_Price_Type (Max_Price));

                           if Global_Bet_Laid then
                              Log ("---  main loop saldo after bet laid :" & Integer (Global_Saldo)'Img & " -----------------");
                              Race.Check_Result
                                (Profit    => Global_Profit,
                                 Saldo     => Global_Saldo,
                                 Last_Loss => Global_Last_Loss,
                                 Bet_Type  => Bet_Type);
                           end if;
                           Races.Race_Package.Get_Next (Race_List, Race, Eol);
                        end loop;
                     end if; -- min_price < Max_Price
                     Log ("main - Global_Profit : " & Integer (Global_Profit)'Img);

                     Log ("stop simulation, saldo =  " & Integer (Global_Saldo)'Img);
                     Print (Integer (Min_Price)'Img & " " & Integer (Max_Price)'Img & " " & Integer (Global_Saldo)'Img);
                     -- Append To file
                     --         begin
                     -- create file if not exists
                     Text_Io.Open
                       (Mode => Text_Io.Append_File,
                        Name => To_String (Fil),
                        File => Target_Dat);
                     Text_Io.Put_Line
                       (Target_Dat, Integer (Min_Price)'Img & " " & Integer (Max_Price)'Img & " " & Integer (Global_Saldo)'Img);
                     Text_Io.Close (Target_Dat);
                     --         exception
                     --            when others => null;
                     --         end;
                     Log ("---  main loop stop " & Race.Market.Market_Id'Img &
                          " profit :" & Integer (Global_Profit)'Img & " -----------------");
                  end loop;
               end loop;

               --              when Races.Lay_Favorite =>
               --                 for Max_Price in Max_Price_Index_Type'Range loop
               --                    for Min_Price in Min_Price_Index_Type'Range loop
               --                       Global_Saldo  := Races.Saldo_Type'Value (Sa_Saldo.all);
               --                       Global_Profit := 0.0;
               --                       Log ("start simulation, saldo =  " & Integer (Global_Saldo)'Img);
               --                       if Integer (Min_Price) < Integer (Max_Price) then
               --                          Races.Race_Package.Get_First (Race_List, Race, Eol);
               --                          loop
               --                             exit when Eol;
               --                             Log ("---  main loop start " &  Race.Market.Market_Id'Img &
               --                                    " saldo :" & Integer (Global_Saldo)'Img & " -----------------");
               --                             -- reset the daily profit when new day is treated
               --                             if Global_Race_Date.Day  /= Race.Market.Event_Date.Day or else
               --                               Global_Race_Date.Month /= Race.Market.Event_Date.Month or else
               --                               Global_Race_Date.Year  /=  Race.Market.Event_Date.Year then
               --                                Global_Race_Date := Race.Market.Event_Date;
               --                                Global_Profit    := 0.0;
               --                                Log ("main loop , race date = " & Sattmate_Calendar.String_Date (Global_Race_Date));
               --                             end if;
               --
               --                             Race.Make_Lay_Favorite_Bet
               --                               (Bet_Laid          => Global_Bet_Laid,
               --                                Profit            => Global_Profit,
               --                                Saldo             => Global_Saldo,
               --                                Last_Loss         => Global_Last_Loss,
               --                                Max_Daily_Loss    => Global_Max_Daily_Loss,
               --                                Max_Profit_Factor => Global_Max_Profit_Factor,
               --                                Size              => Global_Size,
               --                                Min_Price         => Races.Min_Price_Type (Min_Price),
               --                                Max_Price         => Races.Max_Price_Type (Max_Price));
               --
               --                             if Global_Bet_Laid then
               --                                Log ("---  main loop saldo after bet laid :" & Integer (Global_Saldo)'Img & " -----------------");
               --                                Race.Check_Result
               --                                  (Profit    => Global_Profit,
               --                                   Saldo     => Global_Saldo,
               --                                   Last_Loss => Global_Last_Loss,
               --                                   Bet_Type  => Bet_Type);
               --                             end if;
               --                             Races.Race_Package.Get_Next (Race_List, Race, Eol);
               --                          end loop;
               --                       end if; -- min_price < Max_Price
               --                          Log ("main - Global_Profit : " & Integer (Global_Profit)'Img);
               --
               --                          Log ("stop simulation, saldo =  " & Integer (Global_Saldo)'Img);
               --                          Print (Integer (Min_Price)'Img & " " & Integer (Max_Price)'Img & " " & Integer (Global_Saldo)'Img);
               --                          -- Append To file
               --                          --         begin
               --                          -- create file if not exists
               --                          Text_Io.Open
               --                            (Mode => Text_Io.Append_File,
               --                             Name => To_String (Fil),
               --                             File => Target_Dat);
               --                          Text_Io.Put_Line
               --                            (Target_Dat, Integer (Min_Price)'Img & " " & Integer (Max_Price)'Img & " " & Integer (Global_Saldo)'Img);
               --                          Text_Io.Close (Target_Dat);
               --                          --         exception
               --                          --            when others => null;
               --                          --         end;
               --                          Log ("---  main loop stop " & Race.Market.Market_Id'Img &
               --                                 " profit :" & Integer (Global_Profit)'Img & " -----------------");
               --                    end loop;
               --                 end loop;

            when Races.Back =>
               for Back_Price in Back_Price_Index_Type'Range loop
                  for Delta_Price in Delta_Price_Index_Type'Range loop

                     Global_Saldo  := Races.Saldo_Type'Value (Sa_Saldo.all);
                     Global_Profit := 0.0;

                     Log ("start simulation, saldo =  " & Integer (Global_Saldo)'Img);
                     Races.Race_Package.Get_First (Race_List, Race, Eol);
                     loop
                        exit when Eol;
                        Log ("---  main loop start " &  Race.Market.Market_Id'Img &
                             " saldo :" & Integer (Global_Saldo)'Img & " -----------------");
                        -- reset the daily profit when new day is treated
                        if Global_Race_Date.Day   /= Race.Market.Event_Date.Day or else
                          Global_Race_Date.Month /= Race.Market.Event_Date.Month or else
                          Global_Race_Date.Year  /=  Race.Market.Event_Date.Year then
                           Global_Race_Date := Race.Market.Event_Date;
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
                           Back_Price        => Races.Back_Price_Type (Back_Price) / 10.0,
                           Delta_Price       => Races.Delta_Price_Type (Delta_Price) / 10.0);

                        if Global_Bet_Laid then
                           Log ("---  main loop saldo after bet laid :" & Integer (Global_Saldo)'Img & " -----------------");
                           Race.Check_Result
                             (Profit    => Global_Profit,
                              Saldo     => Global_Saldo,
                              Last_Loss => Global_Last_Loss,
                              Bet_Type  => Bet_Type);
                        end if;
                        Races.Race_Package.Get_Next (Race_List, Race, Eol);
                     end loop;
                     Log ("main - Global_Profit : " & Integer (Global_Profit)'Img);
                     Log ("stop simulation, saldo =  " & Integer (Global_Saldo)'Img);
                     Print (Races.Back_Price_Type (Races.Back_Price_Type (Back_Price) / 10.0)'Img & " " &
                            Races.Delta_Price_Type ( Races.Delta_Price_Type (Delta_Price) / 10.0)'Img & " " &
                            Integer (Global_Saldo)'Img);
                     -- Append To file
                     --         begin
                     -- create file if not exists
                     Text_Io.Open
                       (Mode => Text_Io.Append_File,
                        Name => To_String (Fil),
                        File => Target_Dat);
                     Text_Io.Put_Line
                       (Target_Dat,
                        Races.Back_Price_Type (Races.Back_Price_Type (Back_Price) / 10.0)'Img & " " &
                        Races.Delta_Price_Type ( Races.Delta_Price_Type (Delta_Price) / 10.0)'Img & " " &
                        Integer (Global_Saldo)'Img);
                     Text_Io.Close (Target_Dat);
                     --         exception
                     --            when others => null;
                     --         end;
                     Log ("---  main loop stop " & Race.Market.Market_Id'Img &
                          " profit :" & Integer (Global_Profit)'Img & " -----------------");

                  end loop;
               end loop;
            end case;

            Contents_Gpi :=
              To_Unbounded_String
                ("graph_type='" & Sa_Graph_Type.all & "'" & Ada.Characters.Latin_1.Lf &
                 "animal='" & Sa_Animal.all & "'" & Ada.Characters.Latin_1.Lf &
                 "bet_name='" & Lower_Case (Bet_Type'Img) & "'" & Ada.Characters.Latin_1.Lf &
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

         end loop;
      end loop;
   end loop;

exception
   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);
end Simulator;
