with Text_Io;
with Sattmate_Exception;
with Sattmate_Types; use Sattmate_Types;
with Sql;
with General_Routines;
with Aws;
with Aws.Client;
with Aws.Response;
with Aws.Headers;
with Aws.Headers.Set;
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
--with Ada.Directories;

with Process_IO;
with Bot_Messages;

procedure Markets_Fetcher is
  package EV renames Ada.Environment_Variables;
--  package AD renames Ada.Directories;
  
  
  Me : constant String := "Main.";  

  No_Such_UTC_Offset,
  No_Such_Field  : exception;

  Sa_Par_Token : aliased Gnat.Strings.String_Access;
  Ba_Daemon    : aliased Boolean := False;
  Config : Command_Line_Configuration;
  --  Initialize an empty JSON_Value object. We will add values to this
  --  object using the GNATCOLL.JSON.Set_Field procedures.
  Query_List_Market_Catalogue : JSON_Value := Create_Object;
  Query_List_Market_Book      : JSON_Value := Create_Object;

  Answer_List_Market_Catalogue,
  Answer_List_Market_Book     : Aws.Response.Data;
  
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
  
----------------------------------------------
  
  My_Token : Token.Token_Type;
  My_Lock  : Lock.Lock_Type;
  My_Headers : Aws.Headers.List := Aws.Headers.Empty_List;
    
  UTC_Time_Start, UTC_Time_Stop  : Sattmate_Calendar.Time_Type ;
  
  Eleven_Seconds  : Sattmate_Calendar.Interval_Type := (0,0,0,11,0);
--  One_Half_Minute : Sattmate_Calendar.Interval_Type := (0,0,0,30,0);
--  One_Minute      : Sattmate_Calendar.Interval_Type := (0,0,1,0,0);
  One_Hour        : Sattmate_Calendar.Interval_Type := (0,1,0,0,0);
  Two_Hours       : Sattmate_Calendar.Interval_Type := (0,2,0,0,0);
  T : Sql.Transaction_Type;
 
  Turns : Integer := 0;
---------------------------------------------------------------  

  
  procedure Insert_Event(Event, Event_Type : JSON_Value) is
    DB_Event : Table_Aevents.Data_Type := Table_Aevents.Empty_Data;
   -- event:{"id":"27026778",
   --         "name":"Monm 22nd Jun", 
   --         "countryCode":"GB", 
   --         "openDate":"2013-06-22T17:39:00.000Z", 
   --         "timezone":"Europe/London",
   --         "venue":"Monmore"}
   -- eventType:{"id":"7", 
  --              "name":"Horse Racing"}    
--  type Data_Type is record
--      Eventid :    String (1..11) := (others => ' ') ; -- Primary Key
--      Eventname :    String (1..50) := (others => ' ') ; --
--      Countrycode :    String (1..2) := (others => ' ') ; -- non unique index 2
--      Timezone :    String (1..50) := (others => ' ') ; --
--      Opents :    Time_Type  := Time_Type_First ; -- non unique index 3
--      Eventtypeid :    Integer_4  := 0 ; -- non unique index 4
--      Ixxlupd :    String (1..15) := (others => ' ') ; --
--      Ixxluts :    Time_Type  := Time_Type_First ; --
--  end record;
    Eos : Boolean := False;
  begin
    Log(Me, "Insert_Event start"); 
    
    if Event.Has_Field("id") then
      Move(Event.Get("id"), DB_Event.Eventid);
    else
      raise No_Such_Field with "Object 'Event' - Field 'id'";
    end if;
    
    if Event.Has_Field("name") then
      Move(Event.Get("name"), DB_Event.Eventname);
    else
      raise No_Such_Field with "Object 'Event' - Field 'name'";
    end if;

    if Event.Has_Field("countryCode") then
      Move(Event.Get("countryCode"), DB_Event.Countrycode);
    else
      raise No_Such_Field with "Object 'Event' - Field 'countryCode'";
    end if;
    
    if Event.Has_Field("openDate") then
      declare
        Tmp : String := Event.Get("openDate");
      begin  --       "openDate":"2013-06-22T17:39:00.000Z", 
        DB_Event.Opents := Sattmate_Calendar.To_Time_Type(Tmp(1..10), Tmp(12..23));
      end;
    else
      raise No_Such_Field with "Object 'Event' - Field 'openDate'";
    end if;

    if Event.Has_Field("timezone") then
      Move(Event.Get("timezone"), DB_Event.Timezone);
    else
      raise No_Such_Field with "Object 'Event' - Field 'timezone'";
    end if;
    -- event_type !!
    if Event_Type.Has_Field("id") then
      DB_Event.Eventtypeid := Integer_4'Value(Event_Type.Get("id"));
    else
      raise No_Such_Field with "Object 'Event_Type' - Field 'id'";
    end if;

    Table_Aevents.Read(DB_Event, Eos);
    if Eos then
      Table_Aevents.Insert(DB_Event);
    end if;        
  
    Log(Me, Table_Aevents.To_String(DB_Event)); 
    Log(Me, "Insert_Event stop"); 
  end Insert_Event;

  procedure Insert_Market(Market : JSON_Value) is
    DB_Market : Table_Amarkets.Data_Type := Table_Amarkets.Empty_Data;
