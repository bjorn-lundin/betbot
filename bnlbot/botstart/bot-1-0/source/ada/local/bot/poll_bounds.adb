with Ada.Exceptions;
with Ada.Command_Line;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
--with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Environment_Variables;
with Ada.Containers.Doubly_Linked_Lists;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

with Stacktrace;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Sql;
with Calendar2; use Calendar2;
with Bot_Messages;
with Rpc;
with Lock ;
with Posix;
with Ini;
with Logging; use Logging;
with Process_IO;
with Core_Messages;
with Table_Amarkets;
with Table_Aevents;
with Table_Aprices;
--with Table_Abalances;
with Table_Abets;
--with Table_Apriceshistory;
with Bot_Svn_Info;
with Utils; use Utils;

procedure Poll_Bounds is
  package EV renames Ada.Environment_Variables;
  use type Rpc.Result_Type;

  Me              : constant String := "Poll.";
  Timeout         : Duration := 120.0;
  My_Lock         : Lock.Lock_Type;
  Msg             : Process_Io.Message_Type;
  Find_Plc_Market : Sql.Statement_Type;
--  Select_Bet_Size_Portion_Back : Sql.Statement_Type;
  --Select_Bet_Profit : Sql.Statement_Type;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line        : Command_Line_Configuration;
  Now             : Calendar2.Time_Type;
  Ok,
  Is_Time_To_Exit : Boolean := False;

  type Market_Type is (Win, Place);
  type Best_Runners_Array_Type is array (1..4) of Table_Aprices.Data_Type ;

  Data : Bot_Messages.Poll_State_Record ;
  This_Process    : Process_Io.Process_Type := Process_IO.This_Process;
  Markets_Fetcher : Process_Io.Process_Type := (("markets_fetcher"),(others => ' '));

  -------------------------------------------------------------
  type Bet_Type is (
      Back_1_01_1_05_01_07_1_2_WIN, 
      Back_1_01_1_05_08_10_1_2_WIN, 
      Back_1_01_1_05_11_13_1_2_WIN, 
      Back_1_01_1_05_14_17_1_2_WIN, 
      Back_1_01_1_05_18_20_1_2_WIN, 
      Back_1_01_1_05_21_23_1_2_WIN, 
      Back_1_01_1_05_24_26_1_2_WIN, 
      Back_1_01_1_05_27_30_1_2_WIN, 
      Back_1_01_1_05_31_33_1_2_WIN, 
      Back_1_01_1_05_34_37_1_2_WIN, 
      Back_1_01_1_05_38_40_1_2_WIN, 

      Back_1_06_1_10_01_07_1_2_WIN, 
      Back_1_06_1_10_08_10_1_2_WIN, 
      Back_1_06_1_10_11_13_1_2_WIN, 
      Back_1_06_1_10_14_17_1_2_WIN, 
      Back_1_06_1_10_18_20_1_2_WIN, 
      Back_1_06_1_10_21_23_1_2_WIN, 
      Back_1_06_1_10_24_26_1_2_WIN, 
      Back_1_06_1_10_27_30_1_2_WIN, 
      Back_1_06_1_10_31_33_1_2_WIN, 
      Back_1_06_1_10_34_37_1_2_WIN, 
      Back_1_06_1_10_38_40_1_2_WIN, 

      Back_1_11_1_15_01_07_1_2_WIN, 
      Back_1_11_1_15_08_10_1_2_WIN, 
      Back_1_11_1_15_11_13_1_2_WIN, 
      Back_1_11_1_15_14_17_1_2_WIN, 
      Back_1_11_1_15_18_20_1_2_WIN, 
      Back_1_11_1_15_21_23_1_2_WIN, 
      Back_1_11_1_15_24_26_1_2_WIN, 
      Back_1_11_1_15_27_30_1_2_WIN, 
      Back_1_11_1_15_31_33_1_2_WIN, 
      Back_1_11_1_15_34_37_1_2_WIN, 
      Back_1_11_1_15_38_40_1_2_WIN, 

      Back_1_16_1_20_01_07_1_2_WIN, 
      Back_1_16_1_20_08_10_1_2_WIN, 
      Back_1_16_1_20_11_13_1_2_WIN, 
      Back_1_16_1_20_14_17_1_2_WIN, 
      Back_1_16_1_20_18_20_1_2_WIN, 
      Back_1_16_1_20_21_23_1_2_WIN, 
      Back_1_16_1_20_24_26_1_2_WIN, 
      Back_1_16_1_20_27_30_1_2_WIN, 
      Back_1_16_1_20_31_33_1_2_WIN, 
      Back_1_16_1_20_34_37_1_2_WIN, 
      Back_1_16_1_20_38_40_1_2_WIN, 

      Back_1_21_1_25_01_07_1_2_WIN, 
      Back_1_21_1_25_08_10_1_2_WIN, 
      Back_1_21_1_25_11_13_1_2_WIN, 
      Back_1_21_1_25_14_17_1_2_WIN, 
      Back_1_21_1_25_18_20_1_2_WIN, 
      Back_1_21_1_25_21_23_1_2_WIN, 
      Back_1_21_1_25_24_26_1_2_WIN, 
      Back_1_21_1_25_27_30_1_2_WIN, 
      Back_1_21_1_25_31_33_1_2_WIN, 
      Back_1_21_1_25_34_37_1_2_WIN, 
      Back_1_21_1_25_38_40_1_2_WIN, 

      Back_1_26_1_30_01_07_1_2_WIN, 
      Back_1_26_1_30_08_10_1_2_WIN, 
      Back_1_26_1_30_11_13_1_2_WIN, 
      Back_1_26_1_30_14_17_1_2_WIN, 
      Back_1_26_1_30_18_20_1_2_WIN, 
      Back_1_26_1_30_21_23_1_2_WIN, 
      Back_1_26_1_30_24_26_1_2_WIN, 
      Back_1_26_1_30_27_30_1_2_WIN, 
      Back_1_26_1_30_31_33_1_2_WIN, 
      Back_1_26_1_30_34_37_1_2_WIN, 
      Back_1_26_1_30_38_40_1_2_WIN, 

      Back_1_31_1_35_01_07_1_2_WIN, 
      Back_1_31_1_35_08_10_1_2_WIN, 
      Back_1_31_1_35_11_13_1_2_WIN, 
      Back_1_31_1_35_14_17_1_2_WIN, 
      Back_1_31_1_35_18_20_1_2_WIN, 
      Back_1_31_1_35_21_23_1_2_WIN, 
      Back_1_31_1_35_24_26_1_2_WIN, 
      Back_1_31_1_35_27_30_1_2_WIN, 
      Back_1_31_1_35_31_33_1_2_WIN, 
      Back_1_31_1_35_34_37_1_2_WIN, 
      Back_1_31_1_35_38_40_1_2_WIN, 

      Back_1_36_1_40_01_07_1_2_WIN, 
      Back_1_36_1_40_08_10_1_2_WIN, 
      Back_1_36_1_40_11_13_1_2_WIN, 
      Back_1_36_1_40_14_17_1_2_WIN, 
      Back_1_36_1_40_18_20_1_2_WIN, 
      Back_1_36_1_40_21_23_1_2_WIN, 
      Back_1_36_1_40_24_26_1_2_WIN, 
      Back_1_36_1_40_27_30_1_2_WIN, 
      Back_1_36_1_40_31_33_1_2_WIN, 
      Back_1_36_1_40_34_37_1_2_WIN, 
      Back_1_36_1_40_38_40_1_2_WIN, 

      Back_1_41_1_45_01_07_1_2_WIN, 
      Back_1_41_1_45_08_10_1_2_WIN, 
      Back_1_41_1_45_11_13_1_2_WIN, 
      Back_1_41_1_45_14_17_1_2_WIN, 
      Back_1_41_1_45_18_20_1_2_WIN, 
      Back_1_41_1_45_21_23_1_2_WIN, 
      Back_1_41_1_45_24_26_1_2_WIN, 
      Back_1_41_1_45_27_30_1_2_WIN, 
      Back_1_41_1_45_31_33_1_2_WIN, 
      Back_1_41_1_45_34_37_1_2_WIN, 
      Back_1_41_1_45_38_40_1_2_WIN, 

      Back_1_46_1_50_01_07_1_2_WIN, 
      Back_1_46_1_50_08_10_1_2_WIN, 
      Back_1_46_1_50_11_13_1_2_WIN, 
      Back_1_46_1_50_14_17_1_2_WIN, 
      Back_1_46_1_50_18_20_1_2_WIN, 
      Back_1_46_1_50_21_23_1_2_WIN, 
      Back_1_46_1_50_24_26_1_2_WIN, 
      Back_1_46_1_50_27_30_1_2_WIN, 
      Back_1_46_1_50_31_33_1_2_WIN, 
      Back_1_46_1_50_34_37_1_2_WIN, 
      Back_1_46_1_50_38_40_1_2_WIN);

  -------------------------------------------------------------

  type Allowed_Type is record
    Bet_Name          : Bet_Name_Type := (others => ' ');
    Bet_Size          : Bet_Size_Type := 0.0;
 --   Is_Allowed_To_Bet : Boolean       := False;
    Has_Betted        : Boolean       := False;
    Max_Loss_Per_Day  : Bet_Size_Type := 0.0;
 --   Bet_Size_Portion  : Bet_Size_Portion_Type := 0.0;
  end record;

  Bets_Allowed : array (Bet_Type'range) of Allowed_Type;


  --------------------------------------------------------------


  
  type Bet_List_Record is record
    Bet           : Table_Abets.Data_Type;
    Price_Finish  : Table_Aprices.Data_Type;
    Price_Finish2 : Table_Aprices.Data_Type;
  end record;

  package Bet_List_Pack is new Ada.Containers.Doubly_Linked_Lists(Bet_List_Record);


  Global_Bet_List : Bet_List_Pack.List;
  
  
  ----------------------------------------------------------

  procedure Set_Bet_Names is
  begin
    for i in Bet_Type'range loop
      case i is
        when others             => Move(I'Img, Bets_Allowed(i).Bet_Name);
      end case;
    end loop;
  end Set_Bet_Names;
  ----------------------------------------------------------------------------



  --------------------------------------------------------------

  -------------------------------------------------------------------------------------------------------------------
 
  procedure Try_To_Make_Back_Bet(
   -- Bettype         : in     Bet_Type;
    Best_Runners    : in     Best_Runners_Array_Type;
    Win_Marketid    : in     Market_Id_Type;
    Plc_Marketid    : in     Market_Id_Type;
  --  Min_Price       : in     String ;
    Bet_List        : in out Bet_List_Pack.List
    --Match_Directly :  in     Boolean := False
    ) is

    Bet : Table_Abets.Data_Type;
  begin       --1
   --  12345678901234567890
   --  Back_1_10_20_1_4_WIN
    for i in Bet_Type'range loop
      -- 123456789012345678901234567890    
      -- Back_1_46_1_50_11_13_1_2_WIN, 

      declare
        Min_1, Max_1 : Float_8 := 0.0;
        Min_2, Max_2 : Float_8 := 0.0;
        Betname      : String  := i'img;
        Backed_Place    : Integer;
        Next_Place      : Integer;
        
      begin
        if not Bets_Allowed(i).Has_Betted then
         
          Min_1 := Float_8'Value(Betname( 6) & "." & Betname(8..9));
          Max_1 := Float_8'Value(Betname(11) & "." & Betname(13..14));
          Min_2 := Float_8'Value(Betname(16..17));
          Max_2 := Float_8'Value(Betname(19..20));
          Backed_Place := Integer'Value(Betname(32..32));
          Next_Place := Integer'Value(Betname(34..34));
          
          if Best_Runners(Backed_Place).Backprice >= Min_1 and then
             Best_Runners(Backed_Place).Backprice <= Max_1 and then
             Best_Runners(Next_Place).Backprice >= Min_2 and then
             Best_Runners(Next_Place).Backprice <= Max_2 and then
             Best_Runners(Backed_Place).Layprice > Float_8(1.01) and then
             Best_Runners(Backed_Place).Layprice < Float_8(1_000.0) then
             
             Bet := Table_Abets.Empty_Data;

             Bet.Marketid    := Win_Marketid;
             Bet.Selectionid := Best_Runners(Backed_Place).Selectionid;
             Bet.Side        := "BACK";
             Bet.Size        := Float_8(Bets_Allowed(i).Bet_Size);
             Bet.Price       := Best_Runners(Backed_Place).Backprice;
             Bet.Sizematched := Float_8(Bets_Allowed(i).Bet_Size);
             Bet.Pricematched:= Best_Runners(Backed_Place).Backprice;
             Bet.Betplaced   := Best_Runners(Backed_Place).Pricets;
             Bet.Status(1) := 'U';
             Move(Betname, Bet.Betname);
             Bet_List.Append(Bet_List_Record'(
                  Bet          => Bet,
                  Price_Finish => Best_Runners(Backed_Place),
                  Price_Finish2 => Best_Runners(Next_Place))
             );
             
             
             begin
               Bet := Table_Abets.Empty_Data;
              -- also bet on place
               Bet.Marketid    := Plc_Marketid;
               Bet.Selectionid := Best_Runners(Backed_Place).Selectionid;
               Bet.Side        := "BACK";
               Bet.Size        := Float_8(Bets_Allowed(i).Bet_Size);
               Bet.Price       := Best_Runners(Backed_Place).Backprice;
               Bet.Sizematched := Float_8(Bets_Allowed(i).Bet_Size);
               Bet.Pricematched:= Best_Runners(Backed_Place).Backprice;
               Bet.Betplaced   := Best_Runners(Backed_Place).Pricets;
               Bet.Status(1) := 'M';
               Betname(26..28) := "PLC";
               Move(Betname, Bet.Betname);
               Bet_List.Append(Bet_List_Record'(
                    Bet          => Bet,
                    Price_Finish => Best_Runners(Backed_Place),
                    Price_Finish2 => Best_Runners(Next_Place))
               );             
             exception
               when others => 
                 Log("no place market for " & Best_Runners(Backed_Place).Marketid); 
             end ;
             Log("bet list len : " & Bet_List.Length'Img & " " & Bet.To_String); 
             Bets_Allowed(i).Has_Betted := True;                
             
          end if;
          
        end if;    
      end;
    end loop;
  end Try_To_Make_Back_Bet;
  -------------------------------------------------------------------------------------------------------------------

  procedure Run(Market_Notification : in Bot_Messages.Market_Notification_Record) is
    Market    : Table_Amarkets.Data_Type;
    Event     : Table_Aevents.Data_Type;
    Price_List : Table_Aprices.Aprices_List_Pack2.List;
    --------------------------------------------
    function "<" (Left,Right : Table_Aprices.Data_Type) return Boolean is
    begin
      return Left.Backprice < Right.Backprice;
    end "<";
    --------------------------------------------
    package Backprice_Sorter is new  Table_Aprices.Aprices_List_Pack2.Generic_Sorting("<");

    Price             : Table_Aprices.Data_Type;
    Has_Been_In_Play,
    In_Play           : Boolean := False;
    Best_Runners      : Best_Runners_Array_Type := (others => Table_Aprices.Empty_Data);

    Worst_Runner      : Table_Aprices.Data_Type := Table_Aprices.Empty_Data;

    Eos               : Boolean := False;
    Markets           : array (Market_Type'range) of Table_Amarkets.Data_Type;
    Found_Place       : Boolean := True;
    T                 : Sql.Transaction_Type;
    Current_Turn_Not_Started_Race : Integer_4 := 0;
  begin
    Log(Me & "Run", "Treat market: " &  Market_Notification.Market_Id);
    Market.Marketid := Market_Notification.Market_Id;

    Set_Bet_Names;

    --set values from cfg
    for i in Bets_Allowed'range loop
      Bets_Allowed(i).Bet_Size   := 30.0;
      Bets_Allowed(i).Has_Betted := False;
      Bets_Allowed(i).Max_Loss_Per_Day := 10000.0;
    end loop;

    Global_Bet_List.Clear;    

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
--          elsif not Cfg.Country_Is_Ok(Event.Countrycode) then
--            Log(Me & "Run", "not an OK country,  market: " &  Market_Notification.Market_Id);
--            return;
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
        "and MP.NUMWINNERS = 3 " &
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

      if Markets(Place).Numwinners < Integer_4(3) then
        exit Poll_Loop;
      end if;

      --Table_Aprices.Aprices_List_Pack.Remove_All(Price_List);
      Price_List.Clear;
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
        if Current_Turn_Not_Started_Race >= 17 then
           Log(Me & "Make_Bet", "Market took too long time to start, give up");
           exit Poll_Loop;
        else
          Current_Turn_Not_Started_Race := Current_Turn_Not_Started_Race +1;
          delay 5.0; -- no need for heavy polling before start of race
        end if;
      else
        delay 0.05; -- to avoid more than 20 polls/sec
      end if;

      -- ok find the runner with lowest backprice:
      Backprice_Sorter.Sort(Price_List);

      Price.Backprice := 10_000.0;
      Best_Runners := (others => Price);
      Worst_Runner.Layprice := 10_000.0;

      declare
        Idx : Integer := 0;
      begin
        for Tmp of Price_List loop
          if Tmp.Status(1..6) = "ACTIVE" then
            Idx := Idx +1;
            exit when Idx > Best_Runners'Last;
            Best_Runners(Idx) := Tmp;
          end if;
        end loop;
      end ;

      for Tmp of Price_List loop
        if Tmp.Status(1..6) = "ACTIVE" and then
           Tmp.Backprice > Float_8(1.0) and then
           Tmp.Layprice < Float_8(1_000.0) and then
           Tmp.Selectionid /= Best_Runners(1).Selectionid and then
           Tmp.Selectionid /= Best_Runners(2).Selectionid then

          Worst_Runner := Tmp;
        end if;
      end loop;

      for i in Best_Runners'range loop
        Log("Best_Runners(i)" & i'Img & " " & Best_Runners(i).To_String);
      end loop;
      Log("Worst_Runner " & Worst_Runner.To_String);

      if Best_Runners(1).Backprice >= Float_8(1.01) then
        if Found_Place and then Markets(Place).Numwinners >= Integer_4(3) then
          Try_To_Make_Back_Bet (
                Best_Runners => Best_Runners,
                Win_Marketid  => Markets(Win).Marketid,
                Plc_Marketid  => Markets(Place).Marketid,
                Bet_List  => Global_Bet_List);
        else        
          exit Poll_Loop;
        end if;        
      end if;
    end loop Poll_Loop;

    begin
      T.Start;
      for b of Global_Bet_List loop
        b.Bet.Insert;
      end loop;    
      T.Commit;
    exception 
      when others =>
        T.Rollback;
        Log("exception, rolling back");
    end;

    

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

  Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");
  
  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

 -- Cfg := Config.Create(Ev.Value("BOT_HOME") & "/" & Sa_Par_Inifile.all);
 -- Log(Cfg.To_String);
  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("database", "host", ""),
         Port     => Ini.Get_Value("database", "port", 5432),
         Db_Name  => Ini.Get_Value("database", "name", ""),
         Login    => Ini.Get_Value("database", "username", ""),
         Password =>Ini.Get_Value("database", "password", ""));
  Log(Me, "db Connected");

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

  --if Cfg.Enabled then
  --  Cfg.Enabled := Ev.Value("BOT_MACHINE_ROLE") = "PROD";
  --end if;

  Main_Loop : loop
  
    --notfy markets_fetcher that we are free
    Data := (Free => 1, Name => This_Process.Name , Node => This_Process.Node);
    Bot_Messages.Send(Markets_Fetcher, Data);    
  
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
       --   if Cfg.Enabled then
            --notfy markets_fetcher that we are busy
            Data := (Free => 0, Name => Process_Io.This_Process.Name , Node => Process_Io.This_Process.Node);
            Bot_Messages.Send(Markets_Fetcher, Data);    
            Run(Bot_Messages.Data(Msg));
       --   else
    --        Log(Me, "Poll is not enabled in poll.ini");
     --     end if;
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
    Now := Calendar2.Clock;

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
  when E: others =>
    declare
      Last_Exception_Name     : constant String  := Ada.Exceptions.Exception_Name(E);
      Last_Exception_Messsage : constant String  := Ada.Exceptions.Exception_Message(E);
      Last_Exception_Info     : constant String  := Ada.Exceptions.Exception_Information(E);
    begin
      Log(Last_Exception_Name);
      Log("Message : " & Last_Exception_Messsage);
      Log(Last_Exception_Info);
      Log("addr2line" & " --functions --basenames --exe=" &
           Ada.Command_Line.Command_Name & " " & Stacktrace.Pure_Hexdump(Last_Exception_Info));
    end ;

    Log(Me, "Closed log and die");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
end Poll_Bounds;

