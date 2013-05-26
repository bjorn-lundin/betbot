

with Sattmate_Exception;
with Sql;

with Table_Drymarketsf;
with Table_Drymarkets;

with Table_Dryresultsf;
with Table_Dryresults;

with Table_Dryrunnersf;
with Table_Dryrunners;

with Logging; use Logging;

procedure Dry_Runner_Mover is
   Drymarketsf      : Table_Drymarketsf.Data_Type;
   Drymarkets       : Table_Drymarkets.Data_Type;
   Drymarkets_List  : Table_Drymarkets.Drymarkets_List_Pack.List_Type := Table_Drymarkets.Drymarkets_List_Pack.Create ;
   Dryrunnersf      : Table_Dryrunnersf.Data_Type;
   Dryrunners       : Table_Dryrunners.Data_Type;
   Dryrunners_List  : Table_Dryrunners.Dryrunners_List_Pack.List_Type := Table_Dryrunners.Dryrunners_List_Pack.Create ;

   Dryresultsf      : Table_Dryresultsf.Data_Type;
   Dryresults       : Table_Dryresults.Data_Type;
   Dryresults_List  : Table_Dryresults.Dryresults_List_Pack.List_Type := Table_Dryresults.Dryresults_List_Pack.Create ;


   T                       : Sql.Transaction_Type;
   Select_Football_Markets : Sql.Statement_Type;
   Select_Horses_And_Hounds_Markets : Sql.Statement_Type;
   cnt : Natural := 0;
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

   Sql.Prepare (Select_Football_Markets,
                "select * from DRYMARKETS where EVENTHIERARCHY like '/1/%'");
   Table_DryMarkets.Read_List (Stm => Select_Football_Markets, List => DryMarkets_List, Max => 2_000);
   Cnt := Table_DryMarkets.DryMarkets_List_Pack.Get_Count (List => DryMarkets_List);
   Log ("DryMarkets_List count: " & cnt'Img );

   while not Table_DryMarkets.DryMarkets_List_Pack.Is_Empty (List => DryMarkets_List) loop
      Table_DryMarkets.DryMarkets_List_Pack.Remove_From_Head (List => DryMarkets_List, Element => DryMarkets);

      if Cnt mod 1000 = 0 then
        Log (Cnt'Img & " Treat market " & DryMarkets.MarketId'Img & " eventhierarchy " & DryMarkets.EventHierarchy);
      end if;
      Cnt := Cnt -1;

      DryRunners.MarketId := DryMarkets.MarketId;
      Table_DryRunners.Read_I1_MarketId (Data => DryRunners, List => DryRunners_List);

      DryResults.MarketId := DryMarkets.MarketId;
      Table_DryResults.Read_I1_MarketId (Data => DryResults, List => DryResults_List);

      Drymarketsf := (
                      Marketid       => DryMarkets.MarketId,
                      Bspmarket      => DryMarkets.BspMarket,
                      Markettype     => DryMarkets.MarketType,
                      Eventhierarchy => DryMarkets.EventHierarchy,
                      Lastrefresh    => DryMarkets.LastRefresh,
                      Turninginplay  => DryMarkets.TurningInPlay,
                      Menupath       => DryMarkets.MenuPath,
                      Betdelay       => DryMarkets.BetDelay,
                      Exchangeid     => DryMarkets.ExchangeId,
                      Countrycode    => DryMarkets.CountryCode,
                      Marketname     => DryMarkets.MarketName,
                      Marketstatus   => DryMarkets.MarketStatus,
                      Eventdate      => DryMarkets.EventDate,
                      Noofrunners    => DryMarkets.NoOfRunners,
                      Noofwinners    => DryMarkets.NoOfWinners,
                      Totalmatched   => DryMarkets.TotalMatched
                     );
      begin
         Table_Drymarketsf.Insert (Data => Drymarketsf);
      exception
         when Sql.Duplicate_Index => null;
--            Log ("Drymarketsf - Duplicate_Index on marketid" & Drymarketsf.Marketid'Img);
      end;

      Table_DryMarkets.Delete (Data => DryMarkets);

      while not Table_DryRunners.DryRunners_List_Pack.Is_Empty (List => DryRunners_List) loop
         Table_DryRunners.DryRunners_List_Pack.Remove_From_Head (List => DryRunners_List, Element => DryRunners);
         Dryrunnersf := (
                         Marketid           => DryRunners.MarketId,
                         Selectionid        => DryRunners.SelectionId,
                         Index              => DryRunners.Index,
                         Backprice          => DryRunners.BackPrice,
                         Layprice           => DryRunners.LayPrice,
                         Runnername         => DryRunners.RunnerName,
                         Runnernamestripped => DryRunners.Runnernamestripped,
                         Startnum           => DryRunners.Startnum
                        );
         begin
            Table_Dryrunnersf.Insert (Dryrunnersf);
         exception
            when Sql.Duplicate_Index => null;
--               Log ("Dryrunnersf - Duplicate_Index on marketid" & Drymarketsf.Marketid'Img);
         end;
         Table_DryRunners.Delete (Data => DryRunners);
      end loop;

      while not Table_DryResults.DryResults_List_Pack.Is_Empty (List => DryResults_List) loop
         Table_DryResults.DryResults_List_Pack.Remove_From_Head (List => DryResults_List, Element => DryResults);
         Dryresultsf := (
                         Marketid    => DryResults.MarketId,
                         Selectionid => DryResults.SelectionId
                        );
         begin
            Table_Dryresultsf.Insert (Data => Dryresultsf);
         exception
            when Sql.Duplicate_Index => null;
--               Log ("Dryresultsf - Duplicate_Index on marketid" & Drymarketsf.Marketid'Img);
         end;
         Table_DryResults.Delete (Data => DryResults);
      end loop;

   end loop;

   Sql.Commit (T);
   Sql.Close_Session;


exception
   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);
end Dry_Runner_Mover;
