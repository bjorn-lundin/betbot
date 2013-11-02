
with Sattmate_Types; use Sattmate_Types;
with Unchecked_Conversion;
--with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded ; 


package Bot_Types is
--   subtype Bot_Name_Type is Unbounded_String;
--   subtype Bot_Log_File_Name_Type is Unbounded_String;
   type Bet_Market_Type is (Place, Winner);
   type Bet_Type_Type is (Green_Up_Back, Green_Up_Lay); 
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
   type Num_Winners_Type is new Byte;
   type Favorite_By_Type is new Float_8;
   type Profit_Type is new Float_8;
   
   type Mode_Type is (Real, Simulation);
   type Bet_Mode_Type is ( Real, Sim);
   for Bet_Mode_Type'Size use Integer_4'Size;
   for Bet_Mode_Type use ( Real => 2, Sim => 3);
   function Bet_Mode is new Unchecked_Conversion(Bet_Mode_Type, Integer_4);
   function Bet_Mode is new Unchecked_Conversion(Integer_4, Bet_Mode_Type);
   
   
   type Green_Up_Mode_Type is (Lay_First_Then_Back, Back_First_Then_Lay);

   
   function "-" (Left : Back_Price_Type ; Right : Delta_Price_Type) return Back_Price_Type;
   function "+" (Left : Back_Price_Type ; Right : Delta_Price_Type) return Back_Price_Type;
   function "+" (Left : Back_Price_Type ; Right : Favorite_By_Type) return Back_Price_Type;
   function "+" (Left : Float_8 ; Right : Favorite_By_Type) return Back_Price_Type ;
   function "+" (Left : Float_8 ; Right : Favorite_By_Type) return Float_8;
   function "<=" (Left : Back_Price_Type ; Right : Float_8) return Boolean;
   function "<=" (Left : Float_8 ; Right : Back_Price_Type) return Boolean ;
   function "<" (Left : Min_Lay_Price_Type ; Right : Float_8) return Boolean;
   function "<=" (Left : Min_Lay_Price_Type ; Right : Float_8) return Boolean;
   function "<=" (Left : Float_8 ; Right : Max_Lay_Price_Type) return Boolean ;
   
   function "*" (Left : Bet_Size_Type ; Right : Back_Price_Type) return Float_8;
   
   function ">=" (Left : Profit_Type ; Right : Max_Daily_Profit_Type) return Boolean ;
   function ">=" (Left : Profit_Type ; Right : Max_Daily_Loss_Type) return Boolean ;
   function "<" (Left : Profit_Type ; Right : Max_Daily_Loss_Type) return Boolean ;

   function "<" (Left : Integer ; Right : Min_Num_Runners_Type) return Boolean ;
   function ">" (Left : Integer ; Right : Max_Num_Runners_Type) return Boolean ;

   function "=" (Left : Integer_4 ; Right : Num_Winners_Type) return Boolean ;

   function "-" (Left : Bet_Price_Type ; Right : Delta_Price_Type) return Bet_Price_Type;
   function "+" (Left : Bet_Price_Type ; Right : Delta_Price_Type) return Bet_Price_Type;
   function "*" (Left : Bet_Size_Type ; Right : Bet_Price_Type) return Bet_Size_Type;
   function "/" (Left : Bet_Size_Type ; Right : Bet_Price_Type) return Bet_Size_Type;

   
   
   
end Bot_Types;
