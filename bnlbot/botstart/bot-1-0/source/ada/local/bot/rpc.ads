
with Gnatcoll.Json; use Gnatcoll.Json;
with Sattmate_Types; use Sattmate_Types;
with Bot_Types; use Bot_Types;
-- with Table_Awinners;
-- with Table_Anonrunners;
with Table_Amarkets;
with Table_Abalances;
with Token;

package RPC is


  type Result_Type is (Ok, Timeout, Logged_Out);
  
  
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
                                     
                                     
--  procedure Check_Market_Result(Market_Id       : in Market_Id_Type;
--                                Tkn             : in Token.Token_Type;
--                                Winner_List     : in out Table_Awinners.Awinners_List_Pack.List_Type;
--                                Non_Runner_List : in out Table_Anonrunners.Anonrunners_List_Pack.List_Type);

  
end RPC;    