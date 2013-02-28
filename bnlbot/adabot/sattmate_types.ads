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

package SATTMATE_TYPES is

  type BYTE is range 0..255;
  for  BYTE'SIZE use 8;

  type INTEGER_2 is range -32_768..32_767;
  for  INTEGER_2'SIZE use 16;

  type INTEGER_4 is range -2_147_483_648..2_147_483_647;
  for  INTEGER_4'SIZE use 32;

--  type FLOAT_4 is new SYSTEM.F_FLOAT;		-- VAX/Ada
--  type FLOAT_8 is new SYSTEM.D_FLOAT;		-- VAX/Ada

  type FLOAT_4 is new FLOAT;            	-- Alsys Ada on AIX and NT
  type FLOAT_8 is new LONG_FLOAT;       	-- Alsys Ada on AIX and NT

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
  subtype  CLOB is Ada.Strings.Unbounded.Unbounded_String;
  subtype NCLOB is Ada.Strings.Unbounded.Unbounded_String;
  subtype  BLOB is Ada.Strings.Unbounded.Unbounded_String;


  type BIT_ARRAY is array (NATURAL range <>) of BOOLEAN;            -- V5.1
  pragma PACK (BIT_ARRAY);

  type BYTE_ARRAY      is array (NATURAL range <>) of BYTE;         -- V5.1
  type INTEGER_2_ARRAY is array (NATURAL range <>) of INTEGER_2;    -- V5.1
  type INTEGER_4_ARRAY is array (NATURAL range <>) of INTEGER_4;    -- V5.1
  type FLOAT_4_ARRAY   is array (NATURAL range <>) of FLOAT_4;      -- V5.1
  type FLOAT_8_ARRAY   is array (NATURAL range <>) of FLOAT_8;      -- V5.1

  subtype BIT_ARRAY_8  is BIT_ARRAY (1..8);
  subtype BIT_ARRAY_16 is BIT_ARRAY (1..16);
  subtype BIT_ARRAY_32 is BIT_ARRAY (1..32);

  subtype BYTE_ARRAY_2 is BYTE_ARRAY (1..2);
  subtype BYTE_ARRAY_4 is BYTE_ARRAY (1..4);

  function "not" (X: BYTE)           return BYTE;
  function "and" (LEFT, RIGHT: BYTE) return BYTE;
  function "or"  (LEFT, RIGHT: BYTE) return BYTE;
  function "xor" (LEFT, RIGHT: BYTE) return BYTE;

  function "&" (LEFT: BYTE;       RIGHT: BYTE)       return BYTE_ARRAY;
  function "&" (LEFT: BYTE_ARRAY; RIGHT: BYTE)       return BYTE_ARRAY;
  function "&" (LEFT: BYTE;       RIGHT: BYTE_ARRAY) return BYTE_ARRAY;
  function "&" (LEFT: BYTE_ARRAY; RIGHT: BYTE_ARRAY) return BYTE_ARRAY;


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

  function TO_BIT_ARRAY_8  (X: BYTE)         return BIT_ARRAY_8;

  function TO_BIT_ARRAY_16 (X: BYTE_ARRAY_2) return BIT_ARRAY_16;	-- V3.0
  function TO_BIT_ARRAY_16 (X: INTEGER_2)    return BIT_ARRAY_16;

  function TO_BIT_ARRAY_32 (X: BYTE_ARRAY_4) return BIT_ARRAY_32;	-- V3.0
  function TO_BIT_ARRAY_32 (X: INTEGER_4)    return BIT_ARRAY_32;

  function TO_BYTE         (X: BIT_ARRAY_8)  return BYTE;

  function TO_BYTE_ARRAY_2 (X: BIT_ARRAY_16) return BYTE_ARRAY_2;	-- V3.0
  function TO_BYTE_ARRAY_2 (X: INTEGER_2)    return BYTE_ARRAY_2;
  
  function TO_BYTE_ARRAY_4 (X: BIT_ARRAY_32) return BYTE_ARRAY_4;	-- V3.0
  function TO_BYTE_ARRAY_4 (X: INTEGER_4)    return BYTE_ARRAY_4;

  function TO_INTEGER_2    (X: BIT_ARRAY_16) return INTEGER_2;
  function TO_INTEGER_2    (X: BYTE_ARRAY_2) return INTEGER_2;

  function TO_INTEGER_4    (X: BIT_ARRAY_32) return INTEGER_4;
  function TO_INTEGER_4    (X: BYTE_ARRAY_4) return INTEGER_4;

-- CONSTRAINT_ERROR will be raised in function TO_STRING if X contains illegal
-- CHARACTER values.

  function TO_STRING       (X: BYTE_ARRAY)   return STRING;		-- V3.0
  function TO_BYTE_ARRAY   (X: STRING)       return BYTE_ARRAY;		-- V3.0


  -- The following function calculates a "xor" checksum. The checksum is
  -- initially set to 0 and then a new checksum is repeatingly calculated,
  -- using the following formula :
  --
  --	CHECKSUM := CHECKSUM xor B (I)
  -- 
  -- where I loops through B'RANGE.

  function XOR_CHECK_SUM (X: BYTE_ARRAY) return BYTE;


end SATTMATE_TYPES;
