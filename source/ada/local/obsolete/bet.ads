
with Types; use Types;
with Bot_Types; use Bot_Types;
package Bet is
  function Profit_Today(Bet_Name : Bet_Name_Type) return Float_8 ;
  function Exists(Bet_Name : Bet_Name_Type; Market_Id : Market_Id_Type) return Boolean;  
  
end Bet;
