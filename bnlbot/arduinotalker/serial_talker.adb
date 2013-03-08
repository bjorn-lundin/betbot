
with GNAT.Serial_Communications;
with text_io;
with Ada.Streams;

procedure serial_talker is

  tty : GNAT.Serial_Communications.serial_port;

   ------------------------

  function String_To_Stream ( The_String : in String) return Ada.Streams.Stream_Element_Array is
      Return_Value : Ada.Streams.Stream_Element_Array(1..The_String'length);
  begin
--      Put (" Start of Data out  :- ");
      for count in 1..Ada.Streams.Stream_Element_Offset(The_String'Length) loop
         Return_Value(count) := character'pos(The_String(Integer(count)));
--         int_io.Put(Integer(Return_Value(count)));
      end loop;
--      Put (" End of Data out ");
--      Put_Line (The_String);
      Return Return_Value(1..The_String'Length);
   end String_To_Stream;
   ------------------------
begin

 text_io.put_line("before open");
-- GNAT.Serial_Communications.Open
--     (Port => tty,
--      Name => "/dev/ttyUSB0");

 tty.Open(Name => "/dev/ttyUSB0");



 text_io.put_line("before set");

-- GNAT.Serial_Communications.Set (Port => ,
--                                 Rate => GNAT.Serial_Communications.B9600,
--                                 Bits => GNAT.Serial_Communications.CS8,
--                                 Stop_Bits => GNAT.Serial_Communications.one,
--                                 Parity => GNAT.Serial_Communications.None,
--                                 Block  => True);


 tty.Set (Rate => GNAT.Serial_Communications.B9600,
          Bits => GNAT.Serial_Communications.CS8,
          Stop_Bits => GNAT.Serial_Communications.one,
          Parity => GNAT.Serial_Communications.None,
          Block  => True);


 text_io.put_line("before write 1");
 tty.write(Buffer => (String_To_Stream("1"))) ; -- clear lcd 
 text_io.put_line("before write 3");
 tty.write(Buffer => (String_To_Stream("3,0,0,Whatever"))) ; -- text 
 text_io.put_line("before write 2");
 tty.write(Buffer => (String_To_Stream("2,0,1,1500"))) ; -- nummer 
 text_io.put_line("before close");
 tty.close;
 
 

end serial_talker;

