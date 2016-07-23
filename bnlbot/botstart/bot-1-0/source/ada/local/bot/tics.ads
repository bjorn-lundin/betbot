with Types; use Types;
package Tics is
  Bad_odds : exception;
------------------------------------------
  function Get_Tic_Index(Price : Float_8) return Integer ;
------------------------------------------
  function Get_Tic_Price(I : Integer) return Float_8 ;
------------------------------------------ 
end Tics;

  
  