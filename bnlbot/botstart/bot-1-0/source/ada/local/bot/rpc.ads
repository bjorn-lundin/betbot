
with Gnatcoll.Json; use Gnatcoll.Json;
with Sattmate_Types; use Sattmate_Types;
with Bot_Types; use Bot_Types;
with Table_Arunners;
with Table_Amarkets;
with Table_Abalances;
with Table_Abets;

with Token;
with Sattmate_Calendar;

package RPC is


  type Result_Type is (Ok, Timeout, Logged_Out);
  JSON_Exception : exception;
  
  procedure Login;
  procedure Init(Username   : in     String;
                 Password   : in     String;
                 Product_Id : in     String;
                 Vendor_Id  : in     String;
                 App_Key    : in     String) ;
  
  

  function Get_Token return Token.Token_Type ;
  procedure Keep_Alive (Result : out Boolean);

  
  function API_Exceptions_Are_Present(Reply : JSON_Value) return Boolean ;
  procedure Bet_Is_Matched(Betid             : Integer_8 ; 
                           Is_Removed        : out Boolean; 
                           Is_Matched        : out Boolean; 
                           AVG_Price_Matched : out Bet_Price_Type;
                           Size_Matched      : out Bet_Size_Type
                           ) ;
  
  procedure Market_Status_Is_Changed(Market     : in out Table_Amarkets.Data_Type;
                                     Is_Changed :    out Boolean);

  procedure Get_Balance(Betfair_Result : out Result_Type ; Saldo : out Table_Abalances.Data_Type) ;
                                     
                                     
  procedure Check_Market_Result(Market_Id   : in     Market_Id_Type;
                                Runner_List : in out Table_Arunners.Arunners_List_Pack.List_Type);

  procedure Get_Cleared_Bet_Info_List(Bet_Status     : in Bet_Status_Type;
                                      Settled_From   : in Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_First;
                                      Settled_To     : in Sattmate_Calendar.Time_Type := Sattmate_Calendar.Time_Type_Last;
                                      Betfair_Result : out Result_Type;
                                      Bet_List       : out Table_Abets.Abets_List_Pack.List_Type) ;
  
end RPC;    