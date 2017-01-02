--with Text_Io;
with Ada.Exceptions;
with Ada.Command_Line;
with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
with Ada.Strings ; use Ada.Strings;
with Ada.Environment_Variables;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

with Bets;
with Balances;
with Types; use Types;
with Calendar2; use Calendar2;
with Stacktrace;
with Bot_Config;
with Lock;
with Bot_Types; use Bot_Types;
with Bot_Messages;
with Posix;
with Logging; use Logging;
with Process_Io;
with Core_Messages;
with Bot_Svn_Info;
with Rpc;
with Ini;
with Utils;

procedure Bet_Placer is
  package EV renames Ada.Environment_Variables;
  Timeout  : Duration := 30.0;
  My_Lock  : Lock.Lock_Type;
  Msg      : Process_Io.Message_Type;
  Me       : constant String := "Main.";
  OK : Boolean := False;
  Now : Calendar2.Time_Type := Calendar2.Time_Type_First;
  Global_Counter : Integer := 0;

  Is_Time_To_Exit : Boolean := False;

  Sa_Par_Mode     : aliased Gnat.Strings.String_Access;
  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line        : Command_Line_Configuration;
  Global_Enabled         : constant Boolean   := True;
  Global_Max_Outstanding : constant Integer_4 := 4_000;
  Global_Currently_Outstanding : Integer_4 := 0;
  Global_Keep_Alive_Counter           : Integer_4 := 0;
  ------------------------------------------------------
  procedure Place_Bet(Bet_Name     : Betname_Type;
                      Market_Id    : Marketid_Type;
                      Selection_Id : Integer_4;
                      Side         : Bet_Side_Type;
                      Size         : Bet_Size_Type;
                      Price        : Bet_Price_Type;
                      Match_Directly : Integer_4) is

    A_Bet : Bets.Bet_Type;

    Execution_Report_Status        : String (1..50)  :=  (others => ' ') ;
    Execution_Report_Error_Code    : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Status      : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Error_Code  : String (1..50)  :=  (others => ' ') ;
    Order_Status                   : String (1..50)  :=  (others => ' ') ;
    L_Size_Matched,
    Average_Price_Matched          : Float           := 0.0;
    Bet_Id                         : Integer_8       := 0;
    Local_Price : Float_8 := Float_8(Price);
    Local_Size  : Float_8 := Float_8(Size);
    Local_Side  : String (1..4) := (others => ' ');

  begin
    Move(Side'img, Local_Side);

    Log("'" & Bet_Name & "'");
    Log("'" & Local_Side & "'");
    Log("'" & Market_Id & "'");
    Log("'" & Selection_Id'Img & "'");
    Log("'" & Utils.F8_Image(Local_Price) & "'");
    Log("'" & Utils.F8_Image(Local_Size) & "'");

    if Bet_Name(1..2) = "DR" then

      Bet_Id := 0;
      Move( "EXECUTION_COMPLETE", Order_Status);
      Move( "SUCCESS", Execution_Report_Status);
      Move( "SUCCESS", Execution_Report_Error_Code);
      Move( "SUCCESS", Instruction_Report_Status);
      Move( "SUCCESS", Instruction_Report_Error_Code);
      Average_Price_Matched := Float(Local_Price);
      L_Size_Matched := Float(Local_Size);

      A_Bet := (
        Betid          => Bet_Id,
        Marketid       => Market_Id,
        Betmode        => Bot_Mode(Bot_Types.Simulation),
        Powerdays      => Match_Directly,
        Selectionid    => Selection_Id,
        Reference      => (others => '-'),
        Size           => Local_Size,
        Price          => Local_Price,
        Side           => Local_Side,
        Betname        => Bet_Name,
        Betwon         => False,
        Profit         => 0.0,
        Status         => Order_Status, -- ??
        Exestatus      => Execution_Report_Status,
        Exeerrcode     => Execution_Report_Error_Code,
        Inststatus     => Instruction_Report_Status,
        Insterrcode    => Instruction_Report_Error_Code,
        Startts        => Calendar2.Time_Type_First,
        Betplaced      => Now,
        Pricematched   => Float_8(Average_Price_Matched),
        Sizematched    => Float_8(L_Size_Matched),
        Runnername     => (others => ' '),
        Fullmarketname => (others => ' '),
        Svnrevision    => Bot_Svn_Info.Revision,
        Ixxlupd        => (others => ' '), --set by insert
        Ixxluts        => Now              --set by insert
      );
    else -- real bet
      Log(Me & "Place_Bet", "call Rpc.Place_Bet");
      Rpc.Place_Bet (Bet_Name         => Bet_Name,
                     Market_Id        => Market_Id,
                     Side             => Side,
                     Runner_Name      => (others => ' '),
                     Selection_Id     => Selection_Id,
                     Size             => Size,
                     Price            => Price,
                     Bet_Persistence  => Persist,
                     Match_Directly   => Match_Directly,
                     Bet              => A_Bet);
      Log(Me & "Place_Bet", Utils.Trim(Bet_Name) & " created bet to put on disk: " & A_Bet.To_String);
    end if; -- dry run

    -- save bet in JSON on disk
    Global_Counter := Global_Counter +1;
    declare
      Filename : String := EV.Value("BOT_HOME") & "/pending/" &
                        Utils.Trim(Process_io.This_Process.Name) & "_" &
                        Utils.Trim(Global_Counter'Img) & "_" &
                        Utils.Trim(Posix.Getpid'Img) & ".json";
      NBP : Bot_Messages.New_Bet_Placed_Notification_Record := (Dummy => 0);
    begin
      -- create a file using Betid as unique name, and have it locked during the write, until closed
      Lock.Write_File(Name => Filename, Content =>  A_Bet.To_JSON.Write);

      Log(Me, "Notifying 'bet_checker' about newly placed bet");
      Bot_Messages.Send(Process_IO.To_Process_Type("bet_checker"), NBP);

    exception
      when E: others =>
        declare
          Last_Exception_Name     : constant String  := Ada.Exceptions.Exception_Name(E);
          Last_Exception_Messsage : constant String  := Ada.Exceptions.Exception_Message(E);
          Last_Exception_Info     : constant String  := Ada.Exceptions.Exception_Information(E);
        begin
          Log("in Place_Bet: " & Last_Exception_Name);
          Log("Message : " & Last_Exception_Messsage);
          Log(Last_Exception_Info);
          Log("addr2line" & " --functions --basenames --exe=" &
               Ada.Command_Line.Command_Name & " " & Stacktrace.Pure_Hexdump(Last_Exception_Info));
        end ;
    end;
  end Place_Bet;

  -------------------------------------------------------

  procedure Back_Bet(Place_Back_Bet : Bot_Messages.Place_Back_Bet_Record) is
  begin
    Place_Bet(Bet_Name     => Place_Back_Bet.Bet_Name,
              Market_Id    => Place_Back_Bet.Market_Id,
              Selection_Id => Place_Back_Bet.Selection_Id,
              Side         => Back,
              Size         => Bet_Size_Type'Value(Place_Back_Bet.Size),
              Price        => Bet_Price_Type'Value(Place_Back_Bet.Price),
              Match_Directly => Place_Back_Bet.Match_Directly
              ) ;
  end Back_Bet;

  ------------------------------------------------------
  procedure Lay_Bet(Place_Lay_Bet : Bot_Messages.Place_Lay_Bet_Record) is
  begin
    Place_Bet(Bet_Name     => Place_Lay_Bet.Bet_Name,
              Market_Id    => Place_Lay_Bet.Market_Id,
              Selection_Id => Place_Lay_Bet.Selection_Id,
              Side         => Lay,
              Size         => Bet_Size_Type'Value(Place_Lay_Bet.Size),
              Price        => Bet_Price_Type'Value(Place_Lay_Bet.Price),
              Match_Directly => Place_Lay_Bet.Match_Directly) ;
  end Lay_Bet;

  ------------------------------------------------------
  procedure Check_Outstanding_Balance(Outstanding : in out Integer_4) is
    Betfair_Result    : Rpc.Result_Type := Rpc.Result_Type'first;
    Saldo             : Balances.Balance_Type;
  begin
    Rpc.Get_Balance(Betfair_Result => Betfair_Result, Saldo => Saldo);
    Outstanding := Integer_4(abs(Saldo.Exposure));
  end Check_Outstanding_Balance;



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
  --Ini.Load(Ev.Value("BOT_HOME") & "/" & Sa_Par_Inifile.all);
  --Global_Enabled := Ini.Get_Value(Utils.Trim(Utils.Lower_Case(EV.Value("BOT_NAME"))),"enabled",False);
  --Global_Max_Outstanding := Integer_4(Ini.Get_Value("global","max_outstanding",4000));
  Log(Me, "Start main loop");

  if not Bot_Config.Config.Global_Section.Logging then
    Logging.Close;
    Logging.Set_Quiet(True);
  end if;

  Main_Loop : loop
    begin
      Log(Me, "Start receive");
      Process_Io.Receive(Msg, Timeout);
      Log(Me, "msg : "& Process_Io.Identity(Msg)'Img & " from " & Utils.Trim(Process_Io.Sender(Msg).Name));
      case Process_Io.Identity(Msg) is
        when Core_Messages.Exit_Message                  =>
          exit Main_Loop;
        -- when Core_Messages.Enter_Console_Mode_Message    => Enter_Console;
        when Bot_Messages.Place_Back_Bet_Message    =>
          if Global_Enabled then
            if Global_Currently_Outstanding <= Global_Max_Outstanding then
              Back_Bet(Bot_Messages.Data(Msg));
            else
              Log(Me, "Too much outstanding bets, max" & Global_Max_Outstanding'Img & " cur" & Global_Currently_Outstanding'Img );
            end if;
          else
            Log(Me, "I am not enabled in bet_placer.ini!");
          end if;
        when Bot_Messages.Place_Lay_Bet_Message    =>
          if Global_Enabled then
            if Global_Currently_Outstanding <= Global_Max_Outstanding then
              Lay_Bet(Bot_Messages.Data(Msg));
            else
              Log(Me, "Too much outstanding bets, max" & Global_Max_Outstanding'Img & " cur" & Global_Currently_Outstanding'Img );
            end if;
          else
            Log(Me, "I am not enabled in bet_placer.ini!");
          end if;
        when others =>
          Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Log(Me, "Timeout");
        Check_Outstanding_Balance(Global_Currently_Outstanding);
        Global_Keep_Alive_Counter := Global_Keep_Alive_Counter +1;
        if Global_Keep_Alive_Counter >= 10 then
          Rpc.Keep_Alive(OK);
          Global_Keep_Alive_Counter := 0;
          if not OK then
            Rpc.Login;
          end if;
        end if;
    end;
    Now := Calendar2.Clock;

    --restart every day
    Is_Time_To_Exit := Now.Hour = 01 and then
                     ( Now.Minute = 00 or Now.Minute = 01) ; -- timeout = 2 min

    exit Main_Loop when Is_Time_To_Exit;

  end loop Main_Loop;

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
end Bet_Placer;
