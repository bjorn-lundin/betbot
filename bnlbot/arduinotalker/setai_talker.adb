
with GNAT.Serial_Communications;
with text_io;

procedure serial_talker is

 GNAT.Serial_Communications.Set (Port => "/dev/ttyUSB0",
                                 Rate => GNAT.Serial_Communications.B9600,
                                 Bits => GNAT.Serial_Communications.CS8,
                                 Stop_Bits => GNAT.Serial_Communications.one,
                                 Parity => GNAT.Serial_Communications.None);


end serial_talker;

