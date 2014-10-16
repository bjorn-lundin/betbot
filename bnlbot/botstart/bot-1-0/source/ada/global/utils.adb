
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Characters;
with Ada.Environment_Variables;
with Ada.Characters.Handling;  use Ada.Characters.Handling;
--with Text_Io;

package body Utils is
  package EV renames Ada.Environment_Variables;


  function Expand_File_Path (File_Path : String) return String is
    Tmp         : String(File_Path'range) := File_Path;
    Start_Symbol,End_Symbol : Integer         := -1;
    --------------------------------
    procedure Check_Unix_Syntax is
    begin
      for I in Tmp'range loop
        if Tmp(I) = '$' then
          if Start_Symbol = -1 then Start_Symbol := I;  end if;
        end if;
        if Start_Symbol /= -1 then
          if Tmp(I) = '/' then  End_Symbol := I-1; exit; end if;
        end if;
      end loop;
    end Check_Unix_Syntax;
    --------------------------------
    function Expand_Symbol(Tmp : String) return String is
    begin
      return EV.Value(To_Upper(Tmp(Start_Symbol+1..End_Symbol))); 
    end Expand_Symbol;
    --------------------------------
  begin
    --Text_Io.Put_Line("arg: '" & File_Path & "'");
    Check_Unix_Syntax;

    if Start_Symbol /= -1 and End_Symbol /= -1 then
      if    Start_Symbol /= Tmp'First and End_Symbol /= Tmp'Last then
        return Tmp(Tmp'First..Start_Symbol-1) & 
               Expand_Symbol(Tmp(Start_Symbol..End_Symbol)) & 
               Tmp(End_Symbol+1..Tmp'Last);
      else
        if Start_Symbol /= Tmp'First then
          return Tmp(Tmp'First..Start_Symbol-1) & 
                 Expand_Symbol(Tmp(Start_Symbol..End_Symbol));
        else
          return Expand_Symbol(Tmp(Start_Symbol..End_Symbol)) 
                 & Tmp(End_Symbol+1..Tmp'Last);
        end if;
      end if;
    else
      if Start_Symbol /= -1  then
        End_Symbol := Tmp'Last; 
        if Start_Symbol /= Tmp'First then
          return Tmp(Tmp'First..Start_Symbol-1) & 
                 Expand_Symbol(Tmp(Start_Symbol..End_Symbol));
        else
          return Expand_Symbol(Tmp(Start_Symbol..End_Symbol));
        end if;
      else
        return Tmp; 
      end if; 
    end if; 

  end Expand_File_Path;
  
  --------------------------------------------------------
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
  
end Utils;