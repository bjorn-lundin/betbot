with Ada.Exceptions;
with Ada.Command_Line;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Stacktrace;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Sql;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Calendar2; use Calendar2;
with Bot_Messages;
with Rpc;
with Lock ;
with Posix;
with Ini;
with Logging; use Logging;
with Ada.Environment_Variables;
with Process_IO;
with Core_Messages;
with Table_Amarkets;
with Table_Araceprices;
with Table_Aprices;
with Bot_Svn_Info;
with Config;

with Ada.Containers.Doubly_Linked_Lists;

with Utils;
procedure Poll_And_Log is
  package EV renames Ada.Environment_Variables;

  use type Rpc.Result_Type;

  Me : constant String := "Poll_And_Log.";

  Timeout  : Duration := 10.0;
  My_Lock  : Lock.Lock_Type;

  Msg      : Process_Io.Message_Type;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line : Command_Line_Configuration;

  Now : Calendar2.Time_Type;

  package Market_Id_Pck is new Ada.Containers.Doubly_Linked_Lists(Market_Id_Type);
  Market_Id_List : Market_Id_Pck.List;
  
  Ok,
  Is_Time_To_Exit : Boolean := False;
  Cfg : Config.Config_Type;
  -------------------------------------------------------------
  
  type Return_Value_Type is (Success, Wait, Closed);
  -------------------------------------------------------------
  function Get_Market_Prices(Market_Id : Market_Id_Type) return Return_Value_Type is
    Market    : Table_Amarkets.Data_Type;
    Price_List : Table_Aprices.Aprices_List_Pack2.List;
    In_Play   : Boolean := False;
    
  begin
    Log(Me & "Run", "Treat market: " &  Market_Id);

    Rpc.Get_Market_Prices(Market_Id  => Market_Id,
                          Market     => Market,
                          Price_List => Price_List,
                          In_Play    => In_Play);

--    if Market.Markettype(1..10) = "MATCH_ODDS" and then
--      Market.Totalmatched < Float_8(100_000.0) then
--      return Closed;
--    end if;
    
    if not In_Play then
      return Wait;
    end if;

    declare
      Stat   : Table_Araceprices.Data_Type;
      Tmp    : Table_Aprices.Data_Type;
      T      : Sql.Transaction_Type;
      Status : String (Tmp.Status'range ) := (others => ' ');
    begin
      -- insert into finish table
      T.Start;
        
        
      for Tmp of Price_List loop  
        Log("about to insert into Araceprices: " & Tmp.To_String);
        if  Market.Status(1..9)= "SUSPENDED" then
          Log(Me & "Get_Market_Prices", "SUSPENDED marketid: '" & Market_Id & "'");
        end if;    
        
        if Tmp.Status(1..6) = "ACTIVE" then
          if  Market.Status(1..9)= "SUSPENDED" then
           Status(1..16) := "ACTIVE_SUSPENDED";
          elsif  Market.Status(1..6)= "CLOSED" then
           Status(1..13) := "ACTIVE_CLOSED";
          else
            Move( Tmp.Status, Status);          
          end if;
        
        
          Stat := (
            Marketid     =>  Tmp.Marketid,
            Selectionid  =>  Tmp.Selectionid,
            Pricets      =>  Tmp.Pricets,
            Status       =>  Status,
            Backprice    =>  Tmp.Backprice,
            Layprice     =>  Tmp.Layprice,
            Ixxlupd      =>  Tmp.Ixxlupd,
            Ixxluts      =>  Tmp.Ixxluts
          );
          begin
            Stat.Insert;
            Log("Has inserted: " & Tmp.To_String);
          exception
            when Sql.Duplicate_Index =>
            Log("Duplicate_Index on: " & Tmp.To_String);
          end;
        end if;
      end loop;
      T.Commit;
    end;

    if Market.Status(1..6) = "CLOSED" then
      return Closed;
    end if;

    -- there are 3 items in list, home,draw,away selection ids for the same market.
    -- send 1 only    
    declare
      Receiver : Process_IO.Process_Type := ((others => ' '), (others => ' '));
      MNR      : Bot_Messages.Market_Notification_Record;
    begin
      Move("football_better", Receiver.Name);
      Log(Me, "Notifying 'football_better' with marketid: '" & Market_Id & "'");
      MNR.Market_Id := Market_Id;
      Bot_Messages.Send(Receiver, MNR);        
    end;
    return Success;
  end Get_Market_Prices;
  ---------------------------------------------------------------------
  use type Sql.Transaction_Status_Type;
------------------------------ main start -------------------------------------


  procedure Do_Poll_All(List : in out Market_Id_Pck.List) is
    Return_Value : Return_Value_Type;
    Closed_Market_Id_List : Market_Id_Pck.List;    
  begin
  
    for Market_Id of List loop
      Return_Value := Get_Market_Prices(Market_Id);
      case Return_Value is
        when Success => null;
        when Wait    => null;
        when Closed  => Closed_Market_Id_List.Append(Market_Id);
      end case;          
    end loop;
    
    for Market_Id of Closed_Market_Id_List loop
      declare
         C    : Market_Id_Pck.Cursor := List.First;
         Next : Market_Id_Pck.Cursor;
         use type Market_Id_Pck.Cursor;
      begin
         loop
            exit when C = Market_Id_Pck.No_Element;  
            declare
              M_Id : constant Market_Id_Type := Market_Id_Pck.Element(C);
            begin
              if M_Id /= Market_Id then
                 Market_Id_Pck.Next(Position => C);
              else
                 Next := Market_Id_Pck.Next(C);
                 List.Delete(Position => C);
                 C := Next;
              end if;
            end ;
         end loop;
      end;
    end loop;    
  end Do_Poll_All;
-----------------------------------------------------------------                      

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

  Logging.Open(EV.Value("BOT_HOME") & "/log/poll_and_log.log");

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
        when Bot_Messages.Market_Notification_Message    =>
          declare
            Market_Notification : Bot_Messages.Market_Notification_Record;
          begin
            Market_Notification := Bot_Messages.Data(Msg);
            Market_Id_List.Append(Market_Notification.Market_Id);
            Do_Poll_All(Market_Id_List);
          end ;
        
        when others =>
          Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Rpc.Keep_Alive(OK);
        if not OK then
          Rpc.Login;
        end if;
        Do_Poll_All(Market_Id_List);
    end;
    Now := Calendar2.Clock;

    --restart every day
    Is_Time_To_Exit := Now.Hour = 01 and then
                     ( Now.Minute = 00 or Now.Minute = 00) ; -- timeout = 2 min

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
end Poll_And_Log;

