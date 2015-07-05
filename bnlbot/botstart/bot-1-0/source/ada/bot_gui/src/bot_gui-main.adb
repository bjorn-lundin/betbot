with Ada.Exceptions;

with Gnoga.Application.Multi_Connect;

pragma Warnings(Off);
with Bot_Gui.Controller;
pragma Warnings(On);

procedure Bot_Gui.Main is
begin
   Gnoga.Application.Title ("Bot Gui");
   Gnoga.Application.HTML_On_Close
     ("<b>Connection to Application has been terminated</b>");
   
   Gnoga.Application.Multi_Connect.Initialize(Port => 9080);
   
   Gnoga.Application.Multi_Connect.Message_Loop;
exception
   when E : others =>
      Gnoga.Log (Ada.Exceptions.Exception_Name (E) & " - " &
                   Ada.Exceptions.Exception_Message (E));
end Bot_Gui.Main;
