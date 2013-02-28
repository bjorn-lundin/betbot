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

with SYSTEM;                  --9.4.1-8146
with UNCHECKED_CONVERSION;



package body SATTMATE_TYPES is

  use type SYSTEM.BIT_ORDER ; --9.4.1-8146
  
  -----------------------------------------------------------------------------
  function "not" (X: BYTE) return BYTE is
  begin 
    return TO_BYTE (not TO_BIT_ARRAY_8(X)); 
  end "not";
  -----------------------------------------------------------------------------
  function "and" (LEFT, RIGHT: BYTE) return BYTE is
  begin 
    return TO_BYTE (TO_BIT_ARRAY_8(LEFT) and TO_BIT_ARRAY_8(RIGHT)); 
  end "and";
  -----------------------------------------------------------------------------
  function "or" (LEFT, RIGHT: BYTE) return BYTE is
  begin 
    return TO_BYTE (TO_BIT_ARRAY_8(LEFT) or TO_BIT_ARRAY_8(RIGHT)); 
  end "or";
  -----------------------------------------------------------------------------
  function "xor" (LEFT, RIGHT: BYTE) return BYTE is
  begin 
    return TO_BYTE (TO_BIT_ARRAY_8(LEFT) xor TO_BIT_ARRAY_8(RIGHT)); 
  end "xor";
  -----------------------------------------------------------------------------
  function "&" (LEFT: BYTE; RIGHT: BYTE) return BYTE_ARRAY is
  begin 
    return (LEFT,RIGHT); 
  end "&";
  -----------------------------------------------------------------------------
  function "&" (LEFT: BYTE_ARRAY; RIGHT: BYTE) return BYTE_ARRAY is
    RESULT : BYTE_ARRAY (LEFT'FIRST..LEFT'LAST+1);
  begin
    RESULT (LEFT'FIRST..LEFT'LAST) := LEFT;
    RESULT (LEFT'LAST+1)           := RIGHT;
    return RESULT;
  end "&";
  -----------------------------------------------------------------------------
  function "&" (LEFT: BYTE; RIGHT: BYTE_ARRAY) return BYTE_ARRAY is
    RESULT : BYTE_ARRAY (RIGHT'FIRST..RIGHT'LAST+1);
  begin
    RESULT (RIGHT'FIRST)                 := LEFT;
    RESULT (RIGHT'FIRST+1..RIGHT'LAST+1) := RIGHT;
    return RESULT;
  end "&";
  -----------------------------------------------------------------------------
  function "&" (LEFT: BYTE_ARRAY; RIGHT: BYTE_ARRAY) return BYTE_ARRAY is
    RESULT : BYTE_ARRAY (LEFT'FIRST..LEFT'LAST+RIGHT'LENGTH);
  begin
    if LEFT'LENGTH = 0 then
      return RIGHT;
    elsif RIGHT'LENGTH = 0 then
      return LEFT;
    else
      RESULT (LEFT'FIRST..LEFT'LAST)    := LEFT;
      RESULT (LEFT'LAST+1..RESULT'LAST) := RIGHT;
      return RESULT;
    end if;
  end "&";
  -----------------------------------------------------------------------------
 --9.4.1-8146 from ppc start
  procedure MIRROR (BITS: in out BIT_ARRAY) is
    RESULT : BIT_ARRAY(BITS'RANGE);
  begin
    for i in BITS'range loop
      RESULT(RESULT'LAST-I+1) := BITS(I);
    end loop;
    BITS := RESULT;
  end MIRROR;
  -----------------------------------------------------------------------------
  procedure SWAP2 (BYTES: in out BYTE_ARRAY_2) is
    RESULT : BYTE_ARRAY_2;
  begin
    RESULT := (1 => BYTES(2), 2 => BYTES(1));
    BYTES := RESULT;
  end SWAP2;
  -----------------------------------------------------------------------------
  procedure SWAP4 (BYTES: in out BYTE_ARRAY_4) is
    RESULT : BYTE_ARRAY_4;
  begin
    RESULT := (1 => BYTES(4), 2 => BYTES(3), 3 => BYTES(2), 4 => BYTES(1));
    BYTES := RESULT;
  end SWAP4;
  -----------------------------------------------------------------------------
--9.4.1-8146 from ppc stop

 --9.4.1-8146 from ppc but common start

  function BYTE_TO_BIT8   is new UNCHECKED_CONVERSION (SOURCE => BYTE,
                                                       TARGET => BIT_ARRAY_8);
  -----------------------------------------------------------------------------
  function BYTE2_TO_BIT16 is new UNCHECKED_CONVERSION (SOURCE => BYTE_ARRAY_2,
                                                       TARGET => BIT_ARRAY_16);
  -----------------------------------------------------------------------------
  function I2_TO_BIT16    is new UNCHECKED_CONVERSION (SOURCE => INTEGER_2, 
                                                       TARGET => BIT_ARRAY_16);
  -----------------------------------------------------------------------------
  function BYTE4_TO_BIT32 is new UNCHECKED_CONVERSION (SOURCE => BYTE_ARRAY_4,
                                                       TARGET => BIT_ARRAY_32);
  -----------------------------------------------------------------------------
  function I4_TO_BIT32    is new UNCHECKED_CONVERSION (SOURCE => INTEGER_4, 
                                                       TARGET => BIT_ARRAY_32);
  -----------------------------------------------------------------------------
  function BIT8_TO_BYTE   is new UNCHECKED_CONVERSION (SOURCE => BIT_ARRAY_8,
                                                       TARGET => BYTE);
  -----------------------------------------------------------------------------
  function BIT16_TO_BYTE2 is new UNCHECKED_CONVERSION (SOURCE => BIT_ARRAY_16,
                                                       TARGET => BYTE_ARRAY_2);
  -----------------------------------------------------------------------------
  function I2_TO_BYTE2    is new UNCHECKED_CONVERSION (SOURCE => INTEGER_2,
                                                       TARGET => BYTE_ARRAY_2);
  -----------------------------------------------------------------------------
  function BIT32_TO_BYTE4 is new UNCHECKED_CONVERSION (SOURCE => BIT_ARRAY_32,
                                                       TARGET => BYTE_ARRAY_4);
  -----------------------------------------------------------------------------
  function I4_TO_BYTE4    is new UNCHECKED_CONVERSION (SOURCE => INTEGER_4,
                                                       TARGET => BYTE_ARRAY_4);
  -----------------------------------------------------------------------------
  function BIT16_TO_I2    is new UNCHECKED_CONVERSION (SOURCE => BIT_ARRAY_16,
                                                       TARGET => INTEGER_2);
  -----------------------------------------------------------------------------
  function BYTE2_TO_I2    is new UNCHECKED_CONVERSION (SOURCE => BYTE_ARRAY_2,
                                                       TARGET => INTEGER_2);
  -----------------------------------------------------------------------------
  function BIT32_TO_I4    is new UNCHECKED_CONVERSION (SOURCE => BIT_ARRAY_32,
                                                       TARGET => INTEGER_4);
  -----------------------------------------------------------------------------
  function BYTE4_TO_I4    is new UNCHECKED_CONVERSION (SOURCE => BYTE_ARRAY_4,
                                                       TARGET => INTEGER_4);
  -----------------------------------------------------------------------------
 --9.4.1-8146 from ppc but common stop
--x86 start
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_8_X86 (X: BYTE) return BIT_ARRAY_8 is
  begin 
    return BYTE_TO_BIT8(X);
  end TO_BIT_ARRAY_8_X86;	
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_16_X86 (X: BYTE_ARRAY_2) return BIT_ARRAY_16 is	
  begin 
    return BYTE2_TO_BIT16(X);
  end TO_BIT_ARRAY_16_X86;
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_16_X86 (X: INTEGER_2) return BIT_ARRAY_16 is
  begin 
    return I2_TO_BIT16(X);
  end TO_BIT_ARRAY_16_X86;
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_32_X86 (X: BYTE_ARRAY_4) return BIT_ARRAY_32 is	
  begin 
    return BYTE4_TO_BIT32(X);
  end TO_BIT_ARRAY_32_X86;
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_32_X86 (X: INTEGER_4) return BIT_ARRAY_32 is
  begin 
    return I4_TO_BIT32(X);
  end TO_BIT_ARRAY_32_X86;
  -----------------------------------------------------------------------------
  function TO_BYTE_X86 (X: BIT_ARRAY_8) return BYTE is
  begin 
    return BIT8_TO_BYTE(X);
  end TO_BYTE_X86;
  -----------------------------------------------------------------------------
  function TO_BYTE_ARRAY_2_X86 (X: BIT_ARRAY_16) return BYTE_ARRAY_2 is	
  begin 
    return BIT16_TO_BYTE2(X);
  end TO_BYTE_ARRAY_2_X86;
  -----------------------------------------------------------------------------
  function TO_BYTE_ARRAY_2_X86 (X: INTEGER_2) return BYTE_ARRAY_2 is
  begin 
    return I2_TO_BYTE2(X);
  end TO_BYTE_ARRAY_2_X86;
  -----------------------------------------------------------------------------
  function TO_BYTE_ARRAY_4_X86 (X: BIT_ARRAY_32) return BYTE_ARRAY_4 is	
  begin 
    return BIT32_TO_BYTE4(X);
  end TO_BYTE_ARRAY_4_X86;
  -----------------------------------------------------------------------------
  function TO_BYTE_ARRAY_4_X86 (X: INTEGER_4) return BYTE_ARRAY_4 is
  begin 
    return I4_TO_BYTE4(X);
  end TO_BYTE_ARRAY_4_X86;
  -----------------------------------------------------------------------------
  function TO_INTEGER_2_X86 (X: BIT_ARRAY_16) return INTEGER_2 is
  begin 
    return BIT16_TO_I2(X); 
  end TO_INTEGER_2_X86;
  -----------------------------------------------------------------------------
  function TO_INTEGER_2_X86 (X: BYTE_ARRAY_2) return INTEGER_2 is
  begin 
    return BYTE2_TO_I2(X);
  end TO_INTEGER_2_X86;
  -----------------------------------------------------------------------------
  function TO_INTEGER_4_X86 (X: BIT_ARRAY_32) return INTEGER_4 is
  begin 
    return BIT32_TO_I4(X); 
  end TO_INTEGER_4_X86;
  -----------------------------------------------------------------------------
  function TO_INTEGER_4_X86 (X: BYTE_ARRAY_4) return INTEGER_4 is
  begin 
    return BYTE4_TO_I4(X);
  end TO_INTEGER_4_X86;
  -----------------------------------------------------------------------------
--x86 stop
--ppc start
  function TO_BIT_ARRAY_8_PPC (X: BYTE) return BIT_ARRAY_8 is
    RESULT : BIT_ARRAY_8;
  begin
    RESULT := BYTE_TO_BIT8(X);
    MIRROR(RESULT);
    return RESULT;
  end TO_BIT_ARRAY_8_PPC;
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_16_PPC (X: BYTE_ARRAY_2) return BIT_ARRAY_16 is	
    TEMP   : BYTE_ARRAY_2;
    RESULT : BIT_ARRAY_16;
  begin
    TEMP := X;
    SWAP2(TEMP);
    RESULT := BYTE2_TO_BIT16(TEMP);
    MIRROR(RESULT);
    return RESULT;
  end TO_BIT_ARRAY_16_PPC;
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_16_PPC (X: INTEGER_2) return BIT_ARRAY_16 is
    RESULT : BIT_ARRAY_16;
  begin
    RESULT := I2_TO_BIT16(X);
    MIRROR(RESULT);
    return RESULT;
  end TO_BIT_ARRAY_16_PPC;
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_32_PPC (X: BYTE_ARRAY_4) return BIT_ARRAY_32 is	
    TEMP   : BYTE_ARRAY_4;
    RESULT : BIT_ARRAY_32;
  begin 
    TEMP := X;
    SWAP4(TEMP);
    RESULT := BYTE4_TO_BIT32(TEMP);
    MIRROR(RESULT);
    return RESULT;
  end TO_BIT_ARRAY_32_PPC;
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_32_PPC (X: INTEGER_4) return BIT_ARRAY_32 is
    RESULT : BIT_ARRAY_32;
  begin
    RESULT := I4_TO_BIT32(X);
    MIRROR(RESULT);
    return RESULT;
  end TO_BIT_ARRAY_32_PPC;
  -----------------------------------------------------------------------------
  function TO_BYTE_PPC (X: BIT_ARRAY_8) return BYTE is
    TEMP   : BIT_ARRAY_8;
    RESULT : BYTE;
  begin
    TEMP   := X;
    MIRROR(TEMP);
    RESULT := BIT8_TO_BYTE(TEMP);
    return RESULT;
  end TO_BYTE_PPC;
  -----------------------------------------------------------------------------
  function TO_BYTE_ARRAY_2_PPC (X: BIT_ARRAY_16) return BYTE_ARRAY_2 is	
  begin
    return (1 => TO_BYTE(X(1..8)),
            2 => TO_BYTE(BIT_ARRAY_8(X(9..16))));
  end TO_BYTE_ARRAY_2_PPC;
  -----------------------------------------------------------------------------
  function TO_BYTE_ARRAY_2_PPC (X: INTEGER_2) return BYTE_ARRAY_2 is
    RESULT: BYTE_ARRAY_2;
  begin
    RESULT := I2_TO_BYTE2(X);
    SWAP2(RESULT);
    return RESULT;
  end TO_BYTE_ARRAY_2_PPC;
  -----------------------------------------------------------------------------
  function TO_BYTE_ARRAY_4_PPC (X: BIT_ARRAY_32) return BYTE_ARRAY_4 is	
    TEMP  : BIT_ARRAY_32;
    RESULT: BYTE_ARRAY_4;
  begin
    TEMP   := X;
    MIRROR(TEMP);
    RESULT := BIT32_TO_BYTE4(TEMP);
    SWAP4(RESULT);
    return RESULT;
  end TO_BYTE_ARRAY_4_PPC;
  -----------------------------------------------------------------------------
  function TO_BYTE_ARRAY_4_PPC (X: INTEGER_4) return BYTE_ARRAY_4 is
    RESULT: BYTE_ARRAY_4;
  begin 
    RESULT := I4_TO_BYTE4(X);
    SWAP4(RESULT);
    return RESULT;
  end TO_BYTE_ARRAY_4_PPC;
  -----------------------------------------------------------------------------
  function TO_INTEGER_2_PPC (X: BIT_ARRAY_16) return INTEGER_2 is
    TEMP  : BIT_ARRAY_16;
    RESULT: INTEGER_2;
  begin
    TEMP   := X;
    MIRROR(TEMP);
    RESULT := BIT16_TO_I2(TEMP);
    return RESULT;
  end TO_INTEGER_2_PPC;
  -----------------------------------------------------------------------------
  function TO_INTEGER_2_PPC (X: BYTE_ARRAY_2) return INTEGER_2 is
    TEMP   : BYTE_ARRAY_2;
    RESULT : INTEGER_2;
  begin
    TEMP := X;
    SWAP2(TEMP);
    RESULT := BYTE2_TO_I2(TEMP);
    return RESULT;
  end TO_INTEGER_2_PPC;
  -----------------------------------------------------------------------------
  function TO_INTEGER_4_PPC (X: BIT_ARRAY_32) return INTEGER_4 is
    TEMP   : BIT_ARRAY_32;
    RESULT : INTEGER_4;
  begin
    TEMP := X;
    MIRROR(TEMP);
    RESULT := BIT32_TO_I4(TEMP);
    return RESULT;
  end TO_INTEGER_4_PPC;
  -----------------------------------------------------------------------------
  function TO_INTEGER_4_PPC (X: BYTE_ARRAY_4) return INTEGER_4 is
    TEMP   : BYTE_ARRAY_4;
    RESULT : INTEGER_4;
  begin
    TEMP := X;
    SWAP4(TEMP);
    RESULT := BYTE4_TO_I4(TEMP);
    return RESULT;
  end TO_INTEGER_4_PPC;

-- generic start
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_8  (X: BYTE)         return BIT_ARRAY_8 is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_BIT_ARRAY_8_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_BIT_ARRAY_8_X86(X); --x86
    end case;
  end TO_BIT_ARRAY_8;
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_16 (X: BYTE_ARRAY_2) return BIT_ARRAY_16 is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_BIT_ARRAY_16_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_BIT_ARRAY_16_X86(X); --x86
    end case;
  end TO_BIT_ARRAY_16;   	
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_16 (X: INTEGER_2)    return BIT_ARRAY_16 is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_BIT_ARRAY_16_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_BIT_ARRAY_16_X86(X); --x86
    end case;
  end TO_BIT_ARRAY_16;   	
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_32 (X: BYTE_ARRAY_4) return BIT_ARRAY_32 is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_BIT_ARRAY_32_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_BIT_ARRAY_32_X86(X); --x86
    end case;
  end TO_BIT_ARRAY_32;   		
  -----------------------------------------------------------------------------
  function TO_BIT_ARRAY_32 (X: INTEGER_4)    return BIT_ARRAY_32 is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_BIT_ARRAY_32_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_BIT_ARRAY_32_X86(X); --x86
    end case;
  end TO_BIT_ARRAY_32;   	
  -----------------------------------------------------------------------------
  function TO_BYTE         (X: BIT_ARRAY_8)  return BYTE is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_BYTE_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_BYTE_X86(X); --x86
    end case;
  end TO_BYTE;   	
  -----------------------------------------------------------------------------
  function TO_BYTE_ARRAY_2 (X: BIT_ARRAY_16) return BYTE_ARRAY_2 is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_BYTE_ARRAY_2_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_BYTE_ARRAY_2_X86(X); --x86
    end case;
  end TO_BYTE_ARRAY_2;	
  -----------------------------------------------------------------------------
  function TO_BYTE_ARRAY_2 (X: INTEGER_2)    return BYTE_ARRAY_2 is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_BYTE_ARRAY_2_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_BYTE_ARRAY_2_X86(X); --x86
    end case;
  end TO_BYTE_ARRAY_2;
  -----------------------------------------------------------------------------
  function TO_BYTE_ARRAY_4 (X: BIT_ARRAY_32) return BYTE_ARRAY_4 is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_BYTE_ARRAY_4_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_BYTE_ARRAY_4_X86(X); --x86
    end case;
  end TO_BYTE_ARRAY_4;	
  -----------------------------------------------------------------------------
  function TO_BYTE_ARRAY_4 (X: INTEGER_4)    return BYTE_ARRAY_4 is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_BYTE_ARRAY_4_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_BYTE_ARRAY_4_X86(X); --x86
    end case;
  end TO_BYTE_ARRAY_4;
  -----------------------------------------------------------------------------
  function TO_INTEGER_2    (X: BIT_ARRAY_16) return INTEGER_2 is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_INTEGER_2_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_INTEGER_2_X86(X); --x86
    end case;
  end TO_INTEGER_2;
  -----------------------------------------------------------------------------
  function TO_INTEGER_2    (X: BYTE_ARRAY_2) return INTEGER_2 is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_INTEGER_2_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_INTEGER_2_X86(X); --x86
    end case;
  end TO_INTEGER_2;
  -----------------------------------------------------------------------------
  function TO_INTEGER_4    (X: BIT_ARRAY_32) return INTEGER_4 is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_INTEGER_4_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_INTEGER_4_X86(X); --x86
    end case;
  end TO_INTEGER_4;
  -----------------------------------------------------------------------------
  function TO_INTEGER_4    (X: BYTE_ARRAY_4) return INTEGER_4 is
  begin
    case SYSTEM.DEFAULT_BIT_ORDER is  
      when SYSTEM.HIGH_ORDER_FIRST => return TO_INTEGER_4_PPC(X); --ppc        
      when SYSTEM. LOW_ORDER_FIRST => return TO_INTEGER_4_X86(X); --x86
    end case;
  end TO_INTEGER_4;
  -----------------------------------------------------------------------------
  function TO_STRING (X: BYTE_ARRAY) return STRING is			-- V3.0
    RESULT : STRING(X'RANGE);
  begin
    for I in X'RANGE loop
      RESULT(I) := CHARACTER'VAL(INTEGER(X(I)));      
    end loop;
    return RESULT;
  end TO_STRING;
  -----------------------------------------------------------------------------
  function TO_BYTE_ARRAY (X: STRING) return BYTE_ARRAY is		-- V3.0
    RESULT : BYTE_ARRAY(X'RANGE);
  begin
    for I in X'RANGE loop
      RESULT(I) := BYTE(CHARACTER'POS(X(I)));
    end loop;
    return RESULT;
  end TO_BYTE_ARRAY;
  -----------------------------------------------------------------------------
  function XOR_CHECK_SUM (X: BYTE_ARRAY) return BYTE is
    CHECK_SUM : BYTE := 0;
  begin
    for INDEX in X'FIRST..X'LAST loop
      CHECK_SUM := CHECK_SUM xor X(INDEX);
    end loop;
    return CHECK_SUM;
  end XOR_CHECK_SUM;
  -----------------------------------------------------------------------------

end SATTMATE_TYPES;

