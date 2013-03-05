
with Sql;
--with Sattmate_Calendar;
--with Text_Io;

with Logging ; use Logging;


package body Races is


   Select_Markets : Sql.Statement_Type;
   Select_Runners : Sql.Statement_Type;
   Select_Winners : Sql.Statement_Type;

   ------------------------------------------------------------------------------

   procedure Clear (Race : in out Race_Type) is
   begin
      Table_Dry_Runners.Dry_Runners_List_Pack.Remove_All ( Race.Runners_List);
      Table_Dry_Results.Dry_Results_List_Pack.Remove_All ( Race.Winners_List);
      Race.Market := Table_Dry_Markets.Empty_Data;
   end Clear;

   ------------------------------------------------------------------------------

   procedure Get_Runners (Race : in out Race_Type) is
   begin
      Sql.Prepare (Select_Runners, "select * from DRY_RUNNERS where MARKET_ID = :MARKET_ID order by BACK_PRICE");
      Sql.Set (Select_Runners, "MARKET_ID", Race.Market.Market_Id);
      Table_Dry_Runners.Read_List (Select_Runners, Race.Runners_List);
   end Get_Runners;
   ------------------------------------------------------------------------------

   procedure Get_Winners (Race : in out Race_Type) is
   begin
      Sql.Prepare (Select_Winners, "select * from DRY_RESULTS where MARKET_ID = :MARKET_ID");
      Sql.Set (Select_Winners, "MARKET_ID", Race.Market.Market_Id);
      Table_Dry_Results.Read_List (Select_Winners, Race.Winners_List);
   end Get_Winners;
   ------------------------------------------------------------------------------

   function No_Of_Runners (Race : in Race_Type) return Natural is
   begin
      return Table_Dry_Runners.Dry_Runners_List_Pack.Get_Count ( Race.Runners_List);
   end No_Of_Runners;
   ------------------------------------------------------------------------------

   function No_Of_Winners (Race : in Race_Type) return Natural is
   begin
      return Table_Dry_Results.Dry_Results_List_Pack.Get_Count ( Race.Winners_List);
   end No_Of_Winners;

   ------------------------------------------------------------------------------

   procedure Show_Runners (Race : in out Race_Type) is
      Runner : Table_Dry_Runners.Data_Type;
      Eol    : Boolean := False;
   begin
      Table_Dry_Runners.Dry_Runners_List_Pack.Get_First (Race.Runners_List, Runner, Eol);
      loop
         exit when Eol;
         Log ("Show_Runners " &  Table_Dry_Runners.To_String (Runner));
         Table_Dry_Runners.Dry_Runners_List_Pack.Get_Next (Race.Runners_List, Runner, Eol);
      end loop;

   end Show_Runners;
   ------------------------------------------------------------------------------
   procedure Get_Database_Data (Race_List   : in out Race_Package.List_Type;
                                Bet_Type    : in Bet_Name_Type;
                                Animal      : Animal_Type;
                                Start_Date  : Sattmate_Calendar.Time_Type;
                                Stop_Date   : Sattmate_Calendar.Time_Type
                               ) is
      T               : Sql.Transaction_Type;
      Race_Ptr        : Race_Pointer_Type;
      Market_List     : Table_Dry_Markets.Dry_Markets_List_Pack.List_Type := Table_Dry_Markets.Dry_Markets_List_Pack.Create;
      Market          : Table_Dry_Markets.Data_Type;
      Cnt             : Natural;

   begin
      Log ("Get_database_data start: ");
      Sql.Connect
        (Host     => "sebjlun-deb",
         Port     => 5432,
         Db_Name  => "betting",
         Login    => "bnl",
         Password => "bnl");
      Log ("connected to database");
      Sql.Start_Read_Write_Transaction (T);

      case Bet_Type is
         when Place =>
            Sql.Prepare (Select_Markets, "select * from " &
                           "DRY_MARKETS " &
                           "where cast(EVENT_DATE as date) >= :START_DATE " &
                           "and cast(EVENT_DATE as date) <= :STOP_DATE " &
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
                 "where cast(EVENT_DATE as date) >= :START_DATE " &
                 "and cast(EVENT_DATE as date) <= :STOP_DATE " &
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
      end case;
      Log ("reading markets from db into list");
      Table_Dry_Markets.Read_List (Select_Markets, Market_List);
      Log ("reading markets into list done");
      Cnt := Table_Dry_Markets.Dry_Markets_List_Pack.Get_Count (Market_List);
      Log ("antal marknader: " & Cnt'Img);
      Log ("read runners/winners from db into list");

      while not Table_Dry_Markets.Dry_Markets_List_Pack.Is_Empty  (Market_List) loop
         Table_Dry_Markets.Dry_Markets_List_Pack.Remove_From_Head (Market_List, Market);
         Race_Ptr := new Race_Type;
         Race_Ptr.Market := Market;
         Race_Ptr.Get_Runners;
         Race_Ptr.Get_Winners;
         Race_Package.Insert_At_Tail (Race_List, Race_Ptr.all);
         --         Race_Ptr.Show_Runners;
      end loop;
      Sql.Commit (T);
      Log ("read runners/winners from db into list done");
      Sql.Close_Session;
      Table_Dry_Markets.Dry_Markets_List_Pack.Release (Market_List);
      Log ("Get_database_data stop: ");
   end Get_Database_Data;
   ------------------------------------------------------------------------------

   function Ok_To_Make_Bet (Last_Loss         : in Sattmate_Calendar.Time_Type;
                            Event_Date        : in Sattmate_Calendar.Time_Type;
                            Profit            : in  Profit_Type ;
                            Max_Daily_Loss    : in Max_Daily_Loss_Type;
                            Max_Profit_Factor : in Max_Profit_Factor_Type ;
                            Size              : in Size_Type) return Boolean is
      Bet_Laid : Boolean := True;
   begin
      --      Log("Make_Lay_Bet - last_loss:" & Sattmate_Calendar.String_Date_And_Time(Last_Loss));
      -- are we allowed to bet at all? is this the day of the last loss ?
      -- then check if we lost more than allowed.
      if  Last_Loss.Day = Event_Date.Day and then
        Last_Loss.Month = Event_Date.Month and then
        Last_Loss.Year = Event_Date.Year then

         if Profit < Profit_Type (Max_Daily_Loss) then
            Log ("Ok_To_Make_Bet - Lost too much, no more bets today");
            Bet_Laid := False;
         end if;
      end if;
      -- won too much already today ?
      if Max_Profit_Factor > 0.0 then
         if Profit >= Profit_Type ((Size_Type (Max_Profit_Factor) * Size ) * 0.95 ) then
            Log ("Ok_To_Make_Bet - won enough for today, no more bets today");
            Bet_Laid := False;
         end if;
      end if;
      return Bet_Laid;
   end Ok_To_Make_Bet ;
   ------------------------------------------------------------------------------



   procedure Make_Lay_Bet (Race              : in out Race_Type;
                           Bet_Laid          : in out Boolean ;
                           Profit            : in  Profit_Type ;
                           Last_Loss         : in  Sattmate_Calendar.Time_Type;
                           Saldo             : in out Saldo_Type ;
                           Max_Daily_Loss    : in Max_Daily_Loss_Type;
                           Max_Profit_Factor : in Max_Profit_Factor_Type ;
                           Size              : in Size_Type;
                           Min_Price         : in Min_Price_Type;
                           Max_Price         : in Max_Price_Type )  is
      Runner   : Table_Dry_Runners.Data_Type;
      Eol      : Boolean := False;
      Found    : Boolean := False;
   begin
      Race.Selection_Id := 0;
      Race.Price := 0.0;
      Race.Size := 0.0;

      if not Ok_To_Make_Bet (Last_Loss         => Last_Loss,
                             Event_Date        => Race.Market.Event_Date,
                             Profit            => Profit,
                             Max_Daily_Loss    => Max_Daily_Loss,
                             Max_Profit_Factor => Max_Profit_Factor,
                             Size              => Size) then
         return;
      end if;

      -- ok see if we can make a bet.
      -- we want the last runner in the list, since the list
      -- is sorted on back-price, lowest first.
      -- we are looking for the runner with HIGHEST back-price.
      -- So get the last item in list
      -- Then we check that runners lay-price

      Table_Dry_Runners.Dry_Runners_List_Pack.Get_First (Race.Runners_List, Runner, Eol);
      loop
         exit when Eol;
         Found := True;
         Table_Dry_Runners.Dry_Runners_List_Pack.Get_Next (Race.Runners_List, Runner, Eol);
      end loop;
      Log ("last runner: " & Table_Dry_Runners.To_String (Runner));
      Log ("min price/maxprice: " & Integer (Min_Price)'Img & "/" & Integer (Max_Price)'Img);
      if Found then
         if Min_Price <= Min_Price_Type (Runner.Lay_Price) and then
           Max_Price_Type (Runner.Lay_Price) <= Max_Price then
            -- runner found ! make bet
            Race.Selection_Id := Runner.Selection_Id;
            Race.Size := Size;
            Race.Price := Price_Type (Runner.Lay_Price);
            Saldo := Saldo - Saldo_Type ((Size * Size_Type (Runner.Lay_Price)))  + Saldo_Type (Size);
            Bet_Laid := True;
            --          #312,59 -> 233.09. bet 30@3.65
            --          #312.59 - (30*3.65) + 30 = 233.09
            --           self.saldo = self.saldo - (self.size * lay_odds) + self.size
            --           self.num_taken_bets = self.num_taken_bets + 1
            Log ("make_lay_bet - Bet made on " & Table_Dry_Runners.To_String (Runner));
         else
            -- no good runner found !
            Log ("make_lay_bet - No good runner found, no bet");
            Bet_Laid := False;
            return;
         end if;
      else
         -- no runner found !
         Log ("make_lay_bet - No runner (at all) found, no bet");
         Bet_Laid := False;
         return;
      end if;
   end Make_Lay_Bet;
   ------------------------------------------------------------------------------
   procedure Make_Lay_Favorite_Bet
                          (Race              : in out Race_Type;
                           Bet_Laid          : in out Boolean ;
                           Profit            : in  Profit_Type ;
                           Last_Loss         : in Sattmate_Calendar.Time_Type;
                           Saldo             : in out Saldo_Type ;
                           Max_Daily_Loss    : in Max_Daily_Loss_Type;
                           Max_Profit_Factor : in Max_Profit_Factor_Type ;
                           Size              : in Size_Type;
                           Min_Price         : in Min_Price_Type;
                           Max_Price         : in Max_Price_Type ) is
      Runner   : Table_Dry_Runners.Data_Type;
      Eol      : Boolean := False;
      Found    : Boolean := False;
   begin
      Race.Selection_Id := 0;
      Race.Price := 0.0;
      Race.Size := 0.0;

      if not Ok_To_Make_Bet (Last_Loss         => Last_Loss,
                             Event_Date        => Race.Market.Event_Date,
                             Profit            => Profit,
                             Max_Daily_Loss    => Max_Daily_Loss,
                             Max_Profit_Factor => Max_Profit_Factor,
                             Size              => Size) then
         return;
      end if;


      -- ok see if we can make a bet.
      -- we will ALWAYS bet on the favorite will loose
      -- we want the first runner in the list, since the list
      -- is sorted on back-price, lowest first.
      -- we are looking for the runner with LOWEST back-price.
      -- So get the last item in list


      Table_Dry_Runners.Dry_Runners_List_Pack.Get_First (Race.Runners_List, Runner, Eol);
      Found := not Eol;
      Log ("make_lay_favorite_bet - first runner: " & Table_Dry_Runners.To_String (Runner));
      Log ("make_lay_favorite_bet  -min price/maxprice: " & Integer (Min_Price)'Img & "/" & Integer (Max_Price)'Img);
      if Found then
            -- runner found ! make bet
            Race.Selection_Id := Runner.Selection_Id;
            Race.Size := Size;
            Race.Price := Price_Type (Runner.Lay_Price);
            Saldo := Saldo - Saldo_Type ((Size * Size_Type (Runner.Lay_Price)))  + Saldo_Type (Size);
            Bet_Laid := True;
            --          #312,59 -> 233.09. bet 30@3.65
            --          #312.59 - (30*3.65) + 30 = 233.09
            --           self.saldo = self.saldo - (self.size * lay_odds) + self.size
            --           self.num_taken_bets = self.num_taken_bets + 1
            Log ("make_lay_favorite_bet - Bet made on " & Table_Dry_Runners.To_String (Runner));
      else
         -- no runner found !
         Log ("make_lay_favorite_bet - No runner (at all) found, no bet");
         Bet_Laid := False;
         return;
      end if;
   end Make_Lay_Favorite_Bet;

   ------------------------------------------------------------------------------
   procedure Make_Back_Bet (Race              : in out Race_Type;
                            Bet_Laid          : in out Boolean ;
                            Profit            : in  Profit_Type ;
                            Last_Loss         : in  Sattmate_Calendar.Time_Type;
                            Saldo             : in out Saldo_Type ;
                            Max_Daily_Loss    : in Max_Daily_Loss_Type;
                            Max_Profit_Factor : in Max_Profit_Factor_Type ;
                            Size              : in Size_Type;
                            Back_Price        : in Back_Price_Type;
                            Delta_Price       : in Delta_Price_Type )  is
      Runner   : Table_Dry_Runners.Data_Type;
      Eol      : Boolean := False;
      Found    : Boolean := False;
   begin
      Race.Selection_Id := 0;
      Race.Price := 0.0;
      Race.Size := 0.0;

      if not Ok_To_Make_Bet (Last_Loss         => Last_Loss,
                             Event_Date        => Race.Market.Event_Date,
                             Profit            => Profit,
                             Max_Daily_Loss    => Max_Daily_Loss,
                             Max_Profit_Factor => Max_Profit_Factor,
                             Size              => Size) then
         return;
      end if;

      -- ok see if we can make a bet.
      -- we want the first runner in the list, since the list
      -- is sorted on back-price, lowest first.
      -- we are looking for the runner with LOWEST back-price, the favorite.
      -- So get the first item in list
      -- Then we check that runners lay-price

      Table_Dry_Runners.Dry_Runners_List_Pack.Get_First (Race.Runners_List, Runner, Eol);
      Found := not Eol;
      Log ("first runner: " & Table_Dry_Runners.To_String (Runner));
      Log ("min price/deltaprice: " & Back_Price'Img & "/" & Delta_Price'Img);
      if Found then
         if Back_Price - Back_Price_Type(Delta_Price) <= Back_Price_Type(Runner.Back_Price) and then
           Back_Price_Type(Runner.Back_Price) <= Back_Price + Back_Price_Type(Delta_Price) then
            -- runner found ! make bet
            Race.Selection_Id := Runner.Selection_Id;
            Race.Size := Size;
            Race.Price := Price_Type (Runner.Back_Price);
            Saldo := Saldo - Saldo_Type (Size);
            Bet_Laid := True;
            --           self.num_taken_bets = self.num_taken_bets + 1
            Log ("make_back_bet - Bet made on " & Table_Dry_Runners.To_String (Runner));
         else
            -- no good runner found !
            Log ("make_back_bet - No good runner found, no bet");
            Bet_Laid := False;
            return;
         end if;
      else
         -- no runner found !
         Log ("make_back_bet - No runner (at all) found, no bet");
         Bet_Laid := False;
         return;
      end if;
   end Make_Back_Bet;
   -----------------------------------------------------------------------------
   procedure Check_Result (Race              : in out Race_Type;
                           Profit            : in out Profit_Type;
                           Last_Loss         : in out Sattmate_Calendar.Time_Type;
                           Saldo             : in out Saldo_Type ;
                           Bet_Type          : in Bet_Type_Type ) is
      Bet_Won     : Boolean := False;
      Winner      : Table_Dry_Results.Data_Type;
      Eol         : Boolean := False;
      Race_Profit : Profit_Type := 0.0;
   begin
      if Race.Selection_Id = 0 then
         Log ("check_result - No selection was made, no bet assumed");
         return;
      end if;

      case Bet_Type is
--           when Lay | Lay_Favorite =>
         when Lay =>
            Bet_Won := True;
            -- we win if selection not in winners
            Table_Dry_Results.Dry_Results_List_Pack.Get_First (Race.Winners_List, Winner, Eol);
            loop
               exit when Eol;
               if Winner.Selection_Id = Race.Selection_Id then
                  Bet_Won := False;
                  exit;
               end if;
               Table_Dry_Results.Dry_Results_List_Pack.Get_Next (Race.Winners_List, Winner, Eol);
            end loop;

            if Bet_Won then
               --  #312.59 -> 341.09 ( 5% commission?)
               --    # 30 * 3.65 = 109,5
               --    #233.09 + 109.5 - (30 * 0.05) = 341.09
               --    profit = (self.size * local_price) - (self.size * 0.05)
               Race_Profit := Profit_Type  (Race.Size * 0.95);

               Saldo := Saldo + Saldo_Type ((Race.Size * Size_Type (Race.Price)) - (Race.Size * 0.05));
            else
               Race_Profit :=  Profit_Type ( - ( (Race.Size * Size_Type (Race.Price)) + Race.Size));
               Last_Loss := Race.Market.Event_Date;
            end if;
            Profit := Profit + Race_Profit;

         when Back =>
            Bet_Won := False;
            -- we win if selection  in winners
            Table_Dry_Results.Dry_Results_List_Pack.Get_First (Race.Winners_List, Winner, Eol);
            loop
               exit when Eol;
               if Winner.Selection_Id = Race.Selection_Id then
                  Bet_Won := True;
                  exit;
               end if;
               Table_Dry_Results.Dry_Results_List_Pack.Get_Next (Race.Winners_List, Winner, Eol);
            end loop;

            if Bet_Won then
               -- profit = 0.95 * self.size * local_price
               Race_Profit := Profit_Type  (Race.Size * 0.95 * Size_Type(Race.Price));
               Saldo := Saldo + Saldo_Type(Race_Profit);
               --               Log ("check_result - saldo after check_result  " & Integer (Saldo)'Img);
            else
               Race_Profit := 0.0;
               Last_Loss := Race.Market.Event_Date;
            end if;
            Profit := Profit + Race_Profit;
      end case;
   end Check_Result;

   ------------------------------------------------------------------------------


end Races;
