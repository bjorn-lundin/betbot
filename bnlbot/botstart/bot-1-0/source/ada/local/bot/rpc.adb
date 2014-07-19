

with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Logging; use Logging;
with Aws;
with Aws.Headers;
with Aws.Headers.Set;
with Aws.Response;
--with General_Routines; use General_Routines;
with Aws.Client;
with Bot_System_Number;
with Bot_Svn_Info;

pragma Elaborate_All (AWS.Headers);

package body RPC is

  Me : constant String := "RPC.";

  No_Such_Field : exception;

  Global_Token : Token.Token_Type;
  ---------------------------------

  procedure Init(Username   : in     String;
                 Password   : in     String;
                 Product_Id : in     String;
                 Vendor_Id  : in     String;
                 App_Key    : in     String) is
  begin
    Log(Me & "Init", "start");

     Global_Token.Init(
       Username   => Username,
       Password   => Password,
       Product_Id => Product_Id,
       Vendor_id  => Vendor_Id,
       App_Key    => App_Key
     );
    Log(Me & "Init", "stop");
  end Init;

  ------------------------------------------------------------------------------
  function Get_Token return Token.Token_Type is
  begin
    return Global_Token;
  end Get_Token;
  ------------------------------------------------------------------------------

  procedure Login is
    Login_HTTP_Headers : Aws.Headers.List := Aws.Headers.Empty_List;
    AWS_Reply    : Aws.Response.Data;
    Header : AWS.Headers.List;
  begin
    Aws.Headers.Set.Add (Login_HTTP_Headers, "User-Agent", "AWS-BNL/1.0");

    declare
      Data : String :=  "username=" & Global_Token.Get_Username & "&" &
                         "password=" & Global_Token.Get_Password &"&" &
                         "login=true" & "&" &
                         "redirectMethod=POST" & "&" &
                         "product=home.betfair.int" & "&" &
                         "product=home.betfair.int" & "&" &
                         "url=https://www.betfair.com/";
    begin
--      Log(Me & "Login", "Data '" & Data & "'");

      AWS_Reply := Aws.Client.Post (Url          => "https://identitysso.betfair.com/api/login",
                                    Data         => Data,
                                    Content_Type => "application/x-www-form-urlencoded",
                                    Headers      => Login_HTTP_Headers,
                                    Timeouts     => Aws.Client.Timeouts (Each => 30.0));
    end ;
    Log(Me & "Login", "reply" & Aws.Response.Message_Body(AWS_Reply));
    
    -- login reply should look something like below (522 chars)
    -- <html>
    -- <head>
    --     <title>Login</title>
    -- </head>
    -- <body onload="document.postLogin.submit()">
    -- <iframe src="https://secure.img-cdn.mediaplex.com/0/16689/universal.html?page_name=loggedin&amp;loggedin=1&amp;mpuid=6081705" HEIGHT="1" WIDTH="1" FRAMEBORDER="0" ></iframe>
    -- <form name="postLogin" action="https://www.betfair.com/" method="POST">
    --     <input type="hidden" name="productToken" value="UeJjgqWpxf3VstCg9VqFmrDhsrHQkOvHu7alH5NCldA="/>
    --     <input type="hidden" name="loginStatus" value="SUCCESS"/>
    -- </form>
    -- </body>
    -- </html>
    
    declare
      String_Reply : String := Aws.Response.Message_Body(AWS_Reply);
    begin  
      if String_Reply'length < 500 then
        raise Login_Failed with "Bad reply from server at login";
      end if;
    end ;
    
    Header := AWS.Response.Header(AWS_Reply);

    for i in 1 .. AWS.Headers.Length(Header) loop
      declare
        Head : String := AWS.Headers.Get_Line(Header,i);
        Index_First_Equal : Integer := 0;
        Index_First_Semi_Colon : Integer := 0;
