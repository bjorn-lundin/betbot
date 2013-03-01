
with Sql;
--with Sattmate_Calendar;
with Text_IO;

package body Races is


   Select_Markets : Sql.Statement_Type;
   Select_Runners : Sql.Statement_Type;
   Select_Winners : Sql.Statement_Type;




   procedure Get_Runners (Race : in out Race_Type) is
   begin
      Text_Io.Put_Line("Get_Runners, Market_Id=" & Race.Market.Market_Id'Img);
      Sql.Prepare (Select_Runners, "select * from DRY_RUNNERS where MARKET_ID = :MARKET_ID order by BACK_PRICE");
      Sql.Set (Select_Runners, "MARKET_ID", Race.Market.Market_Id);
      Table_Dry_runners.Read_List (Select_Runners, Race.Runners_List);
   end Get_Runners;

   procedure Get_Winners(Race : in out Race_Type) is
   begin
      Text_Io.Put_Line("Get_Winners, Market_Id=" & Race.Market.Market_Id'Img);
      Sql.Prepare(Select_Winners,"select * from DRY_RESULTS where MARKET_ID = :MARKET_ID");
      Sql.Set (Select_Winners, "MARKET_ID", Race.Market.Market_Id);
      Table_Dry_Results.Read_List (Select_Winners, Race.Winners_List);
   end Get_Winners;


   function No_Of_Runners (Race : in Race_Type) return Natural is
   begin
      return Table_Dry_Runners.Dry_Runners_List_Pack.Get_Count( Race.Runners_List);
   end No_Of_Runners;

   function No_Of_Winners (Race : in Race_Type) return Natural is
   begin
      return Table_Dry_Results.Dry_Results_List_Pack.Get_Count( Race.Winners_List);
   end No_Of_Winners;


   procedure Show_Runners (Race : in out Race_Type) is
      Runner : Table_Dry_Runners.Data_Type;
      Eol : Boolean := False;
   begin
      Table_Dry_Runners.Dry_Runners_List_Pack.Get_First (Race.Runners_List, Runner, Eol);
      loop
         exit when Eol;
          Text_Io.Put_Line("Show_Runners " &  Table_Dry_Runners.To_String(Runner));
         Table_Dry_Runners.Dry_Runners_List_Pack.Get_Next (Race.Runners_List, Runner, Eol);
      end loop;

   end Show_Runners;




   procedure Get_Database_Data (Race_List   : in out Race_Package.List_Type;
                                Bet_Type : in Bet_Type_Type;
                                Animal      : Animal_Type;
                                Start_Date  : Sattmate_Calendar.Time_Type;
                                Stop_Date  : Sattmate_Calendar.Time_Type
                               ) is
      T               : Sql.Transaction_Type;
      Race            : Race_Type;
--      Eol             : Boolean := False;
      Market_List     : Table_Dry_Markets.Dry_Markets_List_Pack.List_Type := Table_Dry_Markets.Dry_Markets_List_Pack.Create;
      Market          : Table_Dry_Markets.Data_Type;
      Cnt : Natural;

   begin
      Sql.Connect
        (Host     => "sebjlun-deb",
         Port     => 5432,
         Db_Name  => "betting",
         Login    => "bnl",
         Password => "bnl");
      Sql.Start_Read_Write_Transaction (T);


      case Bet_Type is
         when Place =>
            Sql.Prepare(Select_Markets, "select * from " &
                 "DRY_MARKETS " &
                 "where EVENT_DATE >= :START_DATE " &
                 "and EVENT_DATE <= :STOP_DATE " &
                 "and MARKET_NAME = :MARKET_NAME " &
                 "and EVENT_HIERARCHY like :EVENT_HIERARCHY " &
                 "and exists (select 'x' from DRY_RESULTS where " &
                 "    DRY_MARKETS.MARKET_ID = DRY_RESULTS.MARKET_ID) " &
                 "and exists (select 'x' from DRY_RUNNERS where " &
                 "    DRY_MARKETS.MARKET_ID = DRY_RUNNERS.MARKET_ID) " &
                 "order by EVENT_DATE");
              Sql.Set_Timestamp (Select_Markets, "START_DATE", Start_Date);
            Sql.Set_Timestamp (Select_Markets, "STOP_DATE", Stop_Date);
            Sql.Set (Select_Markets, "MARKET_NAME", "Plats");
            case Animal is
               when Horse =>  Sql.Set (Select_Markets, "EVENT_HIERARCHY", "%/7/%");
               when Hound =>  Sql.Set (Select_Markets, "EVENT_HIERARCHY", "%/4339/%");
            end case;
         when Winner =>
            Sql.Prepare
              (Select_Markets,
               "select * from " &
                 "DRY_MARKETS " &
                 "where EVENT_DATE >= :START_DATE " &
                 "and EVENT_DATE <= :STOP_DATE " &
                 "and lower(MARKET_NAME) not like '%% v %%'  " &
                 "and lower(MARKET_NAME) not like '%%forecast%%'  " &
                 "and lower(MARKET_NAME) not like '%%tbp%%'  " &
                 "and lower(MARKET_NAME) not like '%%challenge%%'  " &
                 "and lower(MARKET_NAME) not like '%%fc%%'  " &
                 "and lower(MENU_PATH) not like '%%daily win%%'  " &
                 "and lower(MARKET_NAME) not like '%%reverse%%'  " &
                 "and lower(MARKET_NAME) not like '%%plats%%'  " &
                 "and lower(MARKET_NAME) not like '%%place%%'  " &
                 "and lower(MARKET_NAME) not like '%%without%%'  " &
                 "and EVENT_HIERARCHY like :EVENT_HIERARCHY " &
                 "and exists (select 'x' from DRY_RUNNERS where " &
                 "    DRY_MARKETS.MARKET_ID = DRY_RUNNERS.MARKET_ID) " &
                 "and exists (select 'x' from DRY_RESULTS where " &
                 "   DRY_MARKETS.MARKET_ID = DRY_RESULTS.MARKET_ID) " &
                 "order by EVENT_DATE");
            Sql.Set_Timestamp (Select_Markets, "START_DATE", Start_Date);
            Sql.Set_Timestamp (Select_Markets, "STOP_DATE", Stop_Date);
            case Animal is
               when Horse =>  Sql.Set (Select_Markets, "EVENT_HIERARCHY", "%/7/%");
               when Hound =>  Sql.Set (Select_Markets, "EVENT_HIERARCHY", "%/4339/%");
            end case;
            Text_Io.Put_Line ("reading markets");

      end case;

      Table_Dry_Markets.Read_List (Select_Markets, Market_List);
      Cnt := Table_Dry_Markets.Dry_Markets_List_Pack.Get_Count (Market_List);
      Text_Io.Put_Line ("antal marknader: " & Cnt'Img);


      while not Table_Dry_Markets.Dry_Markets_List_Pack.Is_Empty  (Market_List) loop
         Table_Dry_Markets.Dry_Markets_List_Pack.Remove_From_Head(Market_List, Market);
         Race.Market := Market;
         Race.Get_Runners;
         Race.Get_Winners;
         Race_Package.Insert_At_Tail (Race_List, Race);
      end loop;


      Sql.Commit (T);

      Sql.Close_Session;
      Table_Dry_Markets.Dry_Markets_List_Pack.Release (Market_List);
   end Get_Database_Data;





end Races;
