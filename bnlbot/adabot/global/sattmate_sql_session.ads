--------------------------------------------------------------------------------
--
--	COPYRIGHT	SattControl AB, Malm|
--
--	FILE NAME	SATTMATE_SQL_SESSION_SPEC.ADA
--
--	RESPONSIBLE	Henrik Dannberg
--
--	DESCRIPTION	This package is used by all processes in a SattMate 
--			system that interact with a database handler via the
--			SQL package. The body of procedure OPEN and START
--			are project specific and should open/close a SQL 
--			session to the database handler currently used.
--
--------------------------------------------------------------------------------
--
--	VERSION		6.0
--	AUTHOR		Henrik Dannberg		14-apr-1994
--	VERIFIED BY	?
--	DESCRIPTION	Original version
--
--------------------------------------------------------------------------------

package SATTMATE_SQL_SESSION is

  procedure OPEN;

  procedure CLOSE;

end SATTMATE_SQL_SESSION;
