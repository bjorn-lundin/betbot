

with Types; use Types;

package Utils is

  function Expand_File_Path (File_Path : String) return String ;
  function F8_Image(F : Float_8; Aft : Natural := 2 ; Exp : Natural := 0) return String ;
  function Trim (What : String) return String ;
  function Skip_All_Blanks (S : String) return String ;
  function Position (S, Match : String) return Integer;
  function Lower_Case (C : Character) return Character;
  function Lower_Case (S : String) return String;
  function Upper_Case (C : Character) return Character;
  function Upper_Case (S : String) return String;
  

end Utils;