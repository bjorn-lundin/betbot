package body Bot_Gui.View is

   ------------
   -- Create --
   ------------

   overriding
   procedure Create
     (View    : in out Default_View_Type;
      Parent  : in out Gnoga.Gui.Base.Base_Type'Class;
      ID      : in     String  := "")
   is
   begin
      Gnoga.Gui.View.View_Type (View).Create (Parent, ID);
      View.Click_Button.Create (View, "stop db task");
      View.Connect_Db.Create (View, "Connect Db");
      View.Disconnect_DB.Create (View, "Disconnect db");
      View.Run_Query.Create (View, "Run query");
      View.Result_Table.Create (View);
      View.Label_Text.Create (View);
      
      View.Label_Text.Overflow_X(Gnoga.Gui.Element.Auto);
   end Create;
   
end Bot_Gui.View;
