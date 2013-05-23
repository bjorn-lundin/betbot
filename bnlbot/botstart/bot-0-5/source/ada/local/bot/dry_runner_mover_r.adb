

with Sattmate_Exception;
with Sql;

with Table_Dry_Markets;
with Table_Drymarketsf;
with Table_Drymarkets;

with Table_Dry_Results;
with Table_Dryresultsf;
with Table_Dryresults;

with Table_Dry_Runners;
with Table_Dryrunnersf;
with Table_Dryrunners;

with Logging; use Logging;

procedure Dry_Runner_Mover_R is
   Dry_Markets      : Table_Dry_Markets.Data_Type;
--   Dry_Markets_List : Table_Dry_Markets.Dry_Markets_List_Pack.List_Type :=
--                        Table_Dry_Markets.Dry_Markets_List_Pack.Create;


   Drymarketsf      : Table_Drymarketsf.Data_Type;
   DryMarketsf_List : Table_DryMarketsf.DryMarketsf_List_Pack.List_Type :=
                        Table_DryMarketsf.DryMarketsf_List_Pack.Create;

   Drymarkets       : Table_Drymarkets.Data_Type;
   DryMarkets_List : Table_DryMarkets.DryMarkets_List_Pack.List_Type :=
                        Table_DryMarkets.DryMarkets_List_Pack.Create;



   Dry_Runners      : Table_Dry_Runners.Data_Type;
--   Dry_Runners_List : Table_Dry_Runners.Dry_Runners_List_Pack.List_Type :=
--                        Table_Dry_Runners.Dry_Runners_List_Pack.Create;

   Dryrunnersf      : Table_Dryrunnersf.Data_Type;
   DryRunnersf_List : Table_DryRunnersf.DryRunnersf_List_Pack.List_Type :=
                        Table_DryRunnersf.DryRunnersf_List_Pack.Create;
   Dryrunners       : Table_Dryrunners.Data_Type;
   DryRunners_List : Table_DryRunners.DryRunners_List_Pack.List_Type :=
                        Table_DryRunners.DryRunners_List_Pack.Create;



   Dry_Results      : Table_Dry_Results.Data_Type;
--   Dry_Results_List : Table_Dry_Results.Dry_Results_List_Pack.List_Type :=
--                        Table_Dry_Results.Dry_Results_List_Pack.Create;


   Dryresultsf      : Table_Dryresultsf.Data_Type;
   DryResultsf_List : Table_DryResultsf.DryResultsf_List_Pack.List_Type :=
                        Table_DryResultsf.DryResultsf_List_Pack.Create;

   Dryresults       : Table_Dryresults.Data_Type;
   DryResults_List : Table_DryResults.DryResults_List_Pack.List_Type :=
                        Table_DryResults.DryResults_List_Pack.Create;


   T                       : Sql.Transaction_Type;
--   Select_Football_Markets : Sql.Statement_Type;
--   Select_Horses_And_Hounds_Markets : Sql.Statement_Type;
   Select_all : array (1..6) of sql.statement_type;

   cnt : Natural := 0;
