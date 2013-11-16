


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
  
  procedure Bet_Is_Matched(Betid             : Integer_8 ; 
                           Tkn               : Token.Token_Type; 
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
--      	"id": 15,
--      	"jsonrpc": "2.0",
--      	"result": {
--      		"moreAvailable": false,
--      		"currentOrders": [{
--      			"marketId": "1.111593623",
--      			"betId": "31122359882",
--      			"handicap": 0.00000E+00,
--      			"orderType": "LIMIT",
--      			"sizeCancelled": 0.00000E+00,
--      			"bspLiability": 0.00000E+00,
--      			"selectionId": 7662169,
--      			"sizeVoided": 0.00000E+00,
--      			"status": "EXECUTION_COMPLETE",
--      			"matchedDate": "2013-10-26T12:49:26.000Z",
--      			"placedDate": "2013-10-26T11:44:54.000Z",
--      			"sizeLapsed": 0.00000E+00,
--      			"side": "LAY",
--      			"priceSize": {
--      				"size": 3.21200E+01,
--      				"price": 1.65000E+01
--      			},
--      			"regulatorCode": "MALTA LOTTERIES AND GAMBLING AUTHORITY",
--      			"sizeMatched": 3.21200E+01,
--      			"persistenceType": "PERSIST",
--      			"sizeRemaining": 0.00000E+00,
--      			"averagePriceMatched": 1.65000E+01
--      		}]
--      	}
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
      end if;        
    end if;
    Log(Me & "Bet_Is_Matched", "Is_Matched: " & Is_Matched'Img & " AVG_Price_Matched: " & F8_Image(Float_8(AVG_Price_Matched)))  ;
  end Bet_Is_Matched;
  -----------------------------------------------------------------  
  procedure Check_Market_Result(Market_Id       : in Market_Id_Type;
                                Tkn             : in Token.Token_Type;
                                Winner_List     : in out Table_Awinners.Awinners_List_Pack.List_Type;
                                Non_Runner_List : in out Table_Anonrunners.Anonrunners_List_Pack.List_Type
                                ) is
--{
--     "jsonrpc": "2.0",
--     "method": "SportsAPING/v1.0/listMarketBook",
--     "params": {
--          "marketIds": ["1.111572663"]
--     },
--     "id": 1
--}  
    Winner     : Table_Awinners.Data_Type;
    Non_Runner : Table_Anonrunners.Data_Type;
    Selection_Id : Integer := 0;

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
    
    Aws.Headers.Set.Reset(My_Headers);
    Aws.Headers.Set.Add (My_Headers, "X-Authentication", Tkn.Get);
    Aws.Headers.Set.Add (My_Headers, "X-Application", Tkn.Get_App_Key);
    Aws.Headers.Set.Add (My_Headers, "Accept", "application/json");
    
    AWS_Reply := Aws.Client.Post (Url          =>  Token.URL_BETTING,
                                  Data         =>  Json_Query.Write,
                                  Content_Type => "application/json",
                                  Headers      =>  My_Headers,
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
      Result := Get(Result_Array,1); -- one element in array only
    else
      Log(Me & "Check_Market_Result", "NO RESULT!!" );
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
          Selection_Id := 0; -- reset
        
          Runner := Get(Runners, i);
          Log(Me & "Check_Market_Result", "got Runner" & i'Img);
 
          if Runner.Has_Field("selectionId") then
            Selection_Id := Runner.Get("selectionId");   
          end if;
          
          if Runner.Has_Field("status") then
            if Runner.Get("status") = "WINNER" then 
              Winner.Marketid := Market_Id_Received ;
              Winner.Selectionid :=Integer_4(Selection_Id) ;
              Table_Awinners.Awinners_List_Pack.Insert_At_Tail(Winner_List, Winner);  
              Log(Me & "Check_Market_Result", "got a winner " & Table_Awinners.To_String(Winner));
              
            elsif Runner.Get("status") = "REMOVED" then 
              Non_Runner.Marketid := Market_Id_Received ;
              Non_Runner.Selectionid :=Integer_4(Selection_Id) ;
              Table_Anonrunners.Anonrunners_List_Pack.Insert_At_Tail(Non_Runner_List, Non_Runner);  
              Log(Me & "Check_Market_Result", "got a non-runner " & Table_Anonrunners.To_String(Non_Runner));
--            elsif Runner.Get("status") = "LOSER" then 
--              null;
            end if;
          end if;
        end loop;
      end if;        
    end if;
  
  end Check_Market_Result;
  ----------------------------------------------------------------
end RPC;