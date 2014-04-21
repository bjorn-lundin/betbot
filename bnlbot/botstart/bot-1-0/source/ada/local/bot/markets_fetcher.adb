--with Text_Io;
with Sattmate_Exception;
with Sattmate_Types; use Sattmate_Types;
with Sql;
with General_Routines;
with Ada.Calendar.Time_Zones;
with Sattmate_Calendar; use Sattmate_Calendar;
with Gnatcoll.Json; use Gnatcoll.Json;

with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;

with Token ;
with Lock ;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Posix;
with Table_Aevents;
with Table_Amarkets;
with Table_Arunners;
with Table_Aprices;
with Ini;
with Logging; use Logging;

with Ada.Environment_Variables;

with Process_IO;
with Bot_Messages;
with Core_Messages;
with Bot_Types;

with RPC ; 

procedure Markets_Fetcher is
  package EV renames Ada.Environment_Variables;
  use type Sql.Transaction_Status_Type;
  
  Me : constant String := "Main.";  

  Msg      : Process_Io.Message_Type;

  No_Such_UTC_Offset,
  No_Such_Field  : exception;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Ba_Daemon    : aliased Boolean := False;
  Cmd_Line : Command_Line_Configuration;
  Query_List_Market_Catalogue : JSON_Value := Create_Object;
  Query_List_Market_Book      : JSON_Value := Create_Object;

--  Answer_List_Market_Catalogue,
--  Answer_List_Market_Book     : Aws.Response.Data;
  
  Reply_List_Market_Catalogue : JSON_Value := Create_Object; 
  Reply_List_Market_Book      : JSON_Value := Create_Object; 

  Result_List_Market_Catalogue : JSON_Array := Empty_Array;
  Result_List_Market_Book     : JSON_Array := Empty_Array;

  
  Params                      : JSON_Value := Create_Object;
  Filter                      : JSON_Value := Create_Object;
  
  Event, 
  Event_Type, 
  Market                      : JSON_Value := Create_Object;
  
  Market_Start_Time           : JSON_Value := Create_Object;
  Market_Projection,
  Market_Countries,
  Market_Type_Codes,
  Market_Betting_Types,
  Exchange_Ids,
  Event_Type_Ids              : JSON_Array := Empty_Array;
  
  UTC_Offset_Minutes          : Ada.Calendar.Time_Zones.Time_Offset;
  
  Matchodds_Exists : Sql.Statement_Type;
  
----------------------------------------------
  
  Is_Time_To_Exit : Boolean := False;
  
  My_Lock  : Lock.Lock_Type;    
  UTC_Time_Start, UTC_Time_Stop  : Sattmate_Calendar.Time_Type ;
  
  Eleven_Seconds  : Sattmate_Calendar.Interval_Type := (0,0,0,11,0);
--  One_Half_Minute : Sattmate_Calendar.Interval_Type := (0,0,0,30,0);
--  One_Minute      : Sattmate_Calendar.Interval_Type := (0,0,1,0,0);
--  Five_Minutes      : Sattmate_Calendar.Interval_Type := (0,0,5,0,0);
  One_Hour        : Sattmate_Calendar.Interval_Type := (0,1,0,0,0);
  Two_Hours       : Sattmate_Calendar.Interval_Type := (0,2,0,0,0);
  T : Sql.Transaction_Type;
 
  Turns : Integer := 0;
