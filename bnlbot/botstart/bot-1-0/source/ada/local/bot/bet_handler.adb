
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Logging; use Logging;
with Gnatcoll.Json; use Gnatcoll.Json;
with Bot_Config; use Bot_Config;
with Bets;
with Sql;
with Calendar2;
with Rpc;

with Utils; --use Utils;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Markets;
with Runners;

package body Bet_Handler is


  Update_Betwon_To_Null,
  Select_Dry_Run_Bets,
  Select_Real_Bets,
  Select_Unsettled_Markets,
  Select_Executable_Bets,
  Select_Ongoing_Markets : Sql.Statement_Type;

  Me : constant String := "Bet_Handler.";

  -------------------------------------------------
   procedure Check_Bets is
    use Utils;
    Bet_List : Bets.List_Pack.List;
    Bet,Bet_From_List      : Bets.Bet_Type;
    T        : Sql.Transaction_Type;
    Illegal_Data : Boolean := False;
    Side       : Bet_Side_Type;
    Runner     : Runners.Runner_Type;
    type Eos_Type is (Arunner ,
                      Abets);
    Eos        : array (Eos_Type'range) of Boolean := (others => False);
    Selection_In_Winners,
    Bet_Won               : Boolean := False;
    Profit                : Float_8 := 0.0;
    Start_Ts              : Calendar2.Time_Type := Calendar2.Time_Type_First;
    Stop_Ts               : Calendar2.Time_Type := Calendar2.Time_Type_Last;

    Rpc_Status : Rpc.Result_Type;
    use type Calendar2.Time_Type;
    Do_Update : Boolean := True;
  begin
    Log(Me & "Check_Bets", "start");
    
    -- update ARUNNERS.STATUS with real result...    
    -- is done by Winners_Fetcher_Json
    --Get result, set status=PRELIMINARY for real bets   

    T.Start;
    -- check the dry run bets
    Select_Dry_Run_Bets.Prepare(
      "select B.* from ABETS B, AMARKETS M " &
      "where B.MARKETID = M.MARKETID " &
      "and B.BETWON is null " & -- will be not null if updated
--      "and B.BETID < 1000000000 " & -- ALL BETS
      "and M.STATUS in ('SUSPENDED','SETTLED','CLOSED') " & -- does 'SETTLED' exist?
      "and exists (select 'a' from ARUNNERS where ARUNNERS.MARKETID = B.MARKETID and ARUNNERS.STATUS = 'WINNER')" ); -- must have had time to check ...  
    Bets.Read_List(Select_Dry_Run_Bets, Bet_List);
    T.Commit;

    for b of Bet_List loop
      Log(Me & "Check_Bets", "betlist " & B.To_String);
    end loop;
    
    Inner : for b of Bet_List  loop
      Bet := b;
      Illegal_Data := False;
      Log(Me & "Check_Bets", "Check bet " & Bet.To_String);
      if Trim(Bet.Side) = "BACK" then
        Side := Back;
      elsif Trim(Bet.Side(1..3)) = "LAY" then --lay + lay1-lay6
        Side := Lay;
      else
        Illegal_Data := True;
        Log(Me & "Check_Bets", "Illegal_Data ! side -> " &  Trim(Bet.Side));
      end if;
      if not Illegal_Data then
        Runner.Marketid := Bet.Marketid;
        Runner.Selectionid := Bet.Selectionid;
        Runner.Read(Eos(Arunner));

        if not Eos(Arunner) then
        -- do we have a non-runner?
          if Runner.Status(1..7) = "REMOVED" then
            -- non -runner - void the bet
            Bet.Betwon := True;
            Bet.Profit := 0.0;
            begin
              T.Start;
              Log(Me & "Check_Bets", " 1 " & Bet.To_String);
              Bet.Update_Withcheck;
              Log(Me & "Check_Bets", " 2 " & Bet.To_String);
              T.Commit;
            exception
              when Sql.No_Such_Row =>
                T.Rollback; -- let the other one do the update
                exit;
            end ;
          elsif Runner.Status(1..6) = "WINNER" then
          -- this one won
            Selection_In_Winners := True;
          elsif Runner.Status(1..5) = "LOSER" then
          -- this one won
            Selection_In_Winners := False;
          else
            Log(Me & "Check_Bets", "unknown runner status, exit '" & Runner.Status & "'");
            exit Inner;
          end if;
        else
            Log(Me & "Check_Bets", "runner not found ?? " & Runner.To_String);
            exit Inner;
        end if;

        case Side is
          when Back    => Bet_Won := Selection_In_Winners;
          when Lay     => Bet_Won := not Selection_In_Winners;
        end case;

        if Bet_Won then
          case Side is     -- Betfair takes 5% provision on winnings, but 5% per market,
                           -- so it won't do to calculate per bet. leave that to the sql-script summarising
            when Back    => Profit := 1.0 * Bet.Sizematched * (Bet.Pricematched - 1.0);
            when Lay     => Profit := 1.0 * Bet.Sizematched;
          end case;
        else -- lost :-(
          case Side is
            when Back    => Profit := - Bet.Sizematched;
            when Lay     => Profit := - Bet.Sizematched * (Bet.Pricematched - 1.0);
          end case;
        end if;

        Bet.Betwon := Bet_Won;
        Bet.Profit := Profit;
        if Bet.Betid > 1_000_000_000 then -- a real bet
          Bet.Status := (others => ' ');
          Move("PRELIMINARY", Bet.Status);            
        end if;
        
        begin
          T.Start;
              Log(Me & "Check_Bets", " 3 " & Bet.To_String);
          Bet.Update_Withcheck;
              Log(Me & "Check_Bets", " 4 " & Bet.To_String);
          T.Commit;
        exception
          when Sql.No_Such_Row =>
             T.Rollback; -- let the other one do the update
             exit Inner;
        end ;
      end if; -- Illegal data
    end loop Inner;

    -- check the real bets
    -- BET_STATUS='PRELIMINARY'
    T.Start;
    Select_Real_Bets.Prepare(
      "select min(STARTTS) from ABETS where STATUS = 'PRELIMINARY' ");

    Select_Real_Bets.Open_Cursor;
    Select_Real_Bets.Fetch(Eos(Abets));
    if not Eos(Abets) then
      Select_Real_Bets.Get_Timestamp(1, Start_Ts);
      Stop_Ts := Start_Ts + (1,0,0,0,0); -- 1 day
    end if;
    Select_Real_Bets.Close_Cursor;
    T.Commit;

    if Start_Ts = Calendar2.Time_Type_First then
      Eos(Abets) := True;
    end if;
    
    if not Eos(Abets) then
      for i in Cleared_Bet_Status_Type'range loop
        Rpc.Get_Cleared_Bet_Info_List(Bet_Status     => i,
                                      Settled_From   => Start_Ts,
                                      Settled_To     => Stop_Ts,
                                      Betfair_Result => Rpc_Status,
                                      Bet_List       => Bet_List) ;
      end loop;

      for b of Bet_List loop
        Bet_From_List := b;
        -- Call Betfair here ! Profit & Loss
        Bet := Bets.Empty_Data;
        Bet.Betid := Bet_From_List.Betid;
        Bet.Read(Eos(Abets));
        Log(Me & "Check_Bets", "Betid" & Bet.Betid'Img & " Eos(Abets) = " & Eos(Abets)'Img);
        if not Eos(Abets) then
          Bet.Pricematched := Bet_From_List.Pricematched;
          Bet.Sizematched  := Bet_From_List.Sizematched;
          Bet.Profit       := Bet_From_List.Profit;
          Bet.Status       := Bet_From_List.Status;
          Bet.Betwon       := Bet.Profit >= 0.0;
          Log(Me & "Check_Bets", "Betid" & Bet.Betid'Img & " status = " & Bet.Status);
  
          Do_Update := Bet.Status(1..6) /= "VOIDED";
          if not Do_Update then
            Do_Update := Bet.Status(1..9) /= "CANCELLED";
          end if;          
          if not Do_Update then
            Do_Update := Bet.Status(1..6) /= "LAPSED";
          end if;          
          if not Do_Update then
            Do_Update := Bet.Status(1..7) /= "SETTLED";
          end if;          
  
          Log(Me & "Check_Bets", "Betid" & Bet.Betid'Img & " Do_Update = " & Do_Update'Img);
  
          if Do_Update then          
            begin
              T.Start;
              Bet.Update_Withcheck;
              T.Commit;
              Log(Me & "Check_Bets", "Betid" & Bet.Betid'Img & " updated status to " &  Bet.Status);
            exception
              when Sql.No_Such_Row =>
                 T.Rollback; -- let the other one do the update
                 Log(Me & "Check_Bets", "No_Such_Row!! " & Bet.To_String);
            end ;
          end if;              
        else
          Log(Me & "Check_Bets", "EOS!! " & Bet.To_String);
        end if;
      end loop;
      
    end if;
    Log(Me & "Check_Bets", "stop");
  end Check_Bets;
  ------------------------------------------------------------------------------

  procedure Check_If_Bet_Accepted is
    T                 : Sql.Transaction_Type;
    Bet_List          : Bets.List_Pack.List;
    Bet               : Bets.Bet_Type;
    Avg_Price_Matched : Bet_Price_Type := 0.0;
    Is_Matched,
    Is_Removed        : Boolean        := False;
    Size_Matched      : Bet_Size_Type  := 0.0;
  begin
    Log(Me & "Check_If_Bet_Accepted", "start");
    T.Start;
    -- check the real bets
    Select_Executable_Bets.Prepare(
      "select B.* from ABETS B, AMARKETS M " &
      "where B.MARKETID = M.MARKETID " & -- all bets, until profit and loss are fixed in API-NG
      "and M.STATUS in ('CLOSED','SETTLED','SUSPENDED') " & -- This is not updated!!!
      "and B.BETWON is null " & -- all bets, until profit and loss are fixed in API-NG
      "and B.BETID > 1000000000 " & -- no dry_run bets
--      "and B.IXXLUPD = :BOTNAME " & --only fix my bets, so no rollbacks ...
      "and B.STATUS = 'EXECUTABLE' "); --only not acctepted bets ...

    Bets.Read_List(Select_Executable_Bets, Bet_List);

    for b of Bet_List loop
      Bet := b;
      Log(Me & "Check_If_Bet_Accepted", "Check bet " & Bet.To_String);

      RPC.Bet_Is_Matched(Bet.Betid, Is_Removed, Is_Matched, Avg_Price_Matched, Size_Matched);

      if Is_Matched then
        Log(Me & "Check_If_Bet_Accepted", "update bet " & Bet.To_String);
        Bet.Status := (others => ' ');
        if Is_Removed then
          Move("EXECUTABLE_NO_MATCH", Bet.Status); --?
        else
          Move("EXECUTION_COMPLETE", Bet.Status);
          Bet.Pricematched := Float_8(Avg_Price_Matched);
          Bet.Sizematched := Float_8(Size_Matched);
        end if;
        Log(Me & "Check_If_Bet_Accepted", "update bet " & Bet.To_String);
        Bet.Update_Withcheck;
        Update_Betwon_To_Null.Prepare("update ABETS set BETWON = null where BETID = :BETID");
        Update_Betwon_To_Null.Set("BETID", Bet.Betid);
        Update_Betwon_To_Null.Execute;
      end if;
    end loop;
    T.Commit;
    Log(Me & "Check_If_Bet_Accepted", "stop");

  end Check_If_Bet_Accepted;
 ---------------------------------------------------------------------------------

  procedure Check_Market_Status is
    T : Sql.Transaction_Type;
    Market_List : Markets.Lists.List;
    Market      : Markets.Market_Type;
    Is_Changed  : Boolean        := False;

  begin
    Log(Me & "Check_Market_Status", "start");
    
    case Bot_Config.Config.System_Section.Bot_Mode is 
      when Real =>
        loop
          begin
            T.Start;
            Select_Ongoing_Markets.Prepare(
              "select M.* from AMARKETS M " &
              "where M.STATUS <> 'CLOSED' order by M.STARTTS");
            Markets.Read_List(Select_Ongoing_Markets, Market_List);
         
            for m of Market_List loop
              Log(Me & "Check_Market_Status", Market_List.Length'Img & " market left to check");
              Market := m;
              Log(Me & "Check_Market_Status", "checking " & Market.Marketid); --Table_Amarkets.To_String(Market));
              RPC.Market_Status_Is_Changed(Market, Is_Changed);
         
              if Is_Changed then
                Log(Me & "Check_Market_Status", "update market " & Market.To_String);
                Market.Update_Withcheck;
              end if;
            end loop;
            T.Commit;
            exit;
          exception
            when Sql.No_Such_Row => 
              Log(Me & "Check_Market_Status", "trf conflict update market " & Market.To_String);
              T.Rollback;
              Market_List.Clear;
          end;          
        end loop;       
        
      when Simulation => null;
    end case;       
    Log(Me & "Check_Market_Status", "stop");
  end Check_Market_Status;
 ---------------------------------------------------------------------------------

  procedure Check_Unsettled_Markets(Inserted_Winner : in out Boolean) is
    T : Sql.Transaction_Type;
    Db_Runner : Runners.Runner_Type;
    Runner_List : Runners.Lists.List;
    Market_List : Markets.Lists.List;
    type Eos_Type is ( Arunners);
    Eos : array (Eos_Type'range) of Boolean := (others => False);
  begin
    Log (Me & "Check_Unsettled_Markets", "Check_Unsettled_Markets start");
    Inserted_Winner := False;
    T.Start;
    Select_Unsettled_Markets.Prepare(
      "select * from AMARKETS where MARKETID in ( " &
          "select distinct(M.MARKETID) " &
          "from AMARKETS M, ARUNNERS R " &
          "where M.MARKETID = R.MARKETID " &
          "and M.STATUS in ('SETTLED','CLOSED') " &
          "and R.STATUS in ('', 'NOT_SET_YET') ) " &
      "order by STARTTS" );

      Markets.Read_List(Select_Unsettled_Markets, Market_List);

      Market_Loop : for Market of Market_List loop
        Rpc.Check_Market_Result(Market_Id   => Market.Marketid,
                                Runner_List => Runner_List);

        Runner_Loop : for List_Runner of Runner_List loop
          Db_Runner := List_Runner;

          Db_Runner.Read( Eos(Arunners));
          if Eos(Arunners) then
            Log (Me & "Check_Unsettled_Markets", "missing runner in db !! " & Db_Runner.To_String);
          else
            Db_Runner.Status := List_Runner.Status;
            if Db_Runner.Status(1..2) = "WI" then
              Log (Me & "Check_Unsettled_Markets", "Got winner : " & Db_Runner.To_String);
              Inserted_Winner := True;
            end if;
            Db_Runner.Update_Withcheck;
          end if;

        end loop Runner_Loop;
      end loop Market_Loop;
    Sql.Commit (T);
    Log (Me & "Check_Unsettled_Markets", "Check_Unsettled_Markets stop");
  exception
    when Sql.Duplicate_Index =>
      Sql.Rollback(T);
      Log (Me & "Check_Unsettled_Markets", "Check_Unsettled_Markets Duplicate index");
      Inserted_Winner := False;
  end Check_Unsettled_Markets;

  -----------------------------------------------------------------------------------


end Bet_Handler;
