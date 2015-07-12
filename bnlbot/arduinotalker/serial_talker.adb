
with GNAT.Serial_Communications;
with Ada.Streams;
procedure Serial_Talker is
  TTY : GNAT.Serial_Communications.Serial_Port;
  ------------------------
  function String_To_Stream ( The_String : in String) return Ada.Streams.Stream_Element_Array is
    Return_Value : Ada.Streams.Stream_Element_Array(1..The_String'length);
  begin
    for Count in 1..Ada.Streams.Stream_Element_Offset(The_String'Length) loop
       Return_Value(Count) := Character'pos(The_String(Integer(Count)));
    end loop;
    return Return_Value(1..The_String'Length);
  end String_To_Stream;
  ------------------------
begin
 TTY.Open(Name => "/dev/ttyUSB0");
 TTY.Set (Rate      => GNAT.Serial_Communications.B9600,
          Bits      => GNAT.Serial_Communications.CS8,
          Stop_Bits => GNAT.Serial_Communications.One,
          Parity    => GNAT.Serial_Communications.None,
          Block     => True);
 TTY.Write(Buffer => (String_To_Stream("1"))); -- whatever you'd like
 TTY.Close;
end Serial_Talker;

