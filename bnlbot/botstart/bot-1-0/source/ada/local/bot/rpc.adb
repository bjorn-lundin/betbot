

with Sattmate_Exception;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
--with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
with Logging; use Logging;
with Aws;
with Aws.Headers;
with Aws.Headers.Set;
with Aws.Response;
with General_Routines; use General_Routines;
with Aws.Client;
--with Token;

pragma Elaborate_All (AWS.Headers);

package body RPC is

  Global_HTTP_Headers : Aws.Headers.List := Aws.Headers.Empty_List;

  Me : constant String := "RPC.";

  No_Such_Field : exception;
  
  
  Global_Token : Token.Token_Type;
  ---------------------------------
  
  
  procedure Login is
  begin
    Global_Token.Login;
  end Login;

  procedure Init(Username   : in     String;
                 Password   : in     String;
                 Product_Id : in     String;
                 Vendor_Id  : in     String;
                 App_Key    : in     String) is
  begin
       Global_Token.Init(
         Username   => Username,
         Password   => Password,
         Product_Id => Product_Id,
         Vendor_id  => Vendor_Id,
         App_Key    => App_Key
       );  
  end Init;  
  
  
  function Get_Token return Token.Token_Type is
  begin
    return Global_Token;
  end Get_Token;
  
  
  procedure Keep_Alive (Result : out Boolean) is
  begin
    Global_Token.Keep_Alive(Result);
  end Keep_Alive;  
  
  
  procedure Reset_AWS_Headers is
  begin
    Aws.Headers.Set.Reset(Global_HTTP_Headers);
    Aws.Headers.Set.Add (Global_HTTP_Headers, "X-Authentication", Global_Token.Get);
    Aws.Headers.Set.Add (Global_HTTP_Headers, "X-Application", Global_Token.Get_App_Key);
    Aws.Headers.Set.Add (Global_HTTP_Headers, "Accept", "application/json");  
  end Reset_AWS_Headers;
  
  
  
  
  function API_Exceptions_Are_Present(Reply : JSON_Value) return Boolean is
     Error, 
     APINGException, 
     Data                      : JSON_Value := Create_Object;
  begin 
    if Reply.Has_Field("error") then
