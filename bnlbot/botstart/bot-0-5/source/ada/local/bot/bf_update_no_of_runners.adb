
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

   Drymarkets    : Table_Drymarkets.Data_Type;
   T                  : Sql.Transaction_Type;
   Select_All         : Sql.Statement_Type;
   Select_Num_Runners : Sql.Statement_Type;
   Select_Num_Runners2 : Sql.Statement_Type;
   Eos,Eos2       : Boolean := False;
   cnt                : Integer_4 := 0;
begin


   Log ("Connect db");
   Sql.Connect
     (Host     => "localhost",
      Port     => 5432,
      Db_Name  => "bfhistory",
      Login    => "bnl",
      Password => "bnl");

      Sql.Start_Read_Write_Transaction (T);


      Sql.Prepare (Select_All,
                   "select * from DRYMARKETS where noofrunners is null" );


      Sql.Prepare (Select_Num_Runners,
                   "select count('a') from DRYRUNNERS where marketid = :MARKETID" );


      Sql.Prepare (Select_Num_Runners2,
                   "select count('a') from DRYMARKETS where noofrunners is null" );


      Sql.Open_Cursor(Select_Num_Runners2);
      Sql.Fetch(Select_Num_Runners2,Eos);
      if not eos then
        Sql.Get(Select_Num_Runners2,1,Cnt);
      end if;
      Sql.Close_Cursor(Select_Num_Runners2);


      Sql.Open_Cursor(Select_All);
      loop
         Sql.Fetch(Select_All,Eos);
         exit when Eos;
         Cnt := Cnt - 1;

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
