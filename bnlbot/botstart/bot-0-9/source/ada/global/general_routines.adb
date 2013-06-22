--------------------------------------------------------------------------------
--
--	COPYRIGHT	SattControl AB, Malm|
--
--	FILE NAME	GENERAL_ROUTINES_BODY.ADA
--
--	RESPONSIBLE	Henrik Dannberg
--
--	DESCRIPTION	This files contains a package body for the
--			package GENERAL_ROUTINES. The package contains
--			subprograms of general interest.
--
--------------------------------------------------------------------------------
--
--	VERSION		1.0
--	AUTHOR		Henrik Dannberg
--	VERIFIED BY	?
--	DESCRIPTION	Original version
--
--------------------------------------------------------------------------------
--
--	VERSION		2.0
--	AUTHOR		Henrik Dannberg
--	VERIFIED BY	?
--	DESCRIPTION	Package name CONVERT changed to
--			ENUMERATION_ASCII_CONVERSION.
--
--			Package NUMERIC_ASCII_CONVERSION added.
--
--------------------------------------------------------------------------------
--
--	VERSION		5.0
--	AUTHOR		Henrik Dannberg
--	VERIFIED BY	?
--	DESCRIPTION  a)	Function IS_ADA_RESERVED removed.
--
--		     b)	New generic parameter NUMERIC added to functions
--			STRING_TO_NUMERIC and NUMERIC_TO_STRING.
--
--		     c)	The following functions have been moved to package
--			SATTMATE_CALENDAR :
--
--				STRING_DATE, STRING_TIME, STRING_DATE_AND_TIME
--------------------------------------------------------------------------------
--9.3 AEA 031124 Add F8_TO_STRING
--------------------------------------------------------------------------------
--9.6-11689 BNL 04-May-2007 Added trim, and fixed *case to handle chars outside a..z
--------------------------------------------------------------------------------
--9.7-12814 BNL 05-Oct-2007 9.6-11689 introduced the assumption that the returned
--                                    string always should start with index 1.
--                                    This is not true anymore. The returned string now
--                                    has the same bounds as the input parameter,
--                                    in Upper_Case and Lower_Case - string versions
--------------------------------------------------------------------------------


with Text_Io;
with Ada.Strings;                    --9.6-11689
with Ada.Strings.Fixed;              --9.6-11689
with Ada.Characters.Handling ;       --9.6-11689

