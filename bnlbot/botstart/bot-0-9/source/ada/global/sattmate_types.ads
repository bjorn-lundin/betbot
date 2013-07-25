--------------------------------------------------------------------------------
--
--	COPYRIGHT	SattControl AB, Malm|
--
--	FILE NAME	SATTMATE_TYPES.ADA
--
--	RESPONSIBLE	Henrik Dannberg
--
--	DESCRIPTION	This file contains a specification of the package
--			SATTMATE_TYPES. The package contains all basic data
--			types used by the SattMate system.
--
--------------------------------------------------------------------------------
--
--	VERSION		2.0
--	AUTHOR		Henrik Dannberg
--	VERIFIED BY	?
--	DESCRIPTION	Original version
--			(replaces NECTAR_TYPES and BYTE_HANDLER)
--
--------------------------------------------------------------------------------
--
--	VERSION		3.0
--	AUTHOR		Henrik Dannberg
--	VERIFIED BY	?
--	DESCRIPTION	New conversion routines.
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
--------------------------------------------------------------------------------
--
--	VERSION		5.1
--	AUTHOR		Ingvar Hedgarde		14-Feb-1992
--	VERIFIED BY
--	DESCRIPTION	The type declarations for the array types have been
--			modified to include 0 in the array range.
--
--------------------------------------------------------------------------------
--
--	VERSION		9.7-SKF
--	AUTHOR		Björn Lundin		03-12-2008
--	VERIFIED BY
--	DESCRIPTION	Type CLOB and NCLOB introduced (for sql-ifc)
--
--------------------------------------------------------------------------------

--with CALENDAR;
--with SYSTEM;
with Ada.Strings.Unbounded;
with Ada.Numerics.Generic_Elementary_Functions ;
package Sattmate_Types is

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

   --  type FLOAT_4 is new SYSTEM.F_FLOAT;		-- VAX/Ada
   --  type FLOAT_8 is new SYSTEM.D_FLOAT;		-- VAX/Ada

   type Float_4 is new Float;            	-- Alsys Ada on AIX and NT
   type Float_8 is new Long_Float;       	-- Alsys Ada on AIX and NT
   
   package Float_8_Functions is new Ada.Numerics.Generic_Elementary_Functions(Float_8);

   --    type FLOAT_4 is new SHORT_FLOAT;		-- Verdix Ada on AIX
   --    type FLOAT_8 is new FLOAT;		-- Verdix Ada on AIX

   --    type FLOAT_4 is new FLOAT;		-- IBM Ada on AIX
   --    type FLOAT_8 is new LONG_FLOAT;		-- IBM Ada on AIX

   -- General declaration of FLOAT types :

   --  type FLOAT_4 is digits 6 range 2.5E-26 .. 1.9E+25;
   --  type FLOAT_8 is digits 9 range 2.0E-38 .. 2.0E+37;

   --  for FLOAT_4'SIZE use 32;
   --  for FLOAT_8'SIZE use 64;

   --9.7-SKF
   subtype  Clob is Ada.Strings.Unbounded.Unbounded_String;
   subtype Nclob is Ada.Strings.Unbounded.Unbounded_String;
   subtype  Blob is Ada.Strings.Unbounded.Unbounded_String;


   type Bit_Array is array (Natural range <>) of Boolean;            -- V5.1
   pragma Pack (Bit_Array);

   type Byte_Array      is array (Natural range <>) of Byte;         -- V5.1
   type Integer_2_Array is array (Natural range <>) of Integer_2;    -- V5.1
   type Integer_4_Array is array (Natural range <>) of Integer_4;    -- V5.1
   type Float_4_Array   is array (Natural range <>) of Float_4;      -- V5.1
   type Float_8_Array   is array (Natural range <>) of Float_8;      -- V5.1

   subtype Bit_Array_8  is Bit_Array (1 .. 8);
   subtype Bit_Array_16 is Bit_Array (1 .. 16);
   subtype Bit_Array_32 is Bit_Array (1 .. 32);

   subtype Byte_Array_2 is Byte_Array (1 .. 2);
   subtype Byte_Array_4 is Byte_Array (1 .. 4);

   function "not" (X : Byte)           return Byte;
   function "and" (Left, Right : Byte) return Byte;
   function "or"  (Left, Right : Byte) return Byte;
   function "xor" (Left, Right : Byte) return Byte;

   function "&" (Left : Byte;       Right : Byte)       return Byte_Array;
   function "&" (Left : Byte_Array; Right : Byte)       return Byte_Array;
   function "&" (Left : Byte;       Right : Byte_Array) return Byte_Array;
   function "&" (Left : Byte_Array; Right : Byte_Array) return Byte_Array;


   -- The results of the following conversion routines will always be the same,
   -- independent of the operating system used. The conversion rules are as
   -- follows :
   --
   --     1) The first bit in a BIT_ARRAY_8 corresponds to the least
   --        significant bit in a byte.
   --
   --     2) The first eight bits in a BIT_ARRAY_16 corresponds to the least
   --        significant byte in an integer_2.
   --
   --     2) The first eight bits in a BIT_ARRAY_32 corresponds to the least
   --        significant byte in the first word of an integer_4.
   --
   -- The following figure further illustrates the conversion rules :
   --
   --                32      25 24      17 16       9 8        1
   --               !----------!----------!----------!----------!
   --               !  byte 4  !  byte 3  !  byte 2  !  byte 1  !
   --               !----------!----------!----------!----------!
   --               !                 INTEGER_4                 !
   --               !----------!----------!----------!----------!
   --                                     !     INTEGER_2       !
   --                                     !----------!----------!
   --                                                !   BYTE   !
   --                                                !----------!

   function To_Bit_Array_8  (X : Byte)         return Bit_Array_8;

   function To_Bit_Array_16 (X : Byte_Array_2) return Bit_Array_16; 	-- V3.0
   function To_Bit_Array_16 (X : Integer_2)    return Bit_Array_16;

   function To_Bit_Array_32 (X : Byte_Array_4) return Bit_Array_32; 	-- V3.0
   function To_Bit_Array_32 (X : Integer_4)    return Bit_Array_32;

   function To_Byte         (X : Bit_Array_8)  return Byte;

   function To_Byte_Array_2 (X : Bit_Array_16) return Byte_Array_2; 	-- V3.0
   function To_Byte_Array_2 (X : Integer_2)    return Byte_Array_2;

   function To_Byte_Array_4 (X : Bit_Array_32) return Byte_Array_4; 	-- V3.0
   function To_Byte_Array_4 (X : Integer_4)    return Byte_Array_4;

   function To_Integer_2    (X : Bit_Array_16) return Integer_2;
   function To_Integer_2    (X : Byte_Array_2) return Integer_2;

   function To_Integer_4    (X : Bit_Array_32) return Integer_4;
   function To_Integer_4    (X : Byte_Array_4) return Integer_4;

   -- CONSTRAINT_ERROR will be raised in function TO_STRING if X contains illegal
   -- CHARACTER values.

   function To_String       (X : Byte_Array)   return String; 		-- V3.0
   function To_Byte_Array   (X : String)       return Byte_Array; 		-- V3.0


   -- The following function calculates a "xor" checksum. The checksum is
   -- initially set to 0 and then a new checksum is repeatingly calculated,
   -- using the following formula :
   --
   --	CHECKSUM := CHECKSUM xor B (I)
   --
   -- where I loops through B'RANGE.

   function Xor_Check_Sum (X : Byte_Array) return Byte;


end Sattmate_Types;
