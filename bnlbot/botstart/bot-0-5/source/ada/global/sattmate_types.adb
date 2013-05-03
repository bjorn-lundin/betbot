--------------------------------------------------------------------------------
--
--	COPYRIGHT	SattControl AB, Malm|
--
--	FILE NAME	SATTMATE_TYPES_BODY.ADA
--
--	RESPONSIBLE	Henrik Dannberg
--
--	DESCRIPTION	This file contains the body of the package
--			SATTMATE_TYPES. The package contains all basic data
--			types used by the SattMate system.
--
--------------------------------------------------------------------------------
--
--	VERSION		2.0
--	AUTHOR		Henrik Dannberg
--	VERIFIED BY	?
--	DESCRIPTION	Original version
--
--------------------------------------------------------------------------------
--
--	VERSION		3.0
--	AUTHOR		Henrik Dannberg	3-DEC-1989
--	VERIFIED BY	?
--	DESCRIPTION	The following functions have been added :
--
--				function TO_BIT_ARRAY_16 (X: BYTE_ARRAY_2)
--				function TO_BIT_ARRAY_32 (X: BYTE_ARRAY_4)
--				function TO_BYTE_ARRAY_2 (X: BIT_ARRAY_16)
--				function TO_BYTE_ARRAY_4 (X: INTEGER_4)
--				function TO_STRING (X: BYTE_ARRAY)
--				function TO_BYTE_ARRAY (X: STRING)
--
--------------------------------------------------------------------------------
--
--	VERSION		5.0
--	AUTHOR		Henrik Dannberg	10-JAN-1991
--	VERIFIED BY	?
--	DESCRIPTION	The following functions have been moved to package
--			SATTMATE_CALENDAR :
--
--				INTEGER_4_TIME
--				INTEGER_4_DATE
--				CALENDAR_TIME
--
--------------------------------------------------------------------------------
--9.4.1-8146 BNL 23-sep-2005
-- Merged the x86 and ppc versions of this package
--------------------------------------------------------------------------------

with System;                  --9.4.1-8146
with Unchecked_Conversion;



