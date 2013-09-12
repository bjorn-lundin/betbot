with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Sattmate_Calendar;

package Token is

  App_Key          : constant String   := "q0XW4VGRNoHuaszo";
  App_Key_Delayed  : constant String   := "fhGwsk2Qay4zEw2Q";
  Application_ID   : constant Positive := 1662;
  Application_Name : constant String := "bnl-bot";
--  URL : constant String := "https://beta-api.betfair.com/json-rpc";
  
  URL_BETTING : constant String := "https://api.betfair.com/exchange/betting/json-rpc/v1";
  URL_ACCOUNT : constant String := "https://api.betfair.com/exchange/account/json-rpc/v1";
  
--  URL : constant String := "https://api-ng.betstores.com/betting/betfair/services/beta-api.betfair.com/betting/json-rpc";
 
  
  Not_Valid_Token,
  Login_Failed  : exception;

  type Token_Type is tagged private;
  
  
  procedure Init(A_Token     : in out Token_Type ;
                  Username   : in     String;
                  Password   : in     String;
                  Product_Id : in     String;
                  Vendor_Id  : in     String) ;
  
  procedure Login(A_Token : in out Token_Type) ;
                  
  function  Get (A_Token  :        Token_Type) return String;
  procedure Set (A_Token  : in out Token_Type; The_Token : String);
  procedure Unset (A_Token : in out Token_Type) ;
  procedure Keep_Alive (A_Token : in out Token_Type ; Result : out Boolean);
  
private
  type Token_Type is tagged record
    Token_Is_Set : Boolean          := False;
    The_Token    : Unbounded_String := Null_Unbounded_String;
    Login_Time   : Sattmate_Calendar.Time_Type;
    Username     : Unbounded_String := Null_Unbounded_String;
    Password     : Unbounded_String := Null_Unbounded_String; 
    Product_Id   : Unbounded_String := Null_Unbounded_String;
    Vendor_Id    : Unbounded_String := Null_Unbounded_String; 
  end record;
end Token;