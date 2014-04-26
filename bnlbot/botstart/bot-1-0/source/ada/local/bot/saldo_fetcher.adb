with Ada;
with Ada.Environment_Variables;
with Ada.Directories;

with Ada.Characters;
with Ada.Characters.Latin_1;

with Ada.Strings;
with Ada.Strings.Fixed;
--with Unicode;
--with Unicode.Encodings;
--with Unicode.CES;
--with Text_Io;
with Sattmate_Exception;
with Sattmate_Types; use Sattmate_Types;
with Sql;
with General_Routines; use General_Routines;

with GNAT;
with GNAT.Sockets;
with GNAT.Command_Line; use GNAT.Command_Line;
with GNAT.Strings;

with Sattmate_Calendar; use Sattmate_Calendar;
with Gnatcoll.Json; use Gnatcoll.Json;

with Rpc;
with Lock ;
with Posix;
with Table_Abalances;
with Ini;
with Logging; use Logging;

with Process_IO;
with Core_Messages;

with AWS;
with AWS.SMTP; 
with AWS.SMTP.Authentication;
with AWS.SMTP.Authentication.Plain;
with AWS.SMTP.Client;


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
---------------------------------------------------------

  function Get_Db_Size(Db_Name : String ) return String ; -- forward declaration only


  procedure Mail_Saldo(Saldo : Table_Abalances.Data_Type) is
     T       : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;
     Subject : constant String             := "BetBot Saldo Report";
     use AWS;
     SMTP_Server_Name : constant String := "email-smtp.eu-west-1.amazonaws.com"; 
     Status : SMTP.Status; 
  begin
    Ada.Directories.Set_Directory(Ada.Environment_Variables.Value("BOT_CONFIG") & "/sslcert");
    declare
      Auth : aliased constant SMTP.Authentication.Plain.Credential :=
                                SMTP.Authentication.Plain.Initialize ("AKIAJZDDS2DVUNB76S6A", 
                                              "AhVJXW+YJRE/AMBPoUEOaCjAaWJWWRTDC8JoU039baJG");
      SMTP_Server : SMTP.Receiver := SMTP.Client.Initialize
                                  (SMTP_Server_Name,
                                   Port       => 2465,
                                   Secure     => True,
                                   Credential => Auth'Unchecked_Access);                                  
      use Ada.Characters.Latin_1;
      Msg : constant String := 
          "Dagens saldo-rapport " & Cr & Lf &
          "konto:     " & Ini.Get_Value("betfair","username","") & Cr & Lf &
          "saldo:     " & F8_Image(Saldo.Balance) & Cr & Lf &
          "exposure:  " & F8_Image(Saldo.Exposure)  & Cr & Lf &
          Cr & Lf &
          "Database sizes:" & Cr & Lf &
          "bnl " & Get_Db_Size("bnl")  & Cr & Lf &
          "jmb " & Get_Db_Size("jmb")  & Cr & Lf &
          "dry " & Get_Db_Size("dry")  & Cr & Lf &
          "ais " & Get_Db_Size("ais")  & Cr & Lf &
          Cr & Lf &          
          "timestamp: " & Sattmate_Calendar.String_Date_Time_ISO (T, " ", " ") & Cr & Lf &
          "sent from: " & GNAT.Sockets.Host_Name ;
          
      Receivers : constant SMTP.Recipients :=  (
                  SMTP.E_Mail("B Lundin", "b.f.lundin@gmail.com") ,
                  SMTP.E_Mail("Joakim Birgerson", "joakim@birgerson.com")
                ); 
    begin     
      SMTP.Client.Send(Server  => SMTP_Server,
                       From    => SMTP.E_Mail ("Nonobet Betbot", "betbot@nonobet.com"),
                       To      => Receivers,
                       Subject => Subject,
                       Message => Msg,
                       Status  => Status);
    end;                   
    if not SMTP.Is_Ok (Status) then
      Log (Me & "Mail_Saldo", "Can't send message: " & SMTP.Status_Message (Status));
    end if;                  
  end Mail_Saldo;

---------------------------------  
  
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
      Mail_Saldo(Saldo);
    end if;  
  end Balance;    
     
     
  -----------------------------------------------------------
  function Get_Db_Size(Db_Name : String ) return String is
    Buff           : String(1..100) := (others => ' ');
    Select_Db_Size : Sql.Statement_Type;
    Eos            : Boolean := False;
    use Ada.Strings;
    use Ada.Strings.Fixed;
    T : Sql.Transaction_Type;
  begin
    T.Start;
    Select_Db_Size.Prepare ("SELECT pg_size_pretty(pg_database_size(:DBNAME))" );
    Select_Db_Size.Set("DBNAME", Db_Name);
    Select_Db_Size.Open_Cursor;
    Select_Db_Size.Fetch(Eos);
    if not Eos then
      Select_Db_Size.Get(1, Buff);
    else
      Move("No such db: " & Db_Name, Buff);    
    end if;
    Select_Db_Size.Close_Cursor;
    T.Commit;
    return Trim(Buff);  
  end Get_Db_Size;
     
------------------------------ main start -------------------------------------
  Is_Time_To_Check_Balance,
  Is_Time_To_Exit  : Boolean := False;
  Day_Last_Check : Sattmate_Calendar.Day_Type := 1;
  Now : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;
  Last_Keep_Alive : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
  
  OK : Boolean := False;
  Saldo : Table_Abalances.Data_Type;
  Global_Enabled : Boolean := True;
begin
  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini"); 
  Global_Enabled := Ini.Get_Value("email","enabled",True);
 
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
  My_Lock.Take(EV.Value("BOT_NAME"));    
   
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

  
  -- to get mail on the 1st of each month too, if restart
  if Now.Day = 1 then
    Day_Last_Check := 12; --cannot be 2, if restart day 01 ...
  end if;
  
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
                                  Now.Minute = 10 and then
                                  Now.Second >= 50 and then 
                                  Day_Last_Check /= Now.Day;
      Log(Me, "Is_Time_To_Check_Balance: " & Is_Time_To_Check_Balance'Img &
      " Day_Last_Check:" & Day_Last_Check'Img &
      " Now.Day:" & Now.Day'Img);  --??
--      Is_Time_To_Check_Balance := True;
      exit Receive_Loop when Is_Time_To_Check_Balance;
      
      exit Main_Loop when Is_Time_To_Exit;
      
    end loop Receive_Loop;  
    Day_Last_Check := Now.Day;
    
    
    if Global_Enabled then   
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
    else  
      Log(Me, "sending mails not enabled in [email] section of login.ini");
    end if;  
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

