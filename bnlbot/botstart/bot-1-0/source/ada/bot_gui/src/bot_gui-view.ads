with Gnoga.Gui.Base;
with Gnoga.Gui.View;
with Gnoga.Gui.Element.Common;
with Gnoga.Gui.Element.Table;

package Bot_Gui.View is
   
   type Default_View_Type is new Gnoga.Gui.View.View_Type with record
      --Result_Table  : Gnoga.Gui.Element.Table.Table_Type;      
      Daily_Table  : Gnoga.Gui.Element.Table.Table_Type;      
      Weekly_Table  : Gnoga.Gui.Element.Table.Table_Type;      
      Label_Text    : Gnoga.Gui.Element.Common.DIV_Type; --Gnoga.Gui.View.View_Type;
      
      Image_Holder : Gnoga.Gui.Element.Common.DIV_Type; --Gnoga.Gui.View.View_Type;
      Lapsed_Image  : Gnoga.Gui.Element.Common.IMG_Type;
      Matched_Image : Gnoga.Gui.Element.Common.IMG_Type;
      
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
