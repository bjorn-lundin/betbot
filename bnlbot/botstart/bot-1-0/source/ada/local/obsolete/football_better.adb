with Ada.Exceptions;
with Ada.Command_Line;
with Types; use Types;
with Calendar2; use Calendar2;
with Stacktrace;
--with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
with Ada.Strings ; use Ada.Strings;
--with General_Routines; use General_Routines;
--with Bot_Config;
with Lock;
--with Text_io;
with Bot_Types; use Bot_Types;
with Sql;
with Bot_Messages;
with Posix;
with Logging; use Logging;
with Process_Io;
with Core_Messages;
with Ada.Environment_Variables;
with Bot_Svn_Info;
with Rpc;
with Ini;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Table_Abets;
with Table_Amarkets;
with Table_Arunners;
with Bet;
with Bot_System_Number;
with Runners;
with Utils;

procedure Football_Better is
  package EV renames Ada.Environment_Variables;
  Timeout  : Duration := 120.0;
  My_Lock  : Lock.Lock_Type;
  Msg      : Process_Io.Message_Type;
  Me       : constant String := "Main.";
 -- use type Bot_Types.Bot_Mode_Type;
  OK : Boolean := False;
  Now : Calendar2.Time_Type := Calendar2.Time_Type_First;

  Is_Time_To_Exit : Boolean := False;
  use type Sql.Transaction_Status_Type;

  Select_Game_Start,
  Select_Race_Runners_In_One_Market,
  Select_Prices_For_All_Runners_In_One_Market,
  Update_Betwon_To_Null : Sql.Statement_Type;

  Sa_Par_Mode     : aliased Gnat.Strings.String_Access;
  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line : Command_Line_Configuration;

  Global_Size : Bet_Size_type := 30.0;
  Global_Max_Loss_Per_Day : Float_8 := -300.0;
  Global_Enabled : Boolean := False;
  type Runners_Type_Type is (Home,  Away, Draw);

  The_Runners : array(Runners_Type_Type'range) of Runners.Runners_Type;
    
  Max_Global_Back_At_Price : Float_8 := 1.85;
  Min_Global_Back_At_Price : Float_8 := 1.2;
  Min_Total_Matched        : Float_8 := 100000.0;
  Upper_Bound_Green_Up     : Float_8 := 10.0;
  Lower_Bound_Green_Up     : Float_8 := 4.0; 
  
  Some_Time_Ago : Calendar2.Interval_Type := (0,0,2,0,0);
  
  Game_Start,
  Current_Game_Time : Calendar2.Time_Type := Calendar2.Time_Type_First; 
  
  Time_Into_Game : Interval_Type := (0,0,0,0,0);
  
  ------------------------------------------------------
  procedure Place_Back_Bet(Place_Back_Bet : Bot_Messages.Place_Back_Bet_Record) is
    T : Sql.Transaction_Type;
    A_Bet : Table_Abets.Data_Type;
    A_Market : Table_Amarkets.Data_Type;
    A_Runner : Table_Arunners.Data_Type;
    type Eos_Type is (Market, Runner);
    Eos : array (Eos_Type'range) of Boolean := (others => False);

    Execution_Report_Status        : String (1..50)  :=  (others => ' ') ;
    Execution_Report_Error_Code    : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Status      : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Error_Code  : String (1..50)  :=  (others => ' ') ;
    Order_Status                   : String (1..50)  :=  (others => ' ') ;
    L_Size_Matched,
    Average_Price_Matched          : Float           := 0.0;
    Bet_Id                         : Integer_8       := 0;
    Local_Price : Float_8 := Float_8'Value(Place_Back_Bet.Price);
    Local_Size  : Float_8 := Float_8'Value(Place_Back_Bet.Size);
  begin
    Log("'" & Place_Back_Bet.Bet_Name & "'");
    Log("'" & Place_Back_Bet.Market_Id & "'");
    Log("'" & Place_Back_Bet.Selection_Id'Img & "'");
    Log("'" & Place_Back_Bet.Size & "'");
    Log("'" & Place_Back_Bet.Price & "'");

    if Bet.Profit_Today(Place_Back_Bet.Bet_Name) < Global_Max_Loss_Per_Day then
      Log(Me & "Run", "lost too much today, max loss is " & Utils.F8_Image(Global_Max_Loss_Per_Day));
      return;
    end if;

    A_Market.Marketid := Place_Back_Bet.Market_Id;
    A_Market.Read(Eos(Market));

    A_Runner.Marketid := Place_Back_Bet.Market_Id;
    A_Runner.Selectionid := Place_Back_Bet.Selection_Id;
    A_Runner.Read(Eos(Runner) );
    
    Bet_Id := Integer_8(Bot_System_Number.New_Number(Bot_System_Number.Betid));
    Move( "EXECUTION_COMPLETE", Order_Status);
    Move( "SUCCESS", Execution_Report_Status);
    Move( "SUCCESS", Execution_Report_Error_Code);
    Move( "SUCCESS", Instruction_Report_Status);
    Move( "SUCCESS", Instruction_Report_Error_Code);
    Average_Price_Matched := Float(Local_Price);
    L_Size_Matched := Float(Local_Size);

    A_Bet := (
      Betid          => Bet_Id,
      Marketid       => Place_Back_Bet.Market_Id,
      Betmode        => Bot_Mode(Bot_Types.Simulation),
      Powerdays      => 0,
      Selectionid    => Place_Back_Bet.Selection_Id,
      Reference      => (others => '-'),
      Size           => Local_Size,
      Price          => Local_Price,
      Side           => "BACK",
      Betname        => Place_Back_Bet.Bet_Name,
      Betwon         => False,
      Profit         => 0.0,
      Status         => Order_Status, -- ??
      Exestatus      => Execution_Report_Status,
      Exeerrcode     => Execution_Report_Error_Code,
      Inststatus     => Instruction_Report_Status,
      Insterrcode    => Instruction_Report_Error_Code,
      Startts        => A_Market.Startts,
      Betplaced      => Now,
      Pricematched   => Float_8(Average_Price_Matched),
      Sizematched    => Float_8(L_Size_Matched),
      Runnername     => A_Runner.Runnername,
      Fullmarketname => A_Market.Marketname,
      Svnrevision    => Bot_Svn_Info.Revision,
      Ixxlupd        => (others => ' '), --set by insert
      Ixxluts        => Now              --set by insert
    );
     
--    Rpc.Place_Bet (Bet_Name         => Place_Back_Bet.Bet_Name,
--                   Market_Id        => Place_Back_Bet.Market_Id,
--                   Side             => Back,
--                   Runner_Name      => A_Runner.Runnername,
--                   Selection_Id     => Place_Back_Bet.Selection_Id,
--                   Size             => Bet_Size_Type'Value(Trim(Place_Back_Bet.Size)),
--                   Price            => Bet_Price_Type'Value(Trim(Place_Back_Bet.Price)),
--                   Bet_Persistence  => Persist,
--                   Bet              => A_Bet);

    T.Start;
      A_Bet.Startts := A_Market.Startts;
      A_Bet.Fullmarketname := A_Market.Marketname;
      A_Bet.Insert;
      Log(Me & "Make_Bet", Utils.Trim(Place_Back_Bet.Bet_Name) & " inserted bet: " & A_Bet.To_String);
      if Utils.Trim(A_Bet.Exestatus) = "SUCCESS" then
        Update_Betwon_To_Null.Prepare("update ABETS set BETWON = null where BETID = :BETID");
        Update_Betwon_To_Null.Set("BETID", A_Bet.Betid);
        Update_Betwon_To_Null.Execute;
      end if;
    T.Commit;
  end Place_Back_Bet;

  ------------------------------------------------------
 procedure Place_Lay_Bet(Place_Lay_Bet : Bot_Messages.Place_Lay_Bet_Record) is
    T : Sql.Transaction_Type;
    A_Bet : Table_Abets.Data_Type;
    A_Market : Table_Amarkets.Data_Type;
    A_Runner : Table_Arunners.Data_Type;
    type Eos_Type is (Market, Runner);
    Eos : array (Eos_Type'range) of Boolean := (others => False);

    Execution_Report_Status        : String (1..50)  :=  (others => ' ') ;
    Execution_Report_Error_Code    : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Status      : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Error_Code  : String (1..50)  :=  (others => ' ') ;
    Order_Status                   : String (1..50)  :=  (others => ' ') ;
    L_Size_Matched,
    Average_Price_Matched          : Float           := 0.0;
    Bet_Id                         : Integer_8       := 0;
    Local_Price : Float_8 := Float_8'Value(Place_Lay_Bet.Price);
    Local_Size  : Float_8 := Float_8'Value(Place_Lay_Bet.Size);
    
  begin
    Log("'" & Place_Lay_Bet.Bet_Name & "'");
    Log("'" & Place_Lay_Bet.Market_Id & "'");
    Log("'" & Place_Lay_Bet.Selection_Id'Img & "'");
    Log("'" & Place_Lay_Bet.Size & "'");
    Log("'" & Place_Lay_Bet.Price & "'");

    if Bet.Profit_Today(Place_Lay_Bet.Bet_Name) < Global_Max_Loss_Per_Day then
      Log(Me & "Run", "lost too much today, max loss is " & Utils.F8_Image(Global_Max_Loss_Per_Day));
      return;
    end if;

    A_Market.Marketid := Place_Lay_Bet.Market_Id;
    Table_Amarkets.Read(A_Market, Eos(Market) );

    A_Runner.Marketid := Place_Lay_Bet.Market_Id;
    A_Runner.Selectionid := Place_Lay_Bet.Selection_Id;
    Table_Arunners.Read(A_Runner, Eos(Runner) );
    
    Bet_Id := Integer_8(Bot_System_Number.New_Number(Bot_System_Number.Betid));
    Move( "EXECUTION_COMPLETE", Order_Status);
    Move( "SUCCESS", Execution_Report_Status);
    Move( "SUCCESS", Execution_Report_Error_Code);
    Move( "SUCCESS", Instruction_Report_Status);
    Move( "SUCCESS", Instruction_Report_Error_Code);
    Average_Price_Matched := Float(Local_Price);
    L_Size_Matched := Float(Local_Size);
    
    A_Bet := (
      Betid          => Bet_Id,
      Marketid       => Place_Lay_Bet.Market_Id,
      Betmode        => Bot_Mode(Bot_Types.Simulation),
      Powerdays      => 0,
      Selectionid    => Place_Lay_Bet.Selection_Id,
      Reference      => (others => '-'),
      Size           => Local_Size,
      Price          => Local_Price,
      Side           => "LAY ",
      Betname        => Place_Lay_Bet.Bet_Name,
      Betwon         => False,
      Profit         => 0.0,
      Status         => Order_Status, -- ??
      Exestatus      => Execution_Report_Status,
      Exeerrcode     => Execution_Report_Error_Code,
      Inststatus     => Instruction_Report_Status,
      Insterrcode    => Instruction_Report_Error_Code,
      Startts        => A_Market.Startts,
      Betplaced      => Now,
      Pricematched   => Float_8(Average_Price_Matched),
      Sizematched    => Float_8(L_Size_Matched),
      Runnername     => A_Runner.Runnername,
      Fullmarketname => A_Market.Marketname,
      Svnrevision    => Bot_Svn_Info.Revision,
      Ixxlupd        => (others => ' '), --set by insert
      Ixxluts        => Now              --set by insert
    );

--    Rpc.Place_Bet (Bet_Name         => Place_Lay_Bet.Bet_Name,
--                   Market_Id        => Place_Lay_Bet.Market_Id,
--                   Side             => Lay,
--                   Runner_Name      => A_Runner.Runnername,
--                   Selection_Id     => Place_Lay_Bet.Selection_Id,
--                   Size             => Bet_Size_Type'Value(Trim(Place_Lay_Bet.Size)),
--                   Price            => Bet_Price_Type'Value(Trim(Place_Lay_Bet.Price)),
--                   Bet_Persistence  => Persist,
--                   Bet              => A_Bet);

    T.Start;
      A_Bet.Startts := A_Market.Startts;
      A_Bet.Fullmarketname := A_Market.Marketname;
      Table_Abets.Insert(A_Bet);
      Log(Me & "Make_Bet", Utils.Trim(Place_Lay_Bet.Bet_Name) & " inserted bet: " & Table_Abets.To_String(A_Bet));
      if Utils.Trim(A_Bet.Exestatus) = "SUCCESS" then
        Update_Betwon_To_Null.Prepare("update ABETS set BETWON = null where BETID = :BETID");
        Sql.Set(Update_Betwon_To_Null,"BETID", A_Bet.Betid);
        Sql.Execute(Update_Betwon_To_Null);
      end if;
    T.Commit;
  end Place_Lay_Bet;
  pragma Unreferenced(Place_Lay_Bet);
  ------------------------------------------------------
  procedure Check_Match_Status(Notification : Bot_Messages.Market_Notification_Record) is
    Place_Back_Bet_Data : Bot_Messages.Place_Back_Bet_Record;
    Selection_Id   : Integer_4 := 0;
    Bet_Name       : Bet_Name_Type := (others => ' ');
    T : Sql.Transaction_Type;
    Ok : Boolean := False;
    Market : Table_Amarkets.Data_Type;
    type Eos_Type is (Runner_Data, Market_Data,Game_Start_Data);
    Eos : array (Eos_Type'range) of Boolean := (others => False);
    
    String_Size  : String(1..7) := (others => ' ');
    String_Price : String(1..6) := (others => ' ');
        
    First_Lap : Boolean := True;
        
  begin
    Log(Me & "Check_Match_Status", "Treat market '" & Notification.Market_Id & "'");
    
    Market.Marketid := Notification.Market_Id;
    Market.Read(Eos(Market_Data));
    if not Eos(Market_Data) then
      if Market.Totalmatched < Min_Total_Matched then
        Log(Me & "Check_Match_Status", "too little totalmatched, skipping, " & Utils.F8_Image(Market.Totalmatched) & " < " & Utils.F8_Image(Min_Total_Matched) );
        return;
      else  
        Log(Me & "Check_Match_Status", "totalmatched " &  Utils.F8_Image(Market.Totalmatched) & " >= " &  Utils.F8_Image(Min_Total_Matched) );
      end if;  
    else
      Log(Me & "Check_Match_Status", "Missing market !!");
      return;
    end if;
    
    Move("DR_HUMAN_BACK_MATCH-ODDS_" & 
       Utils.F8_Image(Min_Global_Back_At_Price, Aft => 1) & "-" &
       Utils.F8_Image(Max_Global_Back_At_Price, Aft => 1) & "_" &
       Utils.F8_Image(Lower_Bound_Green_Up, Aft => 1) & "_" &
       Utils.F8_Image(Upper_Bound_Green_Up, Aft => 1),
      
      Bet_Name);
     
    if Bet.Exists(Bet_Name, Notification.Market_Id) then
      Log(Me & "Check_Match_Status", "Bet already exists for this market - return");
      return;
    end if;  
    
    Select_Game_Start.Prepare("select min(PRICETS) from ARACEPRICES where MARKETID = :MARKETID");
    
    Select_Race_Runners_In_One_Market.Prepare( "select * " &
        "from ARUNNERS " &
        "where MARKETID = :MARKETID " &
        "and STATUS <> 'REMOVED' "  &
        "order by SORTPRIO" ) ;
    
    Select_Prices_For_All_Runners_In_One_Market.Prepare( 
        "select " &
          "RP_DRAW.PRICETS," &
          "RP_DRAW.MARKETID," &
          "R_HOME.RUNNERNAME homename," &
          "R_HOME.STATUS homestatus," &
          "RP_HOME.BACKPRICE homeback," &
          "RP_HOME.LAYPRICE homelay," &
          "R_DRAW.RUNNERNAME drawname," &
          "R_DRAW.STATUS drawstatus," &
          "RP_DRAW.BACKPRICE drawback," &
          "RP_DRAW.LAYPRICE drawlay," &
          "R_AWAY.RUNNERNAME awayname," &
          "R_AWAY.STATUS awaystatus," &
          "RP_AWAY.BACKPRICE awayback," &
          "RP_AWAY.LAYPRICE awaylay " &
        "from " &
          "ARACEPRICES RP_HOME, ARUNNERS R_HOME, " &
          "ARACEPRICES RP_DRAW, ARUNNERS R_DRAW, " &
          "ARACEPRICES RP_AWAY, ARUNNERS R_AWAY, " &
          "AMARKETS M, AEVENTS E " &
        "where RP_DRAW.MARKETID = :MARKETID " &
        "and M.MARKETID = RP_DRAW.MARKETID " &
        "and M.EVENTID = E.EVENTID " &
        "and R_DRAW.MARKETID = RP_DRAW.MARKETID " &
        "and R_DRAW.SELECTIONID = RP_DRAW.SELECTIONID " &
        "and R_DRAW.SELECTIONID = :DRAW_SELECTIONID " &
        "and RP_HOME.MARKETID = RP_DRAW.MARKETID " &
        "and R_HOME.MARKETID = RP_HOME.MARKETID " &
        "and R_HOME.SELECTIONID = RP_HOME.SELECTIONID " &
        "and R_HOME.SELECTIONID = :HOME_SELECTIONID " &
        "and RP_AWAY.MARKETID = RP_DRAW.MARKETID " &
        "and R_AWAY.MARKETID = RP_AWAY.MARKETID " &
        "and R_AWAY.SELECTIONID = RP_AWAY.SELECTIONID " &
        "and R_AWAY.SELECTIONID = :AWAY_SELECTIONID " &
        "and RP_DRAW.PRICETS = RP_HOME.PRICETS " &
        "and RP_DRAW.PRICETS = RP_AWAY.PRICETS " &        
        "and RP_DRAW.PRICETS >= :SOME_TIME_AGO " &
        "order by RP_DRAW.PRICETS" );
    
    -- get the market and selection ids     
    T.Start;
    Select_Race_Runners_In_One_Market.Set("MARKETID", Notification.Market_Id);
    Select_Race_Runners_In_One_Market.Open_Cursor;
    declare
      i : Runners_Type_Type := Runners_Type_Type'first;
    begin  
      loop
        Select_Race_Runners_In_One_Market.Fetch(Eos(Runner_Data));
        exit when Eos(Runner_Data);
        The_Runners(i).Runner := Table_Arunners.Get(Select_Race_Runners_In_One_Market);
        Log(Me & "Check_Match_Status", "Runners(" & i'Img & ").Runner" & The_Runners(i).Runner.To_String);
        if i /=  Runners_Type_Type'last then
          i := Runners_Type_Type'Succ(I);
        end if;  
      end loop;
    end ;
    Select_Race_Runners_In_One_Market.Close_Cursor;
    
    Select_Game_Start.Set("MARKETID", Notification.Market_Id);
    Select_Game_Start.Open_Cursor;
    Select_Game_Start.Fetch(Eos(Game_Start_Data));
    if not Eos(Game_Start_Data) then
      -- use this rather tan startts, so we do not get trouble with delayed games nor with timezones...
      Select_Game_Start.Get_Timestamp(1, Game_Start);
    end if;
    Select_Game_Start.Close_Cursor;
       
    Select_Prices_For_All_Runners_In_One_Market.Set("MARKETID", Notification.Market_Id);
    Select_Prices_For_All_Runners_In_One_Market.Set("HOME_SELECTIONID", The_Runners(Home).Runner.Selectionid);
    Select_Prices_For_All_Runners_In_One_Market.Set("AWAY_SELECTIONID", The_Runners(Away).Runner.Selectionid);
    Select_Prices_For_All_Runners_In_One_Market.Set("DRAW_SELECTIONID", The_Runners(Draw).Runner.Selectionid);
    Select_Prices_For_All_Runners_In_One_Market.Set_Timestamp("SOME_TIME_AGO", Calendar2.Clock - Some_Time_Ago );    
    
    Select_Prices_For_All_Runners_In_One_Market.Open_Cursor; 
   
    Game_Loop : loop -- get a new market/odds combo
      if First_Lap then 
        Log(Me & "Check_Match_Status", "first lap in loop");
        First_Lap := False;
      end if;      
      Select_Prices_For_All_Runners_In_One_Market.Fetch(Eos(Market_Data));
      Log(Me & "Check_Match_Status", "Eos(Market_Data) " & Eos(Market_Data)'Img);
      if First_Lap and then Eos(Market_Data) then
        Log(Me & "Check_Match_Status-Get_Prepared_Statement",Select_Prices_For_All_Runners_In_One_Market.Get_Prepared_Statement);
      end if;
      exit Game_Loop when Eos(Market_Data);
      Select_Prices_For_All_Runners_In_One_Market.Get_Timestamp("PRICETS", Current_Game_Time);
      
      Select_Prices_For_All_Runners_In_One_Market.Get("HOMEBACK", The_Runners(Home).Back_Price);
      Select_Prices_For_All_Runners_In_One_Market.Get("HOMELAY",  The_Runners(Home).Lay_Price);
      
      Select_Prices_For_All_Runners_In_One_Market.Get("AWAYBACK", The_Runners(Away).Back_Price);
      Select_Prices_For_All_Runners_In_One_Market.Get("AWAYLAY",  The_Runners(Away).Lay_Price);
      
      Select_Prices_For_All_Runners_In_One_Market.Get("DRAWBACK", The_Runners(Draw).Back_Price);
      Select_Prices_For_All_Runners_In_One_Market.Get("DRAWLAY",  The_Runners(Draw).Lay_Price);
      
      for i in Runners_Type_Type'range loop
        The_Runners(i).Fix_Average(Current_Game_Time);
      end loop;
             
      Time_Into_Game := Current_Game_Time - Game_Start;
      
      Log(Me & "Time_Into_Game " & String_Interval(Time_Into_Game) );
      Log(Me & "+0h:10 min into game? : " & Boolean'Image(Time_Into_Game > (0,0,10,0,0)));
      Log(Me & "-1h:50 min into game? : " & Boolean'Image(Time_Into_Game < (0,1,50,0,0)));
      
      Log(Me & "Home victory ?");        
      Log(Me & "The_Runners(Home).Lay_Price  " & Utils.F8_Image(The_Runners(Home).Lay_Price)  & " The_Runners(Home).Lay_Price >= 0.0                       " & Boolean'Image(The_Runners(Home).Lay_Price >= 0.0));
      Log(Me & "The_Runners(Home).Back_Price " & Utils.F8_Image(The_Runners(Home).Back_Price) & " The_Runners(Home).Back_Price >= 1.0                      " & Boolean'Image(The_Runners(Home).Back_Price >= 1.0));
      Log(Me & "The_Runners(Home).A_Back     " & Utils.F8_Image(The_Runners(Home).A_Back)     & " Min_Global_Back_At_Price <= The_Runners(Home).A_Back     " & Boolean'Image(Min_Global_Back_At_Price <= The_Runners(Home).A_Back));
      Log(Me & "The_Runners(Home).A_Back     " & Utils.F8_Image(The_Runners(Home).A_Back)     & " The_Runners(Home).A_Back <= Max_Global_Back_At_Price     " & Boolean'Image(The_Runners(Home).A_Back <= Max_Global_Back_At_Price));
      Log(Me & "The_Runners(Home).Back_Price " & Utils.F8_Image(The_Runners(Home).Back_Price) & " Min_Global_Back_At_Price <= The_Runners(Home).Back_Price " & Boolean'Image(Min_Global_Back_At_Price <= The_Runners(Home).Back_Price));
      Log(Me & "The_Runners(Home).Back_Price " & Utils.F8_Image(The_Runners(Home).Back_Price) & " The_Runners(Home).Back_Price <= Max_Global_Back_At_Price " & Boolean'Image(The_Runners(Home).Back_Price <= Max_Global_Back_At_Price));
      Log(Me & "The_Runners(Home).K_Back     " & Utils.F8_Image(The_Runners(Home).K_Back)     & " The_Runners(Home).K_Back <= Float_8(0.0)                 " & Boolean'Image(The_Runners(Home).K_Back <= Float_8(0.0)));
      Log(Me & "The_Runners(Home).K_Back_Avg " & Utils.F8_Image(The_Runners(Home).K_Back_Avg) & " The_Runners(Home).K_Back_Avg <= Float_8(0.0)             " & Boolean'Image(The_Runners(Home).K_Back_Avg <= Float_8(0.0)));
      Log(Me & "The_Runners(Away).A_Back     " & Utils.F8_Image(The_Runners(Away).A_Back)     & " The_Runners(Away).A_Back >= Upper_Bound_Green_Up         " & Boolean'Image(The_Runners(Away).A_Back >= Upper_Bound_Green_Up));
      Log(Me & "The_Runners(Draw).A_Back     " & Utils.F8_Image(The_Runners(Draw).A_Back)     & " The_Runners(Draw).A_Back >= Lower_Bound_Green_Up         " & Boolean'Image(The_Runners(Draw).A_Back >= Lower_Bound_Green_Up));

      Log(Me & "Away victory ?");        
      Log(Me & "The_Runners(Away).Lay_Price  " & Utils.F8_Image(The_Runners(Away).Lay_Price)  & " The_Runners(Away).Lay_Price >= 0.0                        " & Boolean'Image(The_Runners(Away).Lay_Price >= 0.0));
      Log(Me & "The_Runners(Away).Back_Price " & Utils.F8_Image(The_Runners(Away).Back_Price) & " The_Runners(Away).Back_Price >= 1.0                       " & Boolean'Image(The_Runners(Away).Back_Price >= 1.0));
      Log(Me & "The_Runners(Away).A_Back     " & Utils.F8_Image(The_Runners(Away).A_Back)     & " Min_Global_Back_At_Price <= The_Runners(Away).A_Back      " & Boolean'Image(Min_Global_Back_At_Price <= The_Runners(Away).A_Back));
      Log(Me & "The_Runners(Away).A_Back     " & Utils.F8_Image(The_Runners(Away).A_Back)     & " The_Runners(Away).A_Back <= Max_Global_Back_At_Price      " & Boolean'Image(The_Runners(Away).Back_Price <= Max_Global_Back_At_Price));
      Log(Me & "The_Runners(Away).Back_Price " & Utils.F8_Image(The_Runners(Away).Back_Price) & " Min_Global_Back_At_Price <= The_Runners(Away).Back_Price  " & Boolean'Image(Min_Global_Back_At_Price <= The_Runners(Away).Back_Price));
      Log(Me & "The_Runners(Away).Back_Price " & Utils.F8_Image(The_Runners(Away).Back_Price) & " The_Runners(Away).Back_Price <= Max_Global_Back_At_Price  " & Boolean'Image(The_Runners(Away).A_Back <= Max_Global_Back_At_Price));
      Log(Me & "The_Runners(Away).K_Back     " & Utils.F8_Image(The_Runners(Away).K_Back)     & " The_Runners(Away).K_Back <= Float_8(0.0)                  " & Boolean'Image(The_Runners(Away).K_Back <= Float_8(0.0)));
      Log(Me & "The_Runners(Away).K_Back_Avg " & Utils.F8_Image(The_Runners(Away).K_Back_Avg) & " The_Runners(Away).K_Back_Avg <= Float_8(0.0)              " & Boolean'Image(The_Runners(Away).K_Back_Avg <= Float_8(0.0)));
      Log(Me & "The_Runners(Home).A_Back     " & Utils.F8_Image(The_Runners(Home).A_Back)     & " The_Runners(Home).A_Back >= Upper_Bound_Green_Up          " & Boolean'Image(The_Runners(Home).A_Back >= Upper_Bound_Green_Up));
      Log(Me & "The_Runners(Draw).A_Back     " & Utils.F8_Image(The_Runners(Draw).A_Back)     & " The_Runners(Draw).A_Back >= Lower_Bound_Green_Up          " & Boolean'Image(The_Runners(Draw).A_Back >= Lower_Bound_Green_Up));
      
--      if    Time_Into_Game > (0,0,10,0,0) and then
--            Time_Into_Game < (0,1,50,0,0) and then
      if    Time_Into_Game <= (0,0,45,0,0) and then
            The_Runners(Home).Lay_Price >= 0.0 and then
            The_Runners(Home).Back_Price >= 1.0 and then
            -- both average and current back price must be within limits
            Min_Global_Back_At_Price <= The_Runners(Home).A_Back and then  
            The_Runners(Home).A_Back <= Max_Global_Back_At_Price and then  
            Min_Global_Back_At_Price <= The_Runners(Home).Back_Price and then  
            The_Runners(Home).Back_Price <= Max_Global_Back_At_Price and then  
            
            The_Runners(Home).K_Back <= Float_8(0.0) and then  -- straight or descending slope
            The_Runners(Home).K_Back_Avg <= Float_8(0.0) and then  -- for a while too
            
            The_Runners(Away).A_Back >= Upper_Bound_Green_Up and then
            The_Runners(Draw).A_Back >= Lower_Bound_Green_Up then
            
        Selection_Id := The_Runners(Home).Runner.Selectionid;
        Move(Utils.F8_Image( The_Runners(Home).Back_Price),String_Price);
        Log(Me & "Check_Match_Status", "bet on" & Selection_Id'Img);
        
        exit Game_Loop;  
        
--      elsif Time_Into_Game > (0,0,10,0,0) and then
--            Time_Into_Game < (0,1,50,0,0) and then
      elsif    Time_Into_Game <= (0,0,45,0,0) and then
            The_Runners(Away).Lay_Price >= 0.0 and then
            The_Runners(Away).Back_Price >= 1.0 and then
            -- both average and current back price must be within limits
            Min_Global_Back_At_Price <= The_Runners(Away).A_Back and then  
            The_Runners(Away).A_Back <= Max_Global_Back_At_Price and then             
            Min_Global_Back_At_Price <= The_Runners(Away).Back_Price and then  
            The_Runners(Away).Back_Price <= Max_Global_Back_At_Price and then  
            
            The_Runners(Away).K_Back <= Float_8(0.0) and then  -- straight or descending slope
            The_Runners(Away).K_Back_Avg <= Float_8(0.0) and then  -- for a while too
                             
            The_Runners(Home).A_Back >= Upper_Bound_Green_Up and then
            The_Runners(Draw).A_Back >= Lower_Bound_Green_Up then
            
        Selection_Id := The_Runners(Away).Runner.Selectionid;
        Move(Utils.F8_Image( The_Runners(Away).Back_Price),String_Price);
        Log(Me & "Check_Match_Status", "bet on" & Selection_Id'Img);
        exit Game_Loop;  
      end if;
      
    end loop Game_Loop;
    Select_Prices_For_All_Runners_In_One_Market.Close_Cursor;  

    T.Commit;
    
    OK := Selection_Id > 0;
    if OK then
      Move(Utils.F8_Image(Float_8(Global_Size)),String_Size);
      Place_Back_Bet_Data := (
         Bet_Name     => Bet_Name,
         Market_Id    => Notification.Market_Id,
         Selection_Id => Selection_Id,
         Size         => String_Size,
         Price        => String_Price
      );      

      Place_Back_Bet(Place_Back_Bet_Data);
    else
     Log(Me & "Check_Match_Status", "No bet laid this time!");   
    end if;
  
  end Check_Match_Status;
  ------------------------------------------------------

begin
  Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");

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
        Sa_Par_Mode'access,
        Long_Switch => "--mode=",
        Help        => "mode of bot - (real, simulation)");

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
  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");

  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("database","host",""),
         Port     => Ini.Get_Value("database","port",5432),
         Db_Name  => Ini.Get_Value("database","name",""),
         Login    => Ini.Get_Value("database","username",""),
         Password => Ini.Get_Value("database","password",""));
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

  Ini.Load(Ev.Value("BOT_HOME") & "/" & Sa_Par_Inifile.all);
  Global_Size := Bet_Size_Type'Value(Ini.Get_Value("football","size","30.0"));
  Global_Enabled := Ini.Get_Value("football","enabled",false);
  Global_Max_Loss_Per_Day := Float_8'Value(Ini.Get_Value("football","max_loss_per_day","-500.0"));

  Log(Me, "Start main loop");
  
  Main_Loop : loop
    begin
      Log(Me, "Start receive");
      Process_Io.Receive(Msg, Timeout);
      Log(Me, "msg : "& Process_Io.Identity(Msg)'Img & " from " & Utils.Trim(Process_Io.Sender(Msg).Name));
      if Sql.Transaction_Status /= Sql.None then
        raise Sql.Transaction_Error with "Uncommited transaction in progress !! BAD!";
      end if;
      case Process_Io.Identity(Msg) is
        when Core_Messages.Exit_Message                  =>
          exit Main_Loop;
        -- when Core_Messages.Enter_Console_Mode_Message    => Enter_Console;
        
        when Bot_Messages.Market_Notification_Message    =>
          if Global_Enabled then
            Log(Me & "start service Check_Match_Status");
            Check_Match_Status( Bot_Messages.Data(Msg));
            Log(Me & "stop  service Check_Match_Status");
          else  
            Log(Me, "Check_Match_Status is disabled in inifile");  --??
          end if;
        
        when Bot_Messages.Place_Back_Bet_Message    =>
          if Global_Enabled then
            Log(Me, "Place_Back_Bet is disabled");  --??
 --           Place_Back_Bet(Bot_Messages.Data(Msg));
          end if;
        when Bot_Messages.Place_Lay_Bet_Message    =>
          if Global_Enabled then
            Log(Me, "Place_Lay_Bet is disabled");  --??
 --           Place_Lay_Bet(Bot_Messages.Data(Msg));
          end if;
        when others =>
          Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Log(Me, "Timeout");
        if Sql.Transaction_Status /= Sql.None then
          raise Sql.Transaction_Error with "Uncommited transaction in progress 2 !! BAD!";
        end if;

        Rpc.Keep_Alive(OK);
        if not OK then
          Rpc.Login;
        end if;
    end;
    Now := Calendar2.Clock;

    --restart every day
    Is_Time_To_Exit := Now.Hour = 05 and then
                     ( Now.Minute = 02 or Now.Minute = 03) ; -- timeout = 2 min

    exit Main_Loop when Is_Time_To_Exit;

  end loop Main_Loop;


  Log(Me, "Close Db");
  Sql.Close_Session;
  Log (Me, "db closed, Is_Time_To_Exit " & Is_Time_To_Exit'Img);
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
end Football_Better;
