

with Sattmate_Exception;
with Sql;

with Table_Drymarketsf;
with Table_Drymarkets;

with Table_Dryrunnersf;
with Table_Dryrunners;

with Logging; use Logging;

procedure Dry_String_Fixer is
   Drymarketsf      : Table_Drymarketsf.Data_Type;
   Drymarkets       : Table_Drymarkets.Data_Type;

   Dryrunnersf      : Table_Dryrunnersf.Data_Type;
   Dryrunners       : Table_Dryrunners.Data_Type;

   type table_type is (aDrymarketsf, aDrymarkets, aDryrunnersf, aDryrunners);

   T                       : Sql.Transaction_Type;
   Select_All : array (table_type'range) of Sql.Statement_Type;
   cnt : Natural := 0;
   Eos : Boolean := False;
begin
   Log ("Connect db");
   Sql.Connect
     (Host     => "192.168.0.13",
      Port     => 5432,
      Db_Name  => "betting",
      Login    => "bnl",
      Password => "bnl");
   Sql.Start_Read_Write_Transaction (T);

   -- move the footballs away

   Sql.Prepare (Select_All(aDrymarketsf), "select * from DRYMARKETSF");

   Log ("DryMarketsF");
   Sql.Open_Cursor(Select_All(aDrymarketsf));
   loop
     Sql.Fetch(Select_All(aDrymarketsf), Eos);
     exit when EOS;
     Drymarketsf := Table_Drymarketsf.Get(Select_All(aDrymarketsf));
     Table_Drymarketsf.Update(Drymarketsf);
   end loop;
   Sql.Close_Cursor(Select_All(aDrymarketsf));
   Sql.Commit (T);

   Sql.Start_Read_Write_Transaction (T);
   Sql.Prepare (Select_All(aDrymarkets),  "select * from DRYMARKETS");
   Log ("DryMarkets");
   Sql.Open_Cursor(Select_All(aDrymarkets));
   loop
     Sql.Fetch(Select_All(aDrymarkets), Eos);
     exit when EOS;
     Drymarkets := Table_Drymarkets.Get(Select_All(aDrymarkets));
     Table_Drymarkets.Update(Drymarkets);
   end loop;
   Sql.Close_Cursor(Select_All(aDrymarkets));
   Sql.Commit (T);

   Sql.Start_Read_Write_Transaction (T);
   Sql.Prepare (Select_All(aDryrunnersf), "select * from DRYRUNNERSF");
   Log ("Dryrunnersf");
   Sql.Open_Cursor(Select_All(aDryrunnersf));
   loop
     Sql.Fetch(Select_All(aDryrunnersf), Eos);
     exit when EOS;
     Dryrunnersf := Table_Dryrunnersf.Get(Select_All(aDryrunnersf));
     Table_Dryrunnersf.Update(Dryrunnersf);
   end loop;
   Sql.Close_Cursor(Select_All(aDryrunnersf));
   Sql.Commit (T);

   Sql.Start_Read_Write_Transaction (T);
   Sql.Prepare (Select_All(aDryrunners),  "select * from DRYRUNNERS");
   Log ("Dryrunners");
   Sql.Open_Cursor(Select_All(aDryrunners));
   loop
     Sql.Fetch(Select_All(aDryrunners), Eos);
     exit when EOS;
     Dryrunners := Table_Dryrunners.Get(Select_All(aDryrunners));
     Table_Dryrunners.Update(Dryrunners);
   end loop;
   Sql.Close_Cursor(Select_All(aDryrunners));

   Sql.Commit (T);
   Sql.Close_Session;


exception
   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);
end Dry_String_Fixer;
