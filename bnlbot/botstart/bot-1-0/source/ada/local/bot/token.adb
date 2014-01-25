with GNAT.Sockets;
--with Text_IO;
--with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Streams; use Ada.Streams;
--with Ada.Environment_Variables;
with Logging; use Logging;

with Aws;
with Aws.Client;
with Aws.Response;
with Aws.Headers;
with Aws.Headers.Set;
with Gnatcoll.Json; use Gnatcoll.Json;

pragma Elaborate_All(AWS.Headers);

package body Token is
  Me : constant String := "Token.";  
  Global_Headers : Aws.Headers.List := Aws.Headers.Empty_List; -- no not get mem-leaks

  -- package EV renames Ada.Environment_Variables;



  procedure Init(A_Token : in out Token_Type ;
                  Username   : in     String;
                  Password   : in     String;
                  Product_Id : in     String;
                  Vendor_Id  : in     String;
                  App_Key    : in     String) is
  begin
    A_Token.Username   := To_Unbounded_String(Username);
    A_Token.Password   := To_Unbounded_String(Password);
    A_Token.Product_Id := To_Unbounded_String(Product_Id);
    A_Token.Vendor_Id  := To_Unbounded_String(Vendor_Id);
    A_Token.App_Key    := To_Unbounded_String(App_Key);
  end Init;
  
  
  
  procedure Login(A_Token    : in out Token_Type) is
