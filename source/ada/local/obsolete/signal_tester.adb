
with Text_io; use Text_io;
with  Ada.Interrupts ; use Ada.Interrupts;
with  Ada.Interrupts.Names; use  Ada.Interrupts.Names;
with Gnat.Command_Line; use Gnat.Command_Line;
--with Gnat.Strings;
with Posix;


procedure Signal_Tester is

  Ba_Daemon    : aliased Boolean := False;
  Config : Command_Line_Configuration;
  Count : Integer := 0;
  
  package tmp is
    protected type sh is
      procedure handle_SIGPWR;
      pragma Unreserve_All_Interrupts;
      pragma Attach_Handler (Handle_SIGPWR, SIGPWR);
    end sh;
  end tmp;

  package body tmp is  
    protected body sh is
      procedure handle_SIGPWR is
      begin
        Count := Count +1;
      end handle_SIGPWR;
    end sh;
  end tmp;  
begin
    Define_Switch
       (Config,
        Ba_Daemon'access,
        "-d",
        Long_Switch => "--daemon",
        Help        => "become daemon at startup");
    Getopt (Config);  -- process the command line
  
    if Ba_Daemon then
      Posix.Daemonize;
    end if;
    
    --set up signal handling
--    if not Is_Reserved(sigpwr) then
--      put_line("sigpwr not reserved");
--      detach_handler(sigpwr);
--      put_line("detached sigpwr");
--      Attach_Handler( a.handle'access, sigpwr);
--      put_line("attached sigpwr");
--    end if;  
      
    declare
      h : Tmp.sh;
    begin
      loop
        put_line("received signal :" & count'Img & " times");
        exit when count > 5;
        delay 2.0;  
      end loop;
    end;    

    
  end Signal_Tester;
