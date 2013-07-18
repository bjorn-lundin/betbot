
with Sattmate_Types; use Sattmate_Types;
--with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded ; 


package Bot_Types is
--   subtype Bot_Name_Type is Unbounded_String;
--   subtype Bot_Log_File_Name_Type is Unbounded_String;
   type Bet_Market_Type is (Place, Winner);
   type Bet_Type_Type is (Lay, Back); --, Lay_Favorite);
   type Animal_Type is (Horse, Hound);
   type Max_Daily_Profit_Type is new Float_8;
   type Max_Daily_Loss_Type is new Float_8;
   type Max_Lay_Price_Type is new Float_8;
   type Min_Lay_Price_Type is new Float_8;
   type Back_Price_Type is new Float_8;
   type Delta_Price_Type is new Float_8;
   type Bet_Size_Type is new Float_8;
   type Bet_Price_Type is new Float_8;
   type Min_Num_Runners_Type is new Byte;
   type Max_Num_Runners_Type is new Byte;   
   type Favorite_By_Type is new Float_8;
   type Profit_Type is new Float_8;

   
   function "-" (Left : Back_Price_Type ; Right : Delta_Price_Type) return Back_Price_Type;
   function "+" (Left : Back_Price_Type ; Right : Delta_Price_Type) return Back_Price_Type;
   function "+" (Left : Back_Price_Type ; Right : Favorite_By_Type) return Back_Price_Type;
   function "+" (Left : Float_8 ; Right : Favorite_By_Type) return Back_Price_Type ;
   function "+" (Left : Float_8 ; Right : Favorite_By_Type) return Float_8;
   function "<=" (Left : Back_Price_Type ; Right : Float_8) return Boolean;
   function "<=" (Left : Float_8 ; Right : Back_Price_Type) return Boolean ;
   function "<" (Left : Min_Lay_Price_Type ; Right : Float_8) return Boolean;
   function "<=" (Left : Float_8 ; Right : Max_Lay_Price_Type) return Boolean ;

   
   
end Bot_Types;