--              {
--                  "id": 15,
--                  "jsonrpc": "2.0",
--                  "error": {
--                      "code": -32099,
--                      "data": {
--                          "AccountAPINGException": {
--                              "requestUUID": "prdaan001-10091152-0001162118",
--                              "errorCode": "NO_SESSION",
--                              "errorDetails": "Session token is required for this operation"
--                          },
--                          "exceptionname": "AccountAPINGException"
--                      },
--                      "message": "AANGX-0010"
--                  }
--              }      
      
      
      Error := Reply.Get("error");
      if Error.Has_Field("code") then
        Log(Me, "error.code " & Integer(Integer'(Error.Get("code")))'Img);  
        if Error.Has_Field("data") then
          Data := Error.Get("data");
          if Data.Has_Field("APINGException") then
            APINGException := Data.Get("APINGException");
            if APINGException.Has_Field("errorCode") then
              Log(Me, "APINGException.errorCode " & APINGException.Get("errorCode"));
              if APINGException.Has_Field("errorDetails") then
                Log(Me, "APINGException.errorDetails " & APINGException.Get("errorDetails"));
              end if;
              if Data.Has_Field("exceptionname") then
                Log(Me, "exceptionname " & Data.Get("exceptionname"));
              end if;
              return True; -- exit main loop, let cron restart program
            else  
              raise No_Such_Field with "APINGException - errorCode";
            end if;          
          else  
            raise No_Such_Field with "Data - APINGException";
          end if;          
        else  
          raise  No_Such_Field with "Error - data";
        end if;          
      else
        raise No_Such_Field with "Error - code";
      end if;          
    end if;  
    return False;      
  end API_Exceptions_Are_Present;    
  ---------------------------------------------------------------------
  
  procedure Bet_Is_Matched(Betid             : Integer_8 ; 
                           Is_Removed        : out Boolean; 
                           Is_Matched        : out Boolean; 
                           AVG_Price_Matched : out Bet_Price_Type;
                           Size_Matched      : out Bet_Size_Type
                           ) is
    Current_Order_Item,
    Result, 
--    Status,
    Params,
    DateRange, 
    Json_Reply,    
    Json_Query   : JSON_Value := Create_Object;
    
    
    Current_Orders,    
    Bet_Ids      : JSON_Array := Empty_Array;
    String_Betid : String     := Trim(Betid'Img);
    AWS_Reply    : Aws.Response.Data;
  begin
--{
--     "jsonrpc": "2.0",
--     "method": "SportsAPING/v1.0/listCurrentOrders",
--     "params": {
--          "betIds": ["31049748925"],
--          "placedDateRange": {
--          }
--     },
--     "id": 1
--}
    Is_Matched := False;
    AVG_Price_Matched := 0.0;
    Size_Matched := 0.0;
    
    Append (Bet_Ids, Create(String_Betid));    
    Params.Set_Field     (Field_Name => "betIds",          Field => Bet_Ids);
    Params.Set_Field     (Field_Name => "placesDateRange", Field => DateRange);    
    Json_Query.Set_Field (Field_Name => "params",  Field => Params);
    Json_Query.Set_Field (Field_Name => "id",      Field => 15);   --?
    Json_Query.Set_Field (Field_Name => "method",  Field => "SportsAPING/v1.0/listCurrentOrders");
    Json_Query.Set_Field (Field_Name => "jsonrpc", Field => "2.0");
    
    Log(Me, "posting: " & Json_Query.Write);
    
    Reset_AWS_Headers;    
    AWS_Reply := Aws.Client.Post (Url          =>  Token.URL_BETTING,
                                  Data         =>  Json_Query.Write,
                                  Content_Type => "application/json",
                                  Headers      =>  Global_HTTP_Headers,
                                  Timeouts     =>  Aws.Client.Timeouts (Each => 30.0));
    Log(Me & "Bet_Is_Matched", "Got reply, check it ");

    begin
      if String'(Aws.Response.Message_Body(AWS_Reply)) /= "Post Timeout" then
        Json_Reply := Read (Strm     => Aws.Response.Message_Body(AWS_Reply),
                            Filename => "");
        Log(Me & "Bet_Is_Matched", "Got reply: " & Json_Reply.Write  );
      else
        Log(Me & "Bet_Is_Matched", "Post Timeout -> Give up listCurrentOrders");
        return ;
      end if;
    exception
      when others =>
         Log(Me & "Bet_Is_Matched", "***********************  Bad reply start *********************************");
         Log(Me & "Bet_Is_Matched", "Bad reply" & Aws.Response.Message_Body(AWS_Reply));
         Log(Me & "Bet_Is_Matched", "***********************  Bad reply stop  ********" );
         return ;
    end ;

    -- ok, got a valid Json reply, check for errors
    if API_Exceptions_Are_Present(Json_Reply) then
      return ;
    end if;

    -- ok, got a valid Json reply, parse it
--      {
--          "id": 15,
--          "jsonrpc": "2.0",
--          "result": {
--              "moreAvailable": false,
--              "currentOrders": [{
--                  "marketId": "1.111593623",
--                  "betId": "31122359882",
--                  "handicap": 0.00000E+00,
--                  "orderType": "LIMIT",
--                  "sizeCancelled": 0.00000E+00,
--                  "bspLiability": 0.00000E+00,
--                  "selectionId": 7662169,
--                  "sizeVoided": 0.00000E+00,
--                  "status": "EXECUTION_COMPLETE",
--                  "matchedDate": "2013-10-26T12:49:26.000Z",
--                  "placedDate": "2013-10-26T11:44:54.000Z",
--                  "sizeLapsed": 0.00000E+00,
--                  "side": "LAY",
--                  "priceSize": {
--                      "size": 3.21200E+01,
--                      "price": 1.65000E+01
--                  },
--                  "regulatorCode": "MALTA LOTTERIES AND GAMBLING AUTHORITY",
--                  "sizeMatched": 3.21200E+01,
--                  "persistenceType": "PERSIST",
--                  "sizeRemaining": 0.00000E+00,
--                  "averagePriceMatched": 1.65000E+01
--              }]
--          }
--      }
    if Json_Reply.Has_Field("result") then
      Result := Json_Reply.Get("result");
    else
      Log(Me & "Bet_Is_Matched", "NO RESULT!!" );
      return ;
    end if;

    if Result.Has_Field("currentOrders") then
      Current_Orders := Result.Get("currentOrders");
      Log(Me & "Bet_Is_Matched", "got currentOrders, len: " & Length(Current_Orders)'Img);

      if Length(Current_Orders) > Natural(0) then
        Is_Removed := False;
        Current_Order_Item := Get(Current_Orders, 1); -- always element 1, since we only have 1
        Log(Me & "Bet_Is_Matched", "got Current_Order_Item");
 
        if Current_Order_Item.Has_Field("averagePriceMatched") then
          declare
            Tmp : Float := Current_Order_Item.Get("averagePriceMatched"); 
          begin  
            AVG_Price_Matched := Bet_Price_Type(Tmp);
          end ;
        end if;
        
        if Current_Order_Item.Has_Field("sizeMatched") then
          declare
            Tmp : Float := Current_Order_Item.Get("sizeMatched"); 
          begin  
            Size_Matched := Bet_Size_Type(Tmp);
          end ;
        end if;
 
        if Current_Order_Item.Has_Field("status") then
          Log(Me & "Bet_Is_Matched", "got Current_Order_Item.Status");
          Is_Matched := Current_Order_Item.Get("status") = "EXECUTION_COMPLETE";   
        end if;
      else -- len = 0  
        Is_Removed := True;
        Is_Matched := True;   
      end if;        
    end if;
    Log(Me & "Bet_Is_Matched", "Is_Matched: " & Is_Matched'Img & " AVG_Price_Matched: " & F8_Image(Float_8(AVG_Price_Matched)))  ;
  end Bet_Is_Matched;
  -----------------------------------------------------------------  
  procedure Check_Market_Result(Market_Id   : in     Market_Id_Type;
                                Runner_List : in out Table_Arunners.Arunners_List_Pack.List_Type) is
--{
--     "jsonrpc": "2.0",
--     "method": "SportsAPING/v1.0/listMarketBook",
--     "params": {
--          "marketIds": ["1.111572663"]
--     },
--     "id": 1
--}  
    DB_Runner : Table_Arunners.Data_Type;

    Result, 
    Params,
--    Status,
    Runner,
    Json_Reply,    
    Json_Query          : JSON_Value := Create_Object;
    
    Result_Array,Runners, Market_Ids : JSON_Array := Empty_Array;
    AWS_Reply           : Aws.Response.Data;
    Market_Id_Received  : Market_Id_Type := (others => ' ');
  begin
    
    Append (Market_Ids, Create(Market_Id));    
    Params.Set_Field     (Field_Name => "marketIds", Field => Market_Ids);
    Json_Query.Set_Field (Field_Name => "params",  Field => Params);
    Json_Query.Set_Field (Field_Name => "id",      Field => 15);   --?
    Json_Query.Set_Field (Field_Name => "method",  Field => "SportsAPING/v1.0/listMarketBook");
    Json_Query.Set_Field (Field_Name => "jsonrpc", Field => "2.0");
    
    Log(Me, "posting: " & Json_Query.Write);
    
    Reset_AWS_Headers;    
    
    AWS_Reply := Aws.Client.Post (Url          =>  Token.URL_BETTING,
                                  Data         =>  Json_Query.Write,
                                  Content_Type => "application/json",
                                  Headers      =>  Global_HTTP_Headers,
                                  Timeouts     =>  Aws.Client.Timeouts (Each => 30.0));
    Log(Me & "Check_Market_Result", "Got reply, check it ");

    begin
      if String'(Aws.Response.Message_Body(AWS_Reply)) /= "Post Timeout" then
        Json_Reply := Read (Strm     => Aws.Response.Message_Body(AWS_Reply),
                            Filename => "");
        Log(Me & "Check_Market_Result", "Got reply: " & Json_Reply.Write  );
      else
        Log(Me & "Check_Market_Result", "Post Timeout -> Give up listMarketBook");
        return ;
      end if;
    exception
      when others =>
         Log(Me & "Check_Market_Result", "***********************  Bad reply start *********************************");
         Log(Me & "Check_Market_Result", "Bad reply" & Aws.Response.Message_Body(AWS_Reply));
         Log(Me & "Check_Market_Result", "***********************  Bad reply stop  ********" );
         return ;
    end ;

    -- ok, got a valid Json reply, check for errors
    if API_Exceptions_Are_Present(Json_Reply) then
      return ;
    end if;

    -- ok, got a valid Json reply, parse it
--{
--     "jsonrpc": "2.0",
--     "result": [{
--          "marketId": "1.111572663",
--          "isMarketDataDelayed": false,
--          "betDelay": 1,
--          "bspReconciled": true,
--          "complete": true,
--          "inplay": true,
--          "numberOfWinners": 1,
--          "numberOfRunners": 9,
--          "numberOfActiveRunners": 0,
--          "totalMatched": 0.0,
--          "totalAvailable": 0.0,
--          "crossMatching": false,
--          "runnersVoidable": false,
--          "version": 624435001,
--          "runners": [{
--               "selectionId": 5662977,
--               "handicap": 0.0,
--               "adjustmentFactor": 5.3,
--               "removalDate": "2013-10-25T16:19:41.000Z",
--               "status": "REMOVED"
--          },
--          {
--               "selectionId": 6477571,
--               "handicap": 0.0,
--               "adjustmentFactor": 52.5,
--               "status": "LOSER"
--          },
--          {
--               "selectionId": 6437577,
--               "handicap": 0.0,
--               "adjustmentFactor": 12.4,
--               "status": "LOSER"
--          },
--          {
--               "selectionId": 6458897,
--               "handicap": 0.0,
--               "adjustmentFactor": 10.6,
--               "status": "LOSER"
--          },
--          {
--               "selectionId": 4729721,
--               "handicap": 0.0,
--               "adjustmentFactor": 9.6,
--               "status": "WINNER"
--          },
--          {
--               "selectionId": 6784150,
--               "handicap": 0.0,
--               "adjustmentFactor": 4.9,
--               "status": "LOSER"
--          },
--          {
--               "selectionId": 3917956,
--               "handicap": 0.0,
--               "adjustmentFactor": 6.6,
--               "status": "LOSER"
--          },
--          {
--               "selectionId": 6290196,
--               "handicap": 0.0,
--               "adjustmentFactor": 2.4,
--               "status": "LOSER"
--          },
--          {
--               "selectionId": 5119099,
--               "handicap": 0.0,
--               "adjustmentFactor": 1.3,
--               "status": "LOSER"
--          }],
--          "status": "CLOSED"
--     }],
--     "id": 1
--}

    if Json_Reply.Has_Field("result") then
      Result_Array := Json_Reply.Get("result");
      
      Log(Me & "Check_Market_Result", " Length(Result_Array) " &  Length(Result_Array)'Img  );
      
      if Length(Result_Array) > Natural(0) then
        Result := Get(Result_Array,1); -- one element in array only
      else
        Log(Me & "Check_Market_Result", "NO RESULT!! 1 " );
        return ;
      end if;      
    else
      Log(Me & "Check_Market_Result", "NO RESULT!! 2" );
      return ;
    end if;

    
    if Result.Has_Field("marketId") then
      Market_Id_Received := Result.Get("marketId");
      Log(Me & "Check_Market_Result", "got marketId '" & Market_Id_Received & "'");
    else   
      Log(Me & "Check_Market_Result", "NO marketId, return!");
      return;
    end if;
    
    if Result.Has_Field("status") then
      if Result.Get("status") = "CLOSED" or else
         Result.Get("status") = "SETTLED" then

         Log(Me & "Check_Market_Result", "Market IS settled , treat Market_Id_Received '" & Market_Id_Received & "' " &
                                         " Market_Status '" & Result.Get("status") & "'");
      else
        Log(Me & "Check_Market_Result", "Market IS NOT settled, wait/return Market_Id_Received '" & Market_Id_Received & "' " &
                                         " Market_Status '" & Result.Get("status") & "'");
        return;  -- market not settled yed
      end if;      
    end if;
    
    if Result.Has_Field("runners") then
      Runners := Result.Get("runners");
      Log(Me & "Check_Market_Result", "got runners, len: " & Length(Runners)'Img);
      
      if Length(Runners) > Natural(0) then
      
        for i in 1 .. Length(Runners) loop
          DB_Runner := Table_Arunners.Empty_Data;
          
          Runner := Get(Runners, i);
          Log(Me & "Check_Market_Result", "got Runner" & i'Img);
 
          if Runner.Has_Field("selectionId") then
            declare
              i : Integer := Runner.Get("selectionId");
            begin
              DB_Runner.Selectionid := Integer_4(i);
--              Log(Me & "Check_Market_Result", "selection id" & i'Img);
            end; 
          else
            Log(Me & "Check_Market_Result", "no selection id!! Exit loop -  Runner" & i'Img);
            exit ;          
          end if;
          DB_Runner.Marketid := Market_Id_Received ;
          
          if Runner.Has_Field("status") then
            Move(Runner.Get("status"), DB_Runner.Status);
            if Runner.Get("status") = "WINNER" then 
              Log(Me & "Check_Market_Result", "got a winner " & Table_Arunners.To_String(DB_Runner));
            elsif Runner.Get("status") = "REMOVED" then 
              Log(Me & "Check_Market_Result", "got a non-runner " & Table_Arunners.To_String(DB_Runner));
            elsif Runner.Get("status") = "LOSER" then 
              Log(Me & "Check_Market_Result", "got a loser " & Table_Arunners.To_String(DB_Runner));
            else
              Log(Me & "Check_Market_Result", "got something else !! " & Table_Arunners.To_String(DB_Runner));
            end if;
            Table_Arunners.Arunners_List_Pack.Insert_At_Tail(Runner_List, DB_Runner);  
          else
            Log(Me & "Check_Market_Result", "runner is missing status, exit");
            exit;                
          end if;
        end loop;
      end if;        
    end if;
  
  end Check_Market_Result;
  ----------------------------------------------------------------
  
  procedure Market_Status_Is_Changed(Market     : in out Table_Amarkets.Data_Type;
                                     Is_Changed :    out Boolean) is
--{
--     "jsonrpc": "2.0",
--     "method": "SportsAPING/v1.0/listMarketBook",
--     "params": {
--          "marketIds": ["1.111572663"]
--     },
--     "id": 1
--}  

    Result, 
    Params,
--    Status,
    Json_Reply,    
    Json_Query          : JSON_Value := Create_Object;
    
    Result_Array, Market_Ids : JSON_Array := Empty_Array;
    AWS_Reply           : Aws.Response.Data;
    Market_Id_Received  : Market_Id_Type := (others => ' ');
  begin
    Is_Changed := False;
    
    Append (Market_Ids, Create(Market.Marketid));    
    Params.Set_Field     (Field_Name => "marketIds", Field => Market_Ids);
    Json_Query.Set_Field (Field_Name => "params",  Field => Params);
    Json_Query.Set_Field (Field_Name => "id",      Field => 15);   --?
    Json_Query.Set_Field (Field_Name => "method",  Field => "SportsAPING/v1.0/listMarketBook");
    Json_Query.Set_Field (Field_Name => "jsonrpc", Field => "2.0");
    
    Log(Me & "Market_Status_Is_Changed", "posting: " & Json_Query.Write);
    
    Reset_AWS_Headers;    
    
    AWS_Reply := Aws.Client.Post (Url          =>  Token.URL_BETTING,
                                  Data         =>  Json_Query.Write,
                                  Content_Type => "application/json",
                                  Headers      =>  Global_HTTP_Headers,
                                  Timeouts     =>  Aws.Client.Timeouts (Each => 30.0));
    Log(Me & "Market_Status_Is_Changed", "Got reply, check it ");

    begin
      if String'(Aws.Response.Message_Body(AWS_Reply)) /= "Post Timeout" then
        Json_Reply := Read (Strm     => Aws.Response.Message_Body(AWS_Reply),
                            Filename => "");
        Log(Me & "Market_Status_Is_Changed", "Got reply: " & Json_Reply.Write  );
      else
        Log(Me & "Market_Status_Is_Changed", "Post Timeout -> Give up listMarketBook");
        return ;
      end if;
    exception
      when others =>
         Log(Me & "Market_Status_Is_Changed", "***********************  Bad reply start *********************************");
         Log(Me & "Market_Status_Is_Changed", "Bad reply" & Aws.Response.Message_Body(AWS_Reply));
         Log(Me & "Market_Status_Is_Changed", "***********************  Bad reply stop  ********" );
         return ;
    end ;

    -- ok, got a valid Json reply, check for errors
    if API_Exceptions_Are_Present(Json_Reply) then
      raise JSON_Exception with "Bad rpc in Rpc.Market_Status_Is_Changed";
--      return ;
    end if;

    -- ok, got a valid Json reply, parse it
--{
--     "jsonrpc": "2.0",
--     "result": [{
--          "marketId": "1.111572663",
--          "isMarketDataDelayed": false,
--          "betDelay": 1,
--          "bspReconciled": true,
--          "complete": true,
--          "inplay": true,
--          "numberOfWinners": 1,
--          "numberOfRunners": 9,
--          "numberOfActiveRunners": 0,
--          "totalMatched": 0.0,
--          "totalAvailable": 0.0,
--          "crossMatching": false,
--          "runnersVoidable": false,
--          "version": 624435001,
--          "runners": [{
--               "selectionId": 5662977,
--               "handicap": 0.0,
--               "adjustmentFactor": 5.3,
--               "removalDate": "2013-10-25T16:19:41.000Z",
--               "status": "REMOVED"
--          },
--          {
--               "selectionId": 6477571,
--               "handicap": 0.0,
--               "adjustmentFactor": 52.5,
--               "status": "LOSER"
--          },
--          {
--               "selectionId": 6437577,
--               "handicap": 0.0,
--               "adjustmentFactor": 12.4,
--               "status": "LOSER"
--          },
--          {
--               "selectionId": 6458897,
--               "handicap": 0.0,
--               "adjustmentFactor": 10.6,
--               "status": "LOSER"
--          },
--          {
--               "selectionId": 4729721,
--               "handicap": 0.0,
--               "adjustmentFactor": 9.6,
--               "status": "WINNER"
--          },
--          {
--               "selectionId": 6784150,
--               "handicap": 0.0,
--               "adjustmentFactor": 4.9,
--               "status": "LOSER"
--          },
--          {
--               "selectionId": 3917956,
--               "handicap": 0.0,
--               "adjustmentFactor": 6.6,
--               "status": "LOSER"
--          },
--          {
--               "selectionId": 6290196,
--               "handicap": 0.0,
--               "adjustmentFactor": 2.4,
--               "status": "LOSER"
--          },
--          {
--               "selectionId": 5119099,
--               "handicap": 0.0,
--               "adjustmentFactor": 1.3,
--               "status": "LOSER"
--          }],
--          "status": "CLOSED"
--     }],
--     "id": 1
--}

    if Json_Reply.Has_Field("result") then
      Result_Array := Json_Reply.Get("result");
    
      if Length(Result_Array) > Natural(0) then
        Result := Get(Result_Array,1); -- one element in array only
      else
        Log(Me & "Check_Market_Result", "NO RESULT!! 3 " );
        return ;
      end if;      
    else
      Log(Me & "Check_Market_Result", "NO RESULT!! 4" );
      return ;
    end if;
      
    if Result.Has_Field("marketId") then
      Market_Id_Received := Result.Get("marketId");
      Log(Me & "Market_Status_Is_Changed", "got marketId '" & Market_Id_Received & "'");
    else   
      Log(Me & "Market_Status_Is_Changed", "NO marketId, return!");
      return;
    end if;
    
    if Result.Has_Field("status") then
    
      Is_Changed := Result.Get("status")(1..3) /= Market.Status(1..3);
      
      if Is_Changed then
        Market.Status := (others => ' ');
        Move( Result.Get("status"), Market.Status);
      end if;

      Log(Me & "Market_Status_Is_Changed", "Status changed for market '" & Market_Id_Received & "' " &
                                          Is_Changed'img & " status " & Market.Status);
    else
      Log(Me & "Market_Status_Is_Changed", "No status field found!!!");
    end if;
  end Market_Status_Is_Changed;
  ---------------------------------------
  procedure Get_Balance(Betfair_Result : out Result_Type ; Saldo : out Table_Abalances.Data_Type) is
    Parsed_Ok : Boolean := True;
    Query_Get_Account_Funds           : JSON_Value := Create_Object;
    Reply_Get_Account_Funds           : JSON_Value := Create_Object;
    Answer_Get_Account_Funds          : Aws.Response.Data;
    Params                            : JSON_Value := Create_Object;
    Result                            : JSON_Value := Create_Object;
  begin
     Betfair_Result := Ok;

    Reset_AWS_Headers;    

    -- params is empty ...                     
    Query_Get_Account_Funds.Set_Field (Field_Name => "params",  Field => Params);
    Query_Get_Account_Funds.Set_Field (Field_Name => "id",      Field => 15);          -- ???
    Query_Get_Account_Funds.Set_Field (Field_Name => "method",  Field => "AccountAPING/v1.0/getAccountFunds");
    Query_Get_Account_Funds.Set_Field (Field_Name => "jsonrpc", Field => "2.0");

    Log(Me, "posting " & Query_Get_Account_Funds.Write);
    Answer_Get_Account_Funds := Aws.Client.Post (Url          =>  Token.URL_ACCOUNT,
                                                 Data         =>  Query_Get_Account_Funds.Write,
                                                 Content_Type => "application/json",
                                                 Headers      =>  Global_HTTP_Headers,
                                                 Timeouts     =>  Aws.Client.Timeouts (Each => 120.0));
     
    --  Load the reply into a json object
    Log(Me, "Got reply");
    begin
      Reply_Get_Account_Funds := Read (Strm     => Aws.Response.Message_Body(Answer_Get_Account_Funds),
                                       Filename => "");
      Log(Me, Reply_Get_Account_Funds.Write);
    exception
      when E: others =>
        Parsed_Ok := False;
        Log(Me, "Bad reply: " & Aws.Response.Message_Body(Answer_Get_Account_Funds));
        Sattmate_Exception.Tracebackinfo(E);
        --Timeout is given as Aws.Response.Message_Body = "Post Timeout" 
        if Aws.Response.Message_Body(Answer_Get_Account_Funds) = "Post Timeout" then 
          Betfair_Result := Timeout ;
          return;
        end if;  
    end ;       

    if Parsed_Ok then                             
      if API_Exceptions_Are_Present(Reply_Get_Account_Funds) then
        Log(Me & "Get_Balance - Error",Aws.Response.Message_Body(Answer_Get_Account_Funds));
      
        -- try again
        Betfair_Result := Logged_Out ;
        return;
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
      end if;  
    end if;    
  end Get_Balance;    
  
  --------------------------------------- 
end RPC;