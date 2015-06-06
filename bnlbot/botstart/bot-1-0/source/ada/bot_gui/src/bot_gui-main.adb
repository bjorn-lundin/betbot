with Ada.Exceptions;

with Gnoga.Application.Multi_Connect;

with Bot_Gui.Controller;

procedure Bot_Gui.Main is
begin
   Gnoga.Application.Title ("Bot Gui");
   Gnoga.Application.HTML_On_Close
     ("<b>Connection to Application has been terminated</b>");
   
   Gnoga.Application.Multi_Connect.Initialize;
   
   Gnoga.Application.Multi_Connect.Message_Loop;
exception
   when E : others =>
      Gnoga.Log (Ada.Exceptions.Exception_Name (E) & " - " &
                   Ada.Exceptions.Exception_Message (E));
end Bot_Gui.Main;