--    Host : constant String := "nonodev.com";
    Host : constant String := "localhost";
    Host_Entry : Gnat.Sockets.Host_Entry_Type
               := GNAT.Sockets.Get_Host_By_Name(Host);

    Address : GNAT.Sockets.Sock_Addr_Type;
    Socket  : GNAT.Sockets.Socket_Type;
    Channel : GNAT.Sockets.Stream_Access;
    Data    : Ada.Streams.Stream_Element_Array (1..100);
    Size    : Ada.Streams.Stream_Element_Offset;
   -- Ret     : Ada.Strings.Unbounded.Unbounded_String;
  begin
     -- Open a connection to the host
     Address.Addr := GNAT.Sockets.Addresses(Host_Entry, 1);
     Address.Port := 27_123;
     GNAT.Sockets.Create_Socket (Socket);
     GNAT.Sockets.Connect_Socket (Socket, Address);
     
     Channel := Gnat.Sockets.Stream (Socket);

    declare
       S : String := 
         "username="   & To_String(A_Token.Username) &
         ",password="  & To_String(A_Token.Password) &
         ",productid=" & To_String(A_Token.Product_id) &
         ",vendorid="  & To_String(A_Token.Vendor_id);
    begin        
      Log(Me & "Login", "Request: '" & S & "'"); 
      String'Write (Channel, S);
    end ;
    
     --get the reply
     GNAT.Sockets.Receive_Socket(Socket, Data, Size);
     A_Token.The_Token := Null_Unbounded_String;
     for i in 1 .. Size loop
        A_Token.The_Token := A_Token.The_Token & Character'Val(Data(i));
     end loop;
      Log(Me & "Login", "Reply: '" & To_String(A_Token.The_Token) & "'"); 
     
     if To_String(A_Token.The_Token) /= "ACCOUNT_CLOSED" and then
        To_String(A_Token.The_Token) /= "ACCOUNT_SUSPENDED" and then
        To_String(A_Token.The_Token) /= "API_ERROR" and then
        To_String(A_Token.The_Token) /= "FAILED_MESSAGE" and then
        To_String(A_Token.The_Token) /= "INVALID_LOCATION" and then
        To_String(A_Token.The_Token) /= "INVALID_PRODUCT" and then
        To_String(A_Token.The_Token) /= "INVALID_USERNAME_OR_PASSWORD" and then
        To_String(A_Token.The_Token) /= "INVALID_VENDOR_SOFTWARE_ID" and then
        To_String(A_Token.The_Token) /= "LOGIN_FAILED_ACCOUNT_LOCKED" and then
        To_String(A_Token.The_Token) /= "LOGIN_REQUIRE_TERMS_AND_CONDITIONS_ACCENPTANCE" and then
        To_String(A_Token.The_Token) /= "LOGIN_RESTRICTED_LOCATION" and then
        To_String(A_Token.The_Token) /= "LOGIN_UNAUTHORIZED" and then
        To_String(A_Token.The_Token) /= "OK_MESSAGES" and then
        To_String(A_Token.The_Token) /= "POKER_T_AND_C_ACCEPTANCE_REQUIRED" and then
        To_String(A_Token.The_Token) /= "T_AND_C_ACCEPTANCE_REQUIRED" and then
        To_String(A_Token.The_Token) /= "USER_NOT_ACCOUNT_OWNER" then

       A_Token.Token_Is_Set := True;
       A_Token.Login_Time := Sattmate_Calendar.Clock;
     else
       raise Login_Failed with To_String(A_Token.The_Token);
     end if;
  end Login;

  --------------------------------------------------------
  function  Get(A_Token : Token_Type) return String is
  begin
    if A_Token.Token_Is_Set then
      return To_String(A_Token.The_Token);
    else
      raise Not_Valid_Token;
    end if;
  end Get;
  --------------------------------------------------------
  procedure Set (A_Token : in out Token_Type; The_Token : String ) is
  begin
    A_Token.The_Token    := To_Unbounded_String(The_Token);
    A_Token.Token_Is_Set := True;
  end Set;
  -------------------------------------------------------------
  procedure Unset (A_Token : in out Token_Type) is
  begin
    A_Token.The_Token    := Null_Unbounded_String;
    A_Token.Token_Is_Set := False;
  end Unset;
  -------------------------------------------------------------
  
  function  Get_App_Key (A_Token : Token_Type) return String is
  begin
    return To_String(A_Token.App_Key);
  end Get_App_Key;
  -------------------------------------------------------------
  
  function  Get_Username (A_Token : Token_Type) return String is
  begin
    return To_String(A_Token.Username);
  end Get_Username;
  -------------------------------------------------------------
  
  function  Get_Password (A_Token : Token_Type) return String is
  begin
    return To_String(A_Token.Password);
  end Get_Password;
  -------------------------------------------------------------
  
  function  Get_Product_Id (A_Token : Token_Type) return String is
  begin
    return To_String(A_Token.Product_Id);
  end Get_Product_Id;
  -------------------------------------------------------------
  
  function  Get_Vendor_Id (A_Token : Token_Type) return String is
  begin
    return To_String(A_Token.Vendor_Id);
  end Get_Vendor_Id;
  -----------------------------------------------------------
   
  
  procedure Keep_Alive (A_Token : in out Token_Type; Result : out Boolean ) is
    -- just get the eventtypes
    Json_String : String := "{""jsonrpc"": ""2.0"", ""method"": ""SportsAPING/v1.0/listEventTypes"", ""params"": {""filter"":{}}, ""id"": 1}";
    AWS_Keep_Alive_Reply     : Aws.Response.Data;
    JSON_Keep_Alive_Reply : JSON_Value := Create_Object; 
    pragma Warnings(Off,JSON_Keep_Alive_Reply);
    Now : Sattmate_Calendar.Time_Type := Sattmate_Calendar.Clock;
    use  Sattmate_Calendar;
  begin
    if Now - A_Token.Login_Time > (1,0,0,0,0) then
      A_Token.Login;
      Result := True;
    else
--       Log(Me & "Keep_Alive", "start"); 
       Aws.Headers.Set.Reset (Global_Headers);
       Aws.Headers.Set.Add (Global_Headers, "X-Authentication", A_Token.Get);
       Aws.Headers.Set.Add (Global_Headers, "X-Application", A_Token.Get_App_Key);
       Aws.Headers.Set.Add (Global_Headers, "Accept", "application/json");
       AWS_Keep_Alive_Reply := Aws.Client.Post (Url          =>  Token.URL_BETTING,
                                                Data         =>  Json_String,
                                                Content_Type => "application/json",
                                                Headers      =>  Global_Headers,
                                                Timeouts     =>  Aws.Client.Timeouts (Each => 10.0));
       JSON_Keep_Alive_Reply := Read (Strm     => Aws.Response.Message_Body(AWS_Keep_Alive_Reply),
                                      Filename => "");

       Log(Me & "Keep_Alive", "stop - OK "); 
       Result := True;
    end if ;   
    exception   
      when others =>
        Log(Me & "Keep_Alive", Aws.Response.Message_Body(AWS_Keep_Alive_Reply)); 
        Log(Me & "Keep_Alive", "stop - FAIL "); 
        Result := False;
  end Keep_Alive;
  
  
end Token;