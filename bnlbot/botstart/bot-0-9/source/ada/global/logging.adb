

with Text_Io;
with Sattmate_Calendar;

package body Logging is

   Quiet : Boolean := False;
 
   Global_Indent : Integer := 0;

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

   procedure Log (What : in String) is
   begin
      if Quiet then
        return;
      end if;
      Text_Io.Put_Line (Text_Io.Standard_Error, Sattmate_Calendar.String_Date_And_Time(Milliseconds => True) & " " & What);
   end Log;
   ---------------------------------------------
   procedure Print (What : in String) is
   begin
      Text_Io.Put_Line (What);
   end Print;

end Logging;
