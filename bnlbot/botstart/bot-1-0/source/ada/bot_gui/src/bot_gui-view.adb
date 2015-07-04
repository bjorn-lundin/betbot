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
      View.Overflow_Y(Gnoga.Gui.Element.Auto);

      View.Click_Button.Create (View, "stop db task");
      View.Run_Query.Create (View, "Run query");
      View.Horizontal_Rule;
      View.Daily_Table.Create (View);
      View.Horizontal_Rule;
      View.Weekly_Table.Create (View);
      View.Horizontal_Rule;
      View.Image_Holder.Create (View);
      View.Matched_Image.Create(View.Image_Holder,"https://dl.dropboxusercontent.com/u/26175828/profit_vs_matched.png");
      View.Lapsed_Image.Create(View.Image_Holder,"https://dl.dropboxusercontent.com/u/26175828/settled_vs_lapsed.png");
      View.Horizontal_Rule;
      View.Label_Text.Create (View);
   end Create;
   
end Bot_Gui.View;
