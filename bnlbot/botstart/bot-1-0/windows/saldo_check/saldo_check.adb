with GWindows.Windows.Main; use GWindows.Windows.Main;
with GWindows.Static_Controls; use GWindows.Static_Controls;
with GWindows.GStrings; use GWindows.GStrings;
--  with GWindows.Base;
with GWindows.Application;
--with Rpc;

procedure Saldo_Check is
   pragma Linker_Options ("-mwindows");
   Main_Window : Main_Window_Type;

   Saldo_Text_Label   : Label_Type;
   Exposed_Text_Label : Label_Type;
   
   Saldo_Value_Label   : Label_Type;
   Exposed_Value_Label : Label_Type;

begin
   Create (Main_Window, "Saldo Checker", Width => 200, Height => 100);
   Visible (Main_Window, True);
   Create (Saldo_Text_Label, Main_Window,     "Saldo:", 10, 10, 70, 25, Right);
   Create (Exposed_Text_Label, Main_Window, "Exposed:", 10, 30, 70, 25, Right);
   Create (Saldo_Value_Label, Main_Window,         "2", 90, 10, 40, 25, Center);
   Create (Exposed_Value_Label, Main_Window,       "3", 90, 30, 40, 25, Center);

   Text (Saldo_Value_Label, GWindows.GStrings.To_GString_From_String("asd"));
   Text (Exposed_Value_Label, GWindows.GStrings.To_GString_From_String("wsd"));

   
   
   
   GWindows.Application.Message_Loop;
end Saldo_Check;
