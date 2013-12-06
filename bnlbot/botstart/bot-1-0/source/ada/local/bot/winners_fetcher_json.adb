with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
--with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Environment_Variables;
--with Ada.Calendar;
--with Sattmate_Types; use Sattmate_Types;
with Sql;
--with Simple_List_Class;
--pragma Elaborate_All(Simple_List_Class);
with Sattmate_Exception;
with Lock ;
with Table_Awinners;
with Table_Anonrunners;
with Table_Abets;
with Rpc;
with Posix;
--with Ada.Directories;
with Logging; use Logging;
with Bot_Messages;
with Process_Io;
with Ini;
with Token;
--with Bot_Config;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
--with Bot_Types;
with Core_Messages;

procedure Winners_Fetcher_Json is
--  Bad_Data : exception;
  package EV renames Ada.Environment_Variables;
--  package AD renames Ada.Directories;
  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Cmd_Line : Command_Line_Configuration;


  Me : constant String := "Main.";
  --------------------------
  OK : Boolean := False;

  Has_Inserted_Winner : Boolean := False;

  My_Lock  : Lock.Lock_Type;
  
  Winner_List     : Table_Awinners.Awinners_List_Pack.List_Type := Table_Awinners.Awinners_List_Pack.Create;
  Non_Runner_List : Table_Anonrunners.Anonrunners_List_Pack.List_Type := Table_Anonrunners.Anonrunners_List_Pack.Create;
  Bet_List : Table_Abets.Abets_List_Pack.List_Type := Table_Abets.Abets_List_Pack.Create;
  
  Select_Unsettled_Bets : Sql.Statement_Type;
  
--  My_Token : Token.Token_Type;
  Msg      : Process_Io.Message_Type;
  Timeout  : Duration := 47.0;
  

  Ba_Daemon : aliased Boolean := False;
  
  ---------------------------------------------------------------------------
  procedure Check_Unsettled_Bets(Inserted_Winner : in out Boolean) is
    T : Sql.Transaction_Type;
    Winner     : Table_Awinners.Data_Type;
    Non_Runner : Table_Anonrunners.Data_Type;
    Bet : Table_Abets.Data_Type;
    type Eos_Type is (Awinners, Anonrunners);
    Eos : array (Eos_Type'range) of Boolean := (others => False);
    
    
  begin
    Log (Me, "Check_Unsettled_Bets start");
    Inserted_Winner := False;
    T.Start;  
      Table_Abets.Read_List(Select_Unsettled_Bets, Bet_List);
  
      Bet_Loop : while not Table_Abets.Abets_List_Pack.Is_Empty(Bet_List) loop
        Table_Abets.Abets_List_Pack.Remove_From_Head(Bet_List, Bet);
  
        Rpc.Check_Market_Result(Market_Id       => Bet.Marketid,
                                Winner_List     => Winner_List,
                                Non_Runner_List => Non_Runner_List);
  
        Winners : while not Table_Awinners.Awinners_List_Pack.Is_Empty(Winner_List) loop
          Table_Awinners.Awinners_List_Pack.Remove_From_Head(Winner_List, Winner);
          Table_Awinners.Read(Winner, Eos(Awinners));
          if Eos(Awinners) then
            Inserted_Winner := True;
            Log (Me, "inserted Winner : " & Table_Awinners.To_String(Winner));
            Table_Awinners.Insert(Winner);
          end if;
        end loop Winners;       
        
        Non_Runners : while not Table_Anonrunners.Anonrunners_List_Pack.Is_Empty(Non_Runner_List) loop
          Table_Anonrunners.Anonrunners_List_Pack.Remove_From_Head(Non_Runner_List, Non_Runner);
          Table_Anonrunners.Read(Non_Runner, Eos(Anonrunners));
          if Eos(Anonrunners) then
            Inserted_Winner := True;
            Log (Me, "inserted Non_Runner : " & Table_Anonrunners.To_String(Non_Runner));
            Table_Anonrunners.Insert(Non_Runner);
          end if;
        end loop Non_Runners;       
      end loop Bet_Loop;
    Sql.Commit (T);
    Log (Me, "Check_Unsettled_Bets stop");
  exception
    when Sql.Duplicate_Index =>
      Sql.Rollback(T);
      Log (Me, "Check_Unsettled_Bets Duplicate index");
      Inserted_Winner := False;
  end Check_Unsettled_Bets;
----------------------------------------------

  
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
    Getopt (Cmd_Line);  -- process the command line
    
    Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");


    Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");
 --   Logging.Open(EV.Value("BOT_HOME") & "/log/winners_fetcher_json.log");
 --   Logging.New_Log_File_On_Exit(False);

 
         
    if Ba_Daemon then
      Posix.Daemonize;
    end if;
    My_Lock.Take("winners_fetcher_json");    
    
    Log(Me, "Login betfair");
    Rpc.Init(
            Username   => Ini.Get_Value("betfair","username",""),
            Password   => Ini.Get_Value("betfair","password",""),
            Product_Id => Ini.Get_Value("betfair","product_id",""),  
            Vendor_Id  => Ini.Get_Value("betfair","vendor_id",""),
            App_Key    => Ini.Get_Value("betfair","appkey","")
    );
    Rpc.Login;
    
--    Log (Me, "connect db");
    Sql.Connect
        (Host     => Ini.Get_Value("database","host",""),
         Port     => Ini.Get_Value("database","port",5432),
         Db_Name  => Ini.Get_Value("database","name",""),
         Login    => Ini.Get_Value("database","username",""),
         Password => Ini.Get_Value("database","password",""));
--    Log (Me, "connected to db");


    Select_Unsettled_Bets.Prepare(
      "select * from ABETS " &
      "where BETWON is null and BETID > 1000000" ); -- unsettled bets

      
    Main_Loop : loop
      begin
        Log(Me, "Start receive");
        Process_Io.Receive(Msg, Timeout);
        case Process_Io.Identity(Msg) is
          when Core_Messages.Exit_Message                  =>
            exit Main_Loop;
          when others =>
            Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
        end case;
      exception
        when Process_Io.Timeout =>
          Log(Me, "Timeout");
          Rpc.Keep_Alive(OK);
          if not OK then
            Rpc.Login;
          end if;

          Check_Unsettled_Bets(Has_Inserted_Winner);
          
          if Has_Inserted_Winner then
            declare
                NWARNR   : Bot_Messages.New_Winners_Arrived_Notification_Record;
                Receiver : Process_IO.Process_Type := ((others => ' '), (others => ' '));
            begin
                Move("bot", Receiver.Name);
                Log(Me, "Notifying 'bot' of that new winners are arrived");
                Bot_Messages.Send(Receiver, NWARNR);
            end;
          end if;
          
      end;
    end loop Main_Loop;

    Sql.Close_Session;
--    Log (Me, "db closed");

    Logging.Close;
    Posix.Do_Exit(0); -- terminate
exception
  when Lock.Lock_Error =>
    Posix.Do_Exit(0); -- terminate
  when E: others =>
    Sattmate_Exception. Tracebackinfo(E);
    Logging.Close;
    if Sql.Is_Session_Open then
      Sql.Close_Session;
      Log (Me, "db closed");
    end if;
    Posix.Do_Exit(0); -- terminate
end Winners_Fetcher_Json;

