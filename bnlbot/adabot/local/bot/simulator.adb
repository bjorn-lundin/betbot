with Text_Io;
with Sattmate_Calendar;
with Gnat.Command_Line; use Gnat.Command_Line;
with Sattmate_Types; use Sattmate_Types;
with Gnat.Strings;
--with Simple_List_Class;
with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
with Races;
with Logging; use Logging;
--with Ada.Directories;
with Gnat.Os_Lib;
with Ada.Characters.Latin_1;
with Sattmate_Exception;

procedure Simulator is
   Not_Implemented,
   Bad_Animal,
   Bad_Bet_Type,
   Bad_Graph_Type,
   Bad_Name_Type : exception;

   Eol                      : Boolean := False;

   Sa_Price                             : aliased Gnat.Strings.String_Access;
   Sa_Delta_Price                       : aliased Gnat.Strings.String_Access;
   --  Sa_Min_Price                         : aliased Gnat.Strings.String_Access;
   --  Sa_Max_Price                         : aliased Gnat.Strings.String_Access;
   Sa_Bet_Type                          : aliased Gnat.Strings.String_Access;
   Sa_Graph_Type                        : aliased Gnat.Strings.String_Access;
   Sa_Start_Date                        : aliased Gnat.Strings.String_Access;
   Sa_Stop_Date                         : aliased Gnat.Strings.String_Access;
   Sa_Saldo                             : aliased Gnat.Strings.String_Access;
   Sa_Size                              : aliased Gnat.Strings.String_Access;
   Sa_Animal                            : aliased Gnat.Strings.String_Access;
   Sa_Variant                           : aliased Gnat.Strings.String_Access;
   Sa_Max_Profit_Factor                 : aliased Gnat.Strings.String_Access;
   Sa_Max_Daily_Loss                    : aliased Gnat.Strings.String_Access;
   Sa_Bet_Name                          : aliased Gnat.Strings.String_Access;
   Ba_Quiet                             : aliased Boolean;

   Config                               :  Command_Line_Configuration;

   Race_List                            : Races.Race_Package.List_Type := Races.Race_Package.Create;
   Race                                 : Races.Race_Type;


   Global_Animal                                  : Races.Animal_Type;
   Global_Bet_Name                                : Races.Bet_Name_Type;
   Global_Bet_Type                                : Races.Bet_Type_Type;
   Global_Graph_Type                              : Races.Graph_Type;

   Global_Profit                                  : Races.Profit_Type := 0.0;
   Global_Saldo                                   : Races.Saldo_Type := 0.0;
   ---   Global_Date                          : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   Global_Max_Daily_Loss                          : Races.Max_Daily_Loss_Type := 0.0;
   Global_Max_Profit_Factor                       : Races.Max_Profit_Factor_Type := 0.0;
   Global_Bet_Laid                                : Boolean := False;
   Global_Size                                    : Races.Size_Type := 0.0;
   --   Global_Min_Price                            : Races.Min_Price_Type := 0.0;
   --   Global_Max_Price                            : Races.Max_Price_Type := 0.0;

   use type Races.Saldo_Type;

   Global_Last_Loss                            : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
   Global_Race_Date                            : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;

   type Max_Price_Index_Type is range 1 .. 25 ;
   type Min_Price_Index_Type is range 1 .. 25 ;

   Filename      : Unbounded_String := Null_Unbounded_String;
   Fil           : Unbounded_String := Null_Unbounded_String;
   Data_Dir      : Unbounded_String := Null_Unbounded_String;
   Fil_Gpi       : Unbounded_String := Null_Unbounded_String;
   Contents_Gpi  : Unbounded_String := Null_Unbounded_String;

   Target_Dat : Text_Io.File_Type;
   Target_Gpi : Text_Io.File_Type;

   Global_Directory_Separator : String (1 .. 1) ;
