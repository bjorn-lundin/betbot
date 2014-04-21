with Ada.Environment_Variables;
with Logging; use Logging;
with General_Routines; use General_Routines;
--with Sattmate_Types;
with Interfaces.C.Strings;
with Sattmate_Calendar;


package body Lock is
  Me : constant String := "Lock.";  

  package EV renames Ada.Environment_Variables;
  
  
  
  ------------------------------------------------------------------
  procedure Take(A_Lock : in out Lock_Type; Name : in String) is
    L      : Lockstruct;
    result : int;
    use Interfaces.C.Strings;
  begin
  
    A_Lock.Name := To_Unbounded_String(Ev.Value("BOT_HOME") & "/locks/" & Name);
    Log(Me & "Take", "Take lock: '"  & To_String(A_Lock.Name) & "'");
    declare
      C_Name : Chars_Ptr := New_String (To_String(A_Lock.Name));
    begin
      A_Lock.Fd := Posix.Open(C_name, O_RDWR + O_CREAT , 8#644#); --O_NONBLOCK is not needed
      Free(C_Name);
    end;    
      
     L.L_Type := F_WRLCK;
     L.L_Whence := 0;
     L.L_Start := 0;
     L.L_Len := 0;
     Fcntl( result, A_Lock.Fd, F_SETLK, L );
     A_Lock.Currently_Holding_Lock := True;
     if result = -1 then
        Log(Me & "Take", "Take lock failed, Errno =" & Errno'Img);
        A_Lock.Currently_Holding_Lock := False;
        raise Lock_Error with "Errno =" & Errno'Img ;
     end if;
  -- file is now locked
    --put pid in file  
    declare
      use Interfaces.C;
      use Sattmate_Calendar;
      Str : String := Trim(Posix.Getpid'img & "|" & 
                      Sattmate_Calendar.String_Date_Time_ISO(Sattmate_Calendar.Clock, " ","") & "|" &  -- now
                      Sattmate_Calendar.String_Date_Time_ISO(Sattmate_Calendar.Clock + (0,0,10,0,0), " ","") & "|" & --expire lock
                      Ascii.LF);
      C_Pid_Str : Chars_Ptr := New_String (Str);
      Size      : Posix.Size_t;
    begin
      Size := Posix.Write(A_Lock.Fd, C_Pid_Str, Str'Length);
      Free(C_Pid_Str);
      if integer(size) = -1 then
        Log(Me & "Take", "write pid Errno =" & Errno'Img);
      end if;
      if integer(size) /= Str'length then
        Log(Me & "Take", "size/str'length =" & size'Img & "/" & Str'Length'Img);
      end if;
    end;    
    Log(Me & "Take", "Lock taken");
  exception    
    when others => raise Lock_Error;    
  end Take;
  ------------------------------------------------------------------
  
  procedure Finalize(A_Lock : in out Lock_Type) is
    L      : Lockstruct;
    Result : int;
  begin
--      Log(Me & "Finalize", "Remove loc");    
      -- unlock file
    if A_Lock.Currently_Holding_Lock then
      L.L_Start := 0;
      L.L_Len := 0;
      L.L_Type := F_UNLCK;
      L.L_Whence := 0;
      fcntl( result, A_Lock.Fd, F_SETLKW, L );
      if result = -1 then
        Log(Me & "Finalize", "fcntl failed in unlock/Finalize, Errno =" & Errno'Img);
      end if;      
--      Log(Me & "Finalize", "Lock removed");
    end if; 
   end Finalize;
  ------------------------------------------------------------------
  
end Lock;
