--------------------------------------------------------------------------------
--with Ada.Directories;
with GNATCOLL.Traces;
pragma Elaborate_All(GNATCOLL.Traces);
 
package body Posix1 is

  Me : constant GNATCOLL.Traces.Trace_Handle :=  GNATCOLL.Traces.Create ("Posix1");  

  procedure Perror (Msg : String ) is
    subtype Msg_String is String(1 .. Msg'length +1);
    procedure cPerror( Message : access Msg_String);
    pragma Import( C, Cperror, "perror" );
    My_Msg : aliased Msg_String := Msg & Ascii.NUL;
  begin
    cPerror(My_Msg'access);
  end Perror;


  procedure Daemonize is
    The_Pid : Pid_T ;
    Dummy1 : Pid_T;
    pragma Warnings(Off, Dummy1);
    Dummy2 : Mode_T;
    pragma Warnings(Off, Dummy2);
  begin 
    The_Pid := Fork;
    GNATCOLL.Traces.Trace (Me, "The_Pid: " & The_Pid'Img);
    
    if The_Pid < 0 then --fork failed
      GNATCOLL.Traces.Trace (Me, "fork failed: " & The_Pid'Img);
      raise Fork_Failed with "first fork";
    elsif The_Pid > 0 then -- The parent
      Do_Exit(0); -- terminate parent
    end if;
    -- only the child left here
    -- lets fork again
    Dummy1 := Setsid;
    if Dummy1 < 0 then
      Perror("Posix1.Daemonize.Setsid");
    end if;
    GNATCOLL.Traces.Trace (Me, "Setsid: " & The_Pid'Img & Dummy1'Img);

--    Ada.Directories.Set_Directory("/");
    
    Dummy2 := Umask(0);
    GNATCOLL.Traces.Trace (Me, "Umask: " & The_Pid'Img & Dummy2'Img);
  end Daemonize;

end Posix1;


