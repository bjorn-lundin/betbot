--------------------------------------------------------------------------------
--
--	COPYRIGHT	Alfa Laval Automation AB, Malmoe
--
--	FILE NAME	95_SATTMATE_EXCEPTION_BODY_WIN32.ADA
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
--			4.  Email the crashdump-info to e.g. customer-support
--------------------------------------------------------------------------------
--
--	VERSION		8.1
--	AUTHOR		JEP 980331
--	VERIFIED BY
--	DESCRIPTION	Original version for ObjectAda 7.1.1 on Nt
--
--------------------------------------------------------------------------------
--	VERSION		9.3
--	AUTHOR		BNL 2003-10-01
--	VERIFIED BY
--	DESCRIPTION	Adopted to Gnat
--
--------------------------------------------------------------------------------
--9.4.1-8765 2006-01-11 BNL
-- On Windows, we get arelible stacktrace with
-- Gnat.Traceback.Symbolic.Symbolic_Traceback(E)
-- But on Aix, we use GDB (the debugger) via an external tool, stb,
-- to get _RELIABLE_ stacktraces. We print usage information instead.
--------------------------------------------------------------------------------
--9.6-12322 2007-08-31 BNL
-- We now get symbolic stacktraces on Aix too (with gnat 6.1.0w)
-- All platform separion code removed
--------------------------------------------------------------------------------
--9.8-19244 2010-04-20 SNE
-- Because of unpredicted behaviour when exception was raised in tasks, construction
-- of the exception message is altered. Instead a spawn command using addr2line
-- is executed in a subprocess, where the catched output is written on the standard output.
--------------------------------------------------------------------------------

with Ada.Strings;                  use Ada.Strings;             --9.8-19244
with Ada.Strings.Unbounded;        use Ada.Strings.Unbounded;   --9.8-19244
--with Ada.Strings.Fixed;            use Ada.Strings.Fixed;       --9.8-19244
--with Ada.Characters.Handling;      use Ada.Characters.Handling; --9.8-19244

with Text_Io;  use Text_Io;
--9.8-19244 with Gnat.Traceback.Symbolic;
with Sattmate_Calendar;
--with System_Services;   --9.8-19244
with Ada.Command_Line;  --9.8-19244


package body Sattmate_Exception is

  ------------------------------------------------------------------------------
  --9.8-19244
  function Pure_Hexdump(Input : in String) return String is
    Found_Hex        : Boolean := False;
    Start_Of_Hex     : Integer := 0;
  begin
    if Input'Length > 0 then
      for i in Input'first +1 .. Input'last  loop
        if Input(i-1..i) = "0x" then
          Found_Hex := True;
          Start_Of_Hex := i-1;
          exit;
        end if;
      end loop;

      if Found_Hex then
        return Input(Start_Of_Hex .. Input'Last);
      end if;
    end if;
    return Input;
  exception
    when others => return Input;
  end Pure_Hexdump;

  ------------------------------------------------------------------------------

  procedure Tracebackinfo(E : Ada.Exceptions.Exception_Occurrence) is
    Last_Exception_Name     : constant String := Ada.Exceptions.Exception_Name(E);
    Last_Exception_Messsage : constant String := Ada.Exceptions.Exception_Message(E);
    Last_Exception_Info     : constant String := Ada.Exceptions.Exception_Information(E);
 --   Program_Aborted         : exception;
    Now : constant String:= Sattmate_Calendar. String_Date_And_Time(Milliseconds => True);
    Command     : Unbounded_String := Null_Unbounded_String; --9.8-19244
--    Result_Text : Unbounded_String := Null_Unbounded_String; --9.8-19244
--    function Add_Exe_Text (Str : string) return String is
--    begin
--      case System_Services.Operating_System is
--        when System_Services.Win32 => if Ada.Strings.Fixed.Count(Ada.Characters.Handling.To_Lower(Str), ".exe") > 0 then
--                                        return Str;
--                                      else
--                                        return Str&".exe";
--                                      end if;
--        when others                => return Str;
--      end case;
--    end Add_Exe_Text;

  begin
    New_Line;
    Put_Line("..... SattMate TRACEBACKINFO at: " & Now & " .....");
    New_Line;
    Put_Line("Program terminated by an exception propagated out of the main subprogram.");
    Put("Exception raised : ");  Put_Line(Last_Exception_Name);
    New_Line;
    Put_Line("Message : " & Last_Exception_Messsage);
    Put_Line(Last_Exception_Info);
    New_Line;
    Put_Line("...................................................");
    New_Line;
    Append(Command, "addr2line" &
                    " --functions --basenames --exe=" &
                    Ada.Command_Line.Command_Name & " " &
                    Pure_Hexdump(Last_Exception_Info));               --9.8-19244
    Put_Line("Command => " & To_String(Command));                   --9.8-19244
--    System_Services.Execute_Command(To_String(Command), Result_Text); --9.8-19244
--    Put_Line("Hex      Subprogram name and file");
--    Put_Line("-----    ------------------------");
--    Put_Line(To_String(Result_Text));                                 --9.8-19244
    --9.8-19244Put_Line(Gnat.Traceback.Symbolic.Symbolic_Traceback(E));
--    Put_Line("End of propagation.");
    New_Line;
    Put_Line("Command => " & To_String(Command));                   --9.8-19244

  end Tracebackinfo;
  ------------------------------------------------------------------------------


end Sattmate_Exception;
