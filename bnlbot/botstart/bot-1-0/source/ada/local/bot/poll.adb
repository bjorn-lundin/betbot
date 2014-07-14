--with Text_Io;
with Sattmate_Exception;
with Sattmate_Types; use Sattmate_Types;
with Bot_Types; use Bot_Types;
with Sql;
with General_Routines; use General_Routines;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Sattmate_Calendar; use Sattmate_Calendar;
with Bot_Messages;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Rpc;
with Lock ;
with Posix;
with Ini;
with Logging; use Logging;
with Ada.Environment_Variables;
with Process_IO;
with Core_Messages;
with Table_Amarkets;
with Table_Aevents;
with Table_Aprices;
--with Table_Abets;
--with Table_Arunners;
--with Table_Apricesfinish;
with Table_Abalances;
with Bot_Svn_Info;
with Bet;
with Config;

procedure Poll is
  package EV renames Ada.Environment_Variables;
  use type Rpc.Result_Type;

  Me : constant String := "Poll.";
  Timeout  : Duration := 120.0;
  My_Lock  : Lock.Lock_Type;
  Msg      : Process_Io.Message_Type;
  Find_Plc_Market : Sql.Statement_Type;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line : Command_Line_Configuration;

  Now : Sattmate_Calendar.Time_Type;
  Ok,
  Is_Time_To_Exit : Boolean := False;
  Cfg : Config.Config_Type;
  -------------------------------------------------------------
  
  procedure Run(Market_Notification : in     Bot_Messages.Market_Notification_Record) is
    Market    : Table_Amarkets.Data_Type;
    Event     : Table_Aevents.Data_Type;
    Price_List : Table_Aprices.Aprices_List_Pack.List_Type := Table_Aprices.Aprices_List_Pack.Create;
    
