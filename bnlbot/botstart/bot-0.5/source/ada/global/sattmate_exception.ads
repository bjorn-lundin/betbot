--------------------------------------------------------------------------------
--
--	COPYRIGHT	Alfa Laval Automation AB, Malmoe
--
--	FILE NAME	SATTMATE_EXCEPTION_SPEC.ADA
--
--	RESPONSIBLE	XET
--
--	DESCRIPTION	This package contains routines to produce crashdumps
--				This package could be used if You would like to:
--
--			1.  Create a crashdump on compilers that normaly does'nt provide
--				crashdump information (e.g. ObjectAda on NT)
--			2.  It makes it possible to add traceback-information in log-files
--			3.  It makes it possible to keep the program alive, i.e. produce
--				crashdump e.g. from CONSTRAINT_ERROR, but continue to execute
--------------------------------------------------------------------------------
--
--	VERSION		8.1
--	AUTHOR		JEP 980331
--	VERIFIED BY
--	DESCRIPTION	Original version
--
--------------------------------------------------------------------------------
--	VERSION		9.3
--	AUTHOR		Bnl 2003-10-01
--	VERIFIED BY
--	DESCRIPTION	Making this work on both gnat and object_ada
--
--------------------------------------------------------------------------------
with Ada.Exceptions;
package Sattmate_Exception is

--------------------------------------------------------------------------------
--
-- This procedure prints tracebackinfo using text_io.
-- If ABORT_PROGRAM is TRUE, an exception PROGRAM_ABORTED will be raised
--
  procedure Tracebackinfo(E : Ada.Exceptions.Exception_Occurrence) ;

--  procedure TRACEBACKINFO( ABORT_PROGRAM : in BOOLEAN:= FALSE);

--------------------------------------------------------------------------------


end Sattmate_Exception;
