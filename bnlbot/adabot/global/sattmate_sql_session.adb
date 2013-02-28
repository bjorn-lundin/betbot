--------------------------------------------------------------------------------
--
--	COPYRIGHT	SattControl AB, Malm|
--
--	FILE NAME	SATTMATE_SQL_SESSION_BODY.ADA
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
-- 9.8-17252 2009-08-19 BNL
-- Totally rewritten new interface or postgresql
--------------------------------------------------------------------------------

with Sql;
with System_Services;  -- v9.2-0130

package body Sattmate_Sql_Session is

  procedure Open is
    User   : constant string := System_Services.Get_Symbol("SATTMATE_DATABASE_USER");    
    Passwd : constant string := System_Services.Get_Symbol("SATTMATE_DATABASE_PASSWORD");  
    Db     : constant string := System_Services.Get_Symbol("SATTMATE_DATABASE_NAME");  
    Host   : constant string := System_Services.Get_Symbol("SATTMATE_DATABASE_HOST");  
  begin
    Sql.Connect(Host     => Host,
                DB_Name  => Db,
                Login    => User,
                Password => Passwd);   
  end Open;


  procedure Close is
  begin
    Sql.Close_Session;
  end Close;

end Sattmate_Sql_Session;

