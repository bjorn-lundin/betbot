


package body Bot_Types is

   
   ---------------------------------------------
   function "-" (Left : Back_Price_Type ; Right : Delta_Price_Type) return Back_Price_Type is
   begin
     return Left - Back_Price_Type(Right);
   end "-";
   ---------------------------------------------
   function "+" (Left : Back_Price_Type ; Right : Delta_Price_Type) return Back_Price_Type is
   begin
     return Left + Back_Price_Type(Right);
   end "+";
   ---------------------------------------------
   function "+" (Left : Back_Price_Type ; Right : Favorite_By_Type) return Back_Price_Type is
   begin
     return Left + Back_Price_Type(Right);
   end "+";
   ---------------------------------------------
   function "+" (Left : Float_8 ; Right : Favorite_By_Type) return Back_Price_Type is
   begin
     return Back_Price_Type(Left) + Back_Price_Type(Right);
   end "+";
   ---------------------------------------------
   function "+" (Left : Float_8 ; Right : Favorite_By_Type) return Float_8 is
   begin
     return Left + Float_8(Right);
   end "+";
   ---------------------------------------------
   
   function "<=" (Left : Back_Price_Type ; Right : Float_8) return Boolean is
   begin
     return Left <= Back_Price_Type(Right);
   end "<=";

   ---------------------------------------------
   function "<=" (Left : Float_8 ; Right : Back_Price_Type) return Boolean is
   begin
     return Left <= Float_8(Right);
   end "<=";
   ---------------------------------------------
   function "<" (Left : Min_Lay_Price_Type ; Right : Float_8) return Boolean is
   begin
     return Left < Min_Lay_Price_Type(Right);
   end "<";
   ---------------------------------------------
   function "<=" (Left : Min_Lay_Price_Type ; Right : Float_8) return Boolean is
   begin
     return Left <= Min_Lay_Price_Type(Right);
   end "<=";
   ---------------------------------------------
   function "<=" (Left : Float_8 ; Right : Max_Lay_Price_Type) return Boolean is
   begin
     return Left <= Float_8(Right);
   end "<=";
   ---------------------------------------------
   function "*" (Left : Bet_Size_Type ; Right : Back_Price_Type) return Float_8 is
   begin
     return Float_8(Left) * Float_8(Right);
   end "*";
   ---------------------------------------------

   function ">=" (Left : Profit_Type ; Right : Max_Daily_Profit_Type) return Boolean is
   begin
     return Float_8(Left) >= Float_8(Right);
   end ">=";
   ---------------------------------------------
   function ">=" (Left : Profit_Type ; Right : Max_Daily_Loss_Type) return Boolean is
   begin
     return Float_8(Left) >= Float_8(Right);
   end ">=";
   ---------------------------------------------
   function "<" (Left : Profit_Type ; Right : Max_Daily_Loss_Type) return Boolean is
   begin
     return Float_8(Left) < Float_8(Right);
   end "<";

   ---------------------------------------------
   function "<" (Left : Integer ; Right : Min_Num_Runners_Type) return Boolean is
   begin
     return Left < Integer(Right);
   end "<";
   ---------------------------------------------
   function ">" (Left : Integer ; Right : Max_Num_Runners_Type) return Boolean is
   begin
     return Left > Integer(Right);
   end ">";
   ---------------------------------------------
   
end Bot_Types;