--    Price_Finish      : Table_Apricesfinish.Data_Type;   
--    Price_Finish_List : Table_Apricesfinish.Apricesfinish_List_Pack.List_Type := Table_Apricesfinish.Apricesfinish_List_Pack.Create;
    
    Price,Tmp : Table_Aprices.Data_Type;
    Has_Been_In_Play,
    In_Play   : Boolean := False;
    Best_Runners : array (1..3) of Table_Aprices.Data_Type := (others => Table_Aprices.Empty_Data);
    Eol,Eos : Boolean := False;
    type Market_Type is (Win, Place);
    Markets : array (Market_Type'range) of Table_Amarkets.Data_Type;
    Found_Place : Boolean := True;
    T : Sql.Transaction_Type;
    Current_Turn_Not_Started_Race : Integer_4 := 0;
    Betfair_Result : Rpc.Result_Type := Rpc.Result_Type'first;
    Saldo : Table_Abalances.Data_Type;
    
    type Bet_Type is (Back_Low, Back_Medium, Back_High, Lay_Low, 
	                  Back_Low_Marker, Back_Medium_Marker, Back_High_Marker );
    
    type Allowed_Type is record
      Bet_Name          : Bet_Name_Type := (others => ' ');
      Bet_Size          : Bet_Size_Type := Cfg.Size;
      Is_Allowed_To_Bet : Boolean := False;
      Has_Betted        : Boolean := False;
    end record;  
    
    Bets_Allowed : array (Bet_Type'range) of Allowed_Type;
    
  begin
    Log(Me & "Run", "Treat market: " &  Market_Notification.Market_Id);

    Market.Marketid := Market_Notification.Market_Id;

    -- Back_Low : 
    Move("HORSES_PLC_BACK_FINISH_1.10_7.0_1", Bets_Allowed(Back_Low).Bet_Name);
	
    -- Back_Medium : 
    Move("DR_HORSES_PLC_BACK_FINISH_1.15_7.0_1", Bets_Allowed(Back_Medium).Bet_Name);
--    Bets_Allowed(Back_Medium).Bet_Size := 30.0;
    
    -- Back_High : 
    Move("HORSES_PLC_BACK_FINISH_1.25_12.0_1", Bets_Allowed(Back_High).Bet_Name);
--    Bets_Allowed(Back_High).Bet_Size := 30.0;

    -- Lay_Low : 
    Move("DR_HORSES_WIN_LAY_FINISH_1.10_10.0_3", Bets_Allowed(Lay_Low).Bet_Name);
    Bets_Allowed(Lay_Low).Bet_Size := 30.0;
	 
	--markers
    -- Back_Low : 
    Move("MR_HORSES_PLC_BACK_FINISH_1.10_7.0_1", Bets_Allowed(Back_Low_Marker).Bet_Name);
    Bets_Allowed(Back_Low_Marker).Bet_Size := 30.0;
	
    -- Back_Medium : 
    Move("MR_HORSES_PLC_BACK_FINISH_1.15_7.0_1", Bets_Allowed(Back_Medium_Marker).Bet_Name);
    Bets_Allowed(Back_Medium_Marker).Bet_Size := 30.0;
	
    -- Back_High : 
    Move("MR_HORSES_PLC_BACK_FINISH_1.25_12.0_2", Bets_Allowed(Back_High_Marker).Bet_Name);
    Bets_Allowed(Back_High_Marker).Bet_Size := 30.0;
	 
    -- check if ok to bet and set bet size
    for i in Bets_Allowed'range loop
      Bets_Allowed(i).Is_Allowed_To_Bet := Bet.Profit_Today(Bets_Allowed(i).Bet_Name) >= Cfg.Max_Loss_Per_Day;
      if not Bets_Allowed(i).Is_Allowed_To_Bet then
        Log(Me & "Run", Trim(Bets_Allowed(i).Bet_Name) & " has lost too much today, max loss is " & F8_Image(Cfg.Max_Loss_Per_Day));
      end if;
    
      if 0.0 < Bets_Allowed(i).Bet_Size and then Bets_Allowed(i).Bet_Size < 1.0 then
        -- to have the size = a portion of the saldo. 
        Rpc.Get_Balance(Betfair_Result => Betfair_Result, Saldo => Saldo);
        Bets_Allowed(i).Bet_Size := Bets_Allowed(i).Bet_Size * Bet_Size_Type(Saldo.Balance);
        if Bets_Allowed(i).Bet_Size < 30.0 then
          Log(Me & "Run", "Bet_Size too small, set to 30.0, was " & F8_Image(Float_8( Bets_Allowed(i).Bet_Size)) & " " & Table_Abalances.To_String(Saldo));
          Bets_Allowed(i).Bet_Size := 30.0;
        end if;  
      end if;
      Log(Me & "Run", "Bet_Size " & F8_Image(Float_8( Bets_Allowed(i).Bet_Size)) & " " & Table_Abalances.To_String(Saldo));
    end loop;
    
    Bets_Allowed(Back_Medium).Is_Allowed_To_Bet := False;
    Bets_Allowed(Back_Medium_Marker).Is_Allowed_To_Bet := False;   
	
    Table_Amarkets.Read(Market, Eos);
    if not Eos then
      if  Market.Markettype(1..3) /= "WIN"  then
        Log(Me & "Run", "not a WIN market: " &  Market_Notification.Market_Id);
        return;
      else
        Event.Eventid := Market.Eventid;
        Table_Aevents.Read(Event, Eos);
        if not Eos then
          if Event.Eventtypeid /= Integer_4(7) then
            Log(Me & "Run", "not a HORSE market: " &  Market_Notification.Market_Id);
            return;
          elsif not Cfg.Country_Is_Ok(Event.Countrycode) then
            Log(Me & "Run", "not an OK country,  market: " &  Market_Notification.Market_Id);
            return;
          end if;
        else
          Log(Me & "Run", "no event found");
          return;
        end if;
      end if;
    else
      Log(Me & "Run", "no market found");
      return;
    end if;
    Markets(Win):= Market;

    T.Start;
      Find_Plc_Market.Prepare(
        "select MP.* from AMARKETS MW, AMARKETS MP " &
        "where MW.EVENTID = MP.EVENTID " &
        "and MW.STARTTS = MP.STARTTS " &
        "and MW.MARKETID = :WINMARKETID " &
        "and MP.MARKETTYPE = 'PLACE' " &
        "and MW.MARKETTYPE = 'WIN' " &
        "and MP.STATUS = 'OPEN'" ) ;

      Find_Plc_Market.Set("WINMARKETID", Markets(Win).Marketid);
      Find_Plc_Market.Open_Cursor;
      Find_Plc_Market.Fetch(Eos);
      if not Eos then
        Markets(Place) := Table_Amarkets.Get(Find_Plc_Market);
        if Markets(Win).Startts /= Markets(Place).Startts then
           Log(Me & "Make_Bet", "Wrong PLACE market found, give up");
           Found_Place := False;
        end if;
      else
        Log(Me & "Make_Bet", "no PLACE market found");
        Found_Place := False;
      end if;
      Find_Plc_Market.Close_Cursor;
    T.Commit;

    -- do the poll
    Poll_Loop : loop
--      while not Price_List.Is_Empty loop
--        Price_List.Remove_From_Head(Price);
--        Price_Finish := (
--           Marketid     => Price.Marketid,
--           Selectionid  => Price.Selectionid,
--           Pricets      => Price.Pricets,
--           Status       => Price.Status,
--           Totalmatched => Price.Totalmatched,
--           Backprice    => Price.Backprice,
--           Layprice     => Price.Layprice,
--           Ixxlupd      => Price.Ixxlupd,
--           Ixxluts      => Price.Ixxluts
--        );
--        Price_Finish_List.Insert_At_Tail(Price_Finish);
--      end loop;

      Table_Aprices.Aprices_List_Pack.Remove_All(Price_List);      
      Rpc.Get_Market_Prices(Market_Id  => Market_Notification.Market_Id,
                            Market     => Market,
                            Price_List => Price_List,
                            In_Play    => In_Play);

      exit Poll_Loop when Market.Status(1..4) /= "OPEN";

      if not Has_Been_In_Play then
        -- toggle the first time we see in-play=true
        -- makes us insensible to Betfair toggling bug
        Has_Been_In_Play := In_Play;
      end if;

      if not Has_Been_In_Play then
        if Current_Turn_Not_Started_Race >= Cfg.Max_Turns_Not_Started_Race then
           Log(Me & "Make_Bet", "Market took too long time to start, give up");
           exit Poll_Loop;
        else
          Current_Turn_Not_Started_Race := Current_Turn_Not_Started_Race +1;
          delay 30.0; -- no need for heavy polling before start of race
        end if;
      else
        delay 0.05; -- to avoid more than 20 polls/sec
      end if;
      
      -- ok find the runner with lowest backprice:
      Tmp := Table_Aprices.Empty_Data;
      Price.Backprice := 10000.0;
      Price_List.Get_First(Tmp,Eol);
      loop
        exit when Eol;
        if Tmp.Status(1..6) = "ACTIVE" and then
           Tmp.Backprice < Price.Backprice then
          Price := Tmp;
        end if;
        Price_List.Get_Next(Tmp,Eol);
      end loop;
      Best_Runners(1) := Price;

      -- find #2
      Tmp := Table_Aprices.Empty_Data;
      Price.Backprice := 10000.0;
      Price_List.Get_First(Tmp,Eol);
      loop
        exit when Eol;
        if Tmp.Status(1..6) = "ACTIVE" and then
           Tmp.Backprice < Price.Backprice and then
           Tmp.Selectionid /= Best_Runners(1).Selectionid then
          Price := Tmp;
        end if;
        Price_List.Get_Next(Tmp,Eol);
      end loop;
      Best_Runners(2) := Price;

      -- find #3
      Tmp := Table_Aprices.Empty_Data;
      Price.Backprice := 10000.0;
      Price_List.Get_First(Tmp,Eol);
      loop
        exit when Eol;
        if Tmp.Status(1..6) = "ACTIVE" and then
           Tmp.Backprice < Price.Backprice and then
           Tmp.Selectionid /= Best_Runners(1).Selectionid and then
           Tmp.Selectionid /= Best_Runners(2).Selectionid then
          Price := Tmp;
        end if;
        Price_List.Get_Next(Tmp,Eol);
      end loop;
      Best_Runners(3) := Price;

      for i in 1 .. 3 loop
        Log("Best_Runners(i) " & i'Img & Table_Aprices.To_String(Best_Runners(i)));
      end loop;

      if Best_Runners(1).Backprice >= Float_8(1.0) then
        if Found_Place and then Markets(Place).Numwinners >= Integer_4(3) then
          
          if Best_Runners(1).Backprice <= Float_8(1.10) and then
             Best_Runners(2).Backprice >= Float_8(7.0) and then
             Best_Runners(3).Layprice  >= Float_8(1.0)  then
            -- Back The leader in PLC market...
            declare
              PBB             : Bot_Messages.Place_Back_Bet_Record;
              Receiver        : Process_Io.Process_Type := ((others => ' '),(others => ' '));
              PBB_Marker      : Bot_Messages.Place_Back_Bet_Record;
              Receiver_Marker : Process_Io.Process_Type := ((others => ' '),(others => ' '));
			  Did_Bet_1,Did_Bet_2 : Boolean := False;
            begin
              -- number 1 in the race
              PBB.Bet_Name := Bets_Allowed(Back_Low).Bet_Name;
              Move(Markets(Place).Marketid, PBB.Market_Id);
              Move("1.01", PBB.Price);
              PBB.Selection_Id := Best_Runners(1).Selectionid;
			  
              if not Bets_Allowed(Back_Low).Has_Betted and then
                     Bets_Allowed(Back_Low).Is_Allowed_To_Bet then
                Move(F8_Image(Float_8(Bets_Allowed(Back_Low).Bet_Size)), PBB.Size);               
                Move("bet_placer_10" , Receiver.Name);
                Bot_Messages.Send(Receiver, PBB);
                Bets_Allowed(Back_Low).Has_Betted := True;
                Did_Bet_1 := True;				
			  end if;
			  
			  --marker
              if not Bets_Allowed(Back_Low_Marker).Has_Betted and then
                     Bets_Allowed(Back_Low_Marker).Is_Allowed_To_Bet then
                PBB_Marker := PBB;
                PBB_Marker.Bet_Name := Bets_Allowed(Back_Low_Marker).Bet_Name;
                Move(F8_Image(Float_8(Bets_Allowed(Back_Low_Marker).Bet_Size)), PBB_Marker.Size);               
                Move("bet_placer_11" , Receiver_Marker.Name);
                Bot_Messages.Send(Receiver_Marker, PBB_Marker);
                Bets_Allowed(Back_Low_Marker).Has_Betted := True;
                Did_Bet_2 := True;				
			  end if;
			  
              -- just to save time between logs
              if Did_Bet_1 then
                Log("ping '" &  Trim(Receiver.Name) & "' with bet '" & Trim(PBB.Bet_Name) & "' sel.id:" &  PBB.Selection_Id'Img );
	          end if;
			  
              if Did_Bet_2 then
                Log("ping '" &  Trim(Receiver_Marker.Name) & "' with bet '" & Trim(PBB_Marker.Bet_Name) & "' sel.id:" &  PBB_Marker.Selection_Id'Img );
	          end if;
            end;
          end if;
          
            -- Back The leader in PLC market again, but different requirements...
          if Best_Runners(1).Backprice <= Float_8(1.15) and then
             Best_Runners(2).Backprice >= Float_8(7.0) and then
             Best_Runners(3).Layprice  >= Float_8(1.0)  then
            -- Back The leader in PLC market...
            declare
              PBB             : Bot_Messages.Place_Back_Bet_Record;
              Receiver        : Process_Io.Process_Type := ((others => ' '),(others => ' '));
              PBB_Marker      : Bot_Messages.Place_Back_Bet_Record;
              Receiver_Marker : Process_Io.Process_Type := ((others => ' '),(others => ' '));
			  Did_Bet_1,Did_Bet_2 : Boolean := False;
            begin
              -- number 1 in the race
              PBB.Bet_Name := Bets_Allowed(Back_Medium).Bet_Name;
              Move(Markets(Place).Marketid, PBB.Market_Id);
              Move("1.01", PBB.Price);
              PBB.Selection_Id := Best_Runners(1).Selectionid;
			  
              if not Bets_Allowed(Back_Medium).Has_Betted and then
			         Bets_Allowed(Back_Medium).Is_Allowed_To_Bet then
                Move(F8_Image(Float_8(Bets_Allowed(Back_Medium).Bet_Size)), PBB.Size); 
                Move("bet_placer_20", Receiver.Name);
                Bot_Messages.Send(Receiver, PBB);
                Bets_Allowed(Back_Medium).Has_Betted := True;
				Did_Bet_1 := True;
	          end if;
			  
			  --Marker
              if not Bets_Allowed(Back_Medium_Marker).Has_Betted and then 
			         Bets_Allowed(Back_Medium_Marker).Is_Allowed_To_Bet then
                PBB_Marker := PBB;
                PBB_Marker.Bet_Name := Bets_Allowed(Back_Medium_Marker).Bet_Name;
                Move(F8_Image(Float_8(Bets_Allowed(Back_Medium_Marker).Bet_Size)), PBB_Marker.Size); 
                Move("bet_placer_21", Receiver_Marker.Name);
                Bot_Messages.Send(Receiver_Marker, PBB_Marker);
                Bets_Allowed(Back_Medium_Marker).Has_Betted := True;
				Did_Bet_2 := True;
	          end if;
			  
              if Did_Bet_1 then
                Log("ping '" &  Trim(Receiver.Name) & "' with bet '" & Trim(PBB.Bet_Name) & "' sel.id:" &  PBB.Selection_Id'Img );
	          end if;
			  
              if Did_Bet_2 then
                Log("ping '" &  Trim(Receiver_Marker.Name) & "' with bet '" & Trim(PBB_Marker.Bet_Name) & "' sel.id:" &  PBB_Marker.Selection_Id'Img );
	          end if;
            end;
          end if;
            
            -- Back The leader in PLC market again, but different requirements...
         
          if Best_Runners(1).Backprice <= Float_8(1.25) and then
             Best_Runners(3).Backprice >= Float_8(12.0) and then
             Best_Runners(3).Layprice  >= Float_8(1.0)  then
            -- Back The leader in PLC market...
            declare
              PBB             : Bot_Messages.Place_Back_Bet_Record;
              Receiver        : Process_Io.Process_Type := ((others => ' '),(others => ' '));
              PBB_Marker      : Bot_Messages.Place_Back_Bet_Record;
              Receiver_Marker : Process_Io.Process_Type := ((others => ' '),(others => ' '));
			  Did_Bet_1,Did_Bet_2 : Boolean := False;
            begin
              -- number 1 in the race
              Move(Markets(Place).Marketid, PBB.Market_Id);
              Move("1.01", PBB.Price);
              PBB.Selection_Id := Best_Runners(1).Selectionid;
			  
             if not Bets_Allowed(Back_High).Has_Betted and then
                    Bets_Allowed(Back_High).Is_Allowed_To_Bet then
                PBB.Bet_Name := Bets_Allowed(Back_High).Bet_Name;
                Move(F8_Image(Float_8(Bets_Allowed(Back_High).Bet_Size)), PBB.Size); 
                Move("bet_placer_30", Receiver.Name);
                Bot_Messages.Send(Receiver, PBB);
                Bets_Allowed(Back_High).Has_Betted := True;
				Did_Bet_1 := True;
			  end if;
			  
			  --marker
             if not Bets_Allowed(Back_High_Marker).Has_Betted and then
                    Bets_Allowed(Back_High_Marker).Is_Allowed_To_Bet then
                PBB_Marker := PBB;
                PBB_Marker.Bet_Name := Bets_Allowed(Back_High_Marker).Bet_Name;
                Move(F8_Image(Float_8(Bets_Allowed(Back_High_Marker).Bet_Size)), PBB_Marker.Size); 
                Move("bet_placer_31", Receiver_Marker.Name);
                Bot_Messages.Send(Receiver_Marker, PBB_Marker);
                Bets_Allowed(Back_High_Marker).Has_Betted := True;
				Did_Bet_2 := True;
			  end if;
			  
              if Did_Bet_1 then
                Log("ping '" &  Trim(Receiver.Name) & "' with bet '" & Trim(PBB.Bet_Name) & "' sel.id:" &  PBB.Selection_Id'Img );
	          end if;
			  
              if Did_Bet_2 then
                Log("ping '" &  Trim(Receiver_Marker.Name) & "' with bet '" & Trim(PBB_Marker.Bet_Name) & "' sel.id:" &  PBB_Marker.Selection_Id'Img );
	          end if;
            end;
          end if;
          
            -- Back The leader in PLC market again, but different requirements...
          if not Bets_Allowed(Lay_Low).Has_Betted and then
             Bets_Allowed(Lay_Low).Is_Allowed_To_Bet and then
             Best_Runners(1).Backprice <= Float_8(1.10) and then
             Best_Runners(2).Backprice >= Float_8(10.0) and then
             Best_Runners(3).Layprice  >= Float_8(1.0) and then
             Best_Runners(3).Layprice  <= Float_8(25.0) then
            declare
              PLB : Bot_Messages.Place_Lay_Bet_Record;
              Receiver : Process_Io.Process_Type := ((others => ' '),(others => ' '));
            begin
              -- number 3 in the race
              PLB.Bet_Name := Bets_Allowed(Lay_Low).Bet_Name;
              Move(Markets(Win).Marketid, PLB.Market_Id);
--              Move("25", PLB.Price);
              Move(F8_Image(Best_Runners(3).Layprice), PLB.Price);
              Move(F8_Image(Float_8(Bets_Allowed(Lay_Low).Bet_Size)), PLB.Size); 
              PLB.Selection_Id := Best_Runners(3).Selectionid;
              Move("bet_placer_31", Receiver.Name);
              Log("ping '" &  Trim(Receiver.Name) & "' with bet '" & Trim(PLB.Bet_Name) & "' sel.id:" &  PLB.Selection_Id'Img );
              Bot_Messages.Send(Receiver, PLB);
              Bets_Allowed(Lay_Low).Has_Betted := True;
            end;
          end if;

        end if;
      end if;
    end loop Poll_Loop;
    
--    -- insert all the records now, in pricefinsih
--    Log("start insert records into Pricefinish:" & Price_Finish_List.Get_Count'Img);
--    T.Start;
--    begin
--      while not Price_Finish_List.Is_Empty loop
--        Price_Finish_List.Remove_From_Head(Price_Finish);
--        -- Log("will insert " & Price_Finish.To_String);
--        Price_Finish.Insert;
--      end loop;
--    T.Commit;
--    exception
--      when Sql.Duplicate_Index => 
--         Log("Duplicate index " & Price_Finish.To_String);
--         Price_Finish_List.Remove_All;
--         T.Rollback;
--    end;
--    Log("stop insert record into Pricefinish");
--    Price_Finish_List.Release;
    Price_List.Release;
  end Run;
  ---------------------------------------------------------------------
  use type Sql.Transaction_Status_Type;
------------------------------ main start -------------------------------------

begin

   Define_Switch
    (Cmd_Line,
     Sa_Par_Bot_User'access,
     Long_Switch => "--user=",
     Help        => "user of bot");

   Define_Switch
     (Cmd_Line,
      Ba_Daemon'access,
      Long_Switch => "--daemon",
      Help        => "become daemon at startup");

   Define_Switch
     (Cmd_Line,
      Sa_Par_Inifile'access,
      Long_Switch => "--inifile=",
      Help        => "use alternative inifile");

  Getopt (Cmd_Line);  -- process the command line

  if Ba_Daemon then
    Posix.Daemonize;
  end if;

   --must take lock AFTER becoming a daemon ...
   --The parent pid dies, and would release the lock...
  My_Lock.Take(EV.Value("BOT_NAME"));

  Logging.Open(EV.Value("BOT_HOME") & "/log/poll.log");

  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  Cfg := Config.Create(Ev.Value("BOT_HOME") & "/" & Sa_Par_Inifile.all);
  Log(Cfg.To_String);
  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("database", "host", ""),
         Port     => Ini.Get_Value("database", "port", 5432),
         Db_Name  => Ini.Get_Value("database", "name", ""),
         Login    => Ini.Get_Value("database", "username", ""),
         Password =>Ini.Get_Value("database", "password", ""));
  Log(Me, "db Connected");
    -- Ask a pythonscript to login for us, returning a token
  Log(Me, "Login betfair");
  Rpc.Init(
            Username   => Ini.Get_Value("betfair","username",""),
            Password   => Ini.Get_Value("betfair","password",""),
            Product_Id => Ini.Get_Value("betfair","product_id",""),
            Vendor_Id  => Ini.Get_Value("betfair","vendor_id",""),
            App_Key    => Ini.Get_Value("betfair","appkey","")
          );
  Rpc.Login;
  Log(Me, "Login betfair done");

  if Cfg.Enabled then
    Cfg.Enabled := Ev.Value("BOT_MACHINE_ROLE") = "PROD";
  end if;

  Main_Loop : loop
    begin
      Log(Me, "Start receive");
      Process_Io.Receive(Msg, Timeout);
      Log(Me, "msg : "& Process_Io.Identity(Msg)'Img & " from " & Trim(Process_Io.Sender(Msg).Name));
      if Sql.Transaction_Status /= Sql.None then
        raise Sql.Transaction_Error with "Uncommited transaction in progress !! BAD!";
      end if;
      case Process_Io.Identity(Msg) is
        when Core_Messages.Exit_Message                  =>
          exit Main_Loop;
        when Bot_Messages.Market_Notification_Message    =>
          if Cfg.Enabled then
            Run(Bot_Messages.Data(Msg));
          else
            Log(Me, "Poll is not eanbled in poll.ini");
          end if;
        when others =>
          Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Rpc.Keep_Alive(OK);
        if not OK then
          Rpc.Login;
        end if;
    end;
    Now := Sattmate_Calendar.Clock;

    --restart every day
    Is_Time_To_Exit := Now.Hour = 01 and then
                     ( Now.Minute = 00 or Now.Minute = 01) ; -- timeout = 2 min

    exit Main_Loop when Is_Time_To_Exit;

  end loop Main_Loop;

  Log(Me, "Close Db");
  Sql.Close_Session;
  Rpc.Logout;
  Logging.Close;
  Posix.Do_Exit(0); -- terminate

exception
  when Lock.Lock_Error =>
    Log(Me, "lock error, exit");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
  when E: others => Sattmate_Exception.Tracebackinfo(E);
--    Log(Me, "Close Db");
--    Sql.Close_Session;
    Log(Me, "Closed log and die");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
end Poll;

