--with Text_Io;
with Sattmate_Exception;
with Sattmate_Types; use Sattmate_Types;
with Sql;
with General_Routines; use General_Routines;
with Ada.Streams;

with Gnat.Sockets;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

with Sattmate_Calendar; use Sattmate_Calendar;
with Gnatcoll.Json; use Gnatcoll.Json;

with Rpc;
with Lock ;
with Posix;
with Table_Abalances;
with Ini;
with Logging; use Logging;

with Ada.Environment_Variables;

with Process_IO;
with Core_Messages;

procedure Saldo_Fetcher is
  package EV renames Ada.Environment_Variables;

  use type Rpc.Result_Type;
  
  Me : constant String := "Main.";  

  Msg      : Process_Io.Message_Type;

  Sa_Par_Token : aliased Gnat.Strings.String_Access;
  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Ba_Daemon    : aliased Boolean := False;
  Cmd_Line : Command_Line_Configuration;
  
  Betfair_Result : Rpc.Result_Type := Rpc.Ok;
 
  My_Lock  : Lock.Lock_Type;
---------------------------------------------------------------  

  procedure Mail_Saldo(Saldo : Table_Abalances.Data_Type; T : Sattmate_Calendar.Time_Type) is
    pragma unreferenced(T);
    -- use the pythonscript mail_proxy to send away the mail
    Host : constant String := "localhost";
    Host_Entry : Gnat.Sockets.Host_Entry_Type
               := GNAT.Sockets.Get_Host_By_Name(Host);

    Address : Gnat.Sockets.Sock_Addr_Type;
    Socket  : Gnat.Sockets.Socket_Type;
    Channel : Gnat.Sockets.Stream_Access;
    Data    : Ada.Streams.Stream_Element_Array (1..1_000);
    Size    : Ada.Streams.Stream_Element_Offset;
    Str     : String(1 .. 1_000) := (others => ' ');
  begin
     -- Open a connection to the host
     Address.Addr := Gnat.Sockets.Addresses(Host_Entry, 1);
     Address.Port := 27_124;
     Gnat.Sockets.Create_Socket (Socket);
     Gnat.Sockets.Connect_Socket (Socket, Address);
     
     Channel := Gnat.Sockets.Stream (Socket);

    declare
       S : String := 
         "available=" & F8_Image(Saldo.Balance) &
         ",exposed="  & F8_Image(Saldo.Exposure) & 
         ",account=" & Ini.Get_Value("betfair","username","");
    begin        
      Log(Me & "Mail_Saldo", "Request: '" & S & "'"); 
      String'Write (Channel, S);
    end ;
     --get the reply
    GNAT.Sockets.Receive_Socket(Socket, Data, Size);
    for i in 1 .. Size loop
     Str(integer(i)):= Character'Val(Data(i));
    end loop;     
    Log(Me, "reply: '" & Str(1 .. Integer(Size)) & "'"); 
    Log(Me, "Insert_Saldo stop"); 
  end Mail_Saldo;

-----------------------------------------------------------------
  
  procedure Insert_Saldo(S : in out Table_Abalances.Data_Type) is
  begin
    Log(Me, "Insert_Saldo start"); 
    Log(Me, Table_Abalances.To_String(S)); 
    Table_Abalances.Insert(S);  
    Log(Me, "Insert_Saldo stop"); 
  end Insert_Saldo;

  ---------------------------------------------------------------------
  
  procedure Balance( Betfair_Result : in out Rpc.Result_Type ; Saldo : out Table_Abalances.Data_Type) is
    T : Sql.Transaction_Type;
    Now : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;
  begin

    Rpc.Get_Balance(Betfair_Result,Saldo);           
         
    if Betfair_Result = Rpc.Ok then    
      Saldo.Baldate := Now;  
      T.Start;
      Insert_Saldo(Saldo);
      T.Commit;
      Mail_Saldo(Saldo, Now);
    end if;
    
  end Balance;    
  
   
------------------------------ main start -------------------------------------
  Is_Time_To_Check_Balance,
  Is_Time_To_Exit  : Boolean := False;
  Day_Last_Check : Sattmate_Calendar.Day_Type := 1;
  Now : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;
  Last_Keep_Alive : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
  
  OK : Boolean := False;
  Saldo : Table_Abalances.Data_Type;
