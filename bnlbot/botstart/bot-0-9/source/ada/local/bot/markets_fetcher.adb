--with Unchecked_Conversion;
with Sattmate_Exception;
--with Sattmate_Types; use Sattmate_Types;
--with Sql;
--with General_Routines;
--with Simple_List_Class;
--pragma Elaborate_All(Simple_List_Class);

with Logging; use Logging;
with Text_Io; 
with Aws;
with Aws.Client;
with Aws.Response;
with Aws.Headers;
with Aws.Headers.Set;
with Ada.Calendar.Time_Zones;
with Sattmate_Calendar; use Sattmate_Calendar;
with Gnatcoll.Json; use Gnatcoll.Json;


--with Unicode.CES;
--with Unicode.CES.Basic_8bit;

--with Ada.Strings; use Ada.Strings;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;
--with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;


with Token ;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;


procedure Markets_Fetcher is

  No_Such_UTC_Offset : exception;

  Sa_Par_Token : aliased Gnat.Strings.String_Access;
  Config : Command_Line_Configuration;
  --  Initialize an empty JSON_Value object. We will add values to this
  --  object using the GNATCOLL.JSON.Set_Field procedures.
  Query  : JSON_Value := Create_Object;
  Reply  : JSON_Value := Create_Object;
  
  Params : JSON_Value := Create_Object;
  Filter : JSON_Value := Create_Object;
  
  Market_Start_Time : JSON_Value := Create_Object;
  Market_Projection,
  Market_Countries,
  Market_Type_Codes,
  Exchange_Ids,
  Event_Type_Ids :JSON_Array := Empty_Array;
  
  UTC_Offset_Minutes : Ada.Calendar.Time_Zones.Time_Offset;
  
----------------------------------------------

  Answer : Aws.Response.Data;
  
  My_Token : Token.Token_Type;
  My_Headers : Aws.Headers.List := Aws.Headers.Empty_List;
    
  UTC_Time_Start, UTC_Time_Stop  : Sattmate_Calendar.Time_Type ;
  
  One_Minute : Sattmate_Calendar.Interval_Type := (0,0,1,0,0);
  One_Hour   : Sattmate_Calendar.Interval_Type := (0,1,0,0,0);
  Two_Hours  : Sattmate_Calendar.Interval_Type := (0,2,0,0,0);
  
