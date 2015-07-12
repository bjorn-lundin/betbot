package body Bot_Gui.View is

   ------------
   -- Create --
   ------------

   overriding
   procedure Create
     (View    : in out Default_View_Type;
      Parent  : in out Gnoga.Gui.Base.Base_Type'Class;
      ID      : in     String  := "") is
   begin
      Gnoga.Gui.View.View_Type (View).Create (Parent, ID);
      View.Overflow_Y(Gnoga.Gui.Element.Auto);

      View.Click_Button.Create (View, "stop db task");
      View.Run_Query.Create (View, "Run query");
      View.Horizontal_Rule;
      
      View.Table_Holder(Buffer_One).Create(View);
      View.Daily_Table(Buffer_One).Create (View.Table_Holder(Buffer_One));
      View.Horizontal_Rule;
      View.Weekly_Table(Buffer_One).Create (View.Table_Holder(Buffer_One));
      
     -- View.Table_Holder(Buffer_Two).Create(View);
     -- View.Table_Holder(Buffer_Two).Visible(False);
     --  
     -- View.Daily_Table(Buffer_Two).Create ( View.Table_Holder(Buffer_Two));
     -- View.Weekly_Table(Buffer_Two).Create (View.Table_Holder(Buffer_Two));
      
      
      View.Horizontal_Rule;
      View.Image_Holder.Create (View);
      View.Matched_Image.Create(View.Image_Holder,"img/profit_vs_matched_182.png");
      View.Lapsed_Image.Create(View.Image_Holder,"img/settled_vs_lapsed_182.png");
      View.Horizontal_Rule;
      View.Label_Text.Create (View);
   end Create;
   
end Bot_Gui.View;