begin
  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");
 
  Logging.Open(EV.Value("BOT_HOME") & "/log/saldo_fetcher.log");
  
  Define_Switch
   (Cmd_Line,
    Sa_Par_Bot_User'access,
    Long_Switch => "--user=",
    Help        => "user of bot");
    
  Define_Switch
    (Cmd_Line,
     Sa_Par_Token'access,
     "-t:",
     Long_Switch => "--token=",
     Help        => "use this token, if token is already retrieved");

  Define_Switch
     (Cmd_Line,
      Ba_Daemon'access,
      "-d",
      Long_Switch => "--daemon",
      Help        => "become daemon at startup");
  Getopt (Cmd_Line);  -- process the command line
   
  if Ba_Daemon then
     Posix.Daemonize;
  end if;
   --must take lock AFTER becoming a daemon ... 
   --The parent pid dies, and would release the lock...
  My_Lock.Take("saldo_fetcher");
   
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

  Sql.Connect
        (Host     => Ini.Get_Value("database_saldo_fetcher","host",""),
         Port     => Ini.Get_Value("database_saldo_fetcher","port",5432),
         Db_Name  => Ini.Get_Value("database_saldo_fetcher","name",""),
         Login    => Ini.Get_Value("database_saldo_fetcher","username",""),
         Password => Ini.Get_Value("database_saldo_fetcher","password",""));

  
  Main_Loop : loop  
    Receive_Loop : loop   
      begin
        Process_Io.Receive(Msg, 5.0);
        Log(Me, "msg : "& Process_Io.Identity(Msg)'Img & " from " & General_Routines.Trim(Process_Io.Sender(Msg).Name));
        case Process_Io.Identity(Msg) is
          when Core_Messages.Exit_Message                  => exit Main_Loop;
          when others => Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
        end case;  
      exception
        when Process_Io.Timeout => 
          Now := Sattmate_Calendar.Clock;
          if Now - (0,0,10,0,0) > Last_Keep_Alive then
            Rpc.Keep_Alive(OK); 
            Last_Keep_Alive := Now;
            exit Main_Loop when not OK;     
          end if;
      end;
      Now := Sattmate_Calendar.Clock;
      --restart every day
      Is_Time_To_Exit          := Now.Hour = 01 and then 
                                  Now.Minute = 00 and then
                                  Now.Second >= 50 and then 
                                  Day_Last_Check /= Now.Day;
                                  
      Is_Time_To_Check_Balance := Now.Hour = 05 and then 
                                  Now.Minute = 00 and then
                                  Now.Second >= 50 and then 
                                  Day_Last_Check /= Now.Day;
      Log(Me, "Is_Time_To_Check_Balance: " & Is_Time_To_Check_Balance'Img);  --??
--      Is_Time_To_Check_Balance := True;
      exit Receive_Loop when Is_Time_To_Check_Balance;
      
      exit Main_Loop when Is_Time_To_Exit;
      
    end loop Receive_Loop;  
    Day_Last_Check := Now.Day;
    
    Ask : loop
      Balance(Betfair_Result, Saldo );
      Log(Me, "Ask_Balance result : " & Betfair_Result 'Img);
      case Betfair_Result is
        when Rpc.Ok => exit Ask ;
        when Rpc.Logged_Out => 
          delay 2.0;
          Log(Me, "Logged_Out, will log in again");  --??
          Rpc.Login;    
        when Rpc.Timeout =>  delay 5.0;
      end case;           
    end loop Ask;
    
  end loop Main_Loop; 
               
  Log(Me, "shutting down, close db");
  Sql.Close_Session;
  Rpc.Logout;
  Log(Me, "do_exit");
  Posix.Do_Exit(0); -- terminate
  Log(Me, "after do_exit");
 
exception
  when Lock.Lock_Error => 
      Posix.Do_Exit(0); -- terminate

  when E: others =>
    Sattmate_Exception.Tracebackinfo(E);
    Posix.Do_Exit(0); -- terminate
end Saldo_Fetcher;