--  Set-Cookie: ssoid=o604egQ2BuWCG6ij8NMJtyer6fycB2Dw7eHLiWoA1vI=; Domain=.betfair.com; Path=/
      begin
        if Position(Head,"ssoid") > Integer(0) then
          Log("Login"," " & Head);
          for i in Head'range loop
            case Head(i) is
              when '=' =>
                if Index_First_Equal = 0 then
                  Index_First_Equal := i;
                end if;

              when ';' =>
                if Index_First_Semi_Colon = 0 then
                  Index_First_Semi_Colon := i;
                end if;
              when others => null;
            end case;
          end loop;
          if Index_First_Equal > Integer(0) and then Index_First_Semi_Colon > Index_First_Equal then
            Log("Login","ssoid: '" & Head(Index_First_Equal +1 .. Index_First_Semi_Colon -1) & "'");
            Global_Token.Set(Head(Index_First_Equal +1 .. Index_First_Semi_Colon -1));
          end if;
        end if;
      end;
    end loop;
  end Login;

  ------------------------------------------------------------------------------

  procedure Logout is
    Logout_HTTP_Headers : Aws.Headers.List := Aws.Headers.Empty_List;
    AWS_Reply    : Aws.Response.Data;
  begin
    Aws.Headers.Set.Add (Logout_HTTP_Headers, "User-Agent", "AWS-BNL/1.0");
    Aws.Headers.Set.Add (Logout_HTTP_Headers, "Accept", "application/json");
    Aws.Headers.Set.Add (Logout_HTTP_Headers, "X-Authentication", Global_Token.Get);

    AWS_Reply := Aws.Client.Post (Url          => "https://identitysso.betfair.com/api/logout",
                                  Data         => "", --Data,
                                  Content_Type => "application/x-www-form-urlencoded",
                                  Headers      => Logout_HTTP_Headers,
                                  Timeouts     => Aws.Client.Timeouts (Each => 30.0));
    Log(Me & "Logout", Aws.Response.Message_Body(AWS_Reply));

    if Position( Aws.Response.Message_Body(AWS_Reply),"""status"":""SUCCESS""") > Integer(0) then
      Global_Token.Unset;
    end if;
  end Logout;
  ------------------------------------------------------------------------------

  procedure Keep_Alive(Result : out Boolean )is
    Keep_Alive_HTTP_Headers : Aws.Headers.List := Aws.Headers.Empty_List;
    AWS_Reply    : Aws.Response.Data;
  begin
    Result := True;
    Aws.Headers.Set.Add (Keep_Alive_HTTP_Headers, "User-Agent", "AWS-BNL/1.0");
    Aws.Headers.Set.Add (Keep_Alive_HTTP_Headers, "Accept", "application/json");
    Aws.Headers.Set.Add (Keep_Alive_HTTP_Headers, "X-Authentication", Global_Token.Get);

    AWS_Reply := Aws.Client.Post (Url          => "https://identitysso.betfair.com/api/keepAlive",
                                  Data         => "", --Data,
                                  Content_Type => "application/x-www-form-urlencoded",
                                  Headers      => Keep_Alive_HTTP_Headers,
                                  Timeouts     => Aws.Client.Timeouts (Each => 30.0));
    Log(Me & "Keep_Alive", Aws.Response.Message_Body(AWS_Reply));

    if Position( Aws.Response.Message_Body(AWS_Reply),"""status"":""FAIL""") > Integer(0) then
      Result := False;
    end if;
  end Keep_Alive;
  ------------------------------------------------------------------------------

  procedure Get_JSON_Reply (Query : in     JSON_Value;
                            Reply : in out JSON_Value;
                            URL   : in     String) is
    AWS_Reply    : Aws.Response.Data;
    HTTP_Headers : Aws.Headers.List := Aws.Headers.Empty_List;
  begin
    Aws.Headers.Set.Add (HTTP_Headers, "X-Authentication", Global_Token.Get);
    Aws.Headers.Set.Add (HTTP_Headers, "X-Application", Global_Token.Get_App_Key);
    Aws.Headers.Set.Add (HTTP_Headers, "Accept", "application/json");
    Log(Me  & "Get_JSON_Reply", "posting: " & Query.Write);
    AWS_Reply := Aws.Client.Post (Url          => URL,
                                  Data         => Query.Write,
                                  Content_Type => "application/json",
                                  Headers      => HTTP_Headers,
                                  Timeouts     => Aws.Client.Timeouts (Each => 30.0));
    Log(Me & "Get_JSON_Reply", "Got reply, check it ");

      if String'(Aws.Response.Message_Body(AWS_Reply)) /= "Post Timeout" then
        Reply := Read (Strm     => Aws.Response.Message_Body(AWS_Reply),
                       Filename => "");
        Log(Me & "Get_JSON_Reply", "Got reply: " & Reply.Write  );
      else
        Log(Me & "Get_JSON_Reply", "Post Timeout -> Give up!");
        raise POST_Timeout ;
      end if;
    exception
      when POST_Timeout => raise;
      when others =>
         Log(Me & "Get_JSON_Reply", "***********************  Bad reply start *********************************");
         Log(Me & "Get_JSON_Reply", "Bad reply" & Aws.Response.Message_Body(AWS_Reply));
         Log(Me & "Get_JSON_Reply", "***********************  Bad reply stop  ********" );
         raise Bad_Reply ;
  end Get_JSON_Reply;

  ------------------------------------------------------------------------------

  procedure Get_Value(Container: in     JSON_Value;
                      Field    : in     String;
                      Target   : in out Boolean;
                      Found    :    out Boolean ) is
  begin
    if Container.Has_Field(Field) then
      Target := Container.Get(Field);
      Found := True;
    else
      Found := False;
    end if;
  end Get_Value;
  ------------------------------------------------------------------------------

  procedure Get_Value(Container: in    JSON_Value;
                      Field    : in     String;
                      Target   : in out Float_8;
                      Found    :    out Boolean ) is
    Tmp : Float := 0.0;
  begin
    if Container.Has_Field(Field) then
      Tmp := Container.Get(Field);
      Found := True;
      Target := Float_8(Tmp);
    else
      Found := False;
    end if;
  end Get_Value;
  ------------------------------------------------------------------------------

  procedure Get_Value(Container: in     JSON_Value;
                      Field    : in     String;
                      Target   : in out Integer_8;
                      Found    :    out Boolean ) is
    Tmp : String (1..20)  :=  (others => ' ') ;
  begin
    if Container.Has_Field(Field) then
      Move( Container.Get(Field), Tmp );
      if Tmp(2) = '.' then
        Target := Integer_8'Value(Tmp(3 .. Tmp'Last));
      else
        Target := Integer_8'Value(Tmp);
      end if;
      Found := True;
    else
      Found := False;
    end if;
  end Get_Value;
  ------------------------------------------------------------------------------

  procedure Get_Value(Container: in     JSON_Value;
                      Field    : in     String;
                      Target   : in out String;
                      Found    : out    Boolean) is
  begin
    if Container.Has_Field(Field) then
      Move( Source => Container.Get(Field), Target => Target , Drop => Right);
      Found := True;
    else
      Found  := False;
    end if;
  end Get_Value;
  ------------------------------------------------------------------------------

  procedure Get_Value(Container: in     JSON_Value;
                      Field    : in     String;
                      Target   : in out JSON_Value;
                      Found    : out    Boolean) is
  begin
    if Container.Has_Field(Field) then
      Target := Container.Get(Field);
      Found := True;
    else
      Found  := False;
    end if;
  end Get_Value;
  ------------------------------------------------------------------------------

  procedure Get_Value(Container: in     JSON_Value;
                      Field    : in     String;
                      Target   : in out Integer_4;
                      Found    :    out Boolean) is
   Tmp : Integer := 0 ;
 begin
    if Container.Has_Field(Field) then
      Tmp := Container.Get(Field);
      Found := True;
      Target := Integer_4(Tmp);
    else
      Found := False;
    end if;
  end Get_Value;
  ------------------------------------------------------------------------------

  procedure Get_Value(Container: in     JSON_Value;
                      Field    : in     String;
                      Target   : in out Calendar2.Time_Type;
                      Found    :    out Boolean) is
  begin
    if Container.Has_Field(Field) then
      declare
        Tmp : String := Container.Get(Field);
      begin  --       "marketStartTime":"2013-06-22T17:39:00.000Z",
        Target := Calendar2.To_Time_Type(Tmp(1..10), Tmp(12..23));
      end;
      Found := True;
    else
      Found  := False;
    end if;
  end Get_Value;

  ------------------------------------------------------------------

  function API_Exceptions_Are_Present(Reply : JSON_Value) return Boolean is
     Error,
     AccountAPINGException,
     APINGException,
     Data             : JSON_Value := Create_Object;
     Has_Error        : Boolean := False;
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
  begin
    if Reply.Has_Field("error") then
      Has_Error := True;
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
            else
              raise No_Such_Field with "APINGException - errorCode";
            end if;
          elsif Data.Has_Field("AccountAPINGException") then
            AccountAPINGException := Data.Get("AccountAPINGException");
            if AccountAPINGException.Has_Field("errorCode") then
              Log(Me, "APINGException.errorCode " & AccountAPINGException.Get("errorCode"));
              if AccountAPINGException.Get("errorCode") = "INVALID_SESSION_INFORMATION" then
                raise Invalid_Session;
              end if;              
            else
              raise No_Such_Field with "AccountAPINGException - errorCode";
            end if;  
          else
            raise No_Such_Field with "Data - APINGException";
          end if;
        end if;
        if Error.Has_Field("message") then
          Log(Me, "Error.Message " & Error.Get("message"));
        end if;
      else
        raise No_Such_Field with "Error - code";
      end if;
    end if;
    return Has_Error;
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
    Params,
    DateRange,
    Json_Reply,
    Json_Query   : JSON_Value := Create_Object;


    Current_Orders,
    Bet_Ids      : JSON_Array := Empty_Array;
    String_Betid : String     := Trim(Betid'Img);
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

    Get_JSON_Reply (Query => Json_Query,
                    Reply => Json_Reply,
                    URL   => Token.URL_BETTING);

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
    Market_Id_Received  : Market_Id_Type := (others => ' ');
  begin

    Append (Market_Ids, Create(Market_Id));
    Params.Set_Field     (Field_Name => "marketIds", Field => Market_Ids);
    Json_Query.Set_Field (Field_Name => "params",  Field => Params);
    Json_Query.Set_Field (Field_Name => "id",      Field => 15);   --?
    Json_Query.Set_Field (Field_Name => "method",  Field => "SportsAPING/v1.0/listMarketBook");
    Json_Query.Set_Field (Field_Name => "jsonrpc", Field => "2.0");

    Get_JSON_Reply (Query => Json_Query,
                    Reply => Json_Reply,
                    URL   => Token.URL_BETTING);

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
    Market_Id_Received  : Market_Id_Type := (others => ' ');
  begin
    Is_Changed := False;

    Append (Market_Ids, Create(Market.Marketid));
    Params.Set_Field     (Field_Name => "marketIds", Field => Market_Ids);
    Json_Query.Set_Field (Field_Name => "params",  Field => Params);
    Json_Query.Set_Field (Field_Name => "id",      Field => 15);   --?
    Json_Query.Set_Field (Field_Name => "method",  Field => "SportsAPING/v1.0/listMarketBook");
    Json_Query.Set_Field (Field_Name => "jsonrpc", Field => "2.0");

    Get_JSON_Reply (Query => Json_Query,
                    Reply => Json_Reply,
                    URL   => Token.URL_BETTING);

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
    Query_Get_Account_Funds           : JSON_Value := Create_Object;
    Reply_Get_Account_Funds           : JSON_Value := Create_Object;
    Params                            : JSON_Value := Create_Object;
    Result                            : JSON_Value := Create_Object;
  begin
     Betfair_Result := Ok;

    -- params is empty ...
    Query_Get_Account_Funds.Set_Field (Field_Name => "params",  Field => Params);
    Query_Get_Account_Funds.Set_Field (Field_Name => "id",      Field => 15);          -- ???
    Query_Get_Account_Funds.Set_Field (Field_Name => "method",  Field => "AccountAPING/v1.0/getAccountFunds");
    Query_Get_Account_Funds.Set_Field (Field_Name => "jsonrpc", Field => "2.0");

    Get_JSON_Reply (Query => Query_Get_Account_Funds,
                    Reply => Reply_Get_Account_Funds,
                    URL   => Token.URL_ACCOUNT);

    begin                
      if API_Exceptions_Are_Present(Reply_Get_Account_Funds) then
          -- try again
        Betfair_Result := Logged_Out ;
        return;
      end if;
    exception
      when Invalid_Session => 
        Betfair_Result := Logged_Out ;
        return;      
    end ;      

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
  end Get_Balance;

  ---------------------------------------
  procedure Get_Cleared_Bet_Info_List(Bet_Status     : in Bet_Status_Type;
                                      Settled_From   : in Calendar2.Time_Type := Calendar2.Time_Type_First;
                                      Settled_To     : in Calendar2.Time_Type := Calendar2.Time_Type_Last;
                                      Betfair_Result : out Result_Type;
                                      Bet_List       : out Table_Abets.Abets_List_Pack.List_Type) is
    pragma Warnings(Off,Bet_List); -- list is manipulated, not pointer though

    JSON_Query : JSON_Value := Create_Object;
    JSON_Reply : JSON_Value := Create_Object;
    --AWS_Reply  : Aws.Response.Data;
    Params     : JSON_Value := Create_Object;
    Result     : JSON_Value := Create_Object;
    Settled_Date_Range : JSON_Value := Create_Object;
    Cleared_Orders     : JSON_Array := Empty_Array;
    Cleared_Order      : JSON_Value := Create_Object;

    Local_Bet          : Table_Abets.Data_Type;
    Found              : Boolean := False;

  begin
    Betfair_Result := Ok;

    Settled_Date_Range.Set_Field (Field_Name => "from", Field => Calendar2.String_Date_Time_ISO(Settled_From,"T","Z"));
    Settled_Date_Range.Set_Field (Field_Name => "to",   Field => Calendar2.String_Date_Time_ISO(Settled_To,  "T","Z"));

    Params.Set_Field (Field_Name => "groupBy", Field => "BET");
    Params.Set_Field (Field_Name => "includeItemDescription", Field => False);
    Params.Set_Field (Field_Name => "settledDateRange", Field => Settled_Date_Range);
    Params.Set_Field (Field_Name => "betStatus",        Field => Bet_Status'Img);
    -- params is empty ...
    JSON_Query.Set_Field (Field_Name => "params",  Field => Params);
    JSON_Query.Set_Field (Field_Name => "id",      Field => 15);          -- ???
    JSON_Query.Set_Field (Field_Name => "method",  Field => "SportsAPING/v1.0/listClearedOrders");
    JSON_Query.Set_Field (Field_Name => "jsonrpc", Field => "2.0");

    Get_JSON_Reply(Query => JSON_Query,
                   Reply => JSON_Reply,
                   URL   => Token.URL_BETTING);

    if API_Exceptions_Are_Present(JSON_Reply) then
      Betfair_Result := Logged_Out ;
      return;
    end if;

    if JSON_Reply.Has_Field("result") then
       Result := JSON_Reply.Get("result");
       if Result.Has_Field("clearedOrders") then
         Cleared_Orders := Result.Get("clearedOrders");
         if Length(Cleared_Orders) > Integer(0) then
           for i in 1 .. Length (Cleared_Orders) loop
             Log(Me & "Get_Cleared_Bet_Info_List" , " we have cleared order #:" & i'img & " with status: " & Bet_Status'Img);

             Cleared_Order := Get(Cleared_Orders, i);
             Local_Bet := Table_Abets.Empty_Data;
             Get_Value(Container => Cleared_Order,
                       Field     => "betId",
                       Target    => Local_Bet.Betid,
                       Found     => Found);

             Get_Value(Container => Cleared_Order,
                       Field     => "priceMatched",
                       Target    => Local_Bet.Pricematched,
                       Found     => Found);

             Get_Value(Container => Cleared_Order,
                       Field     => "sizeSettled",
                       Target    => Local_Bet.Sizematched,
                       Found     => Found);

             Get_Value(Container => Cleared_Order,
                       Field     => "profit",
                       Target    => Local_Bet.Profit,
                       Found     => Found);

             Move(Bet_Status'Img, Local_Bet.Status);

             Table_Abets.Abets_List_Pack.Insert_At_Tail(Bet_List, Local_Bet);
           end loop;
         else
           Log(Me & "Get_Cleared_Bet_Info_List", "No cleared orders received with status " & Bet_Status'Img);
         end if;
       end if;
    end if;
  end Get_Cleared_Bet_Info_List;
  -----------------------------------

  procedure Cancel_Bet(Market_Id : in Market_Id_Type;
                       Bet_Id    : in Integer_8) is
    JSON_Query : JSON_Value := Create_Object;
    JSON_Reply : JSON_Value := Create_Object;
    Params     : JSON_Value := Create_Object;
    Instruction  : JSON_Value := Create_Object;
    Instructions : JSON_Array := Empty_Array;
    Betfair_Result : Result_Type;

  begin
    Betfair_Result := Ok;

    Instruction.Set_Field (Field_Name => "betId", Field => Trim(Bet_Id'Img));
    Append(Instructions, Instruction);

    Params.Set_Field (Field_Name => "marketId", Field => Market_Id);
    Params.Set_Field (Field_Name => "instructions", Field => Instructions);

    JSON_Query.Set_Field (Field_Name => "params",  Field => Params);
    JSON_Query.Set_Field (Field_Name => "id",      Field => 15);          -- ???
    JSON_Query.Set_Field (Field_Name => "method",  Field => "SportsAPING/v1.0/cancelOrders");
    JSON_Query.Set_Field (Field_Name => "jsonrpc", Field => "2.0");

    Get_JSON_Reply(Query => JSON_Query,
                   Reply => JSON_Reply,
                   URL   => Token.URL_BETTING);

    if API_Exceptions_Are_Present(JSON_Reply) then
      Betfair_Result := Logged_Out ;
      return;
    end if;
    Log(Me & "Cancel_Bet", "Betfair_Result: " & Betfair_Result'Img);
  end  Cancel_Bet;
  -----------------------------------

  procedure Parse_Prices(J_Market   : in     JSON_Value;
                         Price_List : in out Table_Aprices.Aprices_List_Pack.List_Type ) is
    pragma Warnings(Off,Price_List);
    Back,
    Lay,
    Ex,
    Runner            : JSON_Value := Create_Object;
    Back_Array,
    Lay_Array,
    Runner_Prices     : JSON_Array := Empty_Array;
    Array_Length      : Natural;
    Array_Length_Back : Natural;
    Array_Length_Lay  : Natural;
    Now               : Calendar2.Time_Type := Calendar2.Clock;
    Found             : Boolean := False;
    DB_Runner_Price   : Table_Aprices.Data_Type;

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


  begin
    Runner_Prices := J_Market.Get("runners");
    Array_Length  := Length (Runner_Prices);

    for J in 1 .. Array_Length loop
      DB_Runner_Price := Table_Aprices.Empty_Data;

      Runner := Get (Arr   => Runner_Prices, Index => J);

      Get_Value(Container => J_Market,
                Field     => "marketId",
                Target    => DB_Runner_Price.Marketid,
                Found     => Found);
      if not Found then
        raise No_Such_Field with "Object 'Market' - Field 'marketId'";
      end if;

      Get_Value(Container => Runner,
                Field     => "selectionId",
                Target    => DB_Runner_Price.Selectionid,
                Found     => Found);
      if not Found then
        raise No_Such_Field with "Object 'Market' - Field 'selectionId'";
      end if;

      Get_Value(Container => Runner,
                Field     => "status",
                Target    => DB_Runner_Price.Status,
                Found     => Found);
      if not Found then
        raise No_Such_Field with "Object 'Market' - Field 'status'";
      end if;

      Get_Value(Container => Runner,
                Field     => "totalMatched",
                Target    => DB_Runner_Price.Totalmatched,
                Found     => Found);

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

      Table_Aprices.Aprices_List_Pack.Insert_At_Tail(Price_List, DB_Runner_Price);
      Log(Me & "Parse_Prices", Table_Aprices.To_String(DB_Runner_Price));

    end loop;
  end Parse_Prices;

  ---------------------------------



  ---------------------------------

  procedure Parse_Event (J_Event, J_Event_Type : in     JSON_Value ;
                         DB_Event              : in out Table_Aevents.Data_Type) is
    Service : constant String := "Parse_Event";
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
    Found : Boolean := False;
  begin
    Log(Me & Service, "start");

    Get_Value(Container => J_Event,
              Field     => "id",
              Target    => DB_Event.Eventid,
              Found     => Found);

    Get_Value(Container => J_Event,
              Field     => "name",
              Target    => DB_Event.Eventname,
              Found     => Found);

    Get_Value(Container => J_Event,
              Field     => "countryCode",
              Target    => DB_Event.Countrycode,
              Found     => Found);
    if not Found then
      Move("XX", DB_Event.Countrycode);
    end if;

    Get_Value(Container => J_Event,
              Field     => "openDate",
              Target    => DB_Event.Opents,
              Found     => Found);

    Get_Value(Container => J_Event,
              Field     => "timezone",
              Target    => DB_Event.Timezone,
              Found     => Found);

    -- event_type !!
--    Get_Value(Container => J_Event_Type,
--              Field     => "id",
--              Target    => DB_Event.Eventtypeid,
--              Found     => Found);

    declare
      T : String(1..5) := (others => ' ');
    begin
      Get_Value(Container => J_Event_Type,
                Field     => "id",
                Target    => T,
                Found     => Found);
      DB_Event.Eventtypeid := Integer_4'Value(T);
    end;
    Log(Me & Service, Table_Aevents.To_String(DB_Event));
    Log(Me & Service, "stop");

  end Parse_Event;

  ---------------------------------

  procedure Get_Market_Prices(Market_Id : in Market_Id_Type;
                              Market    : out Table_Amarkets.Data_Type;
                              Price_List : in out Table_Aprices.Aprices_List_Pack.List_Type;
                              In_Play   : out Boolean) is
    Market_Ids         : JSON_Array := Empty_Array;
    JSON_Query         : JSON_Value := Create_Object;
    JSON_Reply         : JSON_Value := Create_Object;
    JSON_Market        : JSON_Value := Create_Object;
    Params             : JSON_Value := Create_Object;
    Result             : JSON_Array := Empty_Array;
    Price_Projection   : JSON_Value := Create_Object;
    Price_Data         : JSON_Array := Empty_Array;

  begin
    In_Play := False;

    Append(Market_Ids, Create(Market_Id));
    Append (Price_Data , Create("EX_BEST_OFFERS"));

    Price_Projection.Set_Field (Field_Name => "priceData", Field => Price_Data);

    Params.Set_Field (Field_Name => "priceProjection", Field => Price_Projection);
    Params.Set_Field (Field_Name => "currencyCode",    Field => "SEK");
    Params.Set_Field (Field_Name => "locale",          Field => "sv");
    Params.Set_Field (Field_Name => "marketIds",       Field => Market_Ids);

    JSON_Query.Set_Field (Field_Name => "params",  Field => Params);
    JSON_Query.Set_Field (Field_Name => "id",      Field => 15);   --?
    JSON_Query.Set_Field (Field_Name => "method",  Field => "SportsAPING/v1.0/listMarketBook");
    JSON_Query.Set_Field (Field_Name => "jsonrpc", Field => "2.0");


    Get_JSON_Reply(Query => JSON_Query,
                   Reply => JSON_Reply,
                   URL   => Token.URL_BETTING);

    if RPC.API_Exceptions_Are_Present(JSON_Reply) then
      Log(Me & "Get_Market_Prices", "APINGException is present, return");
      return;
    end if;

     --  Iterate the Reply_List_Market_Book object.
    if JSON_Reply.Has_Field("result") then
      Log(Me, "we have result ");
      Result := JSON_Reply.Get("result");
      for i in 1 .. Length(Result) loop
        JSON_Market := Get(Result, i);
        Parse_Market(JSON_Market, Market, In_Play);
        if JSON_Market.Has_Field("runners") then
          Parse_Prices(JSON_Market, Price_List);
        end if;
      end loop;
    end if;
  end Get_Market_Prices;
  ----------------------------------------------------------------------------------
  procedure Place_Bet (Bet_Name         : in Bet_Name_Type;
                       Market_Id        : in Market_Id_Type;
                       Side             : in Bet_Side_Type;
                       Runner_Name      : in Runner_Name_Type;
                       Selection_Id     : in Integer_4;
                       Size             : in Bet_Size_Type;
                       Price            : in Bet_Price_Type;
                       Bet_Persistence  : in Bet_Persistence_Type;
                       Bet              : out Table_Abets.Data_Type ) is
    JSON_Query   : JSON_Value := Create_Object;
    JSON_Reply   : JSON_Value := Create_Object;
    Params       : JSON_Value := Create_Object;
    Limit_Order  : JSON_Value := Create_Object;
    Instruction  : JSON_Value := Create_Object;
    Instructions : JSON_Array := Empty_Array;

    Execution_Report_Status        : String (1..50)  :=  (others => ' ') ;
    Execution_Report_Error_Code    : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Status      : String (1..50)  :=  (others => ' ') ;
    Instruction_Report_Error_Code  : String (1..50)  :=  (others => ' ') ;
    Order_Status                   : String (1..50)  :=  (others => ' ') ;
    L_Size_Matched,
    Average_Price_Matched          : Float_8 := 0.0;
    Powerdays                      : Integer_4 := 0;

    Bet_Id : Integer_8 := 0;
    Now : Calendar2.Time_Type := Calendar2.Clock;

    Price_String  : String         := F8_Image(Float_8(Price)); -- 2 decimals only
    Local_Price   : Bet_Price_Type := Bet_Price_Type'Value(Price_String); -- to avoid INVALID_BET_PRICE

    Size_String   : String         := F8_Image(Float_8(Size)); -- 2 decimals only
    Local_Size    : Bet_Size_Type  := Bet_Size_Type'Value(Size_String); -- to avoid INVALID_BET_SIZE

    Price_Matched : Bet_Price_Type := 0.0;
    Size_Matched  : Bet_Size_Type  := 0.0;

    Side_String   : Bet_Side_String_Type := (others => ' ');
    Found         : Boolean              := False;

  begin
    Move(Side'Img, Side_String);

    Limit_Order.Set_Field (Field_Name => "persistenceType", Field => Bet_Persistence'Img);
    Limit_Order.Set_Field (Field_Name => "price", Field => Float(Local_Price));
    Limit_Order.Set_Field (Field_Name => "size", Field => Float(Local_Size));

    Instruction.Set_Field (Field_Name => "limitOrder",  Field => Limit_Order);
    Instruction.Set_Field (Field_Name => "orderType",   Field => "LIMIT");
    Instruction.Set_Field (Field_Name => "side",        Field => Side'Img);
    Instruction.Set_Field (Field_Name => "handicap",    Field => 0);
    Instruction.Set_Field (Field_Name => "selectionId", Field => Integer(Selection_Id));

    Append (Instructions , Instruction);

    Params.Set_Field (Field_Name => "instructions", Field => Instructions);
    Params.Set_Field (Field_Name => "marketId",     Field => Trim(Market_Id));

    JSON_Query.Set_Field (Field_Name => "params", Field => Params);
    JSON_Query.Set_Field (Field_Name => "id", Field => 16);
    JSON_Query.Set_Field (Field_Name => "method",   Field      => "SportsAPING/v1.0/placeOrders");
    JSON_Query.Set_Field (Field_Name => "jsonrpc",  Field      => "2.0");

    --{
    --    "jsonrpc": "2.0",
    --    "method": "SportsAPING/v1.0/placeOrders",
    --    "params": {
    --        "marketId": "' + marketId + '",
    --        "instructions": [
    --            {
    --                "selectionId": "' + str(selectionId) + '",
    --                "handicap": "0",
    --                "side": "BACK",
    --                "orderType": "LIMIT",
    --                "limitOrder": {
    --                    "size": "0.01",
    --                    "price": "1.50",
    --                    "persistenceType": "LAPSE"
    --                }
    --            }
    --        ],
    --        "customerRef": "test12121212121"
    --    },
    --    "id": 1
    --}

    Get_JSON_Reply(Query => JSON_Query,
                   Reply => JSON_Reply,
                   URL   => Token.URL_BETTING);
    -- parse out the reply.
    -- check for API exception/Error first

    if RPC.API_Exceptions_Are_Present(JSON_Reply) then
      Log(Me & "Make_Bet", "APINGException is present, return");
      return;
    end if;

-- {
--    "jsonrpc":"2.0",
--    "result":
--            {
--                "status":"SUCCESS",
--                "marketId":"1.110689758",
--                "instructionReports":
--                    [
--                        {
--                             "status":"SUCCESS",
--                             "instruction":
--                                {
--                                   "orderType":"LIMIT",
--                                   "selectionId":6644807,
--                                   "handicap":0.0,
--                                   "side":"BACK",
--                                   "limitOrder":
--                                       {
--                                          "size":30.0,
--                                          "price":2.3,
--                                          "persistenceType":"LAPSE"
--                                        }
--                               },
--                               "betId":"29225429632",
--                               "placedDate":"2013-08-24T12:43:54.000Z",
--                               "averagePriceMatched":2.3399999999999994,
--                               "sizeMatched":30.0
--                        }
--                    ]
--                },
--        "id":15
--}

    -- ok we have a parsable answer with no formal errors.
    -- lets look at it
    declare
      Result           : JSON_Value := Create_Object;
      InstructionsItem : JSON_Value := Create_Object;
      Instructions     : JSON_Array := Empty_Array;
    begin

      Get_Value(Container => JSON_Reply,
                Field     => "result",
                Target    => Result,
                Found     => Found);
      if not Found then
        Log(Me & "Make_Bet", "NO RESULT!!" );
        raise JSON_Exception with "Betfair reply has no result!";
      end if;

      Get_Value(Container => Result,
                Field     => "status",
                Target    => Execution_Report_Status,
                Found     => Found);

      Get_Value(Container => Result,
                Field     => "errorCode",
                Target    => Execution_Report_Error_Code,
                Found     => Found);


      if Result.Has_Field("instructionReports") then
        Instructions := Result.Get("instructionReports");
        Log(Me & "Make_Bet", "got result.instructionReports");

        InstructionsItem  := Get(Instructions, 1); -- always element 1, since we only have 1
        Log(Me & "Make_Bet", "got InstructionsItem");

        Get_Value(Container => InstructionsItem,
                  Field     => "status",
                  Target    => Instruction_Report_Status,
                  Found     => Found);

        Get_Value(Container => InstructionsItem,
                  Field     => "errorCode",
                  Target    => Instruction_Report_Error_Code,
                  Found     => Found);
      end if;

      Get_Value(Container => InstructionsItem,
                Field     => "instruction",
                Target    => Instruction,
                Found     => Found);
      if not Found then
        Log(Me & "Make_Bet", "NO Instruction in Instructions!!" );
        raise JSON_Exception with "Betfair reply has no Instruction!";
      end if;

      Get_Value(Container => InstructionsItem,
                Field     => "betId",
                Target    => Bet_Id,
                Found     => Found);

      Get_Value(Container => InstructionsItem,
                Field     => "sizeMatched",
                Target    => L_Size_Matched,
                Found     => Found);
      if Found then
        Size_Matched := Bet_Size_Type(L_Size_Matched);
      end if;

      if abs(L_Size_Matched - Float_8(Size)) < 0.0001 then
        Move( "EXECUTION_COMPLETE", Order_Status );
      else
        Move( "EXECUTABLE", Order_Status );
      end if;

      Get_Value(Container => InstructionsItem,
                Field     => "averagePriceMatched",
                Target    => Average_Price_Matched,
                Found     => Found);
      if Found then
        Price_Matched := Bet_Price_Type(Average_Price_Matched);
      end if;
    end ;

    if Trim(Execution_Report_Status) /= "SUCCESS" then
      Bet_id := Integer_8(Bot_System_Number.New_Number(Bot_System_Number.Betid));
      Log(Me & "Make_Bet", "bad bet, save it for later with dr betid");
    end if;

    Bet := (
      Betid          => Bet_Id,
      Marketid       => Market_Id,
      Betmode        => Bot_Mode(Real),
      Powerdays      => Powerdays,
      Selectionid    => Selection_Id,
      Reference      => (others => '-'),
      Size           => Float_8(Local_Size),
      Price          => Float_8(Local_Price),
      Side           => Side_String,
      Betname        => Bet_Name,
      Betwon         => False,
      Profit         => 0.0,
      Status         => Order_Status, -- ??
      Exestatus      => Execution_Report_Status,
      Exeerrcode     => Execution_Report_Error_Code,
      Inststatus     => Instruction_Report_Status,
      Insterrcode    => Instruction_Report_Error_Code,
      Startts        => Calendar2.Time_Type_First,
      Betplaced      => Now,
      Pricematched   => Float_8(Price_Matched),
      Sizematched    => Float_8(Size_Matched),
      Runnername     => Runner_Name,
      Fullmarketname => (others => ' '),
      Svnrevision    => Bot_Svn_Info.Revision,
      Ixxlupd        => (others => ' '), --set by insert
      Ixxluts        => Now              --set by insert
    );

  end Place_Bet;
  ------------------------------------------

  procedure Parse_Runners(J_Market      : in     JSON_Value ;
                          Runner_List : in out Table_Arunners.Arunners_List_Pack.List_Type) is
    Service : constant String := "Parse_Runners";
    DB_Runner : Table_Arunners.Data_Type := Table_Arunners.Empty_Data;
    Found   : Boolean := False;
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
   Stop_Paranthesis : Integer := 0;

  begin
    Log(Me & Service, "start");
    Runners := J_Market.Get("runners");
    Array_Length := Length (Runners);

    for J in 1 .. Array_Length loop
      DB_Runner := Table_Arunners.Empty_Data;
       Runner := Get (Arr   => Runners, Index => J);
       Log(Me & Service, "  " & Runner.Write);


       Get_Value(Container => J_Market,
                 Field     => "marketId",
                 Target    => DB_Runner.Marketid,
                 Found     => Found);

       if not Found then
         raise No_Such_Field with "Object 'Market' - Field 'marketId'";
       end if;

       Get_Value(Container => Runner,
                 Field     => "sortPriority",
                 Target    => DB_Runner.Sortprio,
                 Found     => Found);
       if not Found then
         raise No_Such_Field with "Object 'Runner' - Field 'sortPriority'";
       end if;

       Get_Value(Container => Runner,
                 Field     => "handicap",
                 Target    => DB_Runner.Handicap,
                 Found     => Found);
       if not Found then
         raise No_Such_Field with "Object 'Runner' - Field 'handicap'";
       end if;

       Get_Value(Container => Runner,
                 Field     => "selectionId",
                 Target    => DB_Runner.Selectionid,
                 Found     => Found);
       if not Found then
         raise No_Such_Field with "Object 'Runner' - Field 'selectionId'";
       end if;

       Get_Value(Container => Runner,
                 Field     => "runnerName",
                 Target    => DB_Runner.Runnername,
                 Found     => Found);
       if not Found then
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
              Move(Trim(DB_Runner.Sortprio'Img), Runnernamenum);
       end case;

       Move("NOT_SET_YET", DB_Runner.Status);

       Start_Paranthesis := -1;
       Stop_Paranthesis  := -1;

       for i in Runnernamestripped'range loop
         case Runnernamestripped(i) is
           when '('    => Start_Paranthesis := i;
           when ')'    => Stop_Paranthesis  := i;
           when others => null;
         end case;
       end loop;

       if  Start_Paranthesis > Integer(-1) and then
           Stop_Paranthesis > Integer(-1) and then
           Lower_Case(Runnernamestripped(Start_Paranthesis .. Stop_Paranthesis)) = "(res)" then
         Runnernamestripped(Start_Paranthesis .. Stop_Paranthesis) := (others => ' ');
       end if;
       DB_Runner.Runnernamestripped := Runnernamestripped;
       DB_Runner.Runnernamenum      := Runnernamenum;

       Log(Me & Service, Table_Arunners.To_String(DB_Runner));

       Table_Arunners.Arunners_List_Pack.Insert_At_Tail(Runner_List, DB_Runner);

    end loop;
    Log(Me & Service, "stop");
  end Parse_Runners;

  ------------------------------------------
  procedure Parse_Market (J_Market       : in     JSON_Value ;
                          DB_Market      : in out Table_Amarkets.Data_Type ;
                          In_Play_Market :    out Boolean) is
    Service : constant String := "Parse_Market";
    Eos,Found    : Boolean    := False;
    Event  : JSON_Value := Create_Object;
    Market_Description : JSON_Value := Create_Object;
    -- this routine parses replies from both
    -- * List_Market_Catalogue
    -- * List_Market_Book

    --List_Market_Catalogue
    --      "result": [{
    --        "marketId": "1.109863141",
    --        "event": {..},
    --        "eventType": {..},
    --        "runners": [{..},{..},{..} ... ],
    --        "marketName": "A4 480m",
    --        "marketStartTime": "2013-06-24T10:19:00.000Z"
    --        }]

    -- List_Market_Book
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

  begin
    Log(Me & Service, "start");
    In_Play_Market := False;
    Get_Value(Container => J_Market,
              Field     => "marketId",
              Target    =>  DB_Market.Marketid,
              Found     => Found);
    if Found then
      Table_Amarkets.Read(Db_Market, Eos);
    end if;

    Get_Value(Container => J_Market,
              Field     => "marketName",
              Target    =>  DB_Market.Marketname,
              Found     => Found);


    Get_Value(Container => J_Market,
              Field     => "description",
              Target    => Market_Description,
              Found     => Found);
    if Found then
      Get_Value(Container => Market_Description,
                Field     => "marketType",
                Target    => DB_Market.Markettype,
                Found     => Found);
    end if;

    Get_Value(Container => J_Market,
              Field     => "marketStartTime",
              Target    =>  DB_Market.Startts,
              Found     => Found);


    Get_Value(Container => J_Market,
              Field     => "event",
              Target    => Event,
              Found     => Found);
    if Found then
      Get_Value(Container => Event,
                Field     => "id",
                Target    => DB_Market.Eventid,
                Found     => Found);
    end if;

    Get_Value(Container => J_Market,
              Field     => "inplay",
              Target    => In_Play_Market,
              Found     => Found);

    -- update start, ie these fields are in Market_Book only

    Get_Value(Container => J_Market,
              Field     => "numberOfWinners",
              Target    => DB_Market.Numwinners,
              Found     => Found);

    Get_Value(Container => J_Market,
              Field     => "totalAvailable",
              Target    => DB_Market.Totalavailable,
              Found     => Found);

    Get_Value(Container => J_Market,
              Field     => "numberOfRunners",
              Target    => DB_Market.Numrunners,
              Found     => Found);

    Get_Value(Container => J_Market,
              Field     => "numberOfActiveRunners",
              Target    => DB_Market.Numactiverunners,
              Found     => Found);

    Get_Value(Container => J_Market,
              Field     => "totalMatched",
              Target    => DB_Market.Totalmatched,
              Found     => Found);

    Get_Value(Container => J_Market,
              Field     => "status",
              Target    => DB_Market.Status,
              Found     => Found);

    Get_Value(Container => J_Market,
              Field     => "betDelay",
              Target    => DB_Market.Betdelay,
              Found     => Found);

    Log(Me, "In_Play_Market: " & In_Play_Market'Img &  Table_Amarkets.To_String(DB_Market));
    Log(Me & Service, Table_Amarkets.To_String(DB_Market));
    Log(Me & Service, "stop");

  end Parse_Market;

end RPC;
