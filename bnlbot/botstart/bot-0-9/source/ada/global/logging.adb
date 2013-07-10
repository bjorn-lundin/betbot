
with Ada.Directories;
with Text_Io;
with Sattmate_Calendar;

package body Logging is

   Quiet : Boolean := False; 
   Global_Indent : Integer := 0;
   
   File : Text_Io.File_Type;

   ---------------------------------------------
   procedure Change_Indent(How_Much : Integer) is
   begin
    Global_Indent := Global_Indent + How_Much;
   end Change_Indent;
   ---------------------------------------------

   function Indent return String is
    S : String (1 .. Global_Indent) := (others => ' ');
   begin
    return S;
   end Indent;
   
   ---------------------------------------------
   
   
   procedure Set_Quiet (Q: Boolean) is
   begin
     Quiet := Q;
   end Set_Quiet;
   ---------------------------------------------
   procedure Log (Who, What : in String) is
   begin
     Log(Who & " : " & What);
   end Log;
   -------------------------------------------
   procedure Log (What : in String) is
     use Sattmate_Calendar;
   begin
      if Quiet then
        return;
      end if;
      if Text_Io.Is_Open(File) then
        Text_Io.Put_Line (File, String_Date_Time_ISO (Clock, " " , "") & " " & What);
        Text_Io.Flush (File);
      else
        Text_Io.Put_Line (Text_Io.Standard_Error, String_Date_Time_ISO (Clock, " " , "") & " " & What);
      end if;  
   end Log;
   ---------------------------------------------
   procedure Print (What : in String) is
   begin
      Text_Io.Put_Line (What);
   end Print;

   
   procedure Open(Name : String) is
   begin
     if Ada.Directories.Exists(Name) then
       Text_Io.Open(File, Text_Io.Append_File, Name);
     else
       Text_Io.Create(File, Text_Io.Out_File, Name);
     end if;     
   end Open;
   
   
   procedure Close is 
   begin
     Text_Io.Close(File);   
   end Close;
   
   
end Logging;
