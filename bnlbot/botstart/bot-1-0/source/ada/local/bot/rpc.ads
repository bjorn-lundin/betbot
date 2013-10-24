
with Gnatcoll.Json; use Gnatcoll.Json;
with Sattmate_Types; use Sattmate_Types;
with Token;

package RPC is

  function API_Exceptions_Are_Present(Reply : JSON_Value) return Boolean ;
  function Bet_Is_Matched(Betid : Integer_8; Tkn : Token.Token_Type) return Boolean;   
   
end RPC;    