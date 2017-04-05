with Types; use Types;
with Bot_Types; use Bot_Types;
package Tics is
  Bad_odds : exception;
------------------------------------------
  function Get_Tic_Index(Price : Fixed_Type) return Integer ;
------------------------------------------
  function Get_Tic_Price(I : Integer) return Fixed_Type ;
------------------------------------------
  function Get_Zero_Size(Backprice : Back_Price_Type;
                         Backsize  : Bet_Size_Type;
                         Layprice  : Lay_Price_Type) return Bet_Size_Type ;
------------------------------------------
  function Get_Green_Size(Layprice   : Lay_Price_Type;
                          Laysize    : Bet_Size_Type;
                          Backprice  : Back_Price_Type) return Bet_Size_Type ;

  function Get_Nearest_Higher_Tic_Index(Price : Fixed_Type) return Integer ;


end Tics;
