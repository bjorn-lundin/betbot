with Sattmate_Types; use Sattmate_Types;
with Sattmate_Calendar; use Sattmate_Calendar;
with Sattmate_Exception;
--with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
with Ada.Strings ; use Ada.Strings;
with General_Routines; use General_Routines;
with Bot_Config;
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
--with Bet;
with Bot_System_Number;

procedure Bet_Placer is
  package EV renames Ada.Environment_Variables;
  Timeout  : Duration := 120.0;
  My_Lock  : Lock.Lock_Type;
  Msg      : Process_Io.Message_Type;
  Me       : constant String := "Main.";
 -- use type Bot_Types.Bot_Mode_Type;
  OK : Boolean := False;
  Now : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;

  Is_Time_To_Exit : Boolean := False;
  use type Sql.Transaction_Status_Type;

  Update_Betwon_To_Null : Sql.Statement_Type;

  Sa_Par_Mode     : aliased Gnat.Strings.String_Access;
  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line : Command_Line_Configuration;

--  Global_Size : Bet_Size_type := 30.0;
--  Global_Max_Loss_Per_Day : Float_8 := -500.0;
  Global_Enabled : Boolean := False;

  ------------------------------------------------------
  procedure Place_Back_Bet(Place_Back_Bet : Bot_Messages.Place_Back_Bet_Record) is
    T : Sql.Transaction_Type;
    A_Bet : Table_Abets.Data_Type;
    A_Market : Table_Amarkets.Data_Type;
    A_Runner : Table_Arunners.Data_Type;
    type Eos_Type is (Market, Runner);
    Eos : array (Eos_Type'range) of Boolean := (others => False);

--    Execution_Report_Status        : String (1..50)  :=  (others => ' ') ;
--    Execution_Report_Error_Code    : String (1..50)  :=  (others => ' ') ;
--    Instruction_Report_Status      : String (1..50)  :=  (others => ' ') ;
--    Instruction_Report_Error_Code  : String (1..50)  :=  (others => ' ') ;
--    Order_Status                   : String (1..50)  :=  (others => ' ') ;
--    L_Size_Matched,
--    Average_Price_Matched          : Float           := 0.0;
--    Bet_Id                         : Integer_8       := 0;
--    Local_Price : Float_8 := Float_8'Value(Place_Back_Bet.Price);
  begin
    Log("'" & Place_Back_Bet.Bet_Name & "'");
    Log("'" & Place_Back_Bet.Market_Id & "'");
    Log("'" & Place_Back_Bet.Selection_Id'Img & "'");
    Log("'" & Place_Back_Bet.Size & "'");
    Log("'" & Place_Back_Bet.Price & "'");

--    if Bet.Profit_Today(Place_Back_Bet.Bet_Name) < Global_Max_Loss_Per_Day then
--      Log(Me & "Run", "lost too much today, max loss is " & F8_Image(Global_Max_Loss_Per_Day));
--      return;
--    end if;

    A_Market.Marketid := Place_Back_Bet.Market_Id;
    Table_Amarkets.Read(A_Market, Eos(Market) );

    A_Runner.Marketid := Place_Back_Bet.Market_Id;
    A_Runner.Selectionid := Place_Back_Bet.Selection_Id;
    Table_Arunners.Read(A_Runner, Eos(Runner) );
 
    Rpc.Place_Bet (Bet_Name         => Place_Back_Bet.Bet_Name,
                   Market_Id        => Place_Back_Bet.Market_Id,
                   Side             => Back,
                   Runner_Name      => A_Runner.Runnername,
                   Selection_Id     => Place_Back_Bet.Selection_Id,
                   Size             => Bet_Size_Type'Value(Trim(Place_Back_Bet.Size)),
                   Price            => Bet_Price_Type'Value(Trim(Place_Back_Bet.Price)),
                   Bet_Persistence  => Persist,
                   Bet              => A_Bet);

    T.Start;
      A_Bet.Startts := A_Market.Startts;
      A_Bet.Fullmarketname := A_Market.Marketname;
      Table_Abets.Insert(A_Bet);
      Log(Me & "Make_Bet", Trim(Place_Back_Bet.Bet_Name) & " inserted bet: " & Table_Abets.To_String(A_Bet));
      if Trim(A_Bet.Exestatus) = "SUCCESS" then
        Update_Betwon_To_Null.Prepare("update ABETS set BETWON = null where BETID = :BETID");
        Sql.Set(Update_Betwon_To_Null,"BETID", A_Bet.Betid);
        Sql.Execute(Update_Betwon_To_Null);
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

--    if Bet.Profit_Today(Place_Lay_Bet.Bet_Name) < Global_Max_Loss_Per_Day then
--      Log(Me & "Run", "lost too much today, max loss is " & F8_Image(Global_Max_Loss_Per_Day));
--      return;
--    end if;

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
      Log(Me & "Make_Bet", Trim(Place_Lay_Bet.Bet_Name) & " inserted bet: " & Table_Abets.To_String(A_Bet));
      if Trim(A_Bet.Exestatus) = "SUCCESS" then
        Update_Betwon_To_Null.Prepare("update ABETS set BETWON = null where BETID = :BETID");
        Sql.Set(Update_Betwon_To_Null,"BETID", A_Bet.Betid);
        Sql.Execute(Update_Betwon_To_Null);
      end if;
    T.Commit;
  end Place_Lay_Bet;

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
--  Global_Size := Bet_Size_Type'Value(Ini.Get_Value("finish","size","30.0"));
  Global_Enabled := Ini.Get_Value("finish","enabled",false);
--  Global_Max_Loss_Per_Day := Float_8'Value(Ini.Get_Value("finish","max_loss_per_day","-500.0"));

  Log(Me, "Start main loop");

  if not Bot_Config.Config.Global_Section.Logging then
    Logging.Close;
    Logging.Set_Quiet(True);
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
        -- when Core_Messages.Enter_Console_Mode_Message    => Enter_Console;
        when Bot_Messages.Place_Back_Bet_Message    =>
          if Global_Enabled then
            Place_Back_Bet(Bot_Messages.Data(Msg));
          end if;
        when Bot_Messages.Place_Lay_Bet_Message    =>
          if Global_Enabled then
            Place_Lay_Bet(Bot_Messages.Data(Msg));
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
    Now := Sattmate_Calendar.Clock;

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
  when E: others => Sattmate_Exception.Tracebackinfo(E);
    Log(Me, "Close Db");
    Sql.Close_Session;
    Log(Me, "Closed log and die");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
end Bet_Placer;