package body General_Routines is


   --9.6-11689 new function
   function Trim (What : String) return String is
      use Ada.Strings;
      use Ada.Strings.Fixed;
   begin
      return Trim (What, Both);
   end Trim;
   -------------------------------------


   function Lower_Case (C : Character) return Character is
   begin
      --9.6-11689    if C in 'A'..'Z' then return CHARACTER'VAL(CHARACTER'POS(C)+32);
      --9.6-11689                     else return C;
      --9.6-11689    end if;
      return Ada.Characters.Handling.To_Lower (C);  --9.6-11689
   end Lower_Case;

   function Lower_Case (S : String) return String is
      Result     : String (S'Range) := S;
      Tmp_Result : String := Ada.Characters.Handling.To_Lower (S);  --9.7-12814
   begin
      --9.6-11689    for I in RESULT'range loop
      --9.6-11689      if RESULT(I) in 'A'..'Z' then
      --9.6-11689        RESULT(I) := CHARACTER'VAL(CHARACTER'POS(RESULT(I))+32);
      --9.6-11689      end if;
      --9.6-11689    end loop;
      Result := Tmp_Result (Tmp_Result'First .. Tmp_Result'Last);    --9.7-12814
      return Result;
   end Lower_Case;


   function Upper_Case (C : Character) return Character is
   begin
      --9.6-11689    if C in 'a'..'z' then return CHARACTER'VAL(CHARACTER'POS(C)-32);
      --9.6-11689                     else return C;
      --9.6-11689    end if;
      return Ada.Characters.Handling.To_Upper (C);  --9.6-11689
   end Upper_Case;


   function Upper_Case (S : String) return String is
      Result     : String (S'Range) := S;
      Tmp_Result : String := Ada.Characters.Handling.To_Upper (S);  --9.7-12814
   begin
      --9.6-11689    for I in RESULT'range loop
      --9.6-11689      if RESULT(I) in 'a'..'z' then
      --9.6-11689        RESULT(I) := CHARACTER'VAL(CHARACTER'POS(RESULT(I))-32);
      --9.6-11689      end if;
      --9.6-11689    end loop;
      Result := Tmp_Result (Tmp_Result'First .. Tmp_Result'Last);   --9.7-12814
      return Result;
   end Upper_Case;

   --10.1
   function Camel_Case (What : String ; Style : Style_Type := Xml_Style) return String is
   -- will remove underscores, and make Capital letter of next, all
   -- others small : eg COMLI_MASTER_SLAVE -> comliMasterSlave
   -- letter after digits are capitalized: eg SIEMENS_3964R -> siemens3964R
      Tmp             : String   :=  Ada.Characters.Handling.To_Lower (What);
      Capitalize_Next : Boolean  := False;
   begin
      if Style = Ada_Style then
         Tmp (Tmp'First) := Upper_Case (Tmp (Tmp'First));
      end if;
      for I in Tmp'Range loop
         case Tmp (I) is
            when '_'    =>
               Capitalize_Next := True;
               if Style = Xml_Style then
                  Tmp (I) := ' ';
               end if;
            when others =>
               if Ada.Characters.Handling.Is_Digit (Tmp (I)) then
                  Capitalize_Next := True;
               elsif Tmp (I) = '.' then
                  if Style = Ada_Style then
                     Capitalize_Next := True;
                  end if;
               end if;
               if Capitalize_Next then
                  Tmp (I) := Ada.Characters.Handling.To_Upper (Tmp (I));
                  Capitalize_Next := False;
               end if;
         end case;
      end loop;
      return General_Routines.Skip_All_Blanks (Tmp);
   end Camel_Case;
   --generic bodies


   function Skip_All_Blanks (S : String) return String is
      Result : String (S'Range);
      To     : Integer := Result'First - 1;
   begin
      for I in S'Range loop
         if S (I) /= ' ' then
            To := To + 1;
            Result (To) := S (I);
         end if;
      end loop;
      return Result (Result'First .. To);
   end Skip_All_Blanks;


   function Skip_Leading_Blanks (S : String) return String is
   begin
      for I in S'Range loop
         if S (I) /= ' ' then return S (I .. S'Last); end if;
      end loop;
      return "";
   end Skip_Leading_Blanks;


   function Skip_Trailing_Blanks (S : String) return String is
   begin
      for I in reverse S'Range loop
         if S (I) /= ' ' then return S (S'First .. I); end if;
      end loop;
      return "";
   end Skip_Trailing_Blanks;


   function Position (S, Match : String) return Integer is
   begin
      if Match'Length > 0 then
         for I in S'First .. S'Last - Match'Length + 1 loop
            if S (I .. I + Match'Length - 1) = Match then return I; end if;
         end loop;
      end if;
      return S'First - 1;
   end Position;


   function F8_To_String (F : in Float_8) return String is
      package Float8_Io is new Text_Io.Float_Io (Float_8);
      Convert_String : String (1 .. 22) := (others => ' ');
   begin
      Float8_Io.Put (To => Convert_String, Item => F, Aft => 3, Exp => 0);
      return General_Routines.Skip_All_Blanks (Convert_String);
   end F8_To_String;

   function Adjust
     (Str        : in String;
      Adjustment : Adjustment_Type := Right)  return String is

      V   : String (1 .. Str'Length) := (others => ' ');

   begin
      if Str'Length = 0 then return ""; end if;

      case Adjustment is
         when Left  =>
            declare
               Tmp : constant String := General_Routines.Skip_Leading_Blanks (Str);
            begin
               V (1 .. Tmp'Last - Tmp'First + 1) := Tmp;
            end;

         when Right =>
            declare
               Tmp : constant String := General_Routines.Skip_Trailing_Blanks (Str);
            begin
               V (V'Last-(Tmp'Last - Tmp'First) .. V'Last) := Tmp;
            end;
      end case;

      return V;

      --  exception
      --    when others => raise CONVERSION_ERROR;
   end Adjust;





   --============================================================================

   --============================================================================
   -- v1.6
   -- This routine converts an ascii string from ascii 7 codes into an FLOAT_8
   -- type. For example "      .23" =>         0.230
   --                   "111111111" => 111111111.000
   --                   "       1." =>         1.000
   --                   "000000111" =>       111.000
   --                   "0000001.1" =>         1.100
   --
   function String_To_Float_8 (S : in String) return Float_8 is
      package My_Float_Io is new Text_Io.Float_Io ( Float_8);
      Float    : Float_8 := 0.0;
      Last     : Positive := 1;
      Str      : String (1 .. S'Length) := S;
      Real     : constant String := ".0";
      Negative : Boolean := False;  -- 9.4-5780
      ---------
      --v8.3e, 9.4-5780 rewritten
      procedure Check_String (S        : in out String;
                              Negative : out    Boolean)  is
      begin
         Negative := False;
         for I in S'Range loop
            if (S (I) = '-') then
               Negative := True;
               S (I) := ' ';
            end if;
            if (S (I) = '+') then
               S (I) := ' ';
            end if;
            if not (S (I) = ',' or
                      S (I) = '.' or
                      S (I) = ' ' or
                      S (I) = '0' or
                      S (I) = '1' or
                      S (I) = '2' or
                      S (I) = '3' or
                      S (I) = '4' or
                      S (I) = '5' or
                      S (I) = '6' or
                      S (I) = '7' or
                      S (I) = '8' or
                      S (I) = '9') then
               raise Constraint_Error;
            end if;
         end loop;
      end Check_String;
      ---------
      function Edit (S : in String) return String is
         S_Tmp     : String (1 .. S'Length + 2) := (others => '0');
         S_In      : String (1 .. S'Length)   := S;
         Dot_Found : Boolean               := False;
      begin
         for I in S_In'Range loop
            if S_In (I) = ',' then S_In (I) := '.'; end if;
            if S_In (I) = '.' then
               Dot_Found := True;
               exit;
            end if;
         end loop;

         if Dot_Found then
            for I in S_In'Range loop
               if S_In (I) /= ' ' then
                  S_Tmp (I + 1) := S_In (I);
               end if;
            end loop;
            return S_Tmp;
         else
            return General_Routines.Skip_All_Blanks (S) & Real;
         end if;
      end Edit;
      ---------
   begin
      Check_String (Str, Negative);  --v8.3e, 9.4-5780
      My_Float_Io. Get ( Edit (Str), Float  , Last);
      -- 9.4-5780 ---->
      if Negative then
         return 0.0 - Float;
      else
         return Float;
      end if;
      -- 9.4-5780 <----
   end String_To_Float_8;
   --============================================================================
   --============================================================================
   -- V8.1 New function
   function Truncate_Float_8 (Number : Float_8) return Integer_4 is
      Temporary  : Integer_4 := 0;
      Differance : Float_8;
   begin
      Temporary := Integer_4 (Number);
      Differance := Number - Float_8 (Temporary);
      if Differance < Float_8 (0) then
         return Integer_4 (Number - (1.0 + Differance));
      else
         return Integer_4 (Number - Differance);
      end if;
   end Truncate_Float_8;

   --============================================================================
   -- V8.1 New function
   function Mod_Float_8 (Operand1, Operand2 : Float_8) return Float_8 is
      Result      : Float_8   := Float_8 (0);
      Truncresult : Integer_4 := 0;
      Modulus     : Float_8   := Float_8 (0);
   begin
      if Operand2 = Float_8 (0) then
         raise Numeric_Error;
      end if;
      Result      := Operand1 / Operand2;
      Truncresult := Truncate_Float_8 (Result);
      Modulus     := (Result - Float_8 (Truncresult)) * Operand2;
      return Modulus;
   end Mod_Float_8;

   --============================================================================


   package body Enumeration_Ascii_Conversion is

      function Enumeration (Input : String) return Enumeration_Type is
         function Upper_Case (S : String) return String is
            Result : String (S'Range) := S;
         begin
            for I in Result'Range loop
               if Result (I) in 'a' .. 'z' then
                  Result (I) := Character'Val (Character'Pos (Result (I))-32);
               end if;
            end loop;
            return Result;
         end Upper_Case;
      begin
         declare
            Found : Boolean := False;
            Value : Enumeration_Type;
         begin
            for I in Enumeration_Type loop
               declare
                  Image : constant String := Enumeration_Type'Image (I);
               begin
                  if Input'Length > 0 and then Input'Length <= Image'Length then
                     if Upper_Case (Input) =
                       Image (Image'First .. Image'First + Input'Length - 1) then
                        Value := I;
                        if Found then
                           raise Ambigous_Value;
                        else
                           Found := True;
                        end if;
                     end if;
                  end if;
               end;
            end loop;
            if Found then
               return Value;
            else
               raise Illegal_Value;
            end if;
         end;
      end Enumeration;
   end Enumeration_Ascii_Conversion;


   package body Numeric_Ascii_Conversion is

      function String_To_Numeric (Value : String) return Numeric is

         function One_Digit (Value : Character) return Natural is
         begin
            if    Value in '0' .. Character'Val (Character'Pos ('0')+Base) then
               return Character'Pos (Value)-Character'Pos ('0');
            elsif Value in 'A' .. Character'Val (Character'Pos ('A')+Base - 11) then
               return Character'Pos (Value)-Character'Pos ('A')+10;
            elsif Value in 'a' .. Character'Val (Character'Pos ('a')+Base - 11) then
               return Character'Pos (Value)-Character'Pos ('a')+10;
            else
               raise Conversion_Error;
            end if;
         end One_Digit;

         function Several_Digits (Value : String) return Natural is
         begin
            if Value'Length = 0 then
               return 0;
            else
               return Base *
                 Several_Digits (Value (Value'First .. Value'Last - 1)) +
                 One_Digit (Value (Value'Last));
            end if;
         end Several_Digits;

      begin
         return Numeric (Several_Digits (Value));
      end String_To_Numeric;



      function Numeric_To_String (Value : Numeric; Width : Natural := 0) return String is

         function One_Digit (Value : Natural) return Character is
         begin
            if Value < 10 then
               return Character'Val (Character'Pos ('0') +Value);
            else
               return Character'Val (Character'Pos ('A') +Value - 10);
            end if;
         end One_Digit;

         function Several_Digits (Value : Natural) return String is
         begin
            if Value < Base then
               return (1 => One_Digit (Value));
            else
               return Several_Digits (Value / Base) & One_Digit (Value mod Base);
            end if;
         end Several_Digits;

      begin
         declare
            Result : constant String := Several_Digits (Natural (Value));
            Zeroes : constant String (1 .. Width) := (others => '0');
         begin
            if Result'Length > Width and Width > 0 then
               return (1 .. Width => '*');
            else
               return Zeroes (1 .. Width - Result'Length) & Result;
            end if;
         end;
      end Numeric_To_String;

   end Numeric_Ascii_Conversion;

   --chg - 24752
   function What_Coded_Value (X : String) return The_Type is
   begin
      for I in The_Type'Range loop
         if The_Type'Image (I) = Upper_Case (X) then
            return I;
         end if;
      end loop;
      -- Ok there might be a mapping like severeFailure -> Severe_Failure

      for I in The_Type'Range loop
         declare
            The_Image : String := The_Type'Image (I);
         begin
            for J in The_Image'Range loop -- remove any '_'
               case The_Image (J) is
                  when '_'    => The_Image (J) := ' ';
                  when others => null;
               end case;
            end loop;

            if Skip_All_Blanks (The_Image) = Upper_Case (X) then
               return I;
            end if;
         end;
      end loop;

      raise Conversion_Error with "No such enumeration value '" & X & "'";
   end What_Coded_Value;

   
end General_Routines;
