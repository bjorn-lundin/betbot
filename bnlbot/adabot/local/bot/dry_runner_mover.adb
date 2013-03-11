

with Sattmate_Exception;
with Sql;

with Table_Dry_Markets;
with Table_Drymarketsf;

with Table_Dry_Results;
with Table_Dryresultsf;

with Table_Dry_Runners;
with Table_Dryrunnersf;

with Logging; use Logging;

procedure Dry_Runner_Mover is
   Dry_Markets      : Table_Dry_Markets.Data_Type;
   Drymarketsf      : Table_Drymarketsf.Data_Type;
   Dry_Markets_List : Table_Dry_Markets.Dry_Markets_List_Pack.List_Type :=
                        Table_Dry_Markets.Dry_Markets_List_Pack.Create;

   Dry_Runners      : Table_Dry_Runners.Data_Type;
   Dryrunnersf      : Table_Dryrunnersf.Data_Type;
   Dry_Runners_List : Table_Dry_Runners.Dry_Runners_List_Pack.List_Type :=
                        Table_Dry_Runners.Dry_Runners_List_Pack.Create;



   Dry_Results      : Table_Dry_Results.Data_Type;
   Dryresultsf      : Table_Dryresultsf.Data_Type;
   Dry_Results_List : Table_Dry_Results.Dry_Results_List_Pack.List_Type :=
                        Table_Dry_Results.Dry_Results_List_Pack.Create;


   T                : Sql.Transaction_Type;
   Select_Football_Markets : Sql.Statement_Type;
begin
   Log ("Connect db");
   Sql.Connect
     (Host     => "192.168.0.13",
      Port     => 5432,
      Db_Name  => "betting",
      Login    => "bnl",
      Password => "bnl");
   Sql.Start_Read_Write_Transaction (T);
   Sql.Prepare (Select_Football_Markets,
                "select * from DRY_MARKETS where EVENT_HIERARCHY like '%/1/%'");
   Table_Dry_Markets.Read_List (Stm => Select_Football_Markets, List => Dry_Markets_List, Max => 100_000);

   while not Table_Dry_Markets.Dry_Markets_List_Pack.Is_Empty (List => Dry_Markets_List) loop
      Table_Dry_Markets.Dry_Markets_List_Pack.Remove_From_Head (List => Dry_Markets_List, Element => Dry_Markets);

      Log ("Treat market " & Dry_Markets.Market_Id'Img );

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

      Table_Drymarketsf.Insert (Data => Drymarketsf);
      Table_Dry_Markets.Delete(Data => Dry_Markets);

      while not Table_Dry_Runners.Dry_Runners_List_Pack.Is_Empty (List => Dry_Runners_List) loop
         Table_Dry_Runners.Dry_Runners_List_Pack.Remove_From_Head (List => Dry_Runners_List, Element => Dry_Runners);
         Dryrunnersf := (
                         Marketid    => Dry_Runners.Market_Id,
                         Selectionid => Dry_Runners.Selection_Id,
                         Index       => Dry_Runners.Index,
                         Backprice   => Dry_Runners.Back_Price,
                         Layprice    => Dry_Runners.Lay_Price,
                         Runnername  => Dry_Runners.Runner_Name
                        );
         Table_Dryrunnersf.Insert (Dryrunnersf);
         Table_Dry_Runners.Delete(Data => Dry_Runners);
      end loop;

      while not Table_Dry_Results.Dry_Results_List_Pack.Is_Empty (List => Dry_Results_List) loop
      Table_Dry_Results.Dry_Results_List_Pack.Remove_From_Head (List =>  Dry_Results_List, Element => Dry_Results);
      Dryresultsf := (
                     Marketid    => Dry_Results.Market_Id,
                     Selectionid => Dry_Results.Selection_Id
                    );

      Table_Dryresultsf.Insert (Data => Dryresultsf);
      Table_Dry_Results.Delete(Data => Dry_Results);
   end loop;


end loop;





Sql.Commit (T);
Sql.Close_Session;


exception
when E : others =>
   Sattmate_Exception.Tracebackinfo (E);
end Dry_Runner_Mover;
