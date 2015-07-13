with Logging ; use Logging;
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
      Log ("start Bot_Gui.View.Create");
      Gnoga.Gui.View.View_Type (View).Create (Parent, ID);
      
      View.Login_Form.Create (Parent => View,
                              Method => Gnoga.Gui.Element.Form.Post);
      
      View.User.Create (Form  => View.Login_Form,
                        Size  => 40,
                        Name  => "User");
      View.User.Required;
                                 
      View.Password.Create (Form  => View.Login_Form,
                            Size  => 40,
                            Name  => "Password");
      View.Password.Required;
--      View.Do_Login.Create (Form => View.Login_Form, Value => "Login");
      View.Do_Login.Create (PArent => View, Content => "Login");
      
      
      View.Data_Holder.Create(Parent => View);
      --make the data invisible until logged id ok
      View.Data_Holder.Visible(False);
      
      View.Overflow_Y(Gnoga.Gui.Element.Auto);

      View.Horizontal_Rule;
      View.Run_Query.Create (View, "Run query");
      View.Horizontal_Rule;
      
      View.Table_Holder(Buffer_One).Create(View.Data_Holder);
      
      View.Daily_Table(Buffer_One).Create (View.Table_Holder(Buffer_One));
      View.Horizontal_Rule;
      View.Weekly_Table(Buffer_One).Create (View.Table_Holder(Buffer_One));
      
      View.Image_Holder.Create (View.Data_Holder);
      View.Matched_Image_42.Create(View.Image_Holder,"img/profit_vs_matched_42.png");
      View.Lapsed_Image_42.Create(View.Image_Holder,"img/settled_vs_lapsed_42.png");
      View.Matched_Image_182.Create(View.Image_Holder,"img/profit_vs_matched_182.png");
      View.Lapsed_Image_182.Create(View.Image_Holder,"img/settled_vs_lapsed_182.png");
      View.Horizontal_Rule;
      View.Label_Text.Create (View);
      Log ("stop Bot_Gui.View.Create");
      
   end Create;
   
end Bot_Gui.View;
