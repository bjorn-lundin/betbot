with GWindows;                    use GWindows;
with GWindows.Windows.Main; use GWindows.Windows.Main;
with GWindows.Static_Controls; --use GWindows.Static_Controls;
with GWindows.GStrings; use GWindows.GStrings;
with GWindows.Drawing_Objects;    use GWindows.Drawing_Objects;
with GWindows.Windows;            use GWindows.Windows;
with GWindows.Application;
with GWindows.System_Tray;        use GWindows.System_Tray;
with Rpc;
with Sattmate_Exception;
with Logging; use Logging;
with Table_Abalances;
with Sattmate_Calendar;
with Ada.Directories;
with Ada.Command_Line;

procedure Saldo_Check is
   pragma Linker_Options ("-mwindows");

   Last_Updated_Text_Label   : GWindows.Static_Controls.Label_Type;
   Saldo_Text_Label          : GWindows.Static_Controls.Label_Type;
   Exposed_Text_Label        : GWindows.Static_Controls.Label_Type;
   
   Last_Updated_Value_Label  : GWindows.Static_Controls.Label_Type;
   Saldo_Value_Label         : GWindows.Static_Controls.Label_Type;
   Exposed_Value_Label       : GWindows.Static_Controls.Label_Type;
   R : Rpc.Result_Type;
   Bal : Table_Abalances.Data_Type;

   Global_Stop : Boolean := False;


   Notify_Data : Notify_Icon_Data;
   I, Ib : Icon_Type;
   NL : constant GCharacter := GCharacter'Val (10); -- New Line   
   
   Main_Window : Main_Window_Type;
   
   
   pragma Warnings(Off, Global_Stop); -- surpress warning about not modified in loop
   -----------------------------------
   task Updater is
     entry Start;
   end Updater;   

   task body Updater is
     Cnt : Integer := 60;
   begin
    -------------------------- 
     accept Start do
       Log("Update_Task", "Task is starting");
       Rpc.Init(
         Username   => "bnlbnl",
         Password   => "Rebecca1Lundin",
         Product_Id => "82",
         Vendor_id  => "0",
         App_Key    => "q0XW4VGRNoHuaszo"
       );
       Rpc.Login;
     end Start;
    -------------------------- 
     loop
        exit when Global_Stop;
        Cnt := Cnt +1;
        if Cnt >= 60 then
          Rpc.Get_Balance(R, Bal) ;
          case R is
            when Rpc.OK => null;
            when others => 
              Rpc.Logout;
              Rpc.Login;
          end case;  
          Log(Table_Abalances.To_String(Bal));
          Saldo_Value_Label.Text (GWindows.GStrings.Image(Integer(Bal.Balance)));
          Exposed_Value_Label.Text(GWindows.GStrings.Image(Integer(Bal.Exposure)));
          Last_Updated_Value_Label.Text(GWindows.GStrings.To_GString_From_String(Sattmate_Calendar.String_Time));
          
          Notify_Data.Set_Tool_Tip ("    Balance:" & Integer(Bal.Balance)'Img & NL & 
                           "   Exposure:" & Integer(Bal.Exposure)'Img & NL & 
                           "Last update:" & Sattmate_Calendar.String_Time);
                           
          Notify_Data.Notify_Icon (Modify);
          Notify_Data.Set_Balloon ("");
                           
          Cnt := 0;
        end if;  
        delay 1.0;
     end loop;  
     Rpc.Logout;
   exception   
     when E: others => 
       Log("Update_Task", "Task is dying");
       Sattmate_Exception.Tracebackinfo (E);
       Rpc.Logout;
   end Updater;
   ------------------------
   
begin
   Logging.Open(Ada.Directories.Containing_Directory(Ada.Command_Line.Command_Name) & "\saldo_checker.log");
   Main_Window.Create("Saldo Checker", Width => 200, Height => 100);
--   Main_Window.Visible(True);
   Saldo_Text_Label.Create(Main_Window,              "Saldo: ",  5,  3, 90, 15, GWindows.Static_Controls.Right);
   Exposed_Text_Label.Create(Main_Window,          "Exposed: ",  5, 23, 90, 15, GWindows.Static_Controls.Right);
   Last_Updated_Text_Label.Create(Main_Window, "Last update: ",  5, 43, 90, 15, GWindows.Static_Controls.Right);
   Saldo_Value_Label.Create(Main_Window,                   "2", 90,  3, 90, 15, GWindows.Static_Controls.Right);
   Exposed_Value_Label.Create(Main_Window,                 "3", 90, 23, 90, 15, GWindows.Static_Controls.Right);
   Last_Updated_Value_Label.Create(Main_Window,            "4", 90, 43, 90, 15, GWindows.Static_Controls.Right);
   Log("Main", "Will start task");
   Updater.Start;
   Log("Main", "task is started");
   
   Notify_Data.Set_Window (Main_Window);
   I.Load_Stock_Icon (IDI_INFORMATION); -- Icon for the system tray
--   I.Extract_Icon_From_File(GWindows.GStrings.To_GString_From_String("shell32.dll"),80);
   
   Notify_Data.Set_Icon ( i, 1);
   Ib.Load_Stock_Icon (IDI_WINLOGO); -- Icon for the balloons
   Notify_Data.Set_Balloon_Icon (Ib); -- Set user icon for the balloons
   Notify_Data.Set_Tool_Tip ( "Björn's systray" & NL & "The coolest app ever ;-)" & NL & "and it works here too :-))");
   Notify_Data.Set_Balloon (
     "Hoover to get current saldo" & NL & "and exposure" & NL & "and last update",
     "Björn's Betbot",
     Warning_Icon   --   User_Icon
   );
   --  Now the fun part:
   Notify_Data.Notify_Icon (Add);   
   GWindows.Application.Message_Loop;
   Global_Stop := True;
   Notify_Data.Notify_Icon (Delete);   
   
   Log("Main", "After Message_Loop, wait for exit");
   
exception
  when E: others => Sattmate_Exception.Tracebackinfo(E);
   
end Saldo_Check;
