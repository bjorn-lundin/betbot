with GWindows;                    use GWindows;
with GWindows.Windows.Main; use GWindows.Windows.Main;
--with GWindows.Static_Controls; --use GWindows.Static_Controls;
with GWindows.GStrings; use GWindows.GStrings;
with GWindows.Drawing_Objects;    use GWindows.Drawing_Objects;
with GWindows.Windows;            use GWindows.Windows;
with GWindows.Application;
with GWindows.System_Tray;        use GWindows.System_Tray;
with Sattmate_Types;        use Sattmate_Types;
with Rpc;
with Sattmate_Exception;
with Logging; use Logging;
with Table_Abalances; 
with Sattmate_Calendar;
with Ada.Directories;
with Ada.Command_Line;

procedure Saldo_Check is
   pragma Linker_Options ("-mwindows");
   App_Name : constant GWindows.GString :=
                  GWindows.GStrings.To_GString_From_String("Björn's Botwatch");
   R : Rpc.Result_Type;
   Last_Bal,
   Bal : Table_Abalances.Data_Type;
   Global_Stop : Boolean := False;
   Notify_Data : Notify_Icon_Data;
   I, Ib : Icon_Type;
   NL : constant GCharacter := GCharacter'Val (10); -- New Line   
   Main_Window : Main_Window_Type;
   use type Table_Abalances.Data_Type;   
   pragma Warnings(Off, Global_Stop); -- surpress warning about not modified in loop
   -----------------------------------
   task Updater is
     entry Start;
   end Updater;   
   -----------------------------------
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
       begin
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
           
           Notify_Data.Set_Tool_Tip ("    Balance:" & Integer(Bal.Balance)'Img & NL & 
                                     "   Exposure:" & Integer(Bal.Exposure)'Img & NL & 
                                     "Last update:" & Sattmate_Calendar.String_Time);
                            
           if Last_Bal = Bal then
             Notify_Data.Set_Balloon ("");
             Log("Update_Task", "Last_Bal = Bal, empty balloon");
           elsif Bal.Exposure < 0.0 then
             Notify_Data.Set_Balloon ("Bet placed " & Integer(Bal.Exposure)'Img & ":-", App_Name, Information_Icon);
             Log("Update_Task", "balloon set to : Bet placed " & Integer(Bal.Exposure)'Img & ":-");
           elsif Bal.Exposure = 0.0 then
             Notify_Data.Set_Balloon ("Bet settled " & Integer(Bal.Balance)'Img & ":-", App_Name, Information_Icon);
             Log("Update_Task", "balloon set to : Bet settled " & Integer(Bal.Balance)'Img & ":-");
           else  
             Log("Update_Task", "Vafan??");
             Log("Update_Task", "     bal: " & Table_Abalances.To_String(Bal));
             Log("Update_Task", "Last_bal: " & Table_Abalances.To_String(Last_Bal));
           end if;
           
           Notify_Data.Notify_Icon (Modify);
           
           Cnt := 0;
           Last_Bal := Bal;
           Bal := Table_Abalances.Empty_Data;
         end if;  
         delay 1.0;
       exception   
         when Rpc.Post_Timeout => 
           Log("Update_Task", "Post timeout");
         when E: others => 
           Log("Update_Task", "Task is dying");
           Sattmate_Exception.Tracebackinfo (E);
           Rpc.Logout;
           exit;
       end;    
     end loop;  
   end Updater;
   ------------------------
   
begin
   Logging.Open(Ada.Directories.Containing_Directory(Ada.Command_Line.Command_Name) & "\saldo_checker.log");
   Main_Window.Create("Saldo Checker", Width => 200, Height => 100);
--   Main_Window.Visible(True);

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
     App_Name,
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