begin

   Global_Directory_Separator (1) := Gnat.Os_Lib.Directory_Separator;

   Define_Switch (Config, Sa_Price'Access,
                  "-n:", Long_Switch => "--price=",
                  Help           => "price of bet");

   Define_Switch (Config, Sa_Delta_Price'Access,
                  "-x:",  Long_Switch => "--delta_price=",
                  Help            => "+/- fluctuation of price");

   --   Define_Switch (Config, Sa_Max_Price'Access,
   --                  "-X:",  Long_Switch => "--max_price=",
   --                  Help            => "max price");

   --   Define_Switch (Config, Sa_Min_Price'Access,
   --                  "-N:",  Long_Switch => "--min_price=",
   --                  Help            => "min price");

   Define_Switch (Config, Sa_Bet_Type'Access,
                  "-t:",  Long_Switch => "--bet_type=",
                  Help            => "type of bet, 'lay' or 'back'");

   Define_Switch (Config, Sa_Graph_Type'Access,
                  "-g:",  Long_Switch => "--graph_type=",
                  Help            => "type of graph, 'daily', 'weekly' or 'biweekly'");

   Define_Switch (Config, Sa_Start_Date'Access,
                  "-s:",  Long_Switch => "--start_date=",
                  Help            => "when the simulation starts dd-MON-yyyy, 25-FEB-2013");

   Define_Switch (Config, Sa_Stop_Date'Access,
                  "-f:",  Long_Switch => "--stop_date=",
                  Help            => "when the simulation stops dd-MON-yyyy, 25-FEB-2013");

   Define_Switch (Config, Sa_Saldo'Access,
                  "-s:",  Long_Switch => "--saldo=",
                  Help            => "starting saldo");

   Define_Switch (Config, Sa_Size'Access,
                  "-z:",  Long_Switch => "--size=",
                  Help            => "size of bet");

   Define_Switch (Config, Sa_Animal'Access,
                  "-a:",  Long_Switch => "--animal=",
                  Help            => "type of animal, 'hound' or 'horse'");

   Define_Switch (Config, Sa_Variant'Access,
                  "-W:",  Long_Switch => "--variant=",
                  Help            => "type of variant, 'normal', 'max_3', 'max_4', 'max_5', 'max_7'");

   Define_Switch (Config, Sa_Max_Profit_Factor'Access,
                  "-P:",  Long_Switch => "--max_profit_factor=",
                  Help            => "if > 0, Quit when profit of the day > max_profit_factor * size ");

   Define_Switch (Config, Sa_Max_Daily_Loss'Access,
                  "-P:",  Long_Switch => "--max_daily_loss=",
                  Help            => "How much loss is allowed to continue betting this day");

   Define_Switch (Config, Sa_Bet_Name'Access,
                  "-b:",  Long_Switch => "--bet_name=",
                  Help            => "'winner' or 'place'");

   Define_Switch (Config, Ba_Quiet'Access,
                  "-q",  Long_Switch => "--quiet",
                  Help            => "no log output");

  Getopt (Config);  -- process the command line
   --   Display_Help (Config);


   begin
      Logging.Set_Quiet(Ba_Quiet);


      if Sa_Animal.all = "hound" then
         Global_Animal := Races.Hound ;
      elsif Sa_Animal.all = "horse" then
         Global_Animal := Races.Horse ;
      else
         raise Bad_Animal with "Not supported animal: '" & Sa_Animal.all & "'";
      end if;

      if Sa_Bet_Name.all = "winner" then
         Global_Bet_Name := Races.Winner ;
      elsif Sa_Bet_Name.all = "place" then
         Global_Bet_Name := Races.Place ;
      else
         raise Bad_Name_Type with "Not supported bet name: '" & Sa_Bet_Name.all & "'";
      end if;

      if Sa_Bet_Type.all = "lay" then
         Global_Bet_Type := Races.Lay ;
      elsif Sa_Bet_Type.all = "back" then
         Global_Bet_Type := Races.Back ;
      else
         raise Bad_Bet_Type with "Not supported bet type: '" & Sa_Bet_Type.all & "'";
      end if;

      if Sa_Graph_Type.all = "daily" then
         Global_Graph_Type := Races.Daily ;
      elsif Sa_Graph_Type.all = "weekly" then
         Global_Graph_Type := Races.Weekly ;
      elsif Sa_Graph_Type.all = "biweekly" then
         Global_Graph_Type := Races.Bi_Weekly ;
      elsif Sa_Graph_Type.all = "quadweekly" then
         Global_Graph_Type := Races.Quad_Weekly ;
      else
         raise Bad_Graph_Type with "Not supported graph type: '" & Sa_Graph_Type.all & "'";
      end if;


      --  Global_Min_Price := Races.Min_Price_Type'Value (Sa_Min_Price.all);
      --  Global_Max_Price := Races.Max_Price_Type'Value (Sa_Max_Price.all);
      Global_Size := Races.Size_Type'Value (Sa_Size.all);
      Global_Max_Profit_Factor := Races.Max_Profit_Factor_Type'Value (Sa_Max_Profit_Factor.all);
      Global_Max_Daily_Loss := Races.Max_Daily_Loss_Type'Value (Sa_Max_Daily_Loss.all);
      Global_Saldo := Races.Saldo_Type'Value (Sa_Saldo.all);
   exception
      when Constraint_Error =>
         Display_Help (Config);
         return;
   end;


   Races.Get_Database_Data (Race_List  => Race_List,
                            Bet_Type   => Global_Bet_Name,
                            Animal     => Global_Animal,
                            Start_Date => Sattmate_Calendar.To_Time_Type (Sa_Start_Date.all, "00:00:00.000"),
                            Stop_Date  => Sattmate_Calendar.To_Time_Type (Sa_Stop_Date.all, "23:59:59:999")
                           ) ;


   -- what filename to write this to ?
   Filename := To_Unbounded_String ("simulation_ada1-" & Sa_Animal.all & "-" &
                                      Sa_Graph_Type.all & "-" &
                                      Sa_Bet_Name.all  & "-" &
                                      Sa_Bet_Type.all  & "-" &
                                      Sa_Variant.all  & "-" &
                                      Sa_Start_Date.all  & "-" &
                                      Sa_Stop_Date.all  &
                                    --   Sa_Index.all  & "-" &
                                      ".dat");

   Log ("Filename: '" & To_String (Filename) & "'");

   Data_Dir := To_Unbounded_String ("sims");
   Fil := Data_Dir & To_Unbounded_String (Global_Directory_Separator) & Filename;
   Fil_Gpi := Data_Dir & To_Unbounded_String ("/") & Filename & To_Unbounded_String (".gpi");
   Log ("Filename: '" & To_String (Filename) & "'");
   --   begin
   -- create file if not exists
   Text_Io.Create (Mode => Text_Io.Out_File,
                   Name => To_String (Fil),
                   File => Target_Dat);

   Text_Io.Close (Target_Dat);
   --   exception
   --      when others => null;
   --   end;


   for Max_Price in Max_Price_Index_Type' Range loop
      for Min_Price in Min_Price_Index_Type'Range loop

         Global_Saldo := Races.Saldo_Type'Value (Sa_Saldo.all);
         Global_Profit := 0.0;

         if Integer (Min_Price) < Integer (Max_Price) then

            Log ("start simulation, saldo =  " & Integer (Global_Saldo)'Img);
            Races.Race_Package.Get_First (Race_List, Race, Eol);
            loop
               exit when Eol;
               Log ("---  main loop start " & Race.Market.Market_Id'Img & " saldo :" & Integer (Global_Saldo)'Img & " -----------------" );
               if Global_Race_Date.Day /= Race.Market.Event_Date.Day or else
                 Global_Race_Date.Month /= Race.Market.Event_Date.Month or else
                 Global_Race_Date.Year /= Race.Market.Event_Date.Year then
                  Global_Race_Date := Race.Market.Event_Date;
                  Global_Profit := 0.0;
                  Log ("main loop , race date = " & Sattmate_Calendar.String_Date (Global_Race_Date));
               end if;


               Race.Show_Runners;
               case Global_Bet_Type is
                  when Races.Lay =>
                     Race. Make_Lay_Bet ( Bet_Laid         => Global_Bet_Laid,
                                         Profit            => Global_Profit,
                                         Saldo             => Global_Saldo,
                                         Last_Loss         => Global_Last_Loss,
                                         Max_Daily_Loss    => Global_Max_Daily_Loss,
                                         Max_Profit_Factor => Global_Max_Profit_Factor,
                                         --                                Bet_Name          => Global_Bet_Name,
                                         Size              => Global_Size,
                                         Min_Price         => Races.Min_Price_Type (Min_Price),
                                         Max_Price         => Races.Max_Price_Type (Max_Price)) ;

                     if Global_Bet_Laid then
                        Log ("---  main loop saldo after bet laid :" & Integer (Global_Saldo)'Img & " -----------------" );
                        Race.Check_Result (Profit    => Global_Profit,
                                           Saldo     => Global_Saldo,
                                           Last_Loss => Global_Last_Loss,
                                           Bet_Type  => Global_Bet_Type);
                     end if;
                     Log ("main - Global_Profit : " & Integer (Global_Profit)'Img );

                  when Races.Back => raise Not_Implemented with "Bets of type Back not implemented yet";
               end case;
               Log ("---  main loop stop " & Race.Market.Market_Id'Img & " profit :" & Integer (Global_Profit)'Img & " -----------------" );
               Races.Race_Package.Get_Next (Race_List, Race, Eol);
            end loop;

            Log ("stop simulation, saldo =  " & Integer (Global_Saldo)'Img);
         end if; -- min_price < Max_Price
         Print (Integer (Min_Price)'Img & " " & Integer (Max_Price)'Img & " " & Integer (Global_Saldo)'Img );
         -- Append To file
         --         begin
         -- create file if not exists
         Text_Io.Open (Mode => Text_Io.Append_File,
                       Name => To_String (Fil),
                       File => Target_Dat);
         Text_Io.Put_Line (Target_Dat, Integer (Min_Price)'Img & " " & Integer (Max_Price)'Img & " " & Integer (Global_Saldo)'Img );
         Text_Io.Close (Target_Dat);
         --         exception
         --            when others => null;
         --         end;


      end loop;
   end loop;

   Contents_Gpi := To_Unbounded_String ("graph_type='" & Sa_Graph_Type.all & "'" & Ada.Characters.Latin_1.Lf &
                                        "animal='" & Sa_Animal.all & "'" & Ada.Characters.Latin_1.Lf &
                                        "bet_name='" & Sa_Bet_Type.all & "'" & Ada.Characters.Latin_1.Lf &
                                        "bet_type='" & Sa_Bet_Name.all & "'" & Ada.Characters.Latin_1.Lf &
                                        "variant='" & Sa_Variant.all & "'" & Ada.Characters.Latin_1.Lf &
                                        "index='" & "not_supported" & "'" & Ada.Characters.Latin_1.Lf &
                                        "start_date='" & Sa_Start_Date.all & "'" & Ada.Characters.Latin_1.Lf &
                                        "stop_date='" & Sa_Stop_Date.all & "'" & Ada.Characters.Latin_1.Lf &
                                        "datafil='" & To_String (Filename) & "'" & Ada.Characters.Latin_1.Lf &
                                        "datadir='" & To_String (Data_Dir) & "'");

   Text_Io.Create (Mode => Text_Io.Out_File,
                   Name => To_String (Fil_Gpi),
                   File => Target_Gpi);
   Text_Io.Put_Line (Target_Gpi, To_String (Contents_Gpi) );
   Text_Io.Close (Target_Gpi);


exception
  when E: Others =>
    Sattmate_Exception.Tracebackinfo(E) ;
end Simulator;
