--with Unchecked_Conversion;
--with Sattmate_Exception;
with Sattmate_Types; use Sattmate_Types;
with Sql;
with Logging; use Logging;
with Races;
with Text_Io;
with Simple_List_Class;



procedure Back_Bet_Analyzer is
   T                   : Sql.Transaction_Type;
   Select_Back_Winners : array (Races.Animal_Type'Range) of Sql.Statement_Type;
   Animal              : Races.Animal_Type := Races.Hound;
   Interval_Offset : Float_8 := 0.01;
   Interval_Begin : Float_8 := 1.0;
   Interval_Last : Float_8 := 10.0;
   Interval_Current : Float_8 := 0.0;

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
      Result_Pack.Insert_At_Tail(Result_List,Result_Data);
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
   case Animal is
      when Races.Hound  =>
         Sql.Prepare
           (Select_Back_Winners (Animal),
            --               "select count(DRY_RUNNERS.*), DRY_RUNNERS.BACK_PRICE from " &
            "select DRY_RUNNERS.BACK_PRICE from " &
            "DRY_MARKETS , DRY_RESULTS, DRY_RUNNERS where (" &
            "  lower(MARKET_NAME) ~ '^[0-9][a-z]' or" &  -- start with digit-letter
            "  lower(MARKET_NAME) ~ '^[a-z][0-9]' or" &  -- oResult_Dataletter-digit
            "  lower(MARKET_NAME) like 'hp%' or " &
            "  lower(MARKET_NAME) like 'hc%' or " &
            "  lower(MARKET_NAME) like 'or%' or " &
            "  lower(MARKET_NAME) like 'iv%'  " &
            ")  " &
            "and BSP_MARKET = 'Y' " &
            "and lower(MARKET_NAME) <> 'plats'  " &
            "and lower(MARKET_NAME) not like '% v %'  " &
            "and lower(MARKET_NAME) not like '%forecast%'  " &
            "and lower(MARKET_NAME) not like '%tbp%'  " &
            "and lower(MARKET_NAME) not like '%challenge%'  " &
            "and lower(MARKET_NAME) not like '%fc%'  " &
            "and lower(MENU_PATH) not like '%daily win%'  " &
            "and lower(MARKET_NAME) not like '%reverse%'  " &
            "and lower(MARKET_NAME) not like '%plats%'  " &
            "and lower(MARKET_NAME) not like '%place%'  " &
            "and lower(MARKET_NAME) not like '%without%'  " &
            "and EVENT_HIERARCHY like '/4339/%' " &
--            "and EVENT_HIERARCHY like '/7/%' " &
            "and DRY_MARKETS.MARKET_ID = DRY_RESULTS.MARKET_ID " &
            "and DRY_MARKETS.MARKET_ID = DRY_RUNNERS.MARKET_ID " &
            "and DRY_RESULTS.SELECTION_ID = DRY_RUNNERS.SELECTION_ID " &
            --                 "group by DRY_RUNNERS.BACK_PRICE " &
            "order by DRY_RUNNERS.BACK_PRICE ");
      when Races.Horse  =>
         raise Program_Error with "Horse not implemeted yet";
   end case;

   Sql.Open_Cursor(Select_Back_Winners (Races.Hound));
   Fetch_Loop : loop
      Sql.Fetch (Select_Back_Winners (Races.Hound), Eos );
      exit when Eos;
      --      Sql.Get (Select_Back_Winners (Races.Hound), 1, Cnt );
      Sql.Get (Select_Back_Winners (Races.Hound), 1, Price );
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
   Sql.Close_Cursor (Select_Back_Winners (Races.Hound));
   Sql.Commit (T);
   Sql.Close_Session;
   Result_Pack.Get_First (Result_List, Result_Data, Eol);
   loop
      exit when Eol;
      Cur_Price := Result_Data.Start + 0.5*(Result_Data.Stop - Result_Data.Start);
      Text_Io.Put(Cur_Price'Img);
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

end Back_Bet_Analyzer;