---------------------------------------------------------------  

  
  procedure Insert_Event(Event, Event_Type : JSON_Value) is
    DB_Event : Table_Aevents.Data_Type := Table_Aevents.Empty_Data;
    Eos : Boolean := False;
  begin
    Log(Me, "Insert_Event start"); 
    Rpc.Parse_Event(Event, Event_Type, DB_Event);    
    Table_Aevents.Read(DB_Event, Eos);
    if Eos then
      Table_Aevents.Insert(DB_Event);
    end if;        
    Log(Me, Table_Aevents.To_String(DB_Event)); 
    Log(Me, "Insert_Event stop"); 
  end Insert_Event;
  ------------------------------------------------------------
  procedure Insert_Market(Market : JSON_Value) is
    Service : constant String := "Insert_Market";
    DB_Market : Table_Amarkets.Data_Type := Table_Amarkets.Empty_Data;
    Eos, In_Play    : Boolean    := False;
  begin
    Log(Me & Service, "start " & Table_Amarkets.To_String(DB_Market) );     
    Rpc.Parse_Market(Market, DB_Market, In_Play);
    Table_Amarkets.Read(DB_Market, Eos);
    if Eos then
      Table_Amarkets.Insert(DB_Market);
    end if;         
    Log(Me & Service, "stop " & Table_Amarkets.To_String(DB_Market)); 
  end Insert_Market;
  ----------------------------------------------------------------
  procedure Update_Market(Market : JSON_Value) is
    Service : constant String := "Update_Market";
    DB_Market : Table_Amarkets.Data_Type := Table_Amarkets.Empty_Data;
    Eos, In_Play : Boolean := False;
  begin
    Log(Me & Service, "start"); 
    if Market.Has_Field("marketId") then
      Log(Me, "marketId - '" & Market.Get("marketId") & "'");
      Move(Market.Get("marketId"), DB_Market.Marketid);
    else
      raise No_Such_Field with "Object 'Market' - Field 'marketId'";
    end if;
    
    Log(Me & Service, "will update " & Table_Amarkets.To_String(DB_Market)); 
    Table_Amarkets.Read(DB_Market, Eos);
    if not Eos then
      Rpc.Parse_Market(Market, DB_Market, In_Play);
      Table_Amarkets.Update_Withcheck(DB_Market);
    end if; 
     
     Log(Me & Service, Table_Amarkets.To_String(DB_Market)); 
    Log(Me & Service, "stop"); 
  end Update_Market;

  -------------------------------------------------------------
  
  procedure Insert_Runners(Market : JSON_Value) is
    DB_Runner   : Table_Arunners.Data_Type := Table_Arunners.Empty_Data;
    Runner_List : Table_Arunners.Arunners_List_Pack.List_Type := Table_Arunners.Arunners_List_Pack.Create;
    Service : constant String := "Insert_Runners";
    Eos : Boolean := False;
  begin
    Log(Me & Service, "start"); 
    Rpc.Parse_Runners(Market, Runner_List);
    while not Table_Arunners.Arunners_List_Pack.Is_Empty(Runner_List) loop         
       Table_Arunners.Arunners_List_Pack.Remove_From_Head(Runner_List, DB_Runner);
       Table_Arunners.Read(DB_Runner, Eos);
       if Eos then
         Table_Arunners.Insert(DB_Runner);
       end if;              
    end loop;
    Table_Arunners.Arunners_List_Pack.Release(Runner_List);
    Log(Me & Service, "stop"); 
  end Insert_Runners;
  -------------------------------------------------------------
  procedure Insert_Prices(Market : JSON_Value) is
    DB_Runner_Price : Table_Aprices.Data_Type := Table_Aprices.Empty_Data;
    Eos : Boolean := False;
    Price_List : Table_Aprices.Aprices_List_Pack.List_Type := Table_Aprices.Aprices_List_Pack.Create;   
    Service : constant String := "Insert_Runners";
  begin
    Log(Me & Service, "start");     
    Rpc.Parse_Prices(Market, Price_List);
    while not Table_Aprices.Aprices_List_Pack.Is_Empty(Price_List) loop
      Table_Aprices.Aprices_List_Pack.REmove_From_Head(Price_List, DB_Runner_Price);
      Log(Me, Table_Aprices.To_String(DB_Runner_Price));
      Table_Aprices.Read(DB_Runner_Price, Eos);
      if Eos then
        Table_Aprices.Insert(DB_Runner_Price);
      end if;     
    end loop;
    Table_Aprices.Aprices_List_Pack.Release(Price_List);
    Log(Me & Service, "stop"); 
  end Insert_Prices;
  --------------------------------------------------------------------- 
   
------------------------------ main start -------------------------------------
  Is_Time_To_Check_Markets : Boolean ;
  Market_Found : Boolean;
  Market_Ids                  : JSON_Array := Empty_Array;
  Minute_Last_Check : Sattmate_Calendar.Minute_Type := 0;
  Now : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;
  
