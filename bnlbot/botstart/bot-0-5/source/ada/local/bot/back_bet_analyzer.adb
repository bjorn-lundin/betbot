--with Unchecked_Conversion;
with Sattmate_Exception;
with Sattmate_Types; use Sattmate_Types;
with Sql;
with Logging; use Logging;
with Races;
with Text_Io;
with Simple_List_Class;



procedure Back_Bet_Analyzer is
   T                   : Sql.Transaction_Type;
   Select_Back_Winners : array (Races.Bet_Name_Type'Range) of Sql.Statement_Type;
   Animal              : Races.Animal_Type := Races.Horse;
   Bet_Name            : Races.Bet_Name_Type := Races.Winner;

   Interval_Offset     : Float_8 := 0.2;
   Interval_Begin      : Float_8 := 1.0;
   Interval_Last       : Float_8 := 10.0;
   Interval_Current    : Float_8 := 0.0;

   type Result_Type is record
      Count : Integer_4 := 0;
      Start : Float_8 := 0.0;
      Stop  : Float_8 := 0.0;
   end record;

   package Result_Pack is new Simple_List_Class (Result_Type);
   Result_List : Result_Pack.List_Type := Result_Pack.Create;
   Result_Data   :  Result_Type ;
   Eos, Eol : Boolean := False;
   Total : Integer_4 := 0;
   Cur_Price, Price : Float_8 := 0.0;
begin
   Interval_Current := Interval_Begin;
   loop
      Result_Data := (Count => 0, Start => Interval_Current, Stop => Interval_Current + Interval_Offset);
      Result_Pack.Insert_At_Tail (Result_List, Result_Data);
      Interval_Current := Interval_Current + Interval_Offset;
      exit when Interval_Current > Interval_Last ;
   end loop;
   --   Log ("Connect db");
   Sql.Connect
   --     (Host     => "192.168.0.13",
     (Host     => "localhost",
      Port     => 5432,
      Db_Name  => "betting",
      Login    => "bnl",
      Password => "bnl");
   Sql.Start_Read_Write_Transaction (T);
   Sql.Prepare
     (Select_Back_Winners (Bet_Name),
      "select DRYRUNNERS.BACKPRICE from " &
      "DRYMARKETS , DRYRESULTS, DRYRUNNERS where (" &
      "  lower(MARKETNAME) ~ '^[0-9][a-z]' or" &  -- start with digit-letter
      "  lower(MARKETNAME) ~ '^[a-z][0-9]' or" &  -- oResult_Dataletter-digit
      "  lower(MARKETNAME) like 'hp%' or " &
      "  lower(MARKETNAME) like 'hc%' or " &
      "  lower(MARKETNAME) like 'or%' or " &
      "  lower(MARKETNAME) like 'iv%'  " &
      ")  " &
      "and BSPMARKET = 'Y' " &
      "and lower(MARKETNAME) <> 'plats'  " &
      "and lower(MARKETNAME) not like '% v %'  " &
      "and lower(MARKETNAME) not like '%forecast%'  " &
      "and lower(MARKETNAME) not like '%tbp%'  " &
      "and lower(MARKETNAME) not like '%challenge%'  " &
      "and lower(MARKETNAME) not like '%fc%'  " &
      "and lower(MENUPATH) not like '%daily win%'  " &
      "and lower(MARKETNAME) not like '%reverse%'  " &
      "and lower(MARKETNAME) not like '%plats%'  " &
      "and lower(MARKETNAME) not like '%place%'  " &
      "and lower(MARKETNAME) not like '%without%'  " &
      "and EVENTHIERARCHY like :ANIMAL " &
      "and DRYMARKETS.MARKETID = DRYRESULTS.MARKETID " &
      "and DRYMARKETS.MARKETID = DRYRUNNERS.MARKETID " &
      "and DRYRESULTS.SELECTIONID = DRYRUNNERS.SELECTIONID " &
      "order by DRYRUNNERS.BACKPRICE ");
   case Animal is
      when Races.Hound  =>
         Sql.Set (Select_Back_Winners (Races.Winner), "ANIMAL", "/4339/%");
      when Races.Horse  =>
         Sql.Set (Select_Back_Winners (Races.Winner), "ANIMAL", "/7/%");
   end case;

   Sql.Open_Cursor (Select_Back_Winners (Races.Winner));
   Fetch_Loop : loop
      Sql.Fetch (Select_Back_Winners (Races.Winner), Eos );
      exit when Eos;
      Sql.Get (Select_Back_Winners (Races.Winner), 1, Price );
      Total := Total + 1 ;
      Result_Pack.Get_First (Result_List, Result_Data, Eol);
      List_Loop : loop
         exit when Eol;
         if Price > Result_Data.Start and then Price <= Result_Data.Stop then
            Result_Data.Count := Result_Data.Count + 1;
            Result_Pack.Update (Result_List, Result_Data);
            exit List_Loop;
         end if;
         Result_Pack.Get_Next (Result_List, Result_Data, Eol);
      end loop List_Loop;
   end loop Fetch_Loop;
   Sql.Close_Cursor (Select_Back_Winners (Races.Winner));
   Sql.Commit (T);
   Sql.Close_Session;
   Result_Pack.Get_First (Result_List, Result_Data, Eol);
   loop
      exit when Eol;
      Cur_Price := Result_Data.Start + 0.5 * (Result_Data.Stop - Result_Data.Start);
      Text_Io.Put (Cur_Price'Img);
      Text_Io.Put (" ");
      Text_Io.Put (Result_Data.Start'Img);
      Text_Io.Put (" ");
      Text_Io.Put (Result_Data.Stop'Img);
      Text_Io.Put (" ");
      Text_Io.Put (Result_Data.Count'Img);
      Text_Io.Put (" ");
      Text_Io.Put ( Float_8'Image (100.0 * Float_8 (Result_Data.Count) / Float_8 (Total)) );
      Text_Io.Put (" ");
      Text_Io.Put ( Float_8'Image (Cur_Price * 100.0 * Float_8 (Result_Data.Count) / Float_8 (Total)) );
      Text_Io.New_Line;
      Result_Pack.Get_Next (Result_List, Result_Data, Eol);
   end loop;
   Log ("Total:" & Total'Img );

exception
   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);
end Back_Bet_Analyzer;

