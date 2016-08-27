with Types; use Types;
with Bot_Types; use Bot_Types;
package Tics is
  Bad_odds : exception;
------------------------------------------
  function Get_Tic_Index(Price : Float_8) return Integer ;
------------------------------------------
  function Get_Tic_Price(I : Integer) return Float_8 ;
------------------------------------------ 
  function Get_Zero_Size(Backprice : Back_Price_Type;
                         Backsize  : Bet_Size_Type;
                         Layprice  : Lay_Price_Type) return Bet_Size_Type ;
------------------------------------------ 
  function Get_Green_Size(Layprice   : Lay_Price_Type;
                          Laysize    : Bet_Size_Type;
                          Backprice  : Back_Price_Type) return Bet_Size_Type ;
end Tics;

  
  