package body Sattmate_Types is

   use type System.Bit_Order ; --9.4.1-8146

   -----------------------------------------------------------------------------
   function "not" (X : Byte) return Byte is
   begin
      return To_Byte (not To_Bit_Array_8 (X));
   end "not";
   -----------------------------------------------------------------------------
   function "and" (Left, Right : Byte) return Byte is
   begin
      return To_Byte (To_Bit_Array_8 (Left) and To_Bit_Array_8 (Right));
   end "and";
   -----------------------------------------------------------------------------
   function "or" (Left, Right : Byte) return Byte is
   begin
      return To_Byte (To_Bit_Array_8 (Left) or To_Bit_Array_8 (Right));
   end "or";
   -----------------------------------------------------------------------------
   function "xor" (Left, Right : Byte) return Byte is
   begin
      return To_Byte (To_Bit_Array_8 (Left) xor To_Bit_Array_8 (Right));
   end "xor";
   -----------------------------------------------------------------------------
   function "&" (Left : Byte; Right : Byte) return Byte_Array is
   begin
      return (Left, Right);
   end "&";
   -----------------------------------------------------------------------------
   function "&" (Left : Byte_Array; Right : Byte) return Byte_Array is
      Result : Byte_Array (Left'First .. Left'Last + 1);
   begin
      Result (Left'First .. Left'Last) := Left;
      Result (Left'Last + 1)           := Right;
      return Result;
   end "&";
   -----------------------------------------------------------------------------
   function "&" (Left : Byte; Right : Byte_Array) return Byte_Array is
      Result : Byte_Array (Right'First .. Right'Last + 1);
   begin
      Result (Right'First)                 := Left;
      Result (Right'First + 1 .. Right'Last + 1) := Right;
      return Result;
   end "&";
   -----------------------------------------------------------------------------
   function "&" (Left : Byte_Array; Right : Byte_Array) return Byte_Array is
      Result : Byte_Array (Left'First .. Left'Last + Right'Length);
   begin
      if Left'Length = 0 then
         return Right;
      elsif Right'Length = 0 then
         return Left;
      else
         Result (Left'First .. Left'Last)    := Left;
         Result (Left'Last + 1 .. Result'Last) := Right;
         return Result;
      end if;
   end "&";
   -----------------------------------------------------------------------------
   --9.4.1-8146 from ppc start
   procedure Mirror (Bits : in out Bit_Array) is
      Result : Bit_Array (Bits'Range);
   begin
      for I in Bits'Range loop
         Result (Result'Last - I + 1) := Bits (I);
      end loop;
      Bits := Result;
   end Mirror;
   -----------------------------------------------------------------------------
   procedure Swap2 (Bytes : in out Byte_Array_2) is
      Result : Byte_Array_2;
   begin
      Result := (1 => Bytes (2), 2 => Bytes (1));
      Bytes := Result;
   end Swap2;
   -----------------------------------------------------------------------------
   procedure Swap4 (Bytes : in out Byte_Array_4) is
      Result : Byte_Array_4;
   begin
      Result := (1 => Bytes (4), 2 => Bytes (3), 3 => Bytes (2), 4 => Bytes (1));
      Bytes := Result;
   end Swap4;
   -----------------------------------------------------------------------------
   --9.4.1-8146 from ppc stop

   --9.4.1-8146 from ppc but common start

   function Byte_To_Bit8   is new Unchecked_Conversion (Source => Byte,
                                                        Target => Bit_Array_8);
   -----------------------------------------------------------------------------
   function Byte2_To_Bit16 is new Unchecked_Conversion (Source => Byte_Array_2,
                                                        Target => Bit_Array_16);
   -----------------------------------------------------------------------------
   function I2_To_Bit16    is new Unchecked_Conversion (Source => Integer_2,
                                                        Target => Bit_Array_16);
   -----------------------------------------------------------------------------
   function Byte4_To_Bit32 is new Unchecked_Conversion (Source => Byte_Array_4,
                                                        Target => Bit_Array_32);
   -----------------------------------------------------------------------------
   function I4_To_Bit32    is new Unchecked_Conversion (Source => Integer_4,
                                                        Target => Bit_Array_32);
   -----------------------------------------------------------------------------
   function Bit8_To_Byte   is new Unchecked_Conversion (Source => Bit_Array_8,
                                                        Target => Byte);
   -----------------------------------------------------------------------------
   function Bit16_To_Byte2 is new Unchecked_Conversion (Source => Bit_Array_16,
                                                        Target => Byte_Array_2);
   -----------------------------------------------------------------------------
   function I2_To_Byte2    is new Unchecked_Conversion (Source => Integer_2,
                                                        Target => Byte_Array_2);
   -----------------------------------------------------------------------------
   function Bit32_To_Byte4 is new Unchecked_Conversion (Source => Bit_Array_32,
                                                        Target => Byte_Array_4);
   -----------------------------------------------------------------------------
   function I4_To_Byte4    is new Unchecked_Conversion (Source => Integer_4,
                                                        Target => Byte_Array_4);
   -----------------------------------------------------------------------------
   function Bit16_To_I2    is new Unchecked_Conversion (Source => Bit_Array_16,
                                                        Target => Integer_2);
   -----------------------------------------------------------------------------
   function Byte2_To_I2    is new Unchecked_Conversion (Source => Byte_Array_2,
                                                        Target => Integer_2);
   -----------------------------------------------------------------------------
   function Bit32_To_I4    is new Unchecked_Conversion (Source => Bit_Array_32,
                                                        Target => Integer_4);
   -----------------------------------------------------------------------------
   function Byte4_To_I4    is new Unchecked_Conversion (Source => Byte_Array_4,
                                                        Target => Integer_4);
   -----------------------------------------------------------------------------
   --9.4.1-8146 from ppc but common stop
   --x86 start
   -----------------------------------------------------------------------------
   function To_Bit_Array_8_X86 (X : Byte) return Bit_Array_8 is
   begin
      return Byte_To_Bit8 (X);
   end To_Bit_Array_8_X86;
   -----------------------------------------------------------------------------
   function To_Bit_Array_16_X86 (X : Byte_Array_2) return Bit_Array_16 is
   begin
      return Byte2_To_Bit16 (X);
   end To_Bit_Array_16_X86;
   -----------------------------------------------------------------------------
   function To_Bit_Array_16_X86 (X : Integer_2) return Bit_Array_16 is
   begin
      return I2_To_Bit16 (X);
   end To_Bit_Array_16_X86;
   -----------------------------------------------------------------------------
   function To_Bit_Array_32_X86 (X : Byte_Array_4) return Bit_Array_32 is
   begin
      return Byte4_To_Bit32 (X);
   end To_Bit_Array_32_X86;
   -----------------------------------------------------------------------------
   function To_Bit_Array_32_X86 (X : Integer_4) return Bit_Array_32 is
   begin
      return I4_To_Bit32 (X);
   end To_Bit_Array_32_X86;
   -----------------------------------------------------------------------------
   function To_Byte_X86 (X : Bit_Array_8) return Byte is
   begin
      return Bit8_To_Byte (X);
   end To_Byte_X86;
   -----------------------------------------------------------------------------
   function To_Byte_Array_2_X86 (X : Bit_Array_16) return Byte_Array_2 is
   begin
      return Bit16_To_Byte2 (X);
   end To_Byte_Array_2_X86;
   -----------------------------------------------------------------------------
   function To_Byte_Array_2_X86 (X : Integer_2) return Byte_Array_2 is
   begin
      return I2_To_Byte2 (X);
   end To_Byte_Array_2_X86;
   -----------------------------------------------------------------------------
   function To_Byte_Array_4_X86 (X : Bit_Array_32) return Byte_Array_4 is
   begin
      return Bit32_To_Byte4 (X);
   end To_Byte_Array_4_X86;
   -----------------------------------------------------------------------------
   function To_Byte_Array_4_X86 (X : Integer_4) return Byte_Array_4 is
   begin
      return I4_To_Byte4 (X);
   end To_Byte_Array_4_X86;
   -----------------------------------------------------------------------------
   function To_Integer_2_X86 (X : Bit_Array_16) return Integer_2 is
   begin
      return Bit16_To_I2 (X);
   end To_Integer_2_X86;
   -----------------------------------------------------------------------------
   function To_Integer_2_X86 (X : Byte_Array_2) return Integer_2 is
   begin
      return Byte2_To_I2 (X);
   end To_Integer_2_X86;
   -----------------------------------------------------------------------------
   function To_Integer_4_X86 (X : Bit_Array_32) return Integer_4 is
   begin
      return Bit32_To_I4 (X);
   end To_Integer_4_X86;
   -----------------------------------------------------------------------------
   function To_Integer_4_X86 (X : Byte_Array_4) return Integer_4 is
   begin
      return Byte4_To_I4 (X);
   end To_Integer_4_X86;
   -----------------------------------------------------------------------------
   --x86 stop
   --ppc start
   function To_Bit_Array_8_Ppc (X : Byte) return Bit_Array_8 is
      Result : Bit_Array_8;
   begin
      Result := Byte_To_Bit8 (X);
      Mirror (Result);
      return Result;
   end To_Bit_Array_8_Ppc;
   -----------------------------------------------------------------------------
   function To_Bit_Array_16_Ppc (X : Byte_Array_2) return Bit_Array_16 is
      Temp   : Byte_Array_2;
      Result : Bit_Array_16;
   begin
      Temp := X;
      Swap2 (Temp);
      Result := Byte2_To_Bit16 (Temp);
      Mirror (Result);
      return Result;
   end To_Bit_Array_16_Ppc;
   -----------------------------------------------------------------------------
   function To_Bit_Array_16_Ppc (X : Integer_2) return Bit_Array_16 is
      Result : Bit_Array_16;
   begin
      Result := I2_To_Bit16 (X);
      Mirror (Result);
      return Result;
   end To_Bit_Array_16_Ppc;
   -----------------------------------------------------------------------------
   function To_Bit_Array_32_Ppc (X : Byte_Array_4) return Bit_Array_32 is
      Temp   : Byte_Array_4;
      Result : Bit_Array_32;
   begin
      Temp := X;
      Swap4 (Temp);
      Result := Byte4_To_Bit32 (Temp);
      Mirror (Result);
      return Result;
   end To_Bit_Array_32_Ppc;
   -----------------------------------------------------------------------------
   function To_Bit_Array_32_Ppc (X : Integer_4) return Bit_Array_32 is
      Result : Bit_Array_32;
   begin
      Result := I4_To_Bit32 (X);
      Mirror (Result);
      return Result;
   end To_Bit_Array_32_Ppc;
   -----------------------------------------------------------------------------
   function To_Byte_Ppc (X : Bit_Array_8) return Byte is
      Temp   : Bit_Array_8;
      Result : Byte;
   begin
      Temp   := X;
      Mirror (Temp);
      Result := Bit8_To_Byte (Temp);
      return Result;
   end To_Byte_Ppc;
   -----------------------------------------------------------------------------
   function To_Byte_Array_2_Ppc (X : Bit_Array_16) return Byte_Array_2 is
   begin
      return (1 => To_Byte (X (1 .. 8)),
              2 => To_Byte (Bit_Array_8 (X (9 .. 16))));
   end To_Byte_Array_2_Ppc;
   -----------------------------------------------------------------------------
   function To_Byte_Array_2_Ppc (X : Integer_2) return Byte_Array_2 is
      Result : Byte_Array_2;
   begin
      Result := I2_To_Byte2 (X);
      Swap2 (Result);
      return Result;
   end To_Byte_Array_2_Ppc;
   -----------------------------------------------------------------------------
   function To_Byte_Array_4_Ppc (X : Bit_Array_32) return Byte_Array_4 is
      Temp   : Bit_Array_32;
      Result : Byte_Array_4;
   begin
      Temp   := X;
      Mirror (Temp);
      Result := Bit32_To_Byte4 (Temp);
      Swap4 (Result);
      return Result;
   end To_Byte_Array_4_Ppc;
   -----------------------------------------------------------------------------
   function To_Byte_Array_4_Ppc (X : Integer_4) return Byte_Array_4 is
      Result : Byte_Array_4;
   begin
      Result := I4_To_Byte4 (X);
      Swap4 (Result);
      return Result;
   end To_Byte_Array_4_Ppc;
   -----------------------------------------------------------------------------
   function To_Integer_2_Ppc (X : Bit_Array_16) return Integer_2 is
      Temp   : Bit_Array_16;
      Result : Integer_2;
   begin
      Temp   := X;
      Mirror (Temp);
      Result := Bit16_To_I2 (Temp);
      return Result;
   end To_Integer_2_Ppc;
   -----------------------------------------------------------------------------
   function To_Integer_2_Ppc (X : Byte_Array_2) return Integer_2 is
      Temp   : Byte_Array_2;
      Result : Integer_2;
   begin
      Temp := X;
      Swap2 (Temp);
      Result := Byte2_To_I2 (Temp);
      return Result;
   end To_Integer_2_Ppc;
   -----------------------------------------------------------------------------
   function To_Integer_4_Ppc (X : Bit_Array_32) return Integer_4 is
      Temp   : Bit_Array_32;
      Result : Integer_4;
   begin
      Temp := X;
      Mirror (Temp);
      Result := Bit32_To_I4 (Temp);
      return Result;
   end To_Integer_4_Ppc;
   -----------------------------------------------------------------------------
   function To_Integer_4_Ppc (X : Byte_Array_4) return Integer_4 is
      Temp   : Byte_Array_4;
      Result : Integer_4;
   begin
      Temp := X;
      Swap4 (Temp);
      Result := Byte4_To_I4 (Temp);
      return Result;
   end To_Integer_4_Ppc;

   -- generic start
   -----------------------------------------------------------------------------
   function To_Bit_Array_8  (X : Byte)         return Bit_Array_8 is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Bit_Array_8_Ppc (X); --ppc
         when System. Low_Order_First => return To_Bit_Array_8_X86 (X); --x86
      end case;
   end To_Bit_Array_8;
   -----------------------------------------------------------------------------
   function To_Bit_Array_16 (X : Byte_Array_2) return Bit_Array_16 is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Bit_Array_16_Ppc (X); --ppc
         when System. Low_Order_First => return To_Bit_Array_16_X86 (X); --x86
      end case;
   end To_Bit_Array_16;
   -----------------------------------------------------------------------------
   function To_Bit_Array_16 (X : Integer_2)    return Bit_Array_16 is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Bit_Array_16_Ppc (X); --ppc
         when System. Low_Order_First => return To_Bit_Array_16_X86 (X); --x86
      end case;
   end To_Bit_Array_16;
   -----------------------------------------------------------------------------
   function To_Bit_Array_32 (X : Byte_Array_4) return Bit_Array_32 is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Bit_Array_32_Ppc (X); --ppc
         when System. Low_Order_First => return To_Bit_Array_32_X86 (X); --x86
      end case;
   end To_Bit_Array_32;
   -----------------------------------------------------------------------------
   function To_Bit_Array_32 (X : Integer_4)    return Bit_Array_32 is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Bit_Array_32_Ppc (X); --ppc
         when System. Low_Order_First => return To_Bit_Array_32_X86 (X); --x86
      end case;
   end To_Bit_Array_32;
   -----------------------------------------------------------------------------
   function To_Byte         (X : Bit_Array_8)  return Byte is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Byte_Ppc (X); --ppc
         when System. Low_Order_First => return To_Byte_X86 (X); --x86
      end case;
   end To_Byte;
   -----------------------------------------------------------------------------
   function To_Byte_Array_2 (X : Bit_Array_16) return Byte_Array_2 is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Byte_Array_2_Ppc (X); --ppc
         when System. Low_Order_First => return To_Byte_Array_2_X86 (X); --x86
      end case;
   end To_Byte_Array_2;
   -----------------------------------------------------------------------------
   function To_Byte_Array_2 (X : Integer_2)    return Byte_Array_2 is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Byte_Array_2_Ppc (X); --ppc
         when System. Low_Order_First => return To_Byte_Array_2_X86 (X); --x86
      end case;
   end To_Byte_Array_2;
   -----------------------------------------------------------------------------
   function To_Byte_Array_4 (X : Bit_Array_32) return Byte_Array_4 is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Byte_Array_4_Ppc (X); --ppc
         when System. Low_Order_First => return To_Byte_Array_4_X86 (X); --x86
      end case;
   end To_Byte_Array_4;
   -----------------------------------------------------------------------------
   function To_Byte_Array_4 (X : Integer_4)    return Byte_Array_4 is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Byte_Array_4_Ppc (X); --ppc
         when System. Low_Order_First => return To_Byte_Array_4_X86 (X); --x86
      end case;
   end To_Byte_Array_4;
   -----------------------------------------------------------------------------
   function To_Integer_2    (X : Bit_Array_16) return Integer_2 is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Integer_2_Ppc (X); --ppc
         when System. Low_Order_First => return To_Integer_2_X86 (X); --x86
      end case;
   end To_Integer_2;
   -----------------------------------------------------------------------------
   function To_Integer_2    (X : Byte_Array_2) return Integer_2 is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Integer_2_Ppc (X); --ppc
         when System. Low_Order_First => return To_Integer_2_X86 (X); --x86
      end case;
   end To_Integer_2;
   -----------------------------------------------------------------------------
   function To_Integer_4    (X : Bit_Array_32) return Integer_4 is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Integer_4_Ppc (X); --ppc
         when System. Low_Order_First => return To_Integer_4_X86 (X); --x86
      end case;
   end To_Integer_4;
   -----------------------------------------------------------------------------
   function To_Integer_4    (X : Byte_Array_4) return Integer_4 is
   begin
      case System.Default_Bit_Order is
         when System.High_Order_First => return To_Integer_4_Ppc (X); --ppc
         when System. Low_Order_First => return To_Integer_4_X86 (X); --x86
      end case;
   end To_Integer_4;
   -----------------------------------------------------------------------------
   function To_String (X : Byte_Array) return String is			-- V3.0
      Result : String (X'Range);
   begin
      for I in X'Range loop
         Result (I) := Character'Val (Integer (X (I)));
      end loop;
      return Result;
   end To_String;
   -----------------------------------------------------------------------------
   function To_Byte_Array (X : String) return Byte_Array is		-- V3.0
      Result : Byte_Array (X'Range);
   begin
      for I in X'Range loop
         Result (I) := Byte (Character'Pos (X (I)));
      end loop;
      return Result;
   end To_Byte_Array;
   -----------------------------------------------------------------------------
   function Xor_Check_Sum (X : Byte_Array) return Byte is
      Check_Sum : Byte := 0;
   begin
      for Index in X'First .. X'Last loop
         Check_Sum := Check_Sum xor X (Index);
      end loop;
      return Check_Sum;
   end Xor_Check_Sum;
   -----------------------------------------------------------------------------

end Sattmate_Types;