begin
   Log ("Connect db");
   Sql.Connect
     (Host     => "localhost",
      Port     => 5432,
      Db_Name  => "betting",
      Login    => "bnl",
      Password => "bnl");

   Sql.Start_Read_Write_Transaction (T);
   Sql.Prepare (Select_all(1), "select * from DRYMARKETS");
   Table_DryMarkets.Read_List (Stm => Select_all(1), List => DryMarkets_List, Max => 2_000_000);
   Cnt := Table_DryMarkets.DryMarkets_List_Pack.Get_Count (List => DryMarkets_List);
   Log ("DryMarkets_List count: " & Cnt'Img );

   while not Table_DryMarkets.DryMarkets_List_Pack.Is_Empty (List => DryMarkets_List) loop
      Table_DryMarkets.DryMarkets_List_Pack.Remove_From_Head (List => DryMarkets_List, Element => DryMarkets);

      if Cnt mod 1000 = 0 then
        Log (Cnt'Img & " Treat market " & DryMarkets.MarketId'Img & " eventhierarchy " & DryMarkets.EventHierarchy);
      end if;
      Cnt := Cnt -1;

      Dry_markets := (
                      Market_id       => DryMarkets.MarketId,
                      Bsp_market      => DryMarkets.BspMarket,
                      Market_type     => DryMarkets.MarketType,
                      Event_hierarchy => DryMarkets.EventHierarchy,
                      Last_refresh    => DryMarkets.LastRefresh,
                      Turning_in_play  => DryMarkets.TurningInPlay,
                      Menu_path       => DryMarkets.MenuPath,
                      Bet_delay       => DryMarkets.BetDelay,
                      Exchange_id     => DryMarkets.ExchangeId,
                      Country_code    => DryMarkets.CountryCode,
                      Market_name     => DryMarkets.MarketName,
                      Market_status   => DryMarkets.MarketStatus,
                      Event_date      => DryMarkets.EventDate,
                      No_of_runners    => DryMarkets.NoOfRunners,
                      No_of_winners    => DryMarkets.NoOfWinners,
                      Total_matched   => DryMarkets.TotalMatched
                     );
      begin
         Table_Dry_markets.Insert (Data => Dry_markets);
      exception
         when Sql.Duplicate_Index => null;
--            Log ("Dry_markets 1 - Duplicate_Index on marketid" & Dry_markets.Market_id'Img);
      end;
      Table_DryMarkets.Delete (Data => DryMarkets);
   end loop;
   Sql.Commit (T);

   Sql.Start_Read_Write_Transaction (T);
   Sql.Prepare (Select_all(2), "select * from DRYMARKETSF");
   Table_DryMarketsf.Read_List (Stm => Select_all(2), List => DryMarketsf_List, Max => 2_000_000);
   Cnt := Table_DryMarketsf.DryMarketsf_List_Pack.Get_Count (List => DryMarketsf_List);
   Log ("DryMarketsf_List count: " & Cnt'Img );

   while not Table_DryMarketsf.DryMarketsf_List_Pack.Is_Empty (List => DryMarketsf_List) loop
      Table_DryMarketsf.DryMarketsf_List_Pack.Remove_From_Head (List => DryMarketsf_List, Element => DryMarketsf);

      if Cnt mod 1000 = 0 then
         Log (Cnt'Img & " Treat market " & DryMarketsf.MarketId'Img & " eventhierarchy " & DryMarketsf.EventHierarchy);
      end if;
      Cnt := Cnt -1;

      Dry_markets := (
                      Market_id       => DryMarketsf.MarketId,
                      Bsp_market      => DryMarketsf.BspMarket,
                      Market_type     => DryMarketsf.MarketType,
                      Event_hierarchy => DryMarketsf.EventHierarchy,
                      Last_refresh    => DryMarketsf.LastRefresh,
                      Turning_in_play => DryMarketsf.TurningInPlay,
                      Menu_path       => DryMarketsf.MenuPath,
                      Bet_delay       => DryMarketsf.BetDelay,
                      Exchange_id     => DryMarketsf.ExchangeId,
                      Country_code    => DryMarketsf.CountryCode,
                      Market_name     => DryMarketsf.MarketName,
                      Market_status   => DryMarketsf.MarketStatus,
                      Event_date      => DryMarketsf.EventDate,
                      No_of_runners   => DryMarketsf.NoOfRunners,
                      No_of_winners   => DryMarketsf.NoOfWinners,
                      Total_matched   => DryMarketsf.TotalMatched
                     );
      begin
         Table_Dry_markets.Insert (Data => Dry_markets);
      exception
         when Sql.Duplicate_Index => null;
--            Log ("Dry_markets 2 - Duplicate_Index on marketid" & Dry_markets.Market_id'Img);
      end;
      Table_DryMarketsf.Delete (Data => DryMarketsf);
   end loop;
   Sql.Commit (T);

   Sql.Start_Read_Write_Transaction (T);
   Sql.Prepare (Select_all(3), "select * from DRYRUNNERS");
   Table_DryRunners.Read_List (Stm => Select_all(3), List => DryRunners_List, Max => 2_000_000);
   Cnt := Table_DryRunners.DryRunners_List_Pack.Get_Count (List => DryRunners_List);
   Log ("DryRunners_List count: " & Cnt'Img );

   while not Table_DryRunners.DryRunners_List_Pack.Is_Empty (List => DryRunners_List) loop
      Table_DryRunners.DryRunners_List_Pack.Remove_From_Head (List => DryRunners_List, Element => DryRunners);
      if Cnt mod 1000 = 0 then
         Log (Cnt'Img & " Treat runner in market/selection" & DryRunners.MarketId'Img &  DryRunners.SelectionId'Img);
      end if;
      Cnt := Cnt -1;

         Dry_runners := (
                         Market_id           => DryRunners.MarketId,
                         Selection_id        => DryRunners.SelectionId,
                         Index               => DryRunners.Index,
                         Back_price          => DryRunners.BackPrice,
                         Lay_price           => DryRunners.LayPrice,
                         Runner_name         => DryRunners.Runnername,
                         Runnernamestripped => (others => ' '),
                         Startnum           => (others => ' ')
                        );
         begin
            Table_Dry_runners.Insert (Dry_runners);
         exception
            when Sql.Duplicate_Index => null;
--               Log ("Dryrunners - Duplicate_Index on marketid" & DryRunners.Marketid'Img);
         end;
         Table_DryRunners.Delete (Data => DryRunners);
   end loop;
   Sql.Commit (T);

   Sql.Start_Read_Write_Transaction (T);
   Sql.Prepare (Select_all(4), "select * from DRYRUNNERSF");
   Table_DryRunnersf.Read_List (Stm => Select_all(4), List => DryRunnersf_List, Max => 2_000_000);
   Cnt := Table_DryRunnersf.DryRunnersf_List_Pack.Get_Count (List => DryRunnersf_List);
   Log ("DryRunnersf_List count: " & Cnt'Img );

   while not Table_DryRunnersf.DryRunnersf_List_Pack.Is_Empty (List => DryRunnersf_List) loop
      Table_DryRunnersf.DryRunnersf_List_Pack.Remove_From_Head (List => DryRunnersf_List, Element => DryRunnersf);
      if Cnt mod 1000 = 0 then
         Log (Cnt'Img & " Treat runner in market/selection" & DryRunnersf.MarketId'Img &  DryRunnersf.SelectionId'Img);
      end if;
      Cnt := Cnt -1;

         Dry_runners := (
                         Market_id           => DryRunnersf.MarketId,
                         Selection_id        => DryRunnersf.SelectionId,
                         Index               => DryRunnersf.Index,
                         Back_price          => DryRunnersf.BackPrice,
                         Lay_price           => DryRunnersf.LayPrice,
                         Runner_name         => DryRunnersf.Runnername,
                         Runnernamestripped => (others => ' '),
                         Startnum           => (others => ' ')
                        );
         begin
            Table_Dry_runners.Insert (Dry_runners);
         exception
            when Sql.Duplicate_Index => null;
--               Log ("Dryrunners - Duplicate_Index on marketid" & DryRunnersf.Marketid'Img);
         end;
         Table_DryRunnersf.Delete (Data => DryRunnersf);
   end loop;
   Sql.Commit (T);


   Sql.Start_Read_Write_Transaction (T);
   Sql.Prepare (Select_all(5), "select * from DRYRESULTS");
   Table_DryResults.Read_List (Stm => Select_all(5), List => DryResults_List, Max => 2_000_000);
   Cnt := Table_DryResults.DryResults_List_Pack.Get_Count (List => DryResults_List);
   Log ("DryResults_List count: " & Cnt'Img );

   while not Table_DryResults.DryResults_List_Pack.Is_Empty (List => DryResults_List) loop
      Table_DryResults.DryResults_List_Pack.Remove_From_Head (List =>  DryResults_List, Element => DryResults);
      if Cnt mod 1000 = 0 then
        Log (Cnt'Img & " Treat result in market/selection" & DryResults.MarketId'Img &  DryResults.SelectionId'Img);
      end if;
      Cnt := Cnt -1;
         Dry_results := (
                         Market_id    => DryResults.MarketId,
                         Selection_id => DryResults.SelectionId
                        );
         begin
            Table_Dry_results.Insert (Data => Dry_results);
         exception
            when Sql.Duplicate_Index => null;
--               Log ("Dryresults - Duplicate_Index on marketid" & DryResults.Marketid'Img);
         end;
         Table_DryResults.Delete (Data => DryResults);
   end loop;
   Sql.Commit (T);


   Sql.Start_Read_Write_Transaction (T);
   Sql.Prepare (Select_all(6), "select * from DRYRESULTSF");
   Table_DryResultsf.Read_List (Stm => Select_all(6), List => DryResultsf_List, Max => 2_000_000);
   Cnt := Table_DryResultsf.DryResultsf_List_Pack.Get_Count (List => DryResultsf_List);
   Log ("DryResultsf_List count: " & Cnt'Img );

   while not Table_DryResultsf.DryResultsf_List_Pack.Is_Empty (List => DryResultsf_List) loop
      Table_DryResultsf.DryResultsf_List_Pack.Remove_From_Head (List =>  DryResultsf_List, Element => DryResultsf);
      if Cnt mod 1000 = 0 then
         Log (Cnt'Img & " Treat result in market/selection" & DryResultsf.MarketId'Img &  DryResultsf.SelectionId'Img);
      end if;
      Cnt := Cnt -1;
         Dry_results := (
                         Market_id    => DryResultsf.MarketId,
                         Selection_id => DryResultsf.SelectionId
                        );
         begin
            Table_Dry_results.Insert (Data => Dry_results);
         exception
            when Sql.Duplicate_Index => null;
--               Log ("Dryresultsf - Duplicate_Index on marketid" & DryResultsf.Marketid'Img);
         end;
         Table_DryResultsf.Delete (Data => DryResultsf);
   end loop;

   Sql.Commit (T);





   Sql.Close_Session;


exception
   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);
end Dry_Runner_Mover_R;
