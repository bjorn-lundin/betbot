


with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Characters;
with Ada.Characters.Handling;

package body Types is

   -------------------------------------
   function Position (S, Match : String) return Integer is
   begin
      if Match'Length > 0 then
         for I in S'First .. S'Last - Match'Length + 1 loop
            if S (I .. I + Match'Length - 1) = Match then return I; end if;
         end loop;
      end if;
      return S'First - 1;
   end Position;
   -------------------------------------
   function Skip_All_Blanks (S : String) return String is
      Result : String (S'range);
      To     : Integer := Result'First - 1;
   begin
      for I in S'range loop
         if S (I) /= ' ' then
            To := To + 1;
            Result (To) := S (I);
         end if;
      end loop;
      return Result (Result'First .. To);
   end Skip_All_Blanks;
   -------------------------------------

   function Trim (What : String) return String is
      use Ada.Strings;
      use Ada.Strings.Fixed;
   begin
      return Trim (What, Both);
   end Trim;
   -------------------------------------

   function F8_Image(F : Float_8; Aft : Natural := 2 ; Exp : Natural := 0) return String is
      S : String(1..15) := (others => ' ');
   begin
      F8.Put(To => S, Item => F, Aft => Aft, Exp => Exp);
      return Trim(S);
   end F8_Image;
   -------------------------------------
 
   function Lower_Case (C : Character) return Character is
   begin
      return Ada.Characters.Handling.To_Lower (C);
   end Lower_Case;
   -------------------------------------

   function Lower_Case (S : String) return String is
      Result     : String (S'Range) := S;
      Tmp_Result : String := Ada.Characters.Handling.To_Lower (S);
   begin
      Result := Tmp_Result (Tmp_Result'First .. Tmp_Result'Last);
      return Result;
   end Lower_Case;
   -------------------------------------


   function Upper_Case (C : Character) return Character is
   begin
      return Ada.Characters.Handling.To_Upper (C);
   end Upper_Case;
   -------------------------------------


   function Upper_Case (S : String) return String is
      Result     : String (S'Range) := S;
      Tmp_Result : String := Ada.Characters.Handling.To_Upper (S);
   begin
      Result := Tmp_Result (Tmp_Result'First .. Tmp_Result'Last);
      return Result;
   end Upper_Case;  
   -------------------------------------
end Types;