------------------------------------------------------------------------------
--

with Ada.Directories;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps;
with Ada.Characters.Handling;
with Unicode.Encodings;

package body Mobile_Ws_Routines is

  --============================================================================
  -- Move an unbounded string to a fixed of specified length
  --============================================================================
  function Move_Unbounded(Us : in Unbounded_String; Length : in positive) return String is
    From_S : constant String := To_String(Us);
    To_S   : String(1..Length) := (others => ' ');
  begin
    Ada.Strings.Fixed.Move(From_S, To_S, Drop => Ada.Strings.Right);
    return To_S;
  end Move_Unbounded;

  --============================================================================
  -- Move an unbounded string to an integer_4
  --============================================================================
  function Move_Unbounded(Us : in Unbounded_String) return integer_4 is
  begin
    if Ada.Strings.Fixed.Trim(To_String(Us), Ada.Strings.Left) = "" then
      return 0;
    else
      return integer_4'value(To_String(Us));
    end if;
  exception
    when Constraint_Error => return 0;
  end Move_Unbounded;

  --============================================================================
  -- Trim leading zeroes from an unbounded string
  --============================================================================
  function Trim_Leading_Zeroes(Us : in Unbounded_String) return Unbounded_String is

    Trim_Left    : Ada.Strings.Maps.Character_Set := Ada.Strings.Maps.To_Set("0"); 
    Trim_Right   : Ada.Strings.Maps.Character_Set := Ada.Strings.Maps.To_Set("");  -- No trim 
  begin
    return Trim(Us, Trim_Left, Trim_Right);
  end Trim_Leading_Zeroes;

  --============================================================================
  -- Trim a string from leading and trailingf spaces
  --============================================================================
  function Trim(S : in String) return String is
    
    S1 : constant String := Ada.Strings.Fixed.Trim(S, Ada.Strings.Both);
  begin
    return S1;
  end Trim;

  --============================================================================
  -- Convert an Integer_4 value to a trimmed string
  --============================================================================
  function I4ToString(I : in Integer_4) return String is
  begin
    return Trim(Integer_4'Image(I));   
  end I4ToString;

  --============================================================================
  -- Insert leading zeroes in an integer value
  --============================================================================
  function Insert_Leading_Zeroes(Numb : in integer; 
                                 Size : in integer) return String is
    S_Qua : constant String := 
            Ada.Strings.Fixed.Trim(integer'image(Numb), Ada.Strings.Left);
  begin
    return (1..Size - S_Qua'Length=>'0') & S_Qua;
  end Insert_Leading_Zeroes;
  --============================================================================
  -- Lower-case an unbounded string
  --============================================================================
  function To_Lower(Us : in Unbounded_String) return Unbounded_String is
    use Ada.Characters.Handling;
  begin
    return To_Unbounded_String(To_Lower(To_String(Us)));
  end To_Lower;

  --============================================================================
  -- Get the filetype from an URI
  --============================================================================
 

  --============================================================================
  -- Convert a string value to ISOLATIN
  --============================================================================
  function To_Iso_Latin_15(Str : Unicode.CES.Byte_Sequence) return String is
    use Unicode.Encodings;
  begin
    return  Convert(Str  => Str,
                    From => Get_By_Name("utf-8"),
                    To   => Get_By_Name("iso-8859-15"));
  exception
    when Unicode.CES.Invalid_Encoding => return Str;
  end To_Iso_Latin_15;

  --============================================================================
  -- Convert a string value to UTF8
  --============================================================================
  function To_Utf8(Str : Unicode.CES.Byte_Sequence) return String is
    use Unicode.Encodings;
  begin
    return  Convert(Str  => Str,
                    From => Get_By_Name("iso-8859-15"),
                    To => Get_By_Name("utf-8"));
  exception
    when Unicode.CES.Invalid_Encoding => return Str;
  end To_Utf8;

end Mobile_Ws_Routines;