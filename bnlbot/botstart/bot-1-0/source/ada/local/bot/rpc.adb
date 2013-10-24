


--with Ada.Strings; use Ada.Strings;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Logging; use Logging;
with Aws;
with Aws.Headers;
with Aws.Headers.Set;
with Aws.Response;
with General_Routines; use General_Routines;
with Aws.Client;

pragma Elaborate_All (AWS.Headers);

package body RPC is

  My_Headers : Aws.Headers.List := Aws.Headers.Empty_List;

  Me : constant String := "RPC.";

  No_Such_Field : exception;
  
  
  function API_Exceptions_Are_Present(Reply : JSON_Value) return Boolean is
     Error, 
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
  
  function Bet_Is_Matched(Betid : Integer_8 ; Tkn : Token.Token_Type) return Boolean is
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
    AWS_Reply       : Aws.Response.Data;
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
    Append (Bet_Ids, Create(String_Betid));    
    Params.Set_Field     (Field_Name => "betIds",          Field => Bet_Ids);
    Params.Set_Field     (Field_Name => "placesDateRange", Field => DateRange);    
    Json_Query.Set_Field (Field_Name => "params",  Field => Params);
    Json_Query.Set_Field (Field_Name => "id",      Field => 15);   --?
    Json_Query.Set_Field (Field_Name => "method",  Field => "SportsAPING/v1.0/listCurrentOrders");
    Json_Query.Set_Field (Field_Name => "jsonrpc", Field => "2.0");
    
    Log(Me, "posting: " & Json_Query.Write);
    
    Aws.Headers.Set.Reset(My_Headers);
    Aws.Headers.Set.Add (My_Headers, "X-Authentication", Tkn.Get);
    Aws.Headers.Set.Add (My_Headers, "X-Application", Tkn.Get_App_Key);
    Aws.Headers.Set.Add (My_Headers, "Accept", "application/json");
    
    AWS_Reply := Aws.Client.Post (Url          =>  Token.URL_BETTING,
                                  Data         =>  Json_Query.Write,
                                  Content_Type => "application/json",
                                  Headers      =>  My_Headers,
                                  Timeouts     =>  Aws.Client.Timeouts (Each => 30.0));
    Log(Me & "Bet_Is_Matched", "Got reply, check it ");

    begin
      if String'(Aws.Response.Message_Body(AWS_Reply)) /= "Post Timeout" then
        Json_Reply := Read (Strm     => Aws.Response.Message_Body(AWS_Reply),
                            Filename => "");
        Log(Me & "Bet_Is_Matched", "Got reply: " & Json_Reply.Write  );
      else
        Log(Me & "Bet_Is_Matched", "Post Timeout -> Give up listCurrentOrders");
        return False;
      end if;
    exception
      when others =>
         Log(Me & "Bet_Is_Matched", "***********************  Bad reply start *********************************");
         Log(Me & "Bet_Is_Matched", "Bad reply" & Aws.Response.Message_Body(AWS_Reply));
         Log(Me & "Bet_Is_Matched", "***********************  Bad reply stop  ********" );
         return False;
    end ;

    -- ok, got a valid Json reply, check for errors
    if API_Exceptions_Are_Present(Json_Reply) then
      return False;
    end if;

    -- ok, got a valid Json reply, parse it
 -- {
 --     "jsonrpc": "2.0",
 --     "result": {
 --          "currentOrders": [{
 --               "betId": "31049748925",
 --               "marketId": "1.111558021",
 --               "selectionId": 7539782,
 --               "handicap": 0.0,
 --               "priceSize": {
 --                    "price": 40.0,
 --                    "size": 30.0
 --               },
 --               "bspLiability": 0.0,
 --               "placedDate": "2013-10-23T16:42:52.000Z",
 --               "averagePriceMatched": 0.0,
 --               "sizeMatched": 0.0,
 --               "sizeRemaining": 30.0,
 --               "sizeLapsed": 0.0,
 --               "sizeCancelled": 0.0,
 --               "sizeVoided": 0.0,
 --               "regulatorCode": "MALTA LOTTERIES AND GAMBLING AUTHORITY", 
 --               "side": "BACK",
 --               "status": "EXECUTABLE",
 --               "persistenceType": "LAPSE",
 --               "orderType": "LIMIT"
 --          }],
 --          "moreAvailable": false
 --     },
 --     "id": 1
 -- }     

    if Json_Reply.Has_Field("result") then
      Result := Json_Reply.Get("result");
    else
      Log(Me & "Bet_Is_Matched", "NO RESULT!!" );
      return False;
    end if;

    if Result.Has_Field("currentOrders") then
      Log(Me & "Bet_Is_Matched", "got currentOrders");
      Current_Orders := Result.Get("currentOrders");
 
      Current_Order_Item := Get(Current_Orders, 1); -- always element 1, since we only have 1
      Log(Me & "Bet_Is_Matched", "got Current_Order_Item");
 
      if Current_Order_Item.Has_Field("status") then
        Log(Me & "Bet_Is_Matched", "got Current_Order_Item.Status");
        return Current_Order_Item.Get("status") = "EXECUTION_COMPLETE";   
      end if;         
    end if;
    return False;
 
  end Bet_Is_Matched;
  -----------------------------------------------------------------  
  
end RPC;