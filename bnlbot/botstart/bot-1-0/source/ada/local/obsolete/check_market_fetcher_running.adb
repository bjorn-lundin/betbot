
with Lock;
with Ada.Command_Line;      use Ada.Command_Line;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

procedure Check_Bot_Running is
  My_Lock : Lock.Lock_Type;
  Sa_Par_Bot : aliased Gnat.Strings.String_Access;
  Config : Command_Line_Configuration;
begin
  Set_Exit_Status(Success);
  Define_Switch
    (Config,
     Sa_Par_Bot'access,
     "-b:",
     Long_Switch => "--botname=",
     Help        => "what bot to check");
   Getopt (Config);  -- process the command line
  
  if Sa_Par_Bot.all = "" then
    Display_Help (Config);
    return;
  end if;
  
  My_Lock.Take(Sa_Par_Bot.all);
exception
  when Lock.Lock_Error => 
   Set_Exit_Status(Failure); 

end Check_Bot_Running;






