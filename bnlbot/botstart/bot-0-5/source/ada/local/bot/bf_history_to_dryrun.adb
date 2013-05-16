
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

with text_io;

procedure Bf_History_To_Dryrun is
   History2      : Table_History2.Data_Type;
   History2_List : Table_History2.History2_List_Pack.List_Type :=
                  Table_History2.History2_List_Pack.Create;


   Drymarkets    : Table_Drymarkets.Data_Type;
   Dryresults    : Table_Dryresults.Data_Type;
   Dryrunners    : Table_Dryrunners.Data_Type;


   Drymarkets_List    : Table_Drymarkets.Drymarkets_List_Pack.List_Type :=
                        Table_Drymarkets.Drymarkets_List_Pack.Create;


   T                  : Sql.Transaction_Type;
   Select_All         : Sql.Statement_Type;
   Select_Num_Runners : Sql.Statement_Type;
   Select_Markets     : Sql.Statement_Type;

   start_date    : Sattmate_Calendar.time_type := Sattmate_Calendar.Time_Type_First;
   stop_date     : Sattmate_Calendar.time_type := Sattmate_Calendar.Time_Type_First;

   Eos           : Boolean := False;

   Sa_Date       : aliased Gnat.Strings.String_Access;
   I_Num_Days    : aliased Integer;
   Config        : Command_Line_Configuration;

   num_runners        : integer_4 := 0;
   race_ok            : Boolean := False;
   Runnernamestripped : String := Dryrunners.Runnernamestripped;
   Startnum           : String := Dryrunners.Startnum;


   Eventhierarchy : string (Drymarkets.Eventhierarchy'range);


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

      History2 := Table_History2.Empty_Data;

      Sql.Prepare (Select_All,
                   "select * from HISTORY2 " &
                   "where LATESTTAKEN >= :START " &
                   "and LATESTTAKEN <= :STOP " &
                   "and SPORTSID = 7 " &
                   "and FULLDESCRIPTION <> 'Ante Post' " &
                   "and COUNTRY <> 'ANTEPOST' " &
                   "order by EVENTID, SELECTIONID, LATESTTAKEN");

      Sql.Set_Timestamp(Select_all, "START", Start_date);
      Sql.Set_Timestamp(Select_all, "STOP",  Stop_date);

      Table_History2.Read_List (Stm => Select_All, List => History2_List, Max => 1_000_000_000);
      Log ("History2_List records  -  " & Table_History2.History2_List_Pack.Get_Count(History2_List)'img);



--     Sportsid        => History2.Sportsid,
--     Settleddate     => History2.Settleddate,
--     Country         => History2.Country,
--     Fulldescription => History2.Fulldescription,
--     Course          => History2.Course,
--     Scheduledoff    => History2.Scheduledoff,
--     Event           => History2.Event,
--     Selectionid     => History2.Selectionid,
--     Selection       => History2.Selection,
--     Odds            => History2.Odds,
--     Numberbets      => History2.Numberbets,
--     Volumematched   => History2.Volumematched,
--     Latesttaken     => History2.Latesttaken,
--     Firsttaken      => History2.Firsttaken,
--     Winflag         => History2.Winflag,
--     Inplay          => History2.Inplay




      while not Table_History2.History2_List_Pack.Is_Empty (List => History2_List) loop
        Table_History2.History2_List_Pack.Remove_From_Head (List => History2_List, Element => History2);
--          Log ("History -  " & History.eventid'img & "-" & Old_History.eventid'img);


        case History2.event(1) is
          when 'A'| 'B'| 'D'| 'E'| 'H'| 'P'| 'R'| 'S' => race_ok := True;
          when others                                 => race_ok := False;
        end case;

        case History2.event(2) is
          when '1' .. '9' => null; -- just pass
          when others     => race_ok := False;
        end case;



        if History2.event(1..8) = "Forecast" then
          race_ok := False;
        elsif History2.event(1..12) = "TO BE PLACED" then
          race_ok := False;
        end if;

        if race_ok then
            Eventhierarchy := (others => ' ');
            if History2.Sportsid = 1 then
               Eventhierarchy(1..4) := "/1/0";
            elsif History2.Sportsid = 7 then
               Eventhierarchy(1..4) := "/7/0";
            elsif History2.Sportsid = 4339 then
               Eventhierarchy(1..7) := "/4339/0";
            end if;

            Drymarkets := (
                            Marketid        => History2.Eventid,
                            Bspmarket       => 'Y',
                            Markettype      => 'O',
                            Eventhierarchy  => Eventhierarchy, --?
                            Lastrefresh     => History2.latesttaken,
                            Turninginplay   => 'N',
                            Menupath        => History2.Fulldescription,
                            Betdelay        => 0,
                            Exchangeid      => 1,
                            Countrycode     => History2.country,
                            Marketname      => History2.event,
                            Marketstatus    => "ACTIVE         ",
                            Eventdate       => History2.latesttaken,
                            Noofrunners     => 0 , --update later!?
                            Totalmatched    => Integer_4(History2.Volumematched),
                            Noofwinners     => 1 -- only winners games so far
            );

            Table_Drymarkets.Read(Drymarkets,Eos);
            if Eos then
              Table_Drymarkets.Insert(Drymarkets);
            end if;


            Runnernamestripped := (others => ' ');
            Startnum := (others => ' ');


            case History2.Selection(1) is
                when '1'..'9' =>
                   if History2.Selection(2) = '.' and then
                      History2.Selection(3) = ' ' then
                     Runnernamestripped := History2.Selection(4 .. History2.Selection'Last) & "   ";
                     Startnum := History2.Selection(1..1) & ' ';
                   elsif
                      History2.Selection(3) = '.' and then
                      History2.Selection(4) = ' ' then
                     Runnernamestripped := History2.Selection(5 .. History2.Selection'Last) & "    ";
                     Startnum := History2.Selection(1..2);
                   else
                     null;
                   end if;

                when others => null;
            end case;


            Dryrunners := (
                             Marketid           => History2.Eventid,
                             Selectionid        => History2.Selectionid,
                             Index              => 0,
                             Backprice          => History2.Odds,
                             Layprice           => History2.Odds,
                             Runnername         => History2.Selection,
                             Runnernamestripped => Runnernamestripped,
                             Startnum           => Startnum
            );
            begin
              Table_Dryrunners.Insert(Dryrunners);
            exception
               when sql.Duplicate_index =>
                  Text_io.Put_line(Dryrunners.marketid'img & Dryrunners.selectionid'img);
                raise;
            end;
            if History2.Winflag = 1 then
                Dryresults := (
                                 Marketid    => History2.Eventid,
                                 Selectionid => History2.Selectionid
                );
                Table_Dryresults.Insert(Dryresults);
            end if;



        end if; --race_ok

      end loop;
--      Sql.Commit (T);
--      Sql.Start_Read_Write_Transaction (T);

      Sql.Prepare (Select_Markets,
                   "select * from DRYMARKETS " &
                   "where EVENTDATE >= :START " &
                   "and EVENTDATE <= :STOP " &
                   "and NOOFRUNNERS = 0");
      Sql.Set_Timestamp(Select_Markets, "START", Start_date);
      Sql.Set_Timestamp(Select_Markets, "STOP",  Stop_date);

      Table_Drymarkets.Read_List(Select_Markets, Drymarkets_List);

      Sql.Prepare (Select_Num_Runners,
                   "select count('a') from DRYRUNNERS " &
                   "where EVENTDATE >= :START " &
                   "and EVENTDATE <= :STOP " &
                   "and MARKETID = :MARKETID");

      Sql.Set_Timestamp(Select_Num_Runners, "START", Start_date);
      Sql.Set_Timestamp(Select_Num_Runners, "STOP",  Stop_date);

      while not Table_Drymarkets.Drymarkets_List_Pack.Is_Empty(Drymarkets_List) loop
        Table_Drymarkets.Drymarkets_List_Pack.Remove_From_Head(Drymarkets_List, Drymarkets);
        Sql.Set(Select_Num_Runners, "MARKETID",  Drymarkets.Marketid);
        Sql.Open_Cursor(Select_Num_Runners);
        Sql.Fetch(Select_Num_Runners, Eos);
        if not Eos then
          Sql.Get(Select_Num_Runners, 1, Num_Runners);
        else
          Num_Runners := 0;
        end if;
        Sql.Close_Cursor(Select_Num_Runners);
        Drymarkets.Noofrunners := Num_Runners ;
        Table_Drymarkets.Update(Drymarkets);
      end loop;
      Sql.Commit (T);
   end loop;

   Sql.Close_Session;

exception

   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);

end Bf_History_To_Dryrun ;
