--------------------------------------------------------------------------------
with Ada.Directories;
with Text_io;
package body Posix1 is


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
    Text_Io.Put_Line("The_Pid: " & The_Pid'Img);
    
    if The_Pid < 0 then --fork failed
      Text_Io.Put_Line("fork failed: " & The_Pid'Img);
      raise Fork_Failed with "first fork";
    elsif The_Pid > 0 then -- The parent
      Text_Io.Put_Line("will exit: " & The_Pid'Img);
      Do_Exit(0); -- terminate parent
      Text_Io.Put_Line("did exit: " & The_Pid'Img);
    end if;
    -- only the child left here
    -- lets fork again
    Dummy1 := Setsid;
    if Dummy1 < 0 then
      Perror("Posix1.Daemonize.Setsid");
    end if;
    Text_Io.Put_Line("Setsid: " & The_Pid'Img & Dummy1'Img);
    
--    The_Pid := Fork;
--    Text_Io.Put_Line("The_Pid: " & The_Pid'Img);
--    
--    if The_Pid < 0 then --fork failed
--      Text_Io.Put_Line("fork failed: " & The_Pid'Img);
--      raise Fork_Failed with "second fork";
--    elsif The_Pid > 0 then -- The parent
--      Text_Io.Put_Line("will exit: " & The_Pid'Img);
--      Do_Exit(0); -- terminate parent again
--      Text_Io.Put_Line("did exit: " & The_Pid'Img);
--    end if;
    -- only the grandchild left here
    

    Ada.Directories.Set_Directory("/");
    Text_Io.Put_Line("Set_Directory to '/'");
    
    Dummy2 := Umask(0);
    if Dummy2 < 0 then
      Perror("Posix1.Daemonize.Umask");
    end if;
    Text_Io.Put_Line("Umask: " & The_Pid'Img & Dummy2'Img);
  end Daemonize;

end Posix1;


