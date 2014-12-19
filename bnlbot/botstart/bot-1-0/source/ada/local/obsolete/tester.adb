
with Stacktrace;
with Gnat.Command_Line; use Gnat.Command_Line;
with Calendar2; use Calendar2;
with Gnat.Strings;
with Lock ;

with text_io;

procedure Tester is
--  package EV renames Ada.Environment_Variables;
  Me : constant String := "Test.";  
  My_Lock  : Lock.Lock_Type;
  Sa_Par_Delay_Time : aliased Gnat.Strings.String_Access;
  Sa_Par_Keep_Time  : aliased Gnat.Strings.String_Access;
  Config : Command_Line_Configuration;
  Delay_Time, Keep_Time : Duration := 0.0;
  
  
  procedure Trace(who,what : string) is
  begin
    Text_io.Put_Line(Who & " - " & What);
  end Trace;  
  
begin

 
  for i in 1 .. 100 loop
      Trace("none", I'Img);
    if i mod 10 = 0 then
      Trace("mod", I'Img);
    end if;
    if i rem 10 = 0 then
      Trace("rem", I'Img);
    end if;
    
  end loop;
 
 


  Define_Switch
     (Config,
      Sa_Par_Delay_Time'access,
      "-d:",
      Long_Switch => "--delay=",
      Help        => "Time to delay before get lock");

  Define_Switch
     (Config,
      Sa_Par_Keep_Time'access,
      "-k:",
      Long_Switch => "--keep=",
      Help        => "Time to keep taken lock");

  Getopt (Config);  -- process the command line
      
  Delay_Time := Duration'Value(Sa_Par_Delay_Time.all);
  Keep_Time  := Duration'Value(Sa_Par_Keep_Time.all);
      
  Trace(Me, "delay before take lock " & Integer(Delay_Time)'Img);
  delay Delay_Time;    
  
  My_Lock.Take("tester");

  Trace(Me, "delay before release lock " & Integer(Keep_Time)'Img);
  delay Keep_Time;    
           
exception
  when Lock.Lock_Error => null;
  Trace(Me, "Lock_Error captured" );
  when E: others =>
    Stacktrace. Tracebackinfo(E);
end Tester;

