
with Types; use Types;
with Calendar2; use Calendar2;
with Table_Arunners;

package Runners is


  type V_Back_Type is array(1..5) of Float_8 ;

  type Runners_Type is tagged record
    Runner :  Table_Arunners.Data_Type;
    Back_Price : Float_8:= 0.0;
    Lay_Price  : Float_8:= 0.0;
    V_Back     : V_Back_Type := (others => 0.0);
    A_Back     : Float_8 := 0.0;
    V_Lay      : V_Back_Type := (others => 0.0);
    A_Lay      : Float_8 := 0.0;
    A2_Back    : Float_8 := 0.0;
    A2_Lay     : Float_8 := 0.0;
    K_Back, 
    K_Lay      : Float_8 := 0.0; -- slope - odds change / second
    K_Back_V, 
    K_Lay_V  : V_Back_Type := (others => 0.0); -- slope vector - odds change / second
    
    K_Back_Avg, 
    K_Lay_Avg      : Float_8 := 0.0; -- slopeavg  - odds change / second
    
    Last_Ts    : Time_Type := (2012,01,01,00,00,00,000); -- Time_Type_First raises CE on To_Seconds
  end record;
  
  procedure Fix_Average(R : in out Runners_Type; This_Ts :  Time_Type) ;
  
   

end Runners;

