with Ada.Strings; use Ada.Strings;
--with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Environment_Variables;

with Sim;
with Utils; use Utils;
with Types ; use Types;
with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
--with Text_Io;
with Price_Histories; use Price_Histories;
with Bets;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Calendar2;  use Calendar2;
with Logging; use Logging;
with Markets;
with Runners;
with Bot_Svn_Info;
with Ini;
with Ada.Text_IO;


procedure Check_High_Lay_Odds is

   package Ev renames Ada.Environment_Variables;

   Lay_Size  : Bet_Size_Type := 30.0;
   Global_Min_Delta,
   Global_Max_Price   : Fixed_Type := 0.0;
   Ba_Immediate_Match : aliased Boolean := False;


   --------------------------------------------------------------------------

   function "<" (Left,Right : Price_Histories.Price_History_Type) return Boolean is
   begin
      return Left.Backprice < Right.Backprice;
   end "<";
   --------------------------------------------
   package Backprice_Sorter is new Price_Histories.Lists.Generic_Sorting("<");

   type Best_Runners_Array_Type is array (1..12) of Price_Histories.Price_History_Type;


   procedure Treat_Lay(List         : in     Price_Histories.Lists.List ;
                       Market       : in     Markets.Market_Type;
                       Wr           : in     Price_Histories.Price_History_Type ;
                       Bra          : in     Best_Runners_Array_Type ;
                       Old_Bra      : in     Best_Runners_Array_Type ;
                       Status       : in out Bet_Status_Type;
                       Bet_List     : in out Bets.Lists.List) is
      pragma Unreferenced(List);
      pragma Unreferenced(Wr);
      pragma Unreferenced(Status);
      -- pragma Unreferenced(BRA);
      -- pragma Unreferenced(Old_bra);
      Bet    : Bets.Bet_Type;
      Runner : Runners.Runner_Type;
      Name   : Betname_Type := (others => ' ');
      Idx    : Integer := 0;
      Local_Max_Price : Fixed_Type := Global_Max_Price + Fixed_Type(25.0);
      Local_Bra : Best_Runners_Array_Type := Bra;
   begin

      -- remove runners from local-BRA that already are betted on
      for B of Bet_List loop
         for I in Local_Bra'Range loop
            if Local_Bra(I).Selectionid = B.Selectionid then
               Local_Bra(I) := Price_Histories.Empty_Data;
            end if;
         end loop;
      end loop;

      -- find the first one to lay. lay only one at a time
      for I in Local_Bra'Range loop
         if Local_Bra(I).Selectionid > 0 and then
           Local_Bra(I).Layprice >= Global_Min_Delta + Old_Bra(I).Layprice and then
           Old_Bra(I).Layprice < Global_Max_Price then
            Idx := I;
            exit;
         end if;
      end loop;

      if Idx > Integer(0) then --Candidate Found To Lay

         if Local_Bra(Idx).Backprice >= Fixed_Type(1.0)and then
           Local_Bra(Idx).Layprice  >= Fixed_Type(1.0) and then
           Local_Bra(Idx).Backprice <= Fixed_Type(100.0) and then
           Local_Bra(Idx).Layprice  <= Local_Max_Price then

            Runner.Selectionid := Local_Bra(Idx).Selectionid;
            Runner.Marketid := Local_Bra(Idx).Marketid;

            if Global_Min_Delta < 10.0 then
               Move("WIN_LAY_" & F8_Image(Global_Max_Price) & "_0" & F8_Image(Global_Min_Delta) & "_" & Ba_Immediate_Match'Img(1), Name);
            else
               Move("WIN_LAY_" & F8_Image(Global_Max_Price) & "_" & F8_Image(Global_Min_Delta) & "_" & Ba_Immediate_Match'Img(1), Name);
            end if;


            Bet := Bets.Create(Name   => Name,
                               Side   => Lay,
                               Size   => Lay_Size,
                               Price  => Price_Type(Local_Max_Price),
                               Placed => Local_Bra(Idx).Pricets,
                               Runner => Runner,
                               Market => Market);
            Bet_List.Append(Bet);
         end if;
      end if;


      -- Try To check outcome

      for B of Bet_List loop
         --find runner
         declare
            R : Price_Histories.Price_History_Type;
         begin

            for I in Local_Bra'Range loop
               if Bra(I).Selectionid = B.Selectionid then
                  R := Bra(I);
                  exit;
               end if;
            end loop;

            if R.Selectionid > 0 then -- found
               if R.Pricets > B.Betplaced + (0,0,0,1,0) then -- 1 second later at least, time for BF delay
                  if R.Layprice <= B.Price and then -- Laybet so yes '<=' NOT '>='
                    R.Layprice >  Fixed_Type(1.0) and then -- sanity
                    R.Backprice >  Fixed_Type(1.0) and then -- sanity
                    B.Status(1)  = 'U' then -- sanity
                     B.Status(1..20) := "MATCHED             "; --Matched
                     B.Pricematched := R.Layprice;
                     B.Check_Outcome;
                     B.Insert;
                     exit;
                  elsif Ba_Immediate_Match then
                     B.Status(1) := 'L'; -- lapsed. will not be matched anymore
                     exit;
                  end if;
               end if;
            end if;
         end;
      end loop;
   end Treat_Lay;
   pragma Unreferenced (Treat_Lay);



   procedure Sort_Array(List : in out Price_Histories.Lists.List ;
                        Bra  : in out Best_Runners_Array_Type;
                        Wr   :    out Price_Histories.Price_History_Type ) is

      Price             : Price_Histories.Price_History_Type;
   begin
      -- ok find the runner with lowest backprice:
      Backprice_Sorter.Sort(List);

      Price.Backprice := 10_000.0;
      Bra := (others => Price);
      Wr.Layprice := 10_000.0;

      declare
         Idx : Integer := 0;
      begin
         for Tmp of List loop
            if Tmp.Status(1..6) = "ACTIVE" and then
              Tmp.Backprice > Fixed_Type(1.0) and then
              Tmp.Layprice < Fixed_Type(1_000.0)  then
               Idx := Idx +1;
               exit when Idx > Bra'Last;
               Bra(Idx) := Tmp;
            end if;
         end loop;
      end ;

      for Br of reverse Bra loop
         if Price.Backprice < 10_000.0 then
            Wr := Br;
            exit;
         end if;
      end loop;


      for I in BRA'Range loop
         exit when Bra(I) = Wr;
         Log("Best_Runners(i)" & I'Img & " " & BRA(I).To_String);
      end loop;
      Log("Worst_Runner " & WR.To_String);

   end Sort_Array;
   pragma Unreferenced (Sort_Array);
   ---------------------------------------------------------------

   Start_Date     : constant Calendar2.Time_Type := (2016,03,16,0,0,0,0);
   One_Day        : constant Calendar2.Interval_Type := (1,0,0,0,0);
   Current_Date   :          Calendar2.Time_Type := Start_Date;
   Stop_Date      : constant Calendar2.Time_Type := (2018,03,01,0,0,0,0);
   T              :          Sql.Transaction_Type;
   Cmd_Line       :          Command_Line_Configuration;
   Sa_Logfilename : aliased  Gnat.Strings.String_Access;
   Max_Winner_Lay  : Fixed_Type := 0.0;
   Max_Winner_Back : Fixed_Type := 0.0;


begin
   Define_Switch
     (Cmd_Line,
      Sa_Logfilename'Access,
      Long_Switch => "--logfile=",
      Help        => "name of log file");

   Getopt (Cmd_Line);  -- process the command line

   if not Ev.Exists("BOT_NAME") then
      Ev.Set("BOT_NAME","lay_during_race3");
   end if;

   Logging.Open(Ev.Value("BOT_HOME") & "/log/" & Sa_Logfilename.all & ".log");
   Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

   Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
   Log("main", "Connect Db " &
         Ini.Get_Value("database_home", "host", "")  & " " &
         Ini.Get_Value("database_home", "port", 5432)'Img & " " &
         Ini.Get_Value("database_home", "name", "") & " " &
         Ini.Get_Value("database_home", "username", "") & " " &
         Ini.Get_Value("database_home", "password", "")
      );



   Sql.Connect
     (Host     => Ini.Get_Value("database_home", "host", ""),
      Port     => Ini.Get_Value("database_home", "port", 5432),
      Db_Name  => Ini.Get_Value("database_home", "name", ""),
      Login    => Ini.Get_Value("database_home", "username", ""),
      Password => Ini.Get_Value("database_home", "password", ""));
   Log("main", "db Connected");

   Log("main", "params start");

   Log("main", "params stop");


   Date_Loop : loop
      T.Start;
      Log("start fill maps");
      Sim.Fill_Data_Maps(Current_Date, Bot_Types.Horse);
      Log("start process maps");

      declare
         Cnt       : Integer := 0;
      begin
         Market_Loop : for Market of Sim.Market_With_Data_List loop
            if Market.Markettype(1..3) = "WIN" and then
               Market.Marketname_Ok then

               Cnt := Cnt + 1;
               --   Log( F8_Image(Fixed_Type(Cnt)*100.0/ Fixed_Type(Sim.Market_Id_With_Data_List.Length)) & " %");
               -- list of timestamps in this market
               declare
                  Timestamp_To_Prices_History_Map : Sim.Timestamp_To_Prices_History_Maps.Map :=
                    Sim.Marketid_Timestamp_To_Prices_History_Map(Market.Marketid);
                  Winner_Sel_Id : Integer_4 := 0;
               begin
                  Loop_Ts : for Timestamp of Sim.Marketid_Pricets_Map(Market.Marketid) loop
                     declare
                        List : Price_Histories.Lists.List := Timestamp_To_Prices_History_Map(Timestamp.To_String);
                     begin
                        --  Log("in loop", Timestamp.To_String & "_" & F8_Image(Back_1_At) & "_" & F8_Image(Back_2_At));
                        if Winner_Sel_Id = Integer_4(0) then
                           for R of List loop
                              if Sim.Is_Race_Winner(Selectionid => R.Selectionid,
                                                    Marketid    => R.Marketid) then
                                 Winner_Sel_Id := R.Selectionid;
                              end if;
                           end loop;
                        end if;
                        if Winner_Sel_Id = Integer_4(0) then
                           Ada.Text_Io.Put_Line("no winner! " & Market.To_String);
                           exit Loop_Ts;
                        end if;


                        for R of List loop
                           if R.Selectionid = Winner_Sel_Id then
                              if R.Backprice > Max_Winner_Back then
                                 Max_Winner_Back := R.Backprice;
                              end if;
                              if R.Layprice > Max_Winner_Lay then
                                 Max_Winner_Lay := R.Layprice;
                              end if;
                           end if;
                        end loop;
                     end;
                  end loop Loop_Ts; --  Timestamp
               end;
            end if; -- Market_type(1..3) = WIN
         end loop Market_Loop;
      end;

      Sim.Delete_Shared_Mem(Current_Date, Bot_Types.Horse);

      Current_Date := Current_Date + One_Day;
      exit when Current_Date = Stop_Date;

      T.Commit;
   end loop Date_Loop;

   Log("main", "max_win_back " & F8_Image(Max_Winner_Back));
   Log("main", "max_win_lay  " & F8_Image(Max_Winner_Lay));

   Sql.Close_Session;    -- no need for db anymore

exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Check_High_Lay_Odds;
