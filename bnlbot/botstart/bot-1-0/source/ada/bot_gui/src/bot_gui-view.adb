with Logging ; use Logging;
with Ada.Exceptions;
with Ada.Command_Line;
with Stacktrace;

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
      View.Avg_Price_42.Create(View.Image_Holder,"img/avg_price_42.png");
      View.Matched_Image_182.Create(View.Image_Holder,"img/profit_vs_matched_182.png");
      View.Lapsed_Image_182.Create(View.Image_Holder,"img/settled_vs_lapsed_182.png");
      View.Avg_Price_182.Create(View.Image_Holder,"img/avg_price_182.png");
      View.Horizontal_Rule;
      View.Label_Text.Create (View);
      Log ("stop Bot_Gui.View.Create");
      View.Updater:= new Updater_Task_Type;
   end Create;


   task body Updater_Task_Type is
     L_View : Default_View_Access;
   begin

     accept Set_Parent(Object : in out Gnoga.Gui.Base.Base_Type'Class) do
       L_View := Default_View_Access (Object.Parent);
     end Set_Parent;

     -- hang here until started
     accept Start do
       null;
     end Start;

     loop
       L_View.Run_Query.Fire_On_Click;
       delay 1.0;
     end loop;
   exception
        when E: others =>
          declare
            Last_Exception_Name     : constant String  := Ada.Exceptions.Exception_Name(E);
            Last_Exception_Messsage : constant String  := Ada.Exceptions.Exception_Message(E);
            Last_Exception_Info     : constant String  := Ada.Exceptions.Exception_Information(E);
          begin
            Log("task " & Last_Exception_Name);
            Log("Message : " & Last_Exception_Messsage);
            Log(Last_Exception_Info);
            Log("addr2line" & " --functions --basenames --exe=" &
                 Ada.Command_Line.Command_Name & " " & Stacktrace.Pure_Hexdump(Last_Exception_Info));
          end ;

   end Updater_Task_Type;


end Bot_Gui.View;
