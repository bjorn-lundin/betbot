with Text_Io;
with Sattmate_Calendar;
with Gnat.Command_Line; use Gnat.Command_Line;
--with Sattmate_Types; use Sattmate_Types;
with Gnat.Strings;
--with Simple_List_Class;

with Races;


procedure Simulator is

   Bad_Animal, Bad_Bet_Type : exception;
   Eol                      : Boolean := False;


   Sa_Price                             : aliased Gnat.Strings.String_Access;
   Sa_Delta_Price                       : aliased Gnat.Strings.String_Access;
   Sa_Min_Price                         : aliased Gnat.Strings.String_Access;
   Sa_Max_Price                         : aliased Gnat.Strings.String_Access;
   Sa_Bet_Type                          : aliased Gnat.Strings.String_Access;
   Sa_Graph_Type                        : aliased Gnat.Strings.String_Access;
   Sa_Start_Date                        : aliased Gnat.Strings.String_Access;
   Sa_Stop_Date                         : aliased Gnat.Strings.String_Access;
   Sa_Saldo                             : aliased Gnat.Strings.String_Access;
   Sa_Size                              : aliased Gnat.Strings.String_Access;
   Sa_Animal                            : aliased Gnat.Strings.String_Access;
   Sa_Variant                           : aliased Gnat.Strings.String_Access;
   Sa_Max_Profit_Factor                 : aliased Gnat.Strings.String_Access;
   Sa_Bet_Name                          : aliased Gnat.Strings.String_Access;

   Config                               :  Command_Line_Configuration;



   Animal                               : Races.Animal_Type;
   Bet_Type                             : Races.Bet_Type_Type;

   Race_List                            : Races.Race_Package.List_Type := Races.Race_Package.Create;
   Race                                 : Races.Race_Type;



begin

   Define_Switch (Config, Sa_Price'Access,
                  "-n:", Long_Switch => "--price=",
                  Help           => "price of bet");

   Define_Switch (Config, Sa_Delta_Price'Access,
                  "-x:",  Long_Switch => "--delta_price=",
                  Help            => "+/- fluctuation of price");

   Define_Switch (Config, Sa_Min_Price'Access,
                  "-N:",  Long_Switch => "--max_price=",
                  Help            => "max price");

   Define_Switch (Config, Sa_Max_Price'Access,
                  "-X:",  Long_Switch => "--min_price=",
                  Help            => "min price");

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

   Define_Switch (Config, Sa_Bet_Name'Access,
                  "-b:",  Long_Switch => "--bet_name=",
                  Help            => "'winner' or 'place'");

   Getopt (Config);  -- process the command line
   Display_Help (Config);



   if Sa_Animal.all = "hound" then
      Animal := Races.Hound ;
   elsif Sa_Animal.all = "horse" then
      Animal := Races.Horse ;
   else
      raise Bad_Animal with "Not supported animal: '" & Sa_Animal.all & "'";
   end if;

   if Sa_Bet_Type.all = "winner" then
      Bet_Type := Races.Winner ;
   elsif Sa_Bet_Type.all = "place" then
      Bet_Type := Races.Place ;
   else
      raise Bad_Bet_Type with "Not supported bet type: '" & Sa_Bet_Type.all & "'";
   end if;






   Races.Get_Database_Data (Race_List  => Race_List,
                            Bet_Type   => Bet_Type,
                            Animal     => Animal,
                            Start_Date => Sattmate_Calendar.To_Time_Type (Sa_Start_Date.all, "00:00:00.000"),
                            Stop_Date  => Sattmate_Calendar.To_Time_Type (Sa_Stop_Date.all, "23:59:59:999")
                           ) ;




   Races.Race_Package.Get_First (Race_List, Race, Eol);
   loop
      exit when Eol;
      Text_Io.Put_Line ("------------------------------" );
      Text_Io.Put_Line ("marketid: " & Race.Market.Market_Id'Img & " " &  Race.No_Of_Runners'Img & "/" & Race.No_Of_Winners'Img );
      Text_Io.Put_Line ("--++--++--++--++--++--++--++--" );
      Race.Show_Runners;

      Races.Race_Package.Get_Next (Race_List, Race, Eol);
   end loop;




end Simulator;
