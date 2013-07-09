with GNAT.Sockets;
with Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Streams; use Ada.Streams;
with Ini;
with Ada.Environment_Variables;
pragma Elaborate_All(Ini);
with GNATCOLL.Traces; use GNATCOLL.Traces;

package body Token is
  Me : constant GNATCOLL.Traces.Trace_Handle :=  GNATCOLL.Traces.Create ("Token");  

  package EV renames Ada.Environment_Variables;

  procedure Login(A_Token : in out Token_Type) is
--    Host : constant String := "nonodev.com";
    Host : constant String := "localhost";
    Host_Entry : Gnat.Sockets.Host_Entry_Type
               := GNAT.Sockets.Get_Host_By_Name(Host);

    Address : GNAT.Sockets.Sock_Addr_Type;
    Socket  : GNAT.Sockets.Socket_Type;
    Channel : GNAT.Sockets.Stream_Access;
    Data    : Ada.Streams.Stream_Element_Array (1..100);
    Size    : Ada.Streams.Stream_Element_Offset;
    Ret     : Ada.Strings.Unbounded.Unbounded_String;
  begin
     -- Open a connection to the host
     Address.Addr := GNAT.Sockets.Addresses(Host_Entry, 1);
     Address.Port := 27_123;
     GNAT.Sockets.Create_Socket (Socket);
     GNAT.Sockets.Connect_Socket (Socket, Address);
     
     Channel := Gnat.Sockets.Stream (Socket);
     --get from inifile
    declare
       S : String := 
         "username=" & Ini.Get_Value("betfair","username","Not_Found") &
         ",password=" & Ini.Get_Value("betfair","password","Not_Found") &
         ",productid=" & Ini.Get_Value("betfair","product_id","Not_Found") &
         ",vendorid=" & Ini.Get_Value("betfair","vendor_id","Not_Found");
    begin        
      Trace(Me, "Request: '" & S & "'"); 
      String'Write (Channel, S);
    end ;
    
     --get the reply
     GNAT.Sockets.Receive_Socket(Socket, Data, Size);
     A_Token.The_Token := Null_Unbounded_String;
     for i in 1 .. Size loop
        A_Token.The_Token := A_Token.The_Token & Character'Val(Data(i));
     end loop;
      Trace(Me, "Reply: '" & To_String(A_Token.The_Token) & "'"); 
     
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
begin
  Ini.Load(Ev.Value("BOT_START") & "/user/" & EV.Value("BOT_USER") & "/login.ini");
end Token;