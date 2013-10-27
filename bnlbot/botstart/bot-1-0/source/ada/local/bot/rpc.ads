
with Gnatcoll.Json; use Gnatcoll.Json;
with Sattmate_Types; use Sattmate_Types;
with Token;
with Bot_Types; use Bot_Types;

package RPC is

  function API_Exceptions_Are_Present(Reply : JSON_Value) return Boolean ;
  procedure Bet_Is_Matched(Betid             : Integer_8 ; 
                           Tkn               : Token.Token_Type; 
                           Is_Matched        : out Boolean; 
                           AVG_Price_Matched : out Bet_Price_Type;
                           Size_Matched      : out Bet_Size_Type
                           ) ;
  
   
end RPC;    