--      "result": [{
--        "marketId": "1.109863141",
--        "event": {..},
--        "eventType": {..},
--        "runners": [{..},{..},{..} ... ],
--        "marketName": "A4 480m",
--        "marketStartTime": "2013-06-24T10:19:00.000Z"
--        }]
--  type Data_Type is record
--      Marketid :    String (1..11) := (others => ' ') ; -- Primary Key
--      Marketname :    String (1..50) := (others => ' ') ; --
--      Startts :    Time_Type  := Time_Type_First ; --
--      Eventid :    String (1..11) := (others => ' ') ; -- non unique index 2
--      Markettype :    String (1..6) := (others => ' ') ; -- non unique index 3
--      Status :    String (1..50) := (others => ' ') ; -- non unique index 4
--      Betdelay :    Integer_4  := 0 ; --
--      Numwinners :    Integer_4  := 0 ; -- non unique index 5
--      Numrunners :    Integer_4  := 0 ; --
--      Numactiverunners :    Integer_4  := 0 ; --
--      Totalmatched :    Float_8  := 0.0 ; --
--      Totalavailable :    Float_8  := 0.0 ; --
--      Ixxlupd :    String (1..15) := (others => ' ') ; --
--      Ixxluts :    Time_Type  := Time_Type_First ; --
--  end record;
    Eos    : Boolean    := False;
    Event  : JSON_Value := Create_Object;
    Market_Description : JSON_Value := Create_Object;

  begin
  
  
    Log(Me, "Insert_Market start"); 
    if Market.Has_Field("marketId") then
      Move(Market.Get("marketId"), DB_Market.Marketid);
    else
      raise No_Such_Field with "Object 'Market' - Field 'marketId'";
    end if;
    
    if Market.Has_Field("marketName") then
      Move(Market.Get("marketName"), DB_Market.Marketname);
    else
      raise No_Such_Field with "Object 'Market' - Field 'marketName'";
    end if;

    
    if Market.Has_Field("description") then
      Market_Description := Market.Get("description");
      if Market_Description.Has_Field("marketType") then
        Move(Market_Description.Get("marketType"), DB_Market.Markettype);
      else
        raise No_Such_Field with "Object 'Market_Description' - Field 'marketType'";
      end if;
      
      
    else
      raise No_Such_Field with "Object 'Market' - Field 'description'";
    end if;
  
    
    if Market.Has_Field("marketStartTime") then
      declare
        Tmp : String := Market.Get("marketStartTime");
      begin  --       "marketStartTime":"2013-06-22T17:39:00.000Z", 
        DB_Market.Startts := Sattmate_Calendar.To_Time_Type(Tmp(1..10), Tmp(12..23));
      end;
    else
      raise No_Such_Field with "Object 'Market' - Field 'marketStartTime'";
    end if;

    if Market.Has_Field("event") then
      Event := Market.Get("event");
      if Event.Has_Field("id") then
        Move(Event.Get("id"), DB_Market.Eventid);
      else
        raise No_Such_Field with "Object 'Event' - Field 'id'";
      end if;
    else
      raise No_Such_Field with "Object 'Market' - Field 'event'";
    end if;    
    
    Log(Me, Table_Amarkets.To_String(DB_Market)); 
    
    Table_Amarkets.Read(DB_Market, Eos);
    if Eos then
      Table_Amarkets.Insert(DB_Market);
    end if;     
    
    Log(Me, "Insert_Market stop"); 
  end Insert_Market;

  
  procedure Update_Market(Market : JSON_Value) is
    DB_Market : Table_Amarkets.Data_Type := Table_Amarkets.Empty_Data;
