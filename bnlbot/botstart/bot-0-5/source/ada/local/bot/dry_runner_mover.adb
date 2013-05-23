

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

procedure Dry_Runner_Mover is
   Dry_Markets      : Table_Dry_Markets.Data_Type;
   Drymarketsf      : Table_Drymarketsf.Data_Type;
   Drymarkets       : Table_Drymarkets.Data_Type;
   Dry_Markets_List : Table_Dry_Markets.Dry_Markets_List_Pack.List_Type :=
                        Table_Dry_Markets.Dry_Markets_List_Pack.Create;

   Dry_Runners      : Table_Dry_Runners.Data_Type;
   Dryrunnersf      : Table_Dryrunnersf.Data_Type;
   Dryrunners       : Table_Dryrunners.Data_Type;
   Dry_Runners_List : Table_Dry_Runners.Dry_Runners_List_Pack.List_Type :=
                        Table_Dry_Runners.Dry_Runners_List_Pack.Create;



   Dry_Results      : Table_Dry_Results.Data_Type;
   Dryresultsf      : Table_Dryresultsf.Data_Type;
   Dryresults       : Table_Dryresults.Data_Type;
   Dry_Results_List : Table_Dry_Results.Dry_Results_List_Pack.List_Type :=
                        Table_Dry_Results.Dry_Results_List_Pack.Create;


   T                       : Sql.Transaction_Type;
   Select_Football_Markets : Sql.Statement_Type;
   Select_Horses_And_Hounds_Markets : Sql.Statement_Type;
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

   -- move the footballs away

   Sql.Prepare (Select_Football_Markets,
                "select * from DRY_MARKETS where EVENT_HIERARCHY like '/1/%'");
   Table_Dry_Markets.Read_List (Stm => Select_Football_Markets, List => Dry_Markets_List, Max => 2_000_000);
   Cnt := Table_Dry_Markets.Dry_Markets_List_Pack.Get_Count (List => Dry_Markets_List);
   Log ("Dry_Markets_List count: " & cnt'Img );

   while not Table_Dry_Markets.Dry_Markets_List_Pack.Is_Empty (List => Dry_Markets_List) loop
      Table_Dry_Markets.Dry_Markets_List_Pack.Remove_From_Head (List => Dry_Markets_List, Element => Dry_Markets);

      if Cnt mod 1000 = 0 then
        Log (Cnt'Img & " Treat market " & Dry_Markets.Market_Id'Img & " eventhierarchy " & Dry_Markets.Event_Hierarchy);
      end if;
      Cnt := Cnt -1;

      Dry_Runners.Market_Id := Dry_Markets.Market_Id;
      Table_Dry_Runners.Read_I1_Market_Id (Data => Dry_Runners, List => Dry_Runners_List);

      Dry_Results.Market_Id := Dry_Markets.Market_Id;
      Table_Dry_Results.Read_I1_Market_Id (Data => Dry_Results, List => Dry_Results_List);

      Drymarketsf := (
                      Marketid       => Dry_Markets.Market_Id,
                      Bspmarket      => Dry_Markets.Bsp_Market,
                      Markettype     => Dry_Markets.Market_Type,
                      Eventhierarchy => Dry_Markets.Event_Hierarchy,
                      Lastrefresh    => Dry_Markets.Last_Refresh,
                      Turninginplay  => Dry_Markets.Turning_In_Play,
                      Menupath       => Dry_Markets.Menu_Path,
                      Betdelay       => Dry_Markets.Bet_Delay,
                      Exchangeid     => Dry_Markets.Exchange_Id,
                      Countrycode    => Dry_Markets.Country_Code,
                      Marketname     => Dry_Markets.Market_Name,
                      Marketstatus   => Dry_Markets.Market_Status,
                      Eventdate      => Dry_Markets.Event_Date,
                      Noofrunners    => Dry_Markets.No_Of_Runners,
                      Noofwinners    => Dry_Markets.No_Of_Winners,
                      Totalmatched   => Dry_Markets.Total_Matched
                     );
      begin
         Table_Drymarketsf.Insert (Data => Drymarketsf);
      exception
         when Sql.Duplicate_Index => null;
--            Log ("Drymarketsf - Duplicate_Index on marketid" & Drymarketsf.Marketid'Img);
      end;

      Table_Dry_Markets.Delete (Data => Dry_Markets);

      while not Table_Dry_Runners.Dry_Runners_List_Pack.Is_Empty (List => Dry_Runners_List) loop
         Table_Dry_Runners.Dry_Runners_List_Pack.Remove_From_Head (List => Dry_Runners_List, Element => Dry_Runners);
         Dryrunnersf := (
                         Marketid    => Dry_Runners.Market_Id,
                         Selectionid => Dry_Runners.Selection_Id,
                         Index       => Dry_Runners.Index,
                         Backprice   => Dry_Runners.Back_Price,
                         Layprice    => Dry_Runners.Lay_Price,
                         Runnername  => Dry_Runners.Runner_Name,
                         Runnernamestripped => Dry_Runners.Runnernamestripped,
                         Startnum           => Dry_Runners.Startnum
                        );
         begin
            Table_Dryrunnersf.Insert (Dryrunnersf);
         exception
            when Sql.Duplicate_Index => null;
--               Log ("Dryrunnersf - Duplicate_Index on marketid" & Drymarketsf.Marketid'Img);
         end;
         Table_Dry_Runners.Delete (Data => Dry_Runners);
      end loop;

      while not Table_Dry_Results.Dry_Results_List_Pack.Is_Empty (List => Dry_Results_List) loop
         Table_Dry_Results.Dry_Results_List_Pack.Remove_From_Head (List =>  Dry_Results_List, Element => Dry_Results);
         Dryresultsf := (
                         Marketid    => Dry_Results.Market_Id,
                         Selectionid => Dry_Results.Selection_Id
                        );
         begin
            Table_Dryresultsf.Insert (Data => Dryresultsf);
         exception
            when Sql.Duplicate_Index => null;
--               Log ("Dryresultsf - Duplicate_Index on marketid" & Drymarketsf.Marketid'Img);
         end;
         Table_Dry_Results.Delete (Data => Dry_Results);
      end loop;

   end loop;


   -- move the hounds and horses now
   -- move the footballs away

   Sql.Prepare (Select_Horses_And_Hounds_Markets,
                "select * from DRY_MARKETS where (EVENT_HIERARCHY like '/7/%' or EVENT_HIERARCHY like '/4339/%')");
   Table_Dry_Markets.Read_List (Stm => Select_Horses_And_Hounds_Markets, List => Dry_Markets_List, Max => 2_000_000);
   Cnt := Table_Dry_Markets.Dry_Markets_List_Pack.Get_Count (List => Dry_Markets_List);
   Log ("Dry_Markets_List count: " & Cnt'Img );

   while not Table_Dry_Markets.Dry_Markets_List_Pack.Is_Empty (List => Dry_Markets_List) loop
--   Log ("Dry_Markets_List 2");
      Table_Dry_Markets.Dry_Markets_List_Pack.Remove_From_Head (List => Dry_Markets_List, Element => Dry_Markets);

      if Cnt mod 1000 = 0 then
         Log (Cnt'Img & " Treat market " & Dry_Markets.Market_Id'Img & " eventhierarchy " & Dry_Markets.Event_Hierarchy);
      end if;
      Cnt := Cnt -1;

      Dry_Runners.Market_Id := Dry_Markets.Market_Id;
      Table_Dry_Runners.Read_I1_Market_Id (Data => Dry_Runners, List => Dry_Runners_List);

      Dry_Results.Market_Id := Dry_Markets.Market_Id;
      Table_Dry_Results.Read_I1_Market_Id (Data => Dry_Results, List => Dry_Results_List);

      Drymarkets := (
                      Marketid       => Dry_Markets.Market_Id,
                      Bspmarket      => Dry_Markets.Bsp_Market,
                      Markettype     => Dry_Markets.Market_Type,
                      Eventhierarchy => Dry_Markets.Event_Hierarchy,
                      Lastrefresh    => Dry_Markets.Last_Refresh,
                      Turninginplay  => Dry_Markets.Turning_In_Play,
                      Menupath       => Dry_Markets.Menu_Path,
                      Betdelay       => Dry_Markets.Bet_Delay,
                      Exchangeid     => Dry_Markets.Exchange_Id,
                      Countrycode    => Dry_Markets.Country_Code,
                      Marketname     => Dry_Markets.Market_Name,
                      Marketstatus   => Dry_Markets.Market_Status,
                      Eventdate      => Dry_Markets.Event_Date,
                      Noofrunners    => Dry_Markets.No_Of_Runners,
                      Noofwinners    => Dry_Markets.No_Of_Winners,
                      Totalmatched   => Dry_Markets.Total_Matched
                     );
      begin
         Table_Drymarkets.Insert (Data => Drymarkets);
      exception
         when Sql.Duplicate_Index => null;
--            Log ("Drymarkets - Duplicate_Index on marketid" & Drymarkets.Marketid'Img);
      end;

      Table_Dry_Markets.Delete (Data => Dry_Markets);

      while not Table_Dry_Runners.Dry_Runners_List_Pack.Is_Empty (List => Dry_Runners_List) loop
         Table_Dry_Runners.Dry_Runners_List_Pack.Remove_From_Head (List => Dry_Runners_List, Element => Dry_Runners);
--         Log ("Treat runner in market/selection" & Dry_Runners.Market_Id'Img &  Dry_Runners.Selection_Id'Img);

         Dryrunners := (
                         Marketid           => Dry_Runners.Market_Id,
                         Selectionid        => Dry_Runners.Selection_Id,
                         Index              => Dry_Runners.Index,
                         Backprice          => Dry_Runners.Back_Price,
                         Layprice           => Dry_Runners.Lay_Price,
                         Runnername         => Dry_Runners.Runner_name,
                         Runnernamestripped => (others => ' '),
                         Startnum           => (others => ' ')
                        );
         begin
            Table_Dryrunners.Insert (Dryrunners);
         exception
            when Sql.Duplicate_Index => null;
--               Log ("Dryrunners - Duplicate_Index on marketid" & Drymarkets.Marketid'Img);
         end;
         Table_Dry_Runners.Delete (Data => Dry_Runners);
      end loop;

      while not Table_Dry_Results.Dry_Results_List_Pack.Is_Empty (List => Dry_Results_List) loop
         Table_Dry_Results.Dry_Results_List_Pack.Remove_From_Head (List =>  Dry_Results_List, Element => Dry_Results);
  --       Log ("Treat result in market/selection" & Dry_Results.Market_Id'Img &  Dry_Results.Selection_Id'Img);
         Dryresults := (
                         Marketid    => Dry_Results.Market_Id,
                         Selectionid => Dry_Results.Selection_Id
                        );
         begin
            Table_Dryresults.Insert (Data => Dryresults);
         exception
            when Sql.Duplicate_Index => null;
--               Log ("Dryresults - Duplicate_Index on marketid" & Drymarkets.Marketid'Img);
         end;
         Table_Dry_Results.Delete (Data => Dry_Results);
      end loop;
   end loop;

   Sql.Commit (T);
   Sql.Close_Session;


exception
   when E : others =>
      Sattmate_Exception.Tracebackinfo (E);
end Dry_Runner_Mover;
