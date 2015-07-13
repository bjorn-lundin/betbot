with Gnoga.Gui.Window;
with Gnoga.Application.Multi_Connect;
with Gnoga.Gui.Base;

package Bot_Gui.Controller is
   procedure Default
     (Main_Window : in out Gnoga.Gui.Window.Window_Type'Class;
      Connection  : access Gnoga.Application.Multi_Connect.Connection_Holder_Type);
        
--   procedure On_Login (Object : in out Gnoga.Gui.Base.Base_Type'Class) ;
   procedure On_Submit (Object : in out Gnoga.Gui.Base.Base_Type'Class) ;
        
end Bot_Gui.Controller;