begin
  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");
 
  Logging.Open(EV.Value("BOT_HOME") & "/log/markets_fetcher.log");

  Define_Switch
   (Cmd_Line,
    Sa_Par_Bot_User'access,
    Long_Switch => "--user=",
    Help        => "user of bot");

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
   
  Log(Me, "Login");

    -- Ask a pythonscript to login for us, returning a token
  Rpc.Init(
            Username   => Ini.Get_Value("betfair","username",""),
            Password   => Ini.Get_Value("betfair","password",""),
            Product_Id => Ini.Get_Value("betfair","product_id",""),  
            Vendor_Id  => Ini.Get_Value("betfair","vendor_id",""),
            App_Key    => Ini.Get_Value("betfair","appkey","")
          );    
  Rpc.Login;

  Sql.Connect
        (Host     => Ini.Get_Value("database","host",""),
         Port     => Ini.Get_Value("database","port",5432),
         Db_Name  => Ini.Get_Value("database","name",""),
         Login    => Ini.Get_Value("database","username",""),
         Password => Ini.Get_Value("database","password",""));
   
   -- json stuff

   -- Create JSON arrays
  Append(Exchange_Ids , Create("1"));      -- Not Australia 
  Append(Event_Type_Ids , Create("7"));    -- horse
  Append(Event_Type_Ids , Create("4339")); -- hound
  Append(Event_Type_Ids , Create("1")); -- football
