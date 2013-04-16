
with sattmate_types ; use sattmate_types;
with Sattmate_Exception;
with Sql;

with Table_History2;
with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;

with Table_Drymarkets;
with Table_Dryresults;
with Table_Dryrunners;

with Sattmate_Calendar; use Sattmate_Calendar;
with Logging; use Logging;

procedure Bf_History_To_Dryrun is
   History2      : Table_History2.Data_Type;
   History2_List : Table_History2.History2_List_Pack.List_Type :=
                  Table_History2.History2_List_Pack.Create;


   Drymarkets    : Table_Drymarkets.Data_Type;
   Dryresults    : Table_Dryresults.Data_Type;
   Dryrunners    : Table_Dryrunners.Data_Type;


   T             : Sql.Transaction_Type;
   Select_All    : Sql.Statement_Type;

   start_date    : Sattmate_Calendar.time_type := Sattmate_Calendar.Time_Type_First;
   stop_date     : Sattmate_Calendar.time_type := Sattmate_Calendar.Time_Type_First;

   Eos           : Boolean := False;

   Sa_Date       : aliased Gnat.Strings.String_Access;
   I_Num_Days    : aliased Integer;
   Config        : Command_Line_Configuration;

   num_runners,
   num_winners   : integer_4 := 0;
   race_ok       : Boolean := False;


