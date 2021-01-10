with Ada.Command_Line;
with Ada.Text_IO;
with Ada.Directories;
with Inotify.Recursive;
with ADA.IO_EXCEPTIONS;

procedure Monitor2 is
   package AD renames Ada.Directories;
   Instance : Inotify.Recursive.Recursive_Instance;

   procedure Handle_Event
     (Subject      : Inotify.Watch;
      Event        : Inotify.Event_Kind;
      Is_Directory : Boolean;
      Name         : String)
   is
      Kind : constant String := (if Is_Directory then "directory" else "file");
      use type Inotify.Event_Kind;
   begin
      if event = Inotify.CLOSED_WRITE then
        Ada.Text_IO.Put_Line (Event'Img & " " & Instance.Name (Subject) & " ->  [" & Kind & "] '" & Name & "'");
        if name = "/dev/shm/bot/do_rename" then
          begin
            Ad.Rename(name & ".notthere" ,name & ".done");
          exception
            when ADA.IO_EXCEPTIONS.USE_ERROR =>
              Ada.Text_IO.Put_Line ("cannot rename '" & name & "' target exists already");
            when ADA.IO_EXCEPTIONS.NAME_ERROR =>
              Ada.Text_IO.Put_Line ("cannot rename '" & name & "' source does not exist");
          end;
        end if;
      end if;
   end Handle_Event;
begin
   Instance.Add_Watch
     (Path => Ada.Command_Line.Argument (1),
      Mask => (Closed_Write => True, others => False));
   Instance.Process_Events (Handle_Event'Access);
end Monitor2;