--   none for all countries   
--   Append(Market_Countries , Create("GB"));
--   Append(Market_Countries , Create("US"));
--   Append(Market_Countries , Create("IE"));
   
  Append(Market_Betting_Types , Create("ODDS"));
  
  Append(Market_Type_Codes , Create("WIN"));                -- for horses/hounds
  Append(Market_Type_Codes , Create("PLACE"));              -- for horses/hounds
  Append(Market_Type_Codes , Create("MATCH_ODDS"));         -- for football (to lay the draw)
  Append(Market_Type_Codes , Create("CORRECT_SCORE"));      -- for football (to lay 0-0)
  Append(Market_Type_Codes , Create("HALF_TIME_SCORE"));    -- for football (to lay 0-0)
  Append(Market_Type_Codes , Create("SENDING_OFF"));        -- for football 
  Append(Market_Type_Codes , Create("HAT_TRICKED_SCORED")); -- for football
  Append(Market_Type_Codes , Create("ODD_OR_EVEN"));        -- for football 
  Append(Market_Type_Codes , Create("PENALTY_TAKEN"));      -- for football 
  Append(Market_Type_Codes , Create("WIN_BOTH_HALVES"));    -- for football 
  Append(Market_Type_Codes , Create("WIN_HALF"));           -- for football 
  
  Append(Market_Projection , Create("MARKET_DESCRIPTION"));
  Append(Market_Projection , Create("RUNNER_DESCRIPTION"));
  Append(Market_Projection , Create("EVENT"));
  Append(Market_Projection , Create("EVENT_TYPE"));
  Append(Market_Projection , Create("MARKET_START_TIME"));
  
  Main_Loop : loop  
    Market_Found := False;
    Turns := Turns + 1;
    Log(Me, "Turns:" & Turns'Img);
    
    loop   
      begin
        Process_Io.Receive(Msg, 5.0);
        if Sql.Transaction_Status /= Sql.None then
          raise Sql.Transaction_Error with "Uncommited transaction in progress !! BAD!";
        end if;
        
        Log(Me, "msg : "& Process_Io.Identity(Msg)'Img & " from " & General_Routines.Trim(Process_Io.Sender(Msg).Name));
        case Process_Io.Identity(Msg) is
          when Core_Messages.Exit_Message                  => exit Main_Loop;
          when others => Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
        end case;  
      exception
          when Process_io.Timeout =>   
          if Sql.Transaction_Status /= Sql.None then
            raise Sql.Transaction_Error with "Uncommited transaction in progress !! BAD!";
          end if;
      end;
      Now := Sattmate_Calendar.Clock;
      Is_Time_To_Check_Markets := Now.Second >= 50 and then Minute_Last_Check /= Now.Minute;
      Log(Me, "Is_Time_To_Check_Markets: " & Is_Time_To_Check_Markets'Img);  --??
      exit when Is_Time_To_Check_Markets;
      
      --restart every day
      Is_Time_To_Exit := Now.Hour = 01 and then 
                       Now.Minute = 02 ;
    
      exit Main_Loop when Is_Time_To_Exit;
    end loop;           
    Minute_Last_Check := Now.Minute;
    
    T.Start;
    
    UTC_Offset_Minutes := Ada.Calendar.Time_Zones.UTC_Time_Offset;
    case UTC_Offset_Minutes is
      when 60     => UTC_Time_Start := Now - One_Hour;
      when 120    => UTC_Time_Start := Now - Two_Hours;
      when others => raise No_Such_UTC_Offset with UTC_Offset_Minutes'Img;
    end case;   

    --Now set that time 1 hour ahead:
--    UTC_Time_Start := UTC_Time_Start + One_Hour;
    UTC_Time_Stop  := UTC_Time_Start + Eleven_Seconds; 
    
    Market_Start_Time.Set_Field(Field_Name => "from", Field => Sattmate_Calendar.String_Date_Time_ISO(UTC_Time_Start));
    Market_Start_Time.Set_Field(Field_Name => "to",   Field => Sattmate_Calendar.String_Date_Time_ISO(UTC_Time_Stop));
   
    Filter.Set_Field (Field_Name => "exchangeIds",        Field => Exchange_Ids);                    
    Filter.Set_Field (Field_Name => "eventTypeIds",       Field => Event_Type_Ids);                      
    Filter.Set_Field (Field_Name => "marketCountries",    Field => Market_Countries);                
    Filter.Set_Field (Field_Name => "marketTypeCodes",    Field => Market_Type_Codes); 
    Filter.Set_Field (Field_Name => "marketBettingTypes", Field => Market_Betting_Types);    
    Filter.Set_Field (Field_Name => "inPlayOnly",         Field => False);                     
    Filter.Set_Field (Field_Name => "marketStartTime",    Field => Market_Start_Time);
                       
    Params.Set_Field (Field_Name => "filter",           Field => Filter);                     
    Params.Set_Field (Field_Name => "marketProjection", Field => Market_Projection);  
    Params.Set_Field (Field_Name => "locale",           Field => "en"); -- to get ' the draw instead of 'Oavgjort'               
    Params.Set_Field (Field_Name => "sort",             Field => "FIRST_TO_START");
    Params.Set_Field (Field_Name => "maxResults",       Field => "999");
                      
    Query_List_Market_Catalogue.Set_Field (Field_Name => "params",  Field => Params);
    Query_List_Market_Catalogue.Set_Field (Field_Name => "id",      Field => 15);          -- ???
    Query_List_Market_Catalogue.Set_Field (Field_Name => "method",  Field => "SportsAPING/v1.0/listMarketCatalogue");
    Query_List_Market_Catalogue.Set_Field (Field_Name => "jsonrpc", Field => "2.0");
    
    Rpc.Get_JSON_Reply(Query => Query_List_Market_Catalogue,
                       Reply => Reply_List_Market_Catalogue,
                       URL   => Token.URL_BETTING);
    
    if Rpc.API_Exceptions_Are_Present(Reply_List_Market_Catalogue) then
      exit Main_loop;  --  exit main loop, let cron restart program
    end if;

    if Reply_List_Market_Catalogue.Has_Field("result") then
       Result_List_Market_Catalogue := Reply_List_Market_Catalogue.Get("result");
       for i in 1 .. Length (Result_List_Market_Catalogue) loop
         Log(Me, "we have result #:" & i'img);
         Market := Get(Result_List_Market_Catalogue, i);
         
         if Market.Has_Field("marketId") then
           Market_Found := True;
           Insert_Market(Market);
           Event := Market.Get("event");
           if not Event.Has_Field("id") then
             Log(Me, "we no event:" & i'img & " event:" & Event.Write );
           end if;                            
         end if;
         
         if Market.Has_Field("eventType") then
           Event_Type := Market.Get("eventType");
           Insert_Event(Event, Event_Type);
         else
            Log(Me, "we no eventType:" & i'img & " eventType:" & Event_Type.Write );
         end if; 
         
         if Market.Has_Field("runners") then
            Insert_Runners(Market);
         end if;
       end loop;
    end if;  
      -- now get the prices
 
    declare
       Params                      : JSON_Value := Create_Object;
       Price_Data                  : JSON_Array := Empty_Array;
       Price_Projection            : JSON_Value := Create_Object;
       Has_Id                      : Boolean  := False; 
    begin    
      Market_Ids := Empty_Array;
      for i in 1 .. Length (Result_List_Market_Catalogue) loop
        Market := Get(Result_List_Market_Catalogue, i);
        if Market.Has_Field("marketId") then
          Has_Id := True;
          Log(Me, "appending Marketid: '" & Market.Get("marketId") & "'" );
          Append(Market_Ids, Create(string'(Market.Get("marketId"))));
        end if;          
      end loop;
      
      if Has_Id then
      
        Append (Price_Data , Create("EX_BEST_OFFERS"));    
        
        Price_Projection.Set_Field (Field_Name => "priceData", Field => Price_Data);
        
        Params.Set_Field (Field_Name => "priceProjection", Field => Price_Projection);
        Params.Set_Field (Field_Name => "currencyCode",    Field => "SEK");    
        Params.Set_Field (Field_Name => "locale",          Field => "sv");
        Params.Set_Field (Field_Name => "marketIds",       Field => Market_Ids);
        
        Query_List_Market_Book.Set_Field (Field_Name => "params",  Field => Params);
        Query_List_Market_Book.Set_Field (Field_Name => "id",      Field => 15);   --?
        Query_List_Market_Book.Set_Field (Field_Name => "method",  Field => "SportsAPING/v1.0/listMarketBook");
        Query_List_Market_Book.Set_Field (Field_Name => "jsonrpc", Field => "2.0");
              
        Rpc.Get_JSON_Reply(Query => Query_List_Market_Book,
                           Reply => Reply_List_Market_Book,
                           URL   => Token.URL_BETTING);
      
           --  Iterate the Reply_List_Market_Book object. 
        if Reply_List_Market_Book.Has_Field("result") then
          Log(Me, "we have result ");
          Result_List_Market_Book := Reply_List_Market_Book.Get("result");
          for i in 1 .. Length (Result_List_Market_Book) loop
            Log(Me, "we have result #:" & i'img);
            Market := Get(Result_List_Market_Book, i);
            
            if Market.Has_Field("marketId") then
              Update_Market(Market);
              if Market.Has_Field("runners") then
                 Insert_Prices(Market);
              end if;
            end if;
          end loop;
        end if;    
      end if; --has id          
    end;  
    T.Commit;
    
    Log(Me, "Market_Found: " & Market_Found'Img);
    if Market_Found then 
      declare
        use General_Routines;
        Market   : JSON_Value := Create_Object;
        MNR      : Bot_Messages.Market_Notification_Record;
        Receiver : Process_IO.Process_Type := ((others => ' '), (others => ' '));
        type Eos_Type is (Amarket, Aevent);
        Eos       : array (Eos_Type'range) of Boolean := (others => False);
        Db_Market : Table_Amarkets.Data_Type;
        Db_Event  : Table_Aevents.Data_Type;
        Exists    : Boolean := False;
        Sibling_Id :  Bot_Types.Market_Id_Type := (others => ' ');
        --------------------------------------------------------------------                
        procedure Sibling_Market_Exists(L_Eventid     : in     String;
                                        Market_Type   : in     String; 
                                        L_Sibling_Id  :    out Bot_Types.Market_Id_Type ; 
                                        L_Exists      :    out Boolean) is
          L_Eos  : Boolean := True;
          L_Sibling_Market : Table_Amarkets.Data_Type;
        begin
        
          Matchodds_Exists.Prepare("select * from AMARKETS where EVENTID = :EVENTID and MARKETTYPE = :MARKETTYPE");
          Matchodds_Exists.Set("EVENTID", L_Eventid);
          Matchodds_Exists.Set("MARKETTYPE", Market_Type);
          Matchodds_Exists.Open_Cursor;
          Matchodds_Exists.Fetch(L_Eos);
          if not L_Eos then
            L_Sibling_Market := Table_Amarkets.Get(Matchodds_Exists);
          end if;
          Matchodds_Exists.Close_Cursor;
          
          L_Exists := not L_Eos;
          L_Sibling_Id := L_Sibling_Market.Marketid;          
        end Sibling_Market_Exists;
        --------------------------------------------------------------------                
        
      begin
        for i in 1 .. Length (Market_Ids) loop
          Market := Get(Market_Ids, i);
          MNR.Market_Id := (others => ' ');
          Move(String'(Market.Get),MNR.Market_Id);

          --some more detailed dispatching is needed now 
          -- what kind of event is it.  
          T.Start;
            Db_Market.Marketid := MNR.Market_Id;
            Table_Amarkets.Read(DB_Market, Eos(Amarket));
            if not Eos(Amarket) then
              Db_Event.Eventid := Db_Market.Eventid;
              Table_Aevents.Read(Db_Event, Eos(Aevent));
              if not Eos(Aevent) then
              
                case DB_Event.Eventtypeid is
                  ------------------------------------------------------------------                
                  when 1      => -- check markets for MATCH_ODDS/CORRECT_SCORE/HALF_TIME_SCORE
                    -- if CORRECT_SCORE/HALF_TIME_SCORE exists, send their market id instead
                    -- if they do not exist, send nothing, wait for the CORRECT_SCORE/HALF_TIME_SCORE to come in by itself
                    if Trim(Upper_Case(DB_Market.Markettype)) = "MATCH_ODDS" then
                      Sibling_Market_Exists(Db_Event.Eventid, "CORRECT_SCORE", Sibling_Id, Exists);
                      if Exists then
                        Receiver.Name := (others => ' ');
                        Move("bot", Receiver.Name);
                        Log(Me, "Notifying 'bot' with marketid: '" & Sibling_Id & "'");
                        Bot_Messages.Send(Receiver, MNR);
                      end if;     
                      
                      Sibling_Id := (others => ' ');
                      Sibling_Market_Exists(Db_Event.Eventid, "HALF_TIME_SCORE", Sibling_Id, Exists);
                      if Exists then
                        Receiver.Name := (others => ' ');
                        Move("bot", Receiver.Name);
                        Log(Me, "Notifying 'bot' with marketid: '" & Sibling_Id & "'");
                        Bot_Messages.Send(Receiver, MNR);
                      end if;        

                    -- poll_and_log is alway interested in MATCH_ODDS                        
                      Receiver.Name := (others => ' ');
                      Move("poll_and_log", Receiver.Name);
                      Log(Me, "Notifying 'poll_and_log' with marketid: '" & MNR.Market_Id & "'");
                      Bot_Messages.Send(Receiver, MNR);
                    
                    -- if MATCH_ODDS exists,go ahead
                    -- if it does not exist, send nothing, wait for the MATCH_ODDS to come in by itself
                    -- it will then send the market ids of CORRECT_SCORE
                    elsif Trim(Upper_Case(DB_Market.Markettype)) = "CORRECT_SCORE" then
                       Sibling_Market_Exists(Db_Event.Eventid, "MATCH_ODDS", Sibling_Id, Exists);
                      if Exists then
                        Receiver.Name := (others => ' ');
                        Move("bot", Receiver.Name);
                        Log(Me, "Notifying 'bot' with marketid: '" & MNR.Market_Id & "'");
                        Bot_Messages.Send(Receiver, MNR);
                      end if;                
                    -- if MATCH_ODDS exists,go ahead
                    -- if it does not exist, send nothing, wait for the MATCH_ODDS to come in by itself
                    -- it will then send the market ids of HALF_TIME_SCORE
                    elsif Trim(Upper_Case(DB_Market.Markettype)) = "HALF_TIME_SCORE" then
                      Sibling_Market_Exists(Db_Event.Eventid, "MATCH_ODDS", Sibling_Id, Exists);
                      if Exists then
                        Receiver.Name := (others => ' ');
                        Move("bot", Receiver.Name);
                        Log(Me, "Notifying 'bot' with marketid: '" & MNR.Market_Id & "'");
                        Bot_Messages.Send(Receiver, MNR);
                      end if;                
                    else -- pass on as usual
                      Receiver.Name := (others => ' ');
                      Move("bot", Receiver.Name);
                      Log(Me, "Notifying 'bot' with marketid: '" & MNR.Market_Id & "'");
                      Bot_Messages.Send(Receiver, MNR);
                    end if;                    
                  ------------------------------------------------------------------                
                  when 7      =>
                    Receiver.Name := (others => ' ');
                    Move("bot", Receiver.Name);
                    Log(Me, "Notifying 'bot' with marketid: '" & MNR.Market_Id & "'");
                    Bot_Messages.Send(Receiver, MNR);
                    
                    Receiver.Name := (others => ' ');
                    Move("poll", Receiver.Name);
                    Log(Me, "Notifying 'poll' with marketid: '" & MNR.Market_Id & "'");
                    Bot_Messages.Send(Receiver, MNR);                 
                  ------------------------------------------------------------------                
                  when 4339   => 
                    Receiver.Name := (others => ' ');
                    Move("bot", Receiver.Name);
                    Log(Me, "Notifying 'bot' with marketid: '" & MNR.Market_Id & "'");
                    Bot_Messages.Send(Receiver, MNR);
                  ------------------------------------------------------------------                
                  when others => 
                    Receiver.Name := (others => ' ');
                    Move("bot", Receiver.Name);
                    Log(Me, "Notifying 'bot' with marketid: '" & MNR.Market_Id & "'");
                    Bot_Messages.Send(Receiver, MNR);
                  ------------------------------------------------------------------                                  
                end case;  
                             
              end if;
            end if;              
          
          T.Commit;
          
          
        end loop;
      end;  
    end if;        
  end loop Main_Loop; 
               
  Log(Me, "shutting down, close db");
  Sql.Close_Session;
  Log (Me, "db closed, Is_Time_To_Exit " & Is_Time_To_Exit'Img);
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
end Markets_Fetcher;

