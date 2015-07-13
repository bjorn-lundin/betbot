with Gnoga.Gui.Base;
with Gnoga.Gui.View;
with Gnoga.Gui.Element.Common;
with Gnoga.Gui.Element.Table;
with Gnoga.Gui.Element.Form;
package Bot_Gui.View is
   
   type Double_Buffer_Type is (Buffer_One, Buffer_Two);
   type Table_Array_Type is array (Double_Buffer_Type'range) of Gnoga.Gui.Element.Table.Table_Type;
   type Div_Array_Type   is array (Double_Buffer_Type'range) of Gnoga.Gui.Element.Common.DIV_Type;

   type Default_View_Type is new Gnoga.Gui.View.View_Type with record
      Login_Form : Gnoga.Gui.Element.Form.Form_Type;
      User       : Gnoga.Gui.Element.Form.Text_Type;
      Password   : Gnoga.Gui.Element.Form.Password_Type;
      Do_Login   : Gnoga.Gui.Element.Common.Button_Type;
     -- Do_Login   : Gnoga.Gui.Element.Form.Submit_Button_Type;
      User_Is_Validated_OK : Boolean := FAlse;
      
      Data_Holder  : Gnoga.Gui.Element.Common.DIV_Type;
      
      Table_Holder : Div_Array_Type;
   
      Daily_Table   : Table_Array_Type;
      Weekly_Table  : Table_Array_Type;
      
      Label_Text    : Gnoga.Gui.Element.Common.DIV_Type;

      Image_Holder  : Gnoga.Gui.Element.Common.DIV_Type;
      Lapsed_Image_42   : Gnoga.Gui.Element.Common.IMG_Type;
      Matched_Image_42  : Gnoga.Gui.Element.Common.IMG_Type;
      Lapsed_Image_182  : Gnoga.Gui.Element.Common.IMG_Type;
      Matched_Image_182 : Gnoga.Gui.Element.Common.IMG_Type;

      Click_Button  : Gnoga.Gui.Element.Common.Button_Type;
      Run_Query     : Gnoga.Gui.Element.Common.Button_Type;
      Quit_Task     : Boolean := False;
   end record;

   type Default_View_Access is access all Default_View_Type;
   type Pointer_to_Default_View_Class is access all Default_View_Type'Class;

   overriding
   procedure Create
     (View    : in out Default_View_Type;
      Parent  : in out Gnoga.Gui.Base.Base_Type'Class;
      ID      : in     String  := "");


end Bot_Gui.View;
