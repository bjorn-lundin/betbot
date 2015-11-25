------------------------------------------------------------------------------
--
--	COPYRIGHT	Consafe Logistics AB
--
--	FILE NAME	Mobile_Ws_ROUTINES.ADS
--
--	RESPONSIBLE	Ann-Charlotte Andersson
--
--	DESCRIPTION	Global Mobile WebServer routines
--

--------------------------------------------------------------------------------
with Types; use Types;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Unicode;
with Unicode.CES;

package Mobile_Ws_Routines is

  -- Move an unbounded string to a string of fixed length
  function Move_Unbounded(Us : in Unbounded_String; Length : in positive) return String;

  -- Move an unbounded string to an integer_4
  function Move_Unbounded(Us : in Unbounded_String) return integer_4;

  -- Trim leading zeroes from an unbounded string
  function Trim_Leading_Zeroes(Us : in Unbounded_String) return Unbounded_String;

  -- Trim leading and trailing spaces from a string
  function Trim(S : in String) return String;

  -- Convert an Integer_4 to a trimmed string
  function I4ToString(I : in Integer_4) return String;

  function To_Iso_Latin_15(Str : Unicode.CES.Byte_Sequence) return String;

  function To_Utf8(Str : Unicode.CES.Byte_Sequence) return String;

  -- Insert leading zeroes in an integer value 
  function Insert_Leading_Zeroes(Numb : in integer; 
                                 Size : in integer) return String;

  --Converts an unbounded string to lowercase
  function To_Lower(Us : in Unbounded_String) return Unbounded_String;

end Mobile_Ws_Routines;