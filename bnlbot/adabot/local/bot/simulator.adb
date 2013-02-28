with Sql;
with Table_Dry_markets;
with Table_Dry_runners;
with Table_Dry_results;
with Text_IO;
with SATTMATE_CALENDAR;

procedure Simulator is
   Markets        : Table_Dry_markets.Data_Type;
   Markets_List   : Table_Dry_markets.Dry_markets_List_Pack.LIST_TYPE :=
     Table_Dry_markets.Dry_markets_List_Pack.CREATE;
   Select_Markets : Sql.Statement_Type;
   T              : Sql.Transaction_Type;

   Start_Date : SATTMATE_CALENDAR.TIME_TYPE :=
     (2013,
      02,
      25,
      00,
      00,
      00,
      000);
   Stop_Date  : SATTMATE_CALENDAR.TIME_TYPE :=
     (2013,
      02,
      25,
      23,
      59,
      59,
      999);

   cnt : Natural := 1000;
begin

   Sql.Connect
     (Host     => "192.168.0.13",
      Port     => 5432,
      DB_Name  => "betting",
      Login    => "bnl",
      Password => "");
   Sql.Start_Read_Write_Transaction (T);
   Sql.Prepare
     (Select_Markets,
      "select * from " &
      "DRY_MARKETS " &
      "where EVENT_DATE::date >= :START_DATE " &
      "and EVENT_DATE::date <= :STOP_DATE " &
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
   Sql.Set_Date (Select_Markets, "START_DATE", Start_Date);
   Sql.Set_Date (Select_Markets, "STOP_DATE", Stop_Date);
   Sql.Set (Select_Markets, "EVENT_HIERARCHY", "%/4339/%");
   Text_IO.Put_Line ("reading markets");
   Table_Dry_markets.Read_List (Select_Markets, Markets_List);
   Sql.Commit (T);
   cnt := Table_Dry_markets.Dry_markets_List_Pack.GET_COUNT (Markets_List);
   Text_IO.Put_Line ("antal marknader: " & cnt'Img);

   Sql.Close_Session;

end Simulator;
