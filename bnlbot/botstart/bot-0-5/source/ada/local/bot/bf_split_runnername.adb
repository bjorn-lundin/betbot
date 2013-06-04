
with sattmate_types ; use sattmate_types;
with Sattmate_Exception;
with Sql;

--with Gnat.Command_Line; use Gnat.Command_Line;
--with GNAT.Strings;

with Table_Dryrunners;

--with Sattmate_Calendar; use Sattmate_Calendar;
with Logging; use Logging;

--with text_io;
with General_Routines;
procedure Bf_split_runnername is

   Dryrunners    : Table_Dryrunners.Data_Type;



   T                  : Sql.Transaction_Type;
   Select_All         : Sql.Statement_Type;
   Select_Num_Runners : Sql.Statement_Type;
--   Select_Markets     : Sql.Statement_Type;


   Eos           : Boolean := False;

--   Sa_Date       : aliased Gnat.Strings.String_Access;
--   I_Num_Days    : aliased Integer;
--   Config        : Command_Line_Configuration;

--   num_runners        : integer_4 := 0;
--   race_ok            : Boolean := False;
   Runnernamestripped : String := Dryrunners.Runnernamestripped;
   Startnum           : String := Dryrunners.Startnum;
   cnt                : Integer_4 := 0;

   Start_Paranthesis,
   Stop_Paranthesis : integer := 0;

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
                   "select * from DRYRUNNERS " );

      Sql.Prepare (Select_Num_Runners,
                   "select count('a') from DRYRUNNERS " );


      Sql.Open_Cursor(Select_Num_Runners);
      Sql.Fetch(Select_Num_Runners,Eos);
      if not eos then
        Sql.Get(Select_Num_Runners,1,Cnt);
      end if;
      Sql.Close_Cursor(Select_Num_Runners);


      Sql.Open_Cursor(Select_All);


      loop
         Sql.Fetch(Select_All,Eos);
         exit when Eos;
         Cnt := Cnt -1;

         if Cnt mod 1000 = 0 then
          Log("Cnt = " & Cnt'Img);
         end if;

         Runnernamestripped := (others => ' ');
         Startnum := (others => ' ');

         Dryrunners := Table_Dryrunners.Get(Select_All);

         case Dryrunners.Runnername(1) is
             when '1'..'9' =>
                if Dryrunners.Runnername(2) = '.' and then
                   Dryrunners.Runnername(3) = ' ' then
                  Runnernamestripped := Dryrunners.Runnername(4 .. Dryrunners.Runnername'Last) & "   ";
                  Startnum := Dryrunners.Runnername(1..1) & ' ';
                elsif
                   Dryrunners.Runnername(3) = '.' and then
                   Dryrunners.Runnername(4) = ' ' then
                  Runnernamestripped := Dryrunners.Runnername(5 .. Dryrunners.Runnername'Last) & "    ";
                  Startnum := Dryrunners.Runnername(1..2);
                else
                  null;
                end if;

             when others => null;
         end case;

         Start_Paranthesis := -1;
         Stop_Paranthesis  := -1;

         for i in Runnernamestripped'range loop
           case Runnernamestripped(i) is
             when '('    => Start_Paranthesis := i;
             when ')'    => Stop_Paranthesis  := i;
             when others => null;
           end case;
         end loop;

         if  Start_Paranthesis > -1 and then
             Stop_Paranthesis > -1 and then
             General_Routines.Lower_Case(Runnernamestripped(Start_Paranthesis .. Stop_Paranthesis)) = "(res)" then
--           Log(Runnernamestripped);
           Runnernamestripped(Start_Paranthesis .. Stop_Paranthesis) := (others => ' ');
--           Log(Runnernamestripped);
         end if;
         Dryrunners.Runnernamestripped := Runnernamestripped;
         Dryrunners.Startnum           := Startnum;

--         begin
           Table_Dryrunners.Update(Dryrunners);
--         exception
--            when sql.Duplicate_index =>
--               Text_io.Put_line(Dryrunners.marketid'img & Dryrunners.selectionid'img);
--             raise;
---         end;

      end loop;
      Sql.Close_Cursor(Select_All);
      Sql.Commit (T);

   Sql.Close_Session;

exception

   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);

end Bf_split_runnername ;