begin
   Define_Switch
     (Config,
      Sa_Date'access,
      "-d:",
      Long_Switch => "--date=",
      Help        => "when the data move starts yyyy-mm-dd");

   Define_Switch
     (Config,
      I_Num_Days'access,
      "-n:",
      Long_Switch => "--num_days=",
      Help        => "days to move");


   Getopt (Config);  -- process the command line


   Start_Date := Sattmate_Calendar.To_Time_Type (Sa_Date.all, "00:00:00:000");
   Stop_Date  := Sattmate_Calendar.To_Time_Type (Sa_Date.all, "23:59:59:999");


   Log ("Connect db");
   Sql.Connect
     (Host     => "localhost",
      Port     => 5432,
      Db_Name  => "bfhistory",
      Login    => "bnl",
      Password => "bnl");

   for i in 0 .. I_Num_Days loop
      Sql.Start_Read_Write_Transaction (T);

      start_date := start_date + sattmate_calendar.interval_type'(1,0,0,0,0); --add a day
      stop_date  := stop_date  + sattmate_calendar.interval_type'(1,0,0,0,0); --add a day
      Log ("History2 - treat date " & String_Date(start_date));

      History2 := Table_History2.Empty_Data;

      Sql.Prepare (Select_All,
                   "select * from HISTORY2 " &
                   "where LATESTTAKEN >= :START " &
                   "and LATESTTAKEN <= :STOP " &
                   "order by EVENTID, SELECTIONID, LATESTTAKEN");

      Sql.Set_Timestamp(Select_all, "START", Start_date);
      Sql.Set_Timestamp(Select_all, "STOP",  Stop_date);

      Table_History2.Read_List (Stm => Select_All, List => History2_List, Max => 1_000_000_000);
      Log ("History2_List records  -  " & Table_History2.History2_List_Pack.Get_Count(History2_List)'img);

      while not Table_History2.History2_List_Pack.Is_Empty (List => History2_List) loop
        Table_History2.History2_List_Pack.Remove_From_Head (List => History2_List, Element => History2);
--          Log ("History -  " & History.eventid'img & "-" & Old_History.eventid'img);


        case History2.event(1) is
          when 'A'| 'B'| 'D'| 'E'| 'H'| 'P'| 'R'| 'S' => race_ok := True;
          when others                                 => race_ok := False
        end case

        case History2.event(2) is
          when '1' .. '9' => null; -- just pass
          when others     => race_ok := False
        end case



        if History2.event(1..8) = "Forecast" then
        elsif History2.event(1..12) = "TO BE PLACED" then
        else
        end if;


        Drymarkets := (
                        Marketid        => History2.Eventid,
                        Bspmarket       => 'Y',
                        Markettype      => 'O',
                        Eventhierarchy  => (others => ' '),
                        Lastrefresh     => History2.latesttaken,
                        Turninginplay   => 'N',
                        Menupath        => History2.fulldescription,
                        Betdelay        => 0,
                        Exchangeid      => 1,
                        Countrycode     => 'GBR',
                        Marketname      => History2.event,
                        Marketstatus    => "ACTIVE         ",
                        Eventdate       => History2.latesttaken,
                        Noofrunners     =>
                        Totalmatched    => History2.Volumematched.
                        Noofwinners     =>



                        Sportsid        => History2.Sportsid,
                        Settleddate     => History2.Settleddate,
                        Country         => History2.Country,
                        Fulldescription => History2.Fulldescription,
                        Course          => History2.Course,
                        Scheduledoff    => History2.Scheduledoff,
                        Event           => History2.Event,
                        Selectionid     => History2.Selectionid,
                        Selection       => History2.Selection,
                        Odds            => History2.Odds,
                        Numberbets      => History2.Numberbets,
                        Volumematched   => History2.Volumematched,
                        Latesttaken     => History2.Latesttaken,
                        Firsttaken      => History2.Firsttaken,
                        Winflag         => History2.Winflag,
                        Inplay          => History2.Inplay

        );




      Marketid :    Integer_4  := 0 ; -- Primary Key
      Bspmarket :    Character  := ' ' ; --
      Markettype :    Character  := ' ' ; --
      Eventhierarchy :    String (1..150) := (others => ' ') ; -- non unique index 2
      Lastrefresh :    Time_Type  := Time_Type_First ; --
      Turninginplay :    Character  := ' ' ; --
      Menupath :    String (1..200) := (others => ' ') ; --
      Betdelay :    Integer_4  := 0 ; --
      Exchangeid :    Integer_4  := 0 ; --
      Countrycode :    String (1..3) := (others => ' ') ; --
      Marketname :    String (1..50) := (others => ' ') ; -- non unique index 3
      Marketstatus :    String (1..15) := (others => ' ') ; --
      Eventdate :    Time_Type  := Time_Type_First ; -- non unique index 4
      Noofrunners :    Integer_4  := 0 ; --
      Totalmatched :    Integer_4  := 0 ; --
      Noofwinners :    Integer_4  := 0 ; --







        if History.selectionid = Old_History.selectionid then -- same runner
            null; -- get next
        else -- another runner, insert the old row
            if Old_History.pk > 0 then
              begin
                History2 := (
                            Pk              => Old_History.pk,
                            Sportsid        => Old_History.Sportsid,
                            Eventid         => Old_History.Eventid,
                            Settleddate     => Old_History.Settleddate,
                            Country         => Old_History.Country,
                            Fulldescription => Old_History.Fulldescription,
                            Course          => Old_History.Course,
                            Scheduledoff    => Old_History.Scheduledoff,
                            Event           => Old_History.Event,
                            Selectionid     => Old_History.Selectionid,
                            Selection       => Old_History.Selection,
                            Odds            => Old_History.Odds,
                            Numberbets      => Old_History.Numberbets,
                            Volumematched   => Old_History.Volumematched,
                            Latesttaken     => Old_History.Latesttaken,
                            Firsttaken      => Old_History.Firsttaken,
                            Winflag         => Old_History.Winflag,
                            Inplay          => Old_History.Inplay
                );

                Table_History2.Read (Data => History2, End_Of_Set => Eos);
                if Eos then
--                  Log ("History2 - insert " & history2.pk'img);
                  Table_History2.Insert (Data => History2);
                end if;
              exception
                when Sql.Duplicate_Index =>
                  Log ("History2 - Duplicate_Index on " & history2.pk'img);
              end;
          end if;
        end if;
        Old_History := History;

      end loop;
      Sql.Commit (T);
   end loop;

   Sql.Close_Session;

exception
   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);
      Log ("History -  " & History.eventid'img & "-" & Old_History.eventid'img);

end Bf_History_To_Dryrun ;
