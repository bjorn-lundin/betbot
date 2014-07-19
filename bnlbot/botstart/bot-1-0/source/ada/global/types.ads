
with Ada.Text_IO;

package Types is

   type Byte is range 0 .. 255;
   for  Byte'Size use 8;

   type Integer_2 is range -32_768 .. 32_767;
   for  Integer_2'Size use 16;

   type Word is range 0 .. 2**16-1;
   for Word'size use 16;
   
   type Integer_4 is range -2_147_483_648 .. 2_147_483_647;
   for  Integer_4'Size use 32;

   type Integer_8 is range -9_223_372_036_854_775_808 .. 9_223_372_036_854_775_807;
   for  Integer_8'Size use 64;

   type Float_8 is new Long_Float; 
   
   package F8 is new  Ada.Text_IO.Float_IO (Float_8);
   
   function F8_Image(F : Float_8; Aft : Natural := 2 ; Exp : Natural := 0) return String ;
   function Trim (What : String) return String ;
   function Skip_All_Blanks (S : String) return String ;
   function Position (S, Match : String) return Integer;
   function Lower_Case (C : Character) return Character;
   function Lower_Case (S : String) return String;
   function Upper_Case (C : Character) return Character;
   function Upper_Case (S : String) return String;


end Types;
