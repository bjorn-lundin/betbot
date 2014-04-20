--------------------------------------------------------------------------------
--
--	COPYRIGHT	SattControl AB, Malm|
--
--	FILE NAME	COMMAND_PARSER.ADA
--
--	RESPONSIBLE	Henrik Dannberg
--
--	DESCRIPTION	This files contains the generic package COMMAND_PARSER.
--			The package contains general subprograms to be used
--			for parsing system command lines.
--
--------------------------------------------------------------------------------
-- 1.0      HKD            Original version
-- 5.0      HKD 02-JAN-91  Double quotes now handled according to DCL convensions
--                         for string literals.
-- 5.1      HKD 12-JUL-91  Use diffrent option separators on VMS and UNIX.
-- 5.1.1    HKD 23-JUN-92  /NOoption didn't work on UNIX systems 
-- 6.1      HKD 11-nov-94  Support for WIN32 added.
-- 9.2-0054 SNE 28-Feb-02  ObjectAda 7.2.1 warnings corrected
-- 9.2-0104 SNE 13-May-02  Increased allowed option length from 80 to 256 characters.
--------------------------------------------------------------------------------

-- Initialy the procedure PARSE should be called. This procedure reads the
-- system command line (if any) and then decodes it. Inluded parameters,
-- options and their values can then be tested using user defined array
-- OPTION_SET and the functions VALUE and PARAMETER. (OPTION_SET should be
-- initatied with the default option settings before calling PARSE.)
--
-- We illustrate the parsing algorithm with an example. Suppose the following
-- program block is declared :
--
--	with COMMAND_PARSER;
--	declare
--	  type MY_OPTIONS is (DELETE,LIST,OUTPUT,MESSAGE);
--	  package MY_PARSER is new COMMAND_PARSER (MY_OPTIONS, 1);
--	  use MY_PARSER;
--	  IS_SET: OPTION_ARRAY := (DELETE => FALSE,
--	                           LIST   => TRUE,
--	                           OUTPUT => FALSE,
--	                           MESSAGE=> FALSE);
--	begin
--	  PARSE (OPTION_SETTINGS => IS_SET, VALUES_ALLOWED => (DELETE => FALSE,
--	                                                       LIST   => FALSE,
--	                                                       OUTPUT => TRUE,
--	                                                       MESSAGE=> TRUE));
--
--	....
--	....
--	end;
--
--	Suppose further that the following command line has been entered :
--
--		/NOLIST *.*/OUTPUT=txa1: /MESSAGE="Aha !" /de
--
--	After the call to PARSE the following values are available :
--
--		IS_SET(DELETE)		TRUE
--		IS_SET(LIST)		FALSE
--		IS_SET(OUTPUT)		TRUE
--		IS_SET(MESSAGE)		TRUE
--		VALUE(DELETE)		""
--		VALUE(LIST)		""
--		VALUE(OUTPUT)		"TXA1:"
--		VALUE(MESSAGE)		"Aha !"
--		PARAMETER(1)		"*.*"
--
--	Note the following :
--
--	     *	Option values may be enclosed with quotes (").
--
--	     *	The command line will be converted to uppercase, except
--		strings surrounded by quotes.
--
--	     *	Option names may be abbreviated as long as the names are
--		significant.
--
--	     *	If an illegal option has been entered, an appropriate exception
--		will be raised. The function ILLEGAL_OPTION will return the
--		name of the illegal option.


generic
  type OPTION_NAMES is (<>);    -- Enumeration type defining the names of
                                -- the allowed options.

  MAX_PARAMETERS: NATURAL:=0;   -- Max number of allowed parameters.

package COMMAND_PARSER is

  subtype PARAMETER_INDEX is POSITIVE range 1..MAX_PARAMETERS;

  type OPTION_ARRAY is array (OPTION_NAMES) of BOOLEAN;

  procedure PARSE (OPTION_SETTINGS : in out OPTION_ARRAY;
                   VALUES_ALLOWED  : OPTION_ARRAY:=(others=>FALSE));

  function  VALUE     (OPTION: OPTION_NAMES)     return STRING;
  function  PARAMETER (NUMBER: PARAMETER_INDEX) return STRING;

  function  ILLEGAL_OPTION return STRING;

  UNDEFINED_OPTION    : exception;
  AMBIGOUS_OPTION     : exception;
  VALUE_NOT_ALLOWED   : exception;
  TOO_MANY_PARAMETERS : exception;

end COMMAND_PARSER;
