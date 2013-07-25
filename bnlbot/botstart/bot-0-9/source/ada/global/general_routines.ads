--------------------------------------------------------------------------------
--
--	COPYRIGHT	SattControl AB, Malm|
--
--	FILE NAME	GENERAL_ROUTINES_SPEC.ADA
--
--	RESPONSIBLE	Henrik Dannberg
--
--	DESCRIPTION	This files contains a package specification for the
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
--chg-24752 BNL 04-May-2007 Added what_coded_value
--------------------------------------------------------------------------------

with Sattmate_Types; use Sattmate_Types;

--with Sattmate_Calendar;

package General_Routines is

   Conversion_Error : exception;

   type Adjustment_Type is (Left, Right);

   function Adjust
     (Str        : in String;
      Adjustment : Adjustment_Type := Right)  return String;

   -- The data will be left or right adjusted according to input parameter.

   function Trim (What : String) return String ;   --9.6-11689

   function Lower_Case (C : Character) return Character;
   function Lower_Case (S : String)    return String;

   function Upper_Case (C : Character) return Character;
   function Upper_Case (S : String)    return String;

   -- will remove underscores, and make Capital letter of next, all
   -- others small : eg COMLI_MASTER_SLAVE -> comliMasterSlave
   -- letter after digits are capitalized: ef SIEMENS_3964R -> siemens3964R

   type Style_Type is (Ada_Style, Xml_Style);
   function Camel_Case (What : String ; Style : Style_Type := Xml_Style) return String ;


   function Skip_All_Blanks      (S : String) return String;

   -- All blanks will be removed from string S;

   function Skip_Leading_Blanks  (S : String) return String;
   function Skip_Trailing_Blanks (S : String) return String;

   function Position (S, Match : String) return Integer;

   -- Returns the index of the first occurence of MATCH in S.
   -- If no match the returned value will be S'FIRST-1.


   function F8_To_String (F : in Float_8) return String; --3 decimals
   function F8_Image(F : Float_8) return String ; -- 2 decimals

   -- Returns a FLOAT_8 value formatted to a string


   ------------------------------------------------------------------------------V8.2 End
   ------------------------------------------------------------------------------
   -- v1.6
   function String_To_Float_8 (S : in String) return Float_8;

   --
   -- This routine converts an ascii string from ascii 7 codes into an FLOAT_8
   -- type. For example "      .23" =>         0.230
   --                   "111111111" => 111111111.000
   --                   "       1." =>         1.000
   --                   "000000111" =>       111.000
   --                   "0000001.1" =>         1.100
   -- If a ',' is present, it is converted to '.'
   --

   function Mod_Float_8 (Operand1, Operand2 : Float_8) return Float_8;

   -- Modulus function for floating numbers

   function Truncate_Float_8 (Number : Float_8) return Integer_4;

   package Enumeration_Ascii_Conversion is

      generic
         type Enumeration_Type is (<>);
      function Enumeration (Input : String) return Enumeration_Type;

      Ambigous_Value : exception;
      Illegal_Value  : exception;

   end Enumeration_Ascii_Conversion;



   package Numeric_Ascii_Conversion is

      subtype Base_Type is Positive range 2 .. 36;

      generic
         Base : Base_Type;
         type Numeric is range <>;
      function String_To_Numeric (Value : String) return Numeric;

      generic
         Base : Base_Type;
         type Numeric is range <>;
      function Numeric_To_String (Value : Numeric; Width : Natural := 0) return String;

      Conversion_Error : exception;

   end Numeric_Ascii_Conversion;


   --chg-24752
   -- very much like Enumeration_Ascii_Conversion but also does mapping like severeFailure -> Severe_Failure

   generic
      type The_Type is (<>);
   function What_Coded_Value (X : String) return The_Type;

end General_Routines;
