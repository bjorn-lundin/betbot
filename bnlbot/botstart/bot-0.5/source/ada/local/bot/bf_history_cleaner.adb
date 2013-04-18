
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
   select_latest : Sql.Statement_Type;
   start_date   : Sattmate_Calendar.time_type := Sattmate_Calendar.Time_Type_First;
   stop_date    : Sattmate_Calendar.time_type := Sattmate_Calendar.Time_Type_First;

   Eos,Eos2          : Boolean := False;

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
          "select EVENTID, SELECTIONID from HISTORY " &
          "where LATESTTAKEN >= :START " &
          "and LATESTTAKEN <= :STOP " &
          "and EVENT <> 'Forecast' " &
          "and FULLDESCRIPTION <> 'Ante Post' " &
          "group by  EVENTID, SELECTIONID " &
          "order by EVENTID, SELECTIONID ");

      Sql.Set_Timestamp(Select_all, "START", Start_date);
      Sql.Set_Timestamp(Select_all, "STOP",  Stop_date);


      Sql.Open_Cursor(Select_all);
      loop
          Sql.Fetch(Select_all, Eos);
          exit when Eos;
          Sql.Get(Select_All,"EVENTID",History.EVENTID);
          Sql.Get(Select_All,"SELECTIONID",History.SELECTIONID);
          TAble_History.Read_One_Eventid_selectionid(Data  => History,
                                                     Order => False,
                                                     End_Of_Set => Eos2);
          if Eos2 then
                Log ("History - FAIL " & History.EVENTID'img & History.SELECTIONID'img);
                return;
          end if;

          begin
            History2 := (
                        Pk              => History.pk,
                        Sportsid        => History.Sportsid,
                        Eventid         => History.Eventid,
                        Settleddate     => History.Settleddate,
                        Country         => History.Country,
                        Fulldescription => History.Fulldescription,
                        Course          => History.Course,
                        Scheduledoff    => History.Scheduledoff,
                        Event           => History.Event,
                        Selectionid     => History.Selectionid,
                        Selection       => History.Selection,
                        Odds            => History.Odds,
                        Numberbets      => History.Numberbets,
                        Volumematched   => History.Volumematched,
                        Latesttaken     => History.Latesttaken,
                        Firsttaken      => History.Firsttaken,
                        Winflag         => History.Winflag,
                        Inplay          => History.Inplay
            );

            Table_History2.Read (Data => History2, End_Of_Set => Eos);
            if Eos then
--                Log ("History2 - insert " & history2.pk'img);
              Table_History2.Insert (Data => History2);
            end if;
          exception
            when Sql.Duplicate_Index =>
              Log ("History2 - Duplicate_Index on " & history2.pk'img);
          end;


      end loop;
      Sql.Close_Cursor(Select_all);
      Sql.Commit (T);
   end loop;

   Sql.Close_Session;

exception
   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);
      Log ("History -  " & History.eventid'img & "-" & Old_History.eventid'img);

end Bf_History_Cleaner;
