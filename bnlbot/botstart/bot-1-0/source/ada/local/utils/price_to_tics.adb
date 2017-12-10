
with Stacktrace;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Tics;
with Text_Io;
with Types; use Types;

procedure Price_To_Tics is
  Cmd_Line    : Command_Line_Configuration;
  Sa_Value    : aliased Gnat.Strings.String_Access;
  Sa_To_Price : aliased Boolean := False;
begin

  Define_Switch
    (Cmd_Line,
     Sa_value'Access,
     Long_Switch => "--value=",
     Help        => "price to be converted to tics");

  Define_Switch
    (Cmd_Line,
     Sa_To_Price'Access,
     Long_Switch => "--toprice",
     Help        => "tics to be converted to price");

  Getopt (Cmd_Line);  -- process the command line

  if Sa_To_Price then
    Text_Io.Put_Line(Tics.Get_Tic_Price(I => Integer'Value(Sa_Value.all))'Img);
  else
    Text_Io.Put_Line(Tics.Get_Tic_Index(Price => Fixed_Type'Value(Sa_Value.all))'Img);
  end if;

exception
  when E : others =>
    Stacktrace.Tracebackinfo (E);
end Price_To_Tics;