--    "result": [{
--        "numberOfWinners": 2,
--        "betDelay": 0,
--        "marketId": "1.109863158",
--        "totalAvailable": 6.02089E+04,
--        "bspReconciled": false,
--        "numberOfRunners": 6,
--        "numberOfActiveRunners": 6,
--        "totalMatched": 0.00000E+00,
--        "runners": [{ ... }], 
--        "inplay": false,
--        "status": "OPEN",
--        "runnersVoidable": false,
--        "version": 540333571,
--        "isMarketDataDelayed": false,
--        "crossMatching": true,
--        "complete": true
--  type Data_Type is record
--      Marketid :    String (1..11) := (others => ' ') ; -- Primary Key
--      Marketname :    String (1..50) := (others => ' ') ; --
--      Startts :    Time_Type  := Time_Type_First ; --
--      Eventid :    String (1..11) := (others => ' ') ; -- non unique index 2
--      Markettype :    String (1..6) := (others => ' ') ; -- non unique index 3
--      Status :    String (1..50) := (others => ' ') ; -- non unique index 4
--      Betdelay :    Integer_4  := 0 ; --
--      Numwinners :    Integer_4  := 0 ; -- non unique index 5
--      Numrunners :    Integer_4  := 0 ; --
--      Numactiverunners :    Integer_4  := 0 ; --
--      Totalmatched :    Float_8  := 0.0 ; --
--      Totalavailable :    Float_8  := 0.0 ; --
--      Ixxlupd :    String (1..15) := (others => ' ') ; --
--      Ixxluts :    Time_Type  := Time_Type_First ; --
--  end record;
        
    Eos : Boolean := False;
  begin
    Log(Me, "Update_Market start"); 
--    Log(Me, Market.Write); 
    if Market.Has_Field("marketId") then
      Log(Me, "marketId - '" & Market.Get("marketId") & "'");
      Move(Market.Get("marketId"), DB_Market.Marketid);
    else
      raise No_Such_Field with "Object 'Market' - Field 'marketId'";
    end if;
    Table_Amarkets.Read(DB_Market, Eos);
    
    if not Eos then    
      Log(Me, "will update " & Table_Amarkets.To_String(DB_Market)); 
    
      if Market.Has_Field("numberOfWinners") then
        DB_Market.Numwinners := Integer_4(Integer'(Market.Get("numberOfWinners")));
      else
        raise No_Such_Field with "Object 'Market' - Field 'numberOfWinners'";
      end if;
  
      if Market.Has_Field("totalAvailable") then
        DB_Market.Totalavailable := Float_8(Float'(Market.Get("totalAvailable")));
      else
        raise No_Such_Field with "Object 'Market' - Field 'totalAvailable'";
      end if;
  
      if Market.Has_Field("numberOfRunners") then
        DB_Market.Numrunners := Integer_4(Integer'(Market.Get("numberOfRunners")));
      else
        raise No_Such_Field with "Object 'Market' - Field 'numberOfRunners'";
      end if;
  
      if Market.Has_Field("numberOfActiveRunners") then
        DB_Market.Numactiverunners := Integer_4(Integer'(Market.Get("numberOfActiveRunners")));
      else
        raise No_Such_Field with "Object 'Market' - Field 'numberOfActiveRunners'";
      end if;
  
      if Market.Has_Field("totalMatched") then
        DB_Market.Totalmatched := Float_8(Float'(Market.Get("totalMatched")));
      else
        raise No_Such_Field with "Object 'Market' - Field 'totalMatched'";
      end if;
  
      if Market.Has_Field("status") then
        Move(Market.Get("status"), DB_Market.Status);
      else
        raise No_Such_Field with "Object 'Market' - Field 'status'";
      end if;
      
      if Market.Has_Field("betDelay") then
        DB_Market.Betdelay := Integer_4(Integer'(Market.Get("betDelay")));
      else
        raise No_Such_Field with "Object 'Market' - Field 'betDelay'";
      end if;
    
      Table_Amarkets.Update_Withcheck(DB_Market);
--      Table_Amarkets.Update(DB_Market);
      Log(Me, "Update_Market - Update_Withcheck"); 
    end if;     
    
    Log(Me, Table_Amarkets.To_String(DB_Market)); 
    Log(Me, "Update_Market stop"); 
  end Update_Market;
  
  
  procedure Insert_Runners(Market : JSON_Value) is
    DB_Runner : Table_Arunners.Data_Type := Table_Arunners.Empty_Data;
--        "runners": [{
--            "sortPriority": 1,
--            "handicap": 0.00000E+00,
--            "selectionId": 6271034,
--            "runnerName": "1. Russelena Blue"
--        },
--  type Data_Type is record
--      Marketid :    String (1..11) := (others => ' ') ; -- Primary Key
--      Selectionid :    Integer_4  := 0 ; -- Primary Key
--      Sortprio :    Integer_4  := 0 ; --
--      Handicap :    Float_8  := 0.0 ; --
--      Runnername :    String (1..50) := (others => ' ') ; --
--      Runnernamestripped :    String (1..50) := (others => ' ') ; -- non unique index 3
--      Runnernamenum :    String (1..2) := (others => ' ') ; --
--      Ixxlupd :    String (1..15) := (others => ' ') ; --
--      Ixxluts :    Time_Type  := Time_Type_First ; --
--  end record;
   Runners      : JSON_Array := Empty_Array;
   Runner       : JSON_Value := Create_Object;
   Array_Length : Natural ;
   
   Runnernamestripped : String := DB_Runner.Runnernamestripped;
   Runnernamenum      : String := DB_Runner.Runnernamenum;
   Start_Paranthesis,
   Stop_Paranthesis : integer := 0;
   Eos : Boolean := False;
   
  begin
    Log(Me, "Insert_Runners start"); 
    Runners := Market.Get("runners");
    Array_Length := Length (Runners);
    
    
    for J in 1 .. Array_Length loop
      DB_Runner := Table_Arunners.Empty_Data;
      Log(Me, "Insert_Runner start"); 
       Runner := Get (Arr   => Runners, Index => J);
       Log(Me, "  " & Runner.Write);
       
       if Market.Has_Field("marketId") then
         Move(Market.Get("marketId"), DB_Runner.Marketid);
       else
         raise No_Such_Field with "Object 'Market' - Field 'marketId'";
       end if;
          
       if Runner.Has_Field("sortPriority") then
         DB_Runner.Sortprio := Integer_4(Integer'(Runner.Get("sortPriority")));
       else
         raise No_Such_Field with "Object 'Runner' - Field 'sortPriority'";
       end if;
       
       if Runner.Has_Field("handicap") then
         DB_Runner.Handicap := Float_8(Float'(Runner.Get("handicap")));
       else
         raise No_Such_Field with "Object 'Runner' - Field 'handicap'";
       end if;
       
       if Runner.Has_Field("selectionId") then
         DB_Runner.Selectionid := Integer_4(Integer'(Runner.Get("selectionId")));
       else
         raise No_Such_Field with "Object 'Runner' - Field 'selectionId'";
       end if;


       if Runner.Has_Field("runnerName") then
         Move(Runner.Get("runnerName"), DB_Runner.Runnername);
       else
         raise No_Such_Field with "Object 'Runner' - Field 'runnerName'";
       end if;
       
       -- fix runner name
       Runnernamestripped := (others => ' ');
       Runnernamenum := (others => ' ');

       case DB_Runner.Runnername(1) is
           when '1'..'9' =>
              if DB_Runner.Runnername(2) = '.' and then
                 DB_Runner.Runnername(3) = ' ' then
                Runnernamestripped := DB_Runner.Runnername(4 .. DB_Runner.Runnername'Last) & "   ";
                Runnernamenum := DB_Runner.Runnername(1..1) & ' ';
              elsif
                 DB_Runner.Runnername(3) = '.' and then
                 DB_Runner.Runnername(4) = ' ' then
                Runnernamestripped := DB_Runner.Runnername(5 .. DB_Runner.Runnername'Last) & "    ";
                Runnernamenum := DB_Runner.Runnername(1..2);
              else
                null;
              end if;

           when others => 
              Runnernamestripped := DB_Runner.Runnername;
              Move(General_Routines.Trim(DB_Runner.Sortprio'Img), Runnernamenum);
       end case;

       Start_Paranthesis := -1;
       Stop_Paranthesis  := -1;

       for i in Runnernamestripped'range loop
         case Runnernamestripped(i) is
           when '('    => Start_Paranthesis := i;
           when ')'    => Stop_Paranthesis  := i;
           when others => null;
         end case;
       end loop;

       if  Start_Paranthesis > -1 and then
           Stop_Paranthesis > -1 and then
           General_Routines.Lower_Case(Runnernamestripped(Start_Paranthesis .. Stop_Paranthesis)) = "(res)" then
           Log(Me, Runnernamestripped);
         Runnernamestripped(Start_Paranthesis .. Stop_Paranthesis) := (others => ' ');
           Log(Me, Runnernamestripped);
       end if;
       DB_Runner.Runnernamestripped := Runnernamestripped;
       DB_Runner.Runnernamenum      := Runnernamenum;
       
       
       
       Log(Me, Table_Arunners.To_String(DB_Runner)); 
       
       Table_Arunners.Read(DB_Runner, Eos);
       if Eos then
         Table_Arunners.Insert(DB_Runner);
       end if;     
       
       
       Log(Me, "Insert_Runner stop"); 
    end loop;
    Log(Me, "Insert_Runners stop"); 
  end Insert_Runners;

  procedure Insert_Runners_Prices(Market : JSON_Value) is
    DB_Runner_Price : Table_Aprices.Data_Type := Table_Aprices.Empty_Data;
--        "runners": [{
--            "handicap": 0.00000E+00,
--            "totalMatched": 0.00000E+00,
--            "selectionId": 7311189,
--            "status": "ACTIVE",
--            "ex": {
--                "tradedVolume": [],
--                "availableToBack": [{
--                    "size": 1.47106E+03,
--                    "price": 1.06000E+00
--                },
--                {
--                    "size": 4.14300E+01,
--                    "price": 1.04000E+00
--                },
--                {
--                    "size": 8.28656E+03,
--                    "price": 1.03000E+00
--                }],
--                "availableToLay": [{
--                    "size": 2.07160E+02,
--                    "price": 4.00000E+01
--                }]
--            }
--        },
--  type Data_Type is record
--      Marketid :    String (1..11) := (others => ' ') ; -- Primary Key
--      Selectionid :    Integer_4  := 0 ; -- Primary Key
--      Pricets :    Time_Type  := Time_Type_First ; -- Primary Key
--      Status :    String (1..50) := (others => ' ') ; --
--      Totalmatched :    Float_8  := 0.0 ; --
--      Backprice :    Float_8  := 0.0 ; --
--      Layprice :    Float_8  := 0.0 ; --
--      Ixxlupd :    String (1..15) := (others => ' ') ; --
--      Ixxluts :    Time_Type  := Time_Type_First ; --
--  end record;
  
   Back, Lay, Ex, Runner        : JSON_Value := Create_Object;
   Back_Array,Lay_Array,Runner_Prices : JSON_Array := Empty_Array;
   Array_Length      :  Natural;
   Array_Length_Back :  Natural;
   Array_Length_Lay  :  Natural;
   Now           : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;
   Eos : Boolean := False;
  begin
  
    Log(Me, "Insert_Runners_Prices start"); 
    --some fields are missing if runner is removed, accept that
    Runner_Prices := Market.Get("runners");
    Array_Length  := Length (Runner_Prices);
    
    for J in 1 .. Array_Length loop
      DB_Runner_Price := Table_Aprices.Empty_Data;
    
       Log(Me, "Insert_Runner_Price start"); 
       Runner := Get (Arr   => Runner_Prices, Index => J);
       Log(Me, "  " & Runner.Write);
       
       if Market.Has_Field("marketId") then
         Move(Market.Get("marketId"), DB_Runner_Price.Marketid);
       else
         raise No_Such_Field with "Object 'Market' - Field 'marketId'";
       end if;

       if Runner.Has_Field("selectionId") then
         DB_Runner_Price.Selectionid := Integer_4(Integer'(Runner.Get("selectionId")));
       else
         raise No_Such_Field with "Object 'Runner' - Field 'selectionId'";
       end if;

       if Runner.Has_Field("status") then
         Move(Runner.Get("status"), DB_Runner_Price.Status);
       else
         raise No_Such_Field with "Object 'Runner' - Field 'status'";
       end if;
       
       if Runner.Has_Field("totalMatched") then
         DB_Runner_Price.Totalmatched := Float_8(Float'(Runner.Get("totalMatched")));
       end if;

       DB_Runner_Price.Pricets := Now;

       if Runner.Has_Field("ex") then
         Ex := Runner.Get("ex");
         if Ex.Has_Field("availableToBack") then
           Back_Array := Ex.Get("availableToBack");
           Array_Length_Back := Length(Back_Array);
           if Array_Length_Back >= 1 then
              Back := Get (Arr   => Back_Array, Index => 1);
             if Back.Has_Field("price") then
               DB_Runner_Price.Backprice := Float_8(Float'(Back.Get("price")));
             else
               raise No_Such_Field with "Object 'Back' - Field 'price'";
             end if;
           end if;
         else
           raise No_Such_Field with "Object 'Back' - Field 'availableToBack'";         
         end if;          
         
         if Ex.Has_Field("availableToLay") then
           Lay_Array := Ex.Get("availableToLay");
           Array_Length_Lay := Length(Lay_Array);
           if Array_Length_Lay >= 1 then
              Lay := Get (Arr   => Lay_Array, Index => 1);
             if Lay.Has_Field("price") then
               DB_Runner_Price.Layprice := Float_8(Float'(Lay.Get("price")));
             else
               raise No_Such_Field with "Object 'Lay' - Field 'price'";
             end if;
           end if;
         else
           raise No_Such_Field with "Object 'Lay' - Field 'availableToLay'";         
         end if;
       else -- no 'ex'
           raise No_Such_Field with "Object 'Runner' - Field 'ex'";         
       end if;
       
       
       Log(Me, Table_Aprices.To_String(DB_Runner_Price));
       Table_Aprices.Read(DB_Runner_Price, Eos);
       if Eos then
         Table_Aprices.Insert(DB_Runner_Price);
       end if;     
       
       Log(Me, "Insert_Runner_Price stop"); 
    end loop;
    Log(Me, "Insert_Runners_Prices stop"); 
  end Insert_Runners_Prices;

  
   
------------------------------ main start -------------------------------------
  Parsed_Ok1, Parsed_Ok2, Is_Time_To_Check_Markets : Boolean ;
  Post_Timeouts : integer_4 := 0;
  Market_Found : Boolean;
  Market_Ids                  : JSON_Array := Empty_Array;
begin
  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");
 
  Logging.Open(EV.Value("BOT_HOME") & "/log/markets_fetcher.log");
  
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
   My_Lock.Take("markets_fetcher");

   
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
--        (Host     => "192.168.0.13",
        (Host     => "localhost",
         Port     => 5432,
         Db_Name  => "bnl",
         Login    => "bnl",
         Password => "bnl");
   
   -- json stuff

   -- Create JSON arrays
   Append(Exchange_Ids , Create("1"));
   
   Append(Event_Type_Ids , Create("7"));    --horse
   Append(Event_Type_Ids , Create("4339")); -- hound
--   none for all countries   
--   Append(Market_Countries , Create("GB"));
--   Append(Market_Countries , Create("US"));
--   Append(Market_Countries , Create("IE"));
   
   Append(Market_Betting_Types , Create("ODDS"));
   
   Append(Market_Type_Codes , Create("WIN"));
   Append(Market_Type_Codes , Create("PLACE"));
   
   Append(Market_Projection , Create("MARKET_DESCRIPTION"));
   Append(Market_Projection , Create("RUNNER_DESCRIPTION"));
   Append(Market_Projection , Create("EVENT"));
   Append(Market_Projection , Create("EVENT_TYPE"));
   Append(Market_Projection , Create("MARKET_START_TIME"));
   
   Main_Loop : loop
     Market_Found := False;
     Is_Time_To_Check_Markets := Sattmate_Calendar.Clock.Second >= 50 ;
   
     if Is_Time_To_Check_Markets then
       Turns := Turns + 1;
       Log(Me, "Turns:" & Turns'Img);
  --     if Turns mod 3 = 0 then
  --       GNATCOLL.Logs.Finalize;
  --       if AD.Exists(EV.Value("BOT_CONFIG") & "/log/market_fetcher.cfg") then
  --         GNATCOLL.Logs.Parse_Config_File(EV.Value("BOT_CONFIG") & "/log/market_fetcher.cfg"); 
  --       elsif AD.Exists(EV.Value("BOT_CONFIG") & "/log/bot_default.cfg") then
  --         GNATCOLL.Logs.Parse_Config_File(EV.Value("BOT_CONFIG") & "/log/bot_default.cfg"); 
  --       else
  --         raise Program_Error with "No log config file found"; 
  --       end if;  
  --       
  --     end if;
     
     
       Sql.Start_Read_Write_Transaction(T);
     
       UTC_Offset_Minutes := Ada.Calendar.Time_Zones.UTC_Time_Offset;
  
       case UTC_Offset_Minutes is
         when 60     => UTC_Time_Start := Sattmate_Calendar.Clock - One_Hour;
         when 120    => UTC_Time_Start := Sattmate_Calendar.Clock - Two_Hours;
         when others => raise No_Such_UTC_Offset with UTC_Offset_Minutes'Img;
       end case;   
  --     UTC_Time_Stop := UTC_Time_Start + One_Minute; 
       UTC_Time_Stop := UTC_Time_Start + Eleven_Seconds; 
       
       
       Market_Start_Time.Set_Field(Field_Name => "from",
                                   Field      => Sattmate_Calendar.String_Date_Time_ISO(UTC_Time_Start));
       Market_Start_Time.Set_Field(Field_Name => "to",
                                   Field      => Sattmate_Calendar.String_Date_Time_ISO(UTC_Time_Stop));
    
       Filter.Set_Field (Field_Name => "exchangeIds",
                         Field      => Exchange_Ids);
                          
       Filter.Set_Field (Field_Name => "eventTypeIds",
                         Field      => Event_Type_Ids);
                         
       Filter.Set_Field (Field_Name => "marketCountries",
                         Field      => Market_Countries);
                         
       Filter.Set_Field (Field_Name => "marketTypeCodes",
                         Field      => Market_Type_Codes);
    
       Filter.Set_Field (Field_Name => "marketBettingTypes",
                         Field      => Market_Betting_Types);  
    
       Filter.Set_Field (Field_Name => "inPlayOnly",
                         Field      => False);
                         
       Filter.Set_Field (Field_Name => "marketStartTime",
                         Field      => Market_Start_Time);
                          
       Params.Set_Field (Field_Name => "filter",
                         Field      => Filter);
                          
       Params.Set_Field (Field_Name => "marketProjection",
                         Field      => Market_Projection);
    
       Params.Set_Field (Field_Name => "locale",
                         Field      => "en");
                         
       Params.Set_Field (Field_Name => "sort",
                         Field      => "FIRST_TO_START");
    
       Params.Set_Field (Field_Name => "maxResults",
                         Field      => "30");
                         
       Query_List_Market_Catalogue.Set_Field (Field_Name => "params",
                        Field      => Params);
    
       Query_List_Market_Catalogue.Set_Field (Field_Name => "id",
                        Field      => 15);
       Query_List_Market_Catalogue.Set_Field (Field_Name => "method",
                        Field      => "SportsAPING/v1.0/listMarketCatalogue");
       Query_List_Market_Catalogue.Set_Field (Field_Name => "jsonrpc",
                        Field      => "2.0");
  
       Log(Me, "posting " & Query_List_Market_Catalogue.Write);
  --     Log(Me, "posting. ");
       --{"jsonrpc": "2.0", "method": "SportsAPING/v1.0/listEventTypes", "params": {"filter":{}}, "id": 1}
       --"{""jsonrpc"": ""2.0"", ""method"": ""SportsAPING/v1.0/listEventTypes"", ""params"": {""filter"":{}}, ""id"": 1}"  
       Answer_List_Market_Catalogue := Aws.Client.Post (Url          =>  Token.URL,
                                                        Data         =>  Query_List_Market_Catalogue.Write,
                                                        Content_Type => "application/json",
                                                        Headers      =>  My_Headers,
                                                        Timeouts     =>  Aws.Client.Timeouts (Each => 30.0));
       
       
      --Timeout is given as Aws.Response.Message_Body = "Post Timeout" 
       
      --  Load the reply into a json object
      Log(Me, "Got reply");
      Parsed_Ok1 := True;
      begin
      Reply_List_Market_Catalogue := Read (Strm     => Aws.Response.Message_Body(Answer_List_Market_Catalogue),
                                           Filename => "");
      Log(Me, Reply_List_Market_Catalogue.Write);
      Post_Timeouts := 0;
      exception
      when E: others =>
         Parsed_Ok1 := false;
         Log(Me, "Bad reply 1: " & Aws.Response.Message_Body(Answer_List_Market_Catalogue));
         Sattmate_Exception.Tracebackinfo(E);
         if Aws.Response.Message_Body(Answer_List_Market_Catalogue) = "Post Timeout" then 
           Post_Timeouts := Post_Timeouts +1;
         end if;     
         if Post_Timeouts > 5 then
           exit Main_Loop;
         end if;  
      end ;       
                                           
      if Parsed_Ok1 then               
         
         
         declare
           Error, 
           Code, 
           APINGException, 
           Data                      : JSON_Value := Create_Object;
        begin 
          if Reply_List_Market_Catalogue.Has_Field("error") then
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
            Error := Reply_List_Market_Catalogue.Get("error");
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
                      exit; -- exit main loop, let cron restart program
                    else
                      exit; -- exit main loop, let cron restart program
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
        end; 
         
         
         
         
         if Reply_List_Market_Catalogue.Has_Field("result") then
     --      Log(Me, "we have result ");
           Result_List_Market_Catalogue := Reply_List_Market_Catalogue.Get("result");
           for i in 1 .. Length (Result_List_Market_Catalogue) loop
             Log(Me, "we have result #:" & i'img);
             Market := Get(Result_List_Market_Catalogue, i);
             
             if Market.Has_Field("marketId") then
               Market_Found := True;
     --          Log(Me, "we have result #:" & i'img & " Market:" & Market.Write );
               Insert_Market(Market);
               Event := Market.Get("event");
               if Event.Has_Field("id") then
                 null;
     --            Log(Me, "we have event #:" & i'img & " event:" & Event.Write );
               else
                 Log(Me, "we no event:" & i'img & " event:" & Event.Write );
               end if;                            
             end if;
             
             if Market.Has_Field("eventType") then
               Event_Type :=  Market.Get("eventType");
     --          Log(Me, "we have eventType #:" & i'img & " eventType:" & Event_Type.Write );
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
     --{
     --    "jsonrpc": "2.0",
     --    "method": "SportsAPING/v1.0/listMarketBook",
     --    "params": {
     --        "locale": "sv",
     --        "currencyCode": "SEK",
     --        "marketIds": ["1.109808652",
     --        "1.109808651",
     --        "1.109808665"],
     --        "priceProjection": {
     --            "priceData": ["EX_BEST_OFFERS"]
     --        }
     --    },
     --    "id": 1
     --}  
           Params,In_Play              : JSON_Value := Create_Object;
--           Market_Ids                  : JSON_Array := Empty_Array;
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
             
             Price_Projection.Set_Field (Field_Name => "priceData",
                              Field      => Price_Data);
             
             Params.Set_Field (Field_Name => "priceProjection",
                              Field      => Price_Projection);
                              
             Params.Set_Field (Field_Name => "currencyCode",
                              Field      => "SEK");    
             
             
             Params.Set_Field (Field_Name => "locale",
                              Field      => "sv");
                              
             Params.Set_Field (Field_Name => "currencyCode",
                              Field      => "SEK");    
                              
             Params.Set_Field (Field_Name => "marketIds",
                              Field      => Market_Ids);
                              
             
             Query_List_Market_Book.Set_Field (Field_Name => "params",
                              Field      => Params);
             
             Query_List_Market_Book.Set_Field (Field_Name => "id",
                              Field      => 15);
             Query_List_Market_Book.Set_Field (Field_Name => "method",
                              Field      => "SportsAPING/v1.0/listMarketBook");
             Query_List_Market_Book.Set_Field (Field_Name => "jsonrpc",
                              Field      => "2.0");
         
       
             Log(Me, "posting: " & Query_List_Market_Book.Write  );
         
             Answer_List_Market_Book := Aws.Client.Post (Url          =>  Token.URL,
                                                         Data         =>  Query_List_Market_Book.Write,
                                                         Content_Type => "application/json",
                                                         Headers      => My_Headers,
                                                         Timeouts     =>  Aws.Client.Timeouts (Each => 30.0));
             Log(Me, "Got reply ");
       
       --      Log(Me, "betfair called List_Market_Book");
       --      Log(Me, Aws.Response.Message_Body(Answer_List_Market_Book));
              
             --  Load the Reply_List_Market_Catalogue into a json object
             begin
             Reply_List_Market_Book := Read (Strm     => Aws.Response.Message_Body(Answer_List_Market_Book),
                                             Filename => "");
             Parsed_Ok2 := True; 
             exception
             when E: others =>
                Parsed_Ok2 := False; 
                Sattmate_Exception.Tracebackinfo(E);
                Log(Me, "Bad reply 2");
                Text_Io.Put_Line( Aws.Response.Message_Body(Answer_List_Market_Book));
             end ;       
                            
       --      Log(Me, "Reply_List_Market_Book.Write start");
       --      Log(Me, Reply_List_Market_Book.Write);
       --      Log(Me, "Reply_List_Market_Book.Write stop");
         
             if Parsed_Ok2 then
           
               --  Iterate the Reply_List_Market_Book object. 
               if Reply_List_Market_Book.Has_Field("result") then
                 Log(Me, "we have result ");
                 Result_List_Market_Book := Reply_List_Market_Book.Get("result");
                 for i in 1 .. Length (Result_List_Market_Book) loop
                   Log(Me, "we have result #:" & i'img);
                   Market := Get(Result_List_Market_Book, i);
           
                   if Market.Has_Field("inPlay") then
                     In_Play :=  Market.Get("inPlay");
                     Log(Me, "we have inPlay #:" & i'img & " inPlay:" & In_Play.Write );
                   else
                      Log(Me, "we no inPlay:" & i'img );
                   end if; 
                   
                   if Market.Has_Field("marketId") then
         --            Log(Me, "we have result #:" & i'img & " Market:" & Market.Write );
                     Update_Market(Market);
                     if Market.Has_Field("runners") then
                        Insert_Runners_Prices(Market);
                     end if;
                   end if;
                 end loop;
               end if;    
             end if; --has id  
           end if; -- parsed_ok 2   
         end;  
                 
      end if; -- parsed_ok 1   
      Sql.Commit(T);
      if Market_Found then 
        declare
          Market   : JSON_Value := Create_Object;
          MNR      : Bot_Messages.Market_Notification_Record;
          Receiver : Process_IO.Process_Type := ((others => ' '), (others => ' '));
        begin
          Move("bot", Receiver.Name);
          for i in 1 .. Length (Market_Ids) loop
            Market := Get(Market_Ids, i);
            MNR.Market_Id := (others => ' ');
            Move(String'(Market.Get),MNR.Market_Id);
            Log(Me, "Notifying 'bot' with marketid: '" & MNR.Market_Id & "'");
            Bot_Messages.Send(Receiver, MNR);
          end loop;
        end;  
      
      end if;
      
      Log(Me, "Wait 10 secs");
      delay 10.0;
    else  
      Log(Me, "Wait 5 secs to be close to minute shift");
      delay 5.0;
    end if; --Is_Time_To_Check_Markets  
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
end Markets_Fetcher;

