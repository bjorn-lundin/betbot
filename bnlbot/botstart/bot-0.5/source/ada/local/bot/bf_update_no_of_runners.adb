
with sattmate_types ; use sattmate_types;
with Sattmate_Exception;
with Sql;

--with Gnat.Command_Line; use Gnat.Command_Line;
--with GNAT.Strings;

--with Table_Dryrunners;
with Table_Drymarkets;

--with Sattmate_Calendar; use Sattmate_Calendar;
with Logging; use Logging;

--with text_io;

procedure Bf_update_no_of_runners is

--   Dryrunners    : Table_Dryrunners.Data_Type;
   Drymarkets    : Table_Drymarkets.Data_Type;



   T                  : Sql.Transaction_Type;
   Select_All         : Sql.Statement_Type;
   Select_Num_Runners : Sql.Statement_Type;
--   Select_Markets     : Sql.Statement_Type;


   Eos,Eos2       : Boolean := False;

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


      Sql.Prepare (Select_All,
                   "select * from DRYMARKETS where noofrunners is null" );


      Sql.Prepare (Select_Num_Runners,
                   "select count('a') from DRYRUNNERS where marketid = :MARKETID" );


      Sql.Open_Cursor(Select_All);


      loop
         Sql.Fetch(Select_All,Eos);
         exit when Eos;
         Cnt := Cnt +1;

         if Cnt mod 1000 = 0 then
          Log("Cnt =" & Cnt'Img);
         end if;


         Drymarkets:= Table_Drymarkets.Get(Select_All);

         Sql.Set (Select_Num_Runners,"MARKETID", Drymarkets.marketid);
         Sql.Open_Cursor(Select_Num_Runners);
         Sql.Fetch(Select_Num_Runners, Eos2);
         Sql.Get(Select_Num_Runners,1,Drymarkets.Noofrunners);
         if not Eos2 then
           Table_Drymarkets.Update(Drymarkets);
         end if;

         Sql.Close_Cursor(Select_Num_Runners);

      end loop;
      Sql.Close_Cursor(Select_All);
      Sql.Commit (T);

   Sql.Close_Session;

exception

   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);

end Bf_update_no_of_runners;
