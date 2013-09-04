--with Text_Io;
with Sattmate_Exception;
with Sattmate_Types; use Sattmate_Types;
with Sql;
with General_Routines; use General_Routines;
with Aws;
with Aws.Client;
with Aws.Response;
with Aws.Headers;
with Aws.Headers.Set;
with Ada.Streams;
--with Ada.Strings; use Ada.Strings;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;

with Gnat.Sockets;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

with Sattmate_Calendar; use Sattmate_Calendar;
with Gnatcoll.Json; use Gnatcoll.Json;


with Token ;
with Lock ;
with Posix;
with Table_Abalances;
with Ini;
with Logging; use Logging;

with Ada.Environment_Variables;

with Process_IO;
--with Bot_Messages;
with Core_Messages;

procedure Saldo_Fetcher is
  package EV renames Ada.Environment_Variables;
--  package AD renames Ada.Directories;
  
  Me : constant String := "Main.";  

  Msg      : Process_Io.Message_Type;

--  No_Such_UTC_Offset,
  No_Such_Field  : exception;

  Sa_Par_Token : aliased Gnat.Strings.String_Access;
  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Ba_Daemon    : aliased Boolean := False;
  Config : Command_Line_Configuration;
  
 
----------------------------------------------
  
  My_Token : Token.Token_Type;
  My_Lock  : Lock.Lock_Type;
  My_Headers : Aws.Headers.List := Aws.Headers.Empty_List;
    
  T : Sql.Transaction_Type;
 
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
         ",exposed="  & F8_Image(Saldo.Exposure);
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
  function API_Exceptions_Are_Present(Reply : JSON_Value) return Boolean is
     Error, 
     Code, 
     APINGException, 
     Data                      : JSON_Value := Create_Object;
  begin 
    if Reply.Has_Field("error") then
      --    "error": {
      --        "code": -32099,
      --        "data": {
      --            "exceptionname": "APINGException",
      --            "APINGException": {
      --                "requestUUID": "prdang001-06060844-000842110f",
      --                "errorCode": "INVALID_SESSION_INFORMATION",
      --                "errorDetails": "The session token passed is invalid"
      --                }
      --            },
      --            "message": "ANGX-0003"
      --        }
      Error := Reply.Get("error");
      if Error.Has_Field("code") then
        Code := Error.Get("code");
        Log(Me, "error.code " & Integer(Integer'(Error.Get("code")))'Img);
  
        if Code.Has_Field("data") then
          Data := Code.Get("data");
          if Data.Has_Field("APINGException") then
            APINGException := Data.Get("APINGException");
            if APINGException.Has_Field("errorCode") then
              Log(Me, "APINGException.errorCode " & APINGException.Get("errorCode"));
              if APINGException.Get("errorCode") = "INVALID_SESSION_INFORMATION" then
                return True; -- exit main loop, let cron restart program
              else
                return True; -- exit main loop, let cron restart program
              end if;
            else  
              raise No_Such_Field with "APINGException - errorCode";
            end if;          
          else  
            raise No_Such_Field with "Data - APINGException";
          end if;          
        else  
          raise  No_Such_Field with "Code - data";
        end if;          
      else
        raise No_Such_Field with "Error - code";
      end if;          
    end if;  
    return False;      
  end API_Exceptions_Are_Present;    
  ---------------------------------------------------------------------
  
   
------------------------------ main start -------------------------------------
  Parsed_Ok, Is_Time_To_Check_Balance : Boolean ;
  Post_Timeouts : Integer_4 := 0;
  Day_Last_Check : Sattmate_Calendar.Day_Type := 1;
  Now : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;
  Query_Get_Account_Funds           : JSON_Value := Create_Object;
  Reply_Get_Account_Funds           : JSON_Value := Create_Object;
  Answer_Get_Account_Funds          : Aws.Response.Data;
  Params                            : JSON_Value := Create_Object;
  Result                            : JSON_Value := Create_Object;
  
  
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
    (Config,
     Sa_Par_Token'access,
     "-t:",
     Long_Switch => "--token=",
     Help        => "use this token, if token is already retrieved");

  Define_Switch
     (Config,
      Ba_Daemon'access,
      "-d",
      Long_Switch => "--daemon",
      Help        => "become daemon at startup");
  Getopt (Config);  -- process the command line
   
  if Ba_Daemon then
     Posix.Daemonize;
  end if;
   --must take lock AFTER becoming a daemon ... 
   --The parent pid dies, and would release the lock...
  My_Lock.Take("saldo_fetcher");
   
  if Sa_Par_Token.all = "" then
     Log(Me, "Login");

    -- Ask a pythonscript to login for us, returning a token
     My_Token.Login(
            Username   => Ini.Get_Value("betfair","username",""),
            Password   => Ini.Get_Value("betfair","password",""),
            Product_Id => Ini.Get_Value("betfair","product_id",""),  
            Vendor_id  => Ini.Get_Value("betfair","vendor_id","")
          );    
     Log(Me, "Logged in with token '" &  My_Token.Get & "'");
  else
     Log(Me, "set token '" & Sa_Par_Token.all & "'");
     My_Token.Set(Sa_Par_Token.all);
  end if;

  
  
--  UTC_Offset_Minutes := Ada.Calendar.Time_Zones.UTC_Time_Offset;
--  case UTC_Offset_Minutes is
--      when 60     => UTC_Time_Start := Now - One_Hour;
--      when 120    => UTC_Time_Start := Now - Two_Hours;
--      when others => raise No_Such_UTC_Offset with UTC_Offset_Minutes'Img;
--  end case;   

   --http://forum.bdp.betfair.com/showthread.php?t=1832&page=2
   --conn.setRequestProperty("content-type", "application/json");
   --conn.setRequestProperty("X-Authentication", token);
   --conn.setRequestProperty("X-Application", appKey);
   --conn.setRequestProperty("Accept", "application/json");    
  Aws.Headers.Set.Add (My_Headers, "X-Authentication", My_Token.Get);
  Aws.Headers.Set.Add (My_Headers, "X-Application", Token.App_Key);
  Aws.Headers.Set.Add (My_Headers, "Accept", "application/json");
--   Log(Me, "Headers set");

  Sql.Connect
        (Host     => Ini.Get_Value("database_saldo_fetcher","host",""),
         Port     => Ini.Get_Value("database_saldo_fetcher","port",5432),
         Db_Name  => Ini.Get_Value("database_saldo_fetcher","name",""),
         Login    => Ini.Get_Value("database_saldo_fetcher","username",""),
         Password => Ini.Get_Value("database_saldo_fetcher","password",""));
   
   -- json stuff

   -- Create JSON arrays
  
  Main_Loop : loop  
    
    loop   
      begin
        Process_Io.Receive(Msg, 5.0);
        Log(Me, "msg : "& Process_Io.Identity(Msg)'Img & " from " & General_Routines.Trim(Process_Io.Sender(Msg).Name));
        case Process_Io.Identity(Msg) is
          when Core_Messages.Exit_Message                  => exit Main_Loop;
          when others => Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
        end case;  
      exception
          when Process_io.Timeout => null ; -- rewrite to something nicer !!Get_Markets;    
      end;
      Now := Sattmate_Calendar.Clock;
      Is_Time_To_Check_Balance := Now.Hour = 5 and then 
                                  Now.Minute = 0 and then
                                  Now.Second >= 50 and then 
                                  Day_Last_Check /= Now.Day;
--      Log(Me, "Is_Time_To_Check_Markets: " & Is_Time_To_Check_Balance'Img);  --??
--      Is_Time_To_Check_Balance := True;
      exit when Is_Time_To_Check_Balance;
    end loop;           
    Day_Last_Check := Now.Day;
    
    
    --ask for balance
    -- params is empty ...                     
    Query_Get_Account_Funds.Set_Field (Field_Name => "params",  Field => Params);
    Query_Get_Account_Funds.Set_Field (Field_Name => "id",      Field => 15);          -- ???
    Query_Get_Account_Funds.Set_Field (Field_Name => "method",  Field => "AccountAPING/v1.0/getAccountFunds");
    Query_Get_Account_Funds.Set_Field (Field_Name => "jsonrpc", Field => "2.0");

    Log(Me, "posting " & Query_Get_Account_Funds.Write);
--     Log(Me, "posting. ");
     --{"jsonrpc": "2.0", "method": "AccountAPING/v1.0/getAccountFunds", "params": {}, "id": 1}
    Answer_Get_Account_Funds := Aws.Client.Post (Url          =>  Token.URL_ACCOUNT,
                                                 Data         =>  Query_Get_Account_Funds.Write,
                                                 Content_Type => "application/json",
                                                 Headers      =>  My_Headers,
                                                 Timeouts     =>  Aws.Client.Timeouts (Each => 120.0));
     
     
    --Timeout is given as Aws.Response.Message_Body = "Post Timeout" 
     
    --  Load the reply into a json object
    Log(Me, "Got reply");
    Parsed_Ok := True;
    begin
      Reply_Get_Account_Funds := Read (Strm     => Aws.Response.Message_Body(Answer_Get_Account_Funds),
                                           Filename => "");
      Log(Me, Reply_Get_Account_Funds.Write);
      Post_Timeouts := 0;
    exception
      when E: others =>
        Parsed_Ok := False;
        Log(Me, "Bad reply 1: " & Aws.Response.Message_Body(Answer_Get_Account_Funds));
        Sattmate_Exception.Tracebackinfo(E);
        if Aws.Response.Message_Body(Answer_Get_Account_Funds) = "Post Timeout" then 
          Post_Timeouts := Post_Timeouts +1;
        end if;     
        if Post_Timeouts > 5 then
          exit Main_Loop;
        end if;  
    end ;       

    
    if Parsed_Ok then                             
      if API_Exceptions_Are_Present(Reply_Get_Account_Funds) then
        exit Main_loop;  --  exit main loop, let cron restart program
      end if;
 
      if Reply_Get_Account_Funds.Has_Field("result") then
         Result := Reply_Get_Account_Funds.Get("result");
         if Result.Has_Field("availableToBetBalance") then
           Saldo.Balance := Float_8(Float'(Result.Get("availableToBetBalance")));
         else  
           raise No_Such_Field with "Object 'Result' - Field 'availableToBetBalance'";        
         end if;
           
         if Result.Has_Field("exposure") then
           Saldo.Exposure := Float_8(Float'(Result.Get("exposure")));
         else  
         
         
           raise No_Such_Field with "Object 'Result' - Field 'exposure'";        
         end if; 
        Saldo.Baldate := Now;  
        T.Start;
          Insert_Saldo(Saldo);
        T.Commit;
        Mail_Saldo(Saldo, Now);
      end if;  
    end if;    
  end loop Main_Loop; 
               
  Log(Me, "shutting down, close db");
  Sql.Close_Session;
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

