with GWindows.Windows.Main; use GWindows.Windows.Main;
with GWindows.Static_Controls; use GWindows.Static_Controls;
with GWindows.GStrings; use GWindows.GStrings;
--  with GWindows.Base;
with GWindows.Application;
with Rpc;
with Sattmate_Exception;
with Logging; use Logging;
with Table_Abalances;
with Sattmate_Calendar;

procedure Saldo_Check is
--   pragma Linker_Options ("-mwindows");
   Main_Window : Main_Window_Type;

   Last_Updated_Text_Label   : Label_Type;
   Saldo_Text_Label          : Label_Type;
   Exposed_Text_Label        : Label_Type;
   
   Last_Updated_Value_Label  : Label_Type;
   Saldo_Value_Label         : Label_Type;
   Exposed_Value_Label       : Label_Type;
   R : Rpc.Result_Type;
   Bal : Table_Abalances.Data_Type;

   Global_Stop : Boolean := False;
   pragma warnings(off,Global_Stop);
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
          Log(Table_Abalances.To_String(Bal));
          Text (Saldo_Value_Label, GWindows.GStrings.Image(Integer(Bal.Balance)));
          Text (Exposed_Value_Label, GWindows.GStrings.Image(Integer(Bal.Exposure)));
          Text (Last_Updated_Value_Label, GWindows.GStrings.To_GString_From_String(Sattmate_Calendar.String_Time));
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
   Create (Main_Window, "Saldo Checker", Width => 200, Height => 100);
   Visible(Main_Window, True);
   Create (Saldo_Text_Label, Main_Window,              "Saldo:",  5, 10, 70, 25, Right);
   Create (Exposed_Text_Label, Main_Window,          "Exposed:",  5, 30, 70, 25, Right);
   Create (Last_Updated_Text_Label, Main_Window, "Last update:",  5, 50, 70, 25, Right);
   Create (Saldo_Value_Label, Main_Window,                  "2", 90, 10, 70, 25, Right);
   Create (Exposed_Value_Label, Main_Window,                "3", 90, 25, 70, 25, Right);
   Create (Last_Updated_Value_Label, Main_Window,           "4", 90, 35, 70, 25, Right);
   Log("Main", "Will start task");
   Updater.Start;
   Log("Main", "task is started");
   
   GWindows.Application.Message_Loop;
   Global_Stop := True;
   
   Log("Main", "After Message_Loop, wait for exit");
   
exception
  when E: others => Sattmate_Exception.Tracebackinfo(E);
   
end Saldo_Check;
