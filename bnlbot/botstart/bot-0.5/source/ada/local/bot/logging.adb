

with Text_Io;
with Sattmate_Calendar;

package body Logging is

   Quiet : Boolean := False;

   procedure Set_Quiet (Q: Boolean) is
   begin
     Quiet := Q;
   end Set_Quiet;

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
