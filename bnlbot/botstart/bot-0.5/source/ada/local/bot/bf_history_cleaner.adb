
with sattmate_types ; use sattmate_types;
with Sattmate_Exception;
with Sql;

with Table_History;
with Table_History2;
with Gnat.Command_Line; use Gnat.Command_Line;
with GNAT.Strings;


--with Table_Drymarkets;
--with Table_Dryresults;
--with Table_Dryrunners;
with Sattmate_Calendar; use Sattmate_Calendar;
with Logging; use Logging;

procedure Bf_History_Cleaner is
   History,Old_History : Table_History.Data_Type;
   History_List : Table_History.History_List_Pack.List_Type :=
                  Table_History.History_List_Pack.Create;

   History2     : Table_History2.Data_Type;

   T                       : Sql.Transaction_Type;
   Select_All   : Sql.Statement_Type;

   start_date   : Sattmate_Calendar.time_type := Sattmate_Calendar.Time_Type_First;
   stop_date    : Sattmate_Calendar.time_type := Sattmate_Calendar.Time_Type_First;

   Eos          : Boolean := False;

   Sa_Date      : aliased Gnat.Strings.String_Access;
   I_Num_Days   : aliased Integer;
   Config       : Command_Line_Configuration;


begin
   Define_Switch
     (Config      => Config,
      Output      => Sa_Date'access,
      Switch      => "-d:",
      Long_Switch => "--date=",
      Help        => "when the data move starts yyyy-mm-dd");

   Define_Switch
     (Config      => Config,
      Output      => I_Num_Days'access,
      Initial     =>  0,
      Switch      => "-n:",
      Long_Switch => "--num_days=",
      Help        => "days to move");

   Getopt (Config);  -- process the command line

   if Sa_Date.all = "" or else I_Num_Days = 0 then
     Display_Help (Config);
     return ;
   end if;

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

      History := Table_History.Empty_Data;
      History2 := Table_History2.Empty_Data;

      Sql.Prepare (Select_All,
                   "select * from HISTORY " &
                   "where LATESTTAKEN >= :START " &
                   "and LATESTTAKEN <= :STOP " &
                   "and EVENT <> 'Forecast' " &
                   "and FULLDESCRIPTION <> 'Ante Post' " &
                   "order by EVENTID, SELECTIONID, LATESTTAKEN");

      Sql.Set_Timestamp(Select_all, "START", Start_date);
      Sql.Set_Timestamp(Select_all, "STOP",  Stop_date);

      Table_History.Read_List (Stm => Select_All, List => History_List, Max => 1_000_000_000);
      Log ("History_List records  -  " & Table_History.History_List_Pack.Get_Count(History_List)'img);

      while not Table_History.History_List_Pack.Is_Empty (List => History_List) loop
        Table_History.History_List_Pack.Remove_From_Head (List => History_List, Element => History);
--          Log ("History -  " & History.eventid'img & "-" & Old_History.eventid'img);
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

end Bf_History_Cleaner;