---------------------------------------------------------------

   procedure Handler
     (Name  : in UTF8_String;
      Value : in JSON_Value)
   is
      use Text_IO;
   begin
      case Kind (Val => Value) is
         when JSON_Null_Type =>
            Put_Line (Name & "(null):null");
         when JSON_Boolean_Type =>
            Put_Line (Name & "(boolean):" & Boolean'Image (Get (Value)));
         when JSON_Int_Type =>
            Put_Line (Name & "(integer):" & Integer'Image (Get (Value)));
         when JSON_Float_Type =>
            Put_Line (Name & "(float):" & Float'Image (Get (Value)));
         when JSON_String_Type =>
            Put_Line (Name & "(string):" & Get (Value));
         when JSON_Array_Type =>
            declare
               A_JSON_Array : constant JSON_Array := Get (Val => Value);
               A_JSON_Value : JSON_Value;
               Array_Length : constant Natural := Length (A_JSON_Array);
            begin
               Put (Name & "(array):[");
               for J in 1 .. Array_Length loop
                  New_Line;
                  A_JSON_Value := Get (Arr   => A_JSON_Array,
                                       Index => J);
--                  Put (Get (A_JSON_Value));
                  Put (A_JSON_Value.Write);

                  if J < Array_Length then
                     Put (", ");
                  end if;
               end loop;
               Put ("]");
               New_Line;
            end;
         when JSON_Object_Type =>
            Put_Line (Name & "(object):");
            Map_JSON_Object (Val => Value,
                             CB  => Handler'Access);
      end case;
      --  Decide output depending on the kind of JSON field we're dealing with.
      --  Note that if we get a JSON_Object_Type, then we recursively call
      --  Map_JSON_Object again, which in turn calls this Handler procedure.
   end Handler;

---------------------------------------------------------------  
  
  
begin


   Define_Switch
     (Config,
      Sa_Par_Token'access,
      "-t:",
      Long_Switch => "--token=",
      Help        => "use this token, if token is already retrieved");
    Getopt (Config);  -- process the command line

    if Sa_Par_Token.all = "" then
      Log("Login");
      My_Token.Login; -- Ask a pythonscript to login for us, returning a token
      Log("Logged in with token '" &  My_Token.Get & "'");
    else
      Log("set token '" & Sa_Par_Token.all & "'");
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
    Log("Headers set");

    -- json stuff

    -- Create JSON arrays
    Append(Exchange_Ids , Create("1"));
    
    Append(Event_Type_Ids , Create("7"));    --horse
    Append(Event_Type_Ids , Create("4339")); -- hound
    
    Append(Market_Countries , Create("GB"));
    Append(Market_Countries , Create("US"));
    
    Append(Market_Type_Codes , Create("WIN"));
    Append(Market_Type_Codes , Create("PLACE"));
    
    Append(Market_Projection , Create("RUNNER_DESCRIPTION"));
    Append(Market_Projection , Create("EVENT"));
    Append(Market_Projection , Create("EVENT_TYPE"));
    Append(Market_Projection , Create("MARKET_START_TIME"));
    loop
      UTC_Offset_Minutes := Ada.Calendar.Time_Zones.UTC_Time_Offset;

      case UTC_Offset_Minutes is
        when 60     => UTC_Time_Start := Sattmate_Calendar.Clock - One_Hour;
        when 120    => UTC_Time_Start := Sattmate_Calendar.Clock - Two_Hours;
        when others => raise No_Such_UTC_Offset with UTC_Offset_Minutes'Img;
      end case;   
      UTC_Time_Stop := UTC_Time_Start + One_Minute; 
      
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
--                        Field      => "sv");
                        
      Params.Set_Field (Field_Name => "sort",
                        Field      => "FIRST_TO_START");
   
      Params.Set_Field (Field_Name => "maxResults",
                        Field      => "3");
                        
      Query.Set_Field (Field_Name => "params",
                       Field      => Params);
   
      Query.Set_Field (Field_Name => "id",
                       Field      => 15);
      Query.Set_Field (Field_Name => "method",
                       Field      => "SportsAPING/v1.0/listMarketCatalogue");
      Query.Set_Field (Field_Name => "jsonrpc",
                       Field      => "2.0");
               


      Log("call betfair with ");
      Log(Query.Write);
      --{"jsonrpc": "2.0", "method": "SportsAPING/v1.0/listEventTypes", "params": {"filter":{}}, "id": 1}
      --"{""jsonrpc"": ""2.0"", ""method"": ""SportsAPING/v1.0/listEventTypes"", ""params"": {""filter"":{}}, ""id"": 1}"  
      Answer := Aws.Client.Post (Url          =>  Token.URL,
                                 Data         =>  Query.Write,
                                 Content_Type => "application/json",
                                 Headers      => My_Headers);
      Log("betfair called");
      
      
  --    Log(Aws.Response.Message_Body(Answer));
      
      
     --  Load the reply into a json object
     Reply := Read (Strm     => Aws.Response.Message_Body(Answer),
                    Filename => "");
     Log ("Reply.Write start");
     Log (Reply.Write);
     Log ("Reply.Write stop");
  
     --  Iterate the Reply object. The Handler procedure is responsible for
     --  outputting the contents.
     Log ("--> Reply Start <--");
     Map_JSON_Object (Val   => Reply,
                      CB    => Handler'access);
     Log ("--> Reply Stop <--");
      
     Log("Wait 45 secs");
     Log("Offset" & UTC_Offset_Minutes'Img);
     Log("UTC_Time_Start: " & Sattmate_Calendar.String_Date_Time_ISO(UTC_Time_Start));
     Log("UTC_Time_Stop : " & Sattmate_Calendar.String_Date_Time_ISO(UTC_Time_Stop));
     
     delay 45.0;
   end loop; 
               
               
               
--{
--    "jsonrpc": "2.0", 
--    "method": "SportsAPING/v1.0/listMarketCatalogue", 
--    "params": {    
--               "filter":{
--                         "exchangeIds":["1"],
--                         "eventTypeIds":["7","4339"],
--                         "inPlayOnly":false,
--                         "marketCountries":["GB","US"],
--                         "marketTypeCodes":["WIN","PLACE"],
--                         "marketStartTime":{
--                              "from":"2013-06-20T15:00:00Z"}
--               },
--               "locale":"sv",
--               "sort":"FIRST_TO_START",
--               "maxResults":"3",
--               "marketProjection":["RUNNER_DESCRIPTION","EVENT","EVENT_TYPE","MARKET_START_TIME"]
--    }, 
--    "id": 1
--}
--




--    Sql.Connect
--        (Host     => "192.168.0.13",
--         Port     => 5432,
--         Db_Name  => "betting",
--         Login    => "bnl",
--         Password => "bnl");
--
--
--    if Get_Horses then
--      R := Aws.Client.Get(URL => URL_HORSES);
--      Log("----------- Start Horses -----------------" );
--      My_Reader.Current_Tag := Null_Unbounded_String;
--      Open(Aws.Response.Message_Body(R), Unicode.CES.Basic_8bit.Basic_8bit_Encoding,Input);
--      My_Reader.Set_Feature(Validation_Feature,False);
--      My_Reader.Parse(Input);
--      Close(Input);
--      Log("----------- Stop Horses -----------------" );
--      Log("");
--    end if;
--
--    if Get_Hounds then    
--      R := Aws.Client.Get(URL => URL_HOUNDS);
--      Log("----------- Start Hounds -----------------" );
--      My_Reader.Current_Tag := Null_Unbounded_String;
--      Open(Aws.Response.Message_Body(R), Unicode.CES.Basic_8bit.Basic_8bit_Encoding,Input);
--      My_Reader.Set_Feature(Validation_Feature,False);
--      My_Reader.Parse(Input);
--      Close(Input);
--      Log("----------- Stop Hounds -----------------" );
--      Log("");
--    end if;
--
--    Sql.Close_Session;
    
exception
  when E: others =>
    Sattmate_Exception. Tracebackinfo(E);
end Markets_Fetcher;

