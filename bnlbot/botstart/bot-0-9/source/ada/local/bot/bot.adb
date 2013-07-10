with Sattmate_Types; use Sattmate_Types;
with Sattmate_Exception;
with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
with Token;
with General_Routines; use General_Routines;
with Bot_Config;
with Lock; --?
with Text_io;
with Sql;
with Bot_Messages;
with Posix;
with Logging; use Logging;
with Process_Io;
with Core_Messages;

procedure Bot is
  Timeout  : Duration := 120.0; 
  My_Token : Token.Token_Type;
  Msg      : Process_Io.Message_Type;
  Me       : constant String := "Main";  
  
begin
--  misc_init ; -- read from cmd-line?
  Bot_Config.Config.Read; -- even from cmdline
  
  if Bot_Config.Config.System_Section.Daemonize then
    Posix.Daemonize;
  end if;
  
  Logging.Open(To_String(Bot_Config.Config.Bot_Log_file_Name));
  Log(Bot_Config.Config.To_String);
  Log(Me & " Login betfair");
  My_Token.Login(
    Username   => To_String(Bot_Config.Config.Betfair_Section.Username),
    Password   => To_String(Bot_Config.Config.Betfair_Section.Password),
    Product_Id => To_String(Bot_Config.Config.Betfair_Section.Product_Id),  
    Vendor_id  => To_String(Bot_Config.Config.Betfair_Section.Vendor_id)
  );
  Log(Me & " Login betfair done");
   
  Log(Me & " Connect Db");
  Sql.Connect
        (Host     => To_String(Bot_Config.Config.Database_Section.Host),
         Port     => 5432,
         Db_Name  => To_String(Bot_Config.Config.Database_Section.Name),
         Login    => To_String(Bot_Config.Config.Database_Section.Username),
         Password => To_String(Bot_Config.Config.Database_Section.Password));
  Log(Me & " db Connected");
         
  Log(Me & " Start main loop");
  Main_Loop : loop
    begin
      Log(Me & " Start receive");
      Process_Io.Receive(Msg, Timeout);
      
      Log(Me & " msg : "& Process_Io.Identity(Msg)'Img & " from " & Trim(Process_Io.Sender(Msg).Name));
      
      case Process_Io.Identity(Msg) is
        when Core_Messages.Exit_Message               => exit Main_Loop;
        when Core_Messages.Enter_Console_Mode_Message => null ; --Enter_Console;
        when Core_Messages.Read_Config_Message        => Bot_Config.Re_Read_Config ; 
        when Bot_Messages.Bet_Notification_Message    => null; --Treat_Bet(Msg.Data,My_Token);
        when others => Log(Me & " Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Log(Me & " Timeout start");
        if not My_Token.Keep_Alive then
          My_Token.Login(
            Username   => To_String(Bot_Config.Config.Betfair_Section.Username),
            Password   => To_String(Bot_Config.Config.Betfair_Section.Password),
            Product_Id => To_String(Bot_Config.Config.Betfair_Section.Product_Id),  
            Vendor_id  => To_String(Bot_Config.Config.Betfair_Section.Vendor_id)
          );
        end if;
        Log(Me & " Timeout stop");
    end;    
  end loop Main_Loop;
  Log(Me & " Close db");
  Sql.Close_Session;
  Log(Me & " Db Closed");
  Logging.Close;
  

exception
  when E: others => Sattmate_Exception.Tracebackinfo(E);

end Bot;
