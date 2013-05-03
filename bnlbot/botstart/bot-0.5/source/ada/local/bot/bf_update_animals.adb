
with sattmate_types ; use sattmate_types;
with Sattmate_Exception;
with Sql;

--with Gnat.Command_Line; use Gnat.Command_Line;
--with GNAT.Strings;

--with Table_Dryrunners;
--with Table_Drymarkets;
--with Table_Dryresults;
with Table_Animals;

with Sattmate_Calendar; use Sattmate_Calendar;
with Logging; use Logging;

--with text_io;

procedure Bf_update_animals is

--   Dryrunners    : Table_Dryrunners.Data_Type;
--   Drymarkets    : Table_Drymarkets.Data_Type;
   Empty_Animal, Animal     : Table_Animals.Data_Type;



   Select_All_Animals,
   Select_Num_Races,
   Select_Num_Wins,
   Select_Price_Stats,
   Select_Last_Win       : Sql.Statement_Type;


   T : Sql.Transaction_Type;

   type eos_type is (animals, Num_Races, Num_Wins, Price_Stats, Last_Win);
   Eos : array (eos_type'range) of Boolean := (others => False);

--   Sa_Date       : aliased Gnat.Strings.String_Access;
--   I_Num_Days    : aliased Integer;
--   Config        : Command_Line_Configuration;

--   num_runners        : integer_4 := 0;
--   race_ok            : Boolean := False;
--   Runnernamestripped : String := Dryrunners.Runnernamestripped;
--   Startnum           : String := Dryrunners.Startnum;
   cnt                : Integer_4 := 0;
begin
--   Define_Switch
--     (Config      => Config,
--      Output      => Sa_Date'access,
--      Switch      => "-d:",
--      Long_Switch => "--date=",
--      Help        => "when the data move starts yyyy-mm-dd");
--
--   Define_Switch
--     (Config      => Config,
--      Output      => I_Num_Days'access,
--      Initial     =>  0,
--      Switch      => "-n:",
--      Long_Switch => "--num_days=",
--      Help        => "days to move");
--
--   Getopt (Config);  -- process the command line
--
--   if Sa_Date.all = "" or else I_Num_Days = 0 then
--     Display_Help (Config);
--     return ;
--   end if;


   Log ("Connect db");
   Sql.Connect
     (Host     => "localhost",
      Port     => 5432,
      Db_Name  => "bfhistory",
      Login    => "bnl",
      Password => "bnl");

--   for i in 0 .. I_Num_Days loop
      Sql.Start_Read_Write_Transaction (T);


      Sql.Prepare (Select_All_Animals,
                   "select RUNNERNAMESTRIPPED, COUNT('a') " &
                   "from DRYRUNNERS " &
                   "group by RUNNERNAMESTRIPPED " &
                   "order by RUNNERNAMESTRIPPED" );

      Sql.Prepare (Select_Num_Races,
                   "select count('a') " &
                   "from DRYRUNNERS, DRYMARKETS " &
                   "where DRYRUNNERS.MARKETID = DRYMARKETS.MARKETID " &
                   "and DRYMARKETS.NOOFWINNERS = 1 " &
                   "and DRYRUNNERS.RUNNERNAMESTRIPPED = :RUNNERNAMESTRIPPED" );

      Sql.Prepare (Select_Num_Wins,
                   "select count('a') " &
                   "from DRYRUNNERS, DRYMARKETS, DRYRESULTS " &
                   "where DRYRUNNERS.MARKETID = DRYMARKETS.MARKETID " &
                   "and DRYRESULTS.MARKETID = DRYMARKETS.MARKETID " &
                   "and DRYRESULTS.SELECTIONID = DRYRUNNERS.SELECTIONID " &
                   "and DRYMARKETS.NOOFWINNERS = 1 " &
                   "and DRYRUNNERS.RUNNERNAMESTRIPPED = :RUNNERNAMESTRIPPED" );

      Sql.Prepare (Select_Price_Stats,
                   "select min(BACKPRICE), avg(BACKPRICE), max(BACKPRICE) " &
                   "from DRYRUNNERS, DRYMARKETS " &
                   "where DRYRUNNERS.MARKETID = DRYMARKETS.MARKETID " &
                   "and DRYMARKETS.NOOFWINNERS = 1 " &
                   "and DRYRUNNERS.RUNNERNAMESTRIPPED = :RUNNERNAMESTRIPPED" );


      Sql.Prepare (Select_Last_Win,
                   "select EVENTDATE " &
                   "from DRYRUNNERS, DRYMARKETS " &
                   "where DRYRUNNERS.MARKETID = DRYMARKETS.MARKETID " &
                   "and DRYMARKETS.NOOFWINNERS = 1 " &
                   "and DRYRUNNERS.RUNNERNAMESTRIPPED = :RUNNERNAMESTRIPPED " &
                   "order by EVENTDATE desc limit 1");


      Sql.Open_Cursor(Select_All_Animals);


      loop
         Sql.Fetch(Select_All_Animals, Eos(Animals));
         exit when Eos(Animals);
         Cnt := Cnt +1;

         if Cnt mod 1000 = 0 then
          Log("Cnt =" & Cnt'Img);
         end if;

         Animal.Name := (others => ' ');
         Sql.Get(Select_All_Animals,"RUNNERNAMESTRIPPED",Animal.Name);
          Log(Animal.Name);

         Table_Animals.Read(Animal, Eos(Animals));

         Sql.Set (Select_Num_Races,"RUNNERNAMESTRIPPED", Animal.Name);
         Sql.Open_Cursor(Select_Num_Races);
         Sql.Fetch(Select_Num_Races, Eos(Num_Races));
         if not Eos(Num_Races) then
            Sql.Get(Select_Num_Races,1,Animal.numraces);
         else
           Animal.numraces := 0;
         end if;
         Sql.Close_Cursor(Select_Num_Races);


         Sql.Set (Select_Num_Wins,"RUNNERNAMESTRIPPED", Animal.Name);
         Sql.Open_Cursor(Select_Num_Wins);
         Sql.Fetch(Select_Num_Wins, Eos(Num_Wins));
         if not Eos(Num_Wins) then
            Sql.Get(Select_Num_Wins,1,Animal.numvictories);
         else
           Animal.numvictories := 0;
         end if;
         Sql.Close_Cursor(Select_Num_Wins);


         Sql.Set (Select_Price_Stats,"RUNNERNAMESTRIPPED", Animal.Name);
         Sql.Open_Cursor(Select_Price_Stats);
         Sql.Fetch(Select_Price_Stats, Eos(Price_Stats));
         if not Eos(Price_Stats) then
            Sql.Get(Select_Price_Stats,1,Animal.minprice);
            Sql.Get(Select_Price_Stats,2,Animal.avgprice);
            Sql.Get(Select_Price_Stats,3,Animal.maxprice);
         else
           Animal.minprice := 0.0;
           Animal.avgprice := 0.0;
           Animal.maxprice := 0.0;
         end if;
         Sql.Close_Cursor(Select_Price_Stats);


         Sql.Set (Select_Last_Win,"RUNNERNAMESTRIPPED", Animal.Name);
         Sql.Open_Cursor(Select_Last_Win);
         Sql.Fetch(Select_Last_Win, Eos(Last_Win));
         if not Eos(Last_Win) then
            Sql.Get_Timestamp(Select_Last_Win,"EVENTDATE", Animal.lastvictory);
         else
            Animal.lastvictory := sattmate_calendar.time_type_first;
         end if;
         Sql.Close_Cursor(Select_Last_Win);



         if Eos(Animals) then
           Animal.Kind     := "hound";
           Animal.Racetype := "winner";
           if Animal.Name /= Empty_Animal.Name then
             Table_Animals.Insert(Animal);
           end if;
         else
           Table_Animals.Update_Withcheck(Animal);
--           Table_Animals.Update(Animal);
         end if;

      end loop;
      Sql.Close_Cursor(Select_All_Animals);
      Sql.Commit (T);

   Sql.Close_Session;

exception

   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);

end Bf_update_animals;
