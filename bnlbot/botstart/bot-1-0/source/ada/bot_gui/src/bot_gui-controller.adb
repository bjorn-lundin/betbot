with Gnoga.Gui.Base;
with Bot_Gui.View;
with Gnoga.Gui.Element.Table;
with Binary_Semaphores.Controls;
with Calendar2;
with Sql;
with Types     ; use Types;
with Bot_Types ; use Bot_Types;
with Utils;

package body Bot_Gui.Controller is

   DB_Semaphore : aliased Binary_Semaphores.Semaphore_Type;
   Select_Profit : Sql.Statement_Type;
   Select_Profit_Tot : Sql.Statement_Type;
   
   
   task type Updater_Task_Type is
     entry Set_View( View : Bot_Gui.View.Default_View_Access);
   end Updater_Task_Type;   
   
   type Updater_Type_Access is access all Updater_Task_Type;
   
   
   task body Updater_Task_Type is
     Local_View : Bot_Gui.View.Default_View_Access ;  
   begin
     accept Set_View( View : Bot_Gui.View.Default_View_Access) do
       Local_View := View;
     end Set_View;
     
     loop
       exit when Local_View.Quit_Task;
       Local_View.Run_Query.Fire_On_Click;
       delay 15.0;
     end loop;
     Local_View.Label_Text.Put_Line ("Updater_Task_Type - has quit");
   end Updater_Task_Type;
   
   
   
   procedure On_Click (Object : in out Gnoga.Gui.Base.Base_Type'Class);
   
   procedure On_Click (Object : in out Gnoga.Gui.Base.Base_Type'Class) is
      View : Bot_Gui.View.Default_View_Access := 
               Bot_Gui.View.Default_View_Access (Object.Parent);
   begin
      View.Label_Text.Put_Line ("Do_Stop");
      View.Quit_Task := True;
   end On_Click;
   -------------------------------------------
   
   
   procedure On_Click_Connect_Db (Object : in out Gnoga.Gui.Base.Base_Type'Class) is
      View : Bot_Gui.View.Default_View_Access := 
               Bot_Gui.View.Default_View_Access (Object.Parent);
   begin
      View.Label_Text.Put_Line ("Will connect");
      Sql.Connect (Host     => "db.nonodev.com",
                   Port     => 5432,
                   Db_Name  => "bnl",
                   Login    => "bnl",
                   Password => "BettingFotboll1$");      
      View.Label_Text.Put_Line ("Connected");
   end On_Click_Connect_Db;   
   -------------------------------------------
   procedure On_Click_Disconnect_Db (Object : in out Gnoga.Gui.Base.Base_Type'Class) is
      View : Bot_Gui.View.Default_View_Access := 
               Bot_Gui.View.Default_View_Access (Object.Parent);
               
   begin
      View.Label_Text.Put_Line ("Will disconnect");
      Sql.Close_Session;      
      View.Label_Text.Put_Line ("Disconnected");
   end On_Click_Disconnect_Db;   
   -------------------------------------------
   procedure On_Click_Run_Query (Object : in out Gnoga.Gui.Base.Base_Type'Class) is
      View : Bot_Gui.View.Default_View_Access := 
               Bot_Gui.View.Default_View_Access (Object.Parent);
     T : Sql.Transaction_Type;
     Eos : Boolean := True;
     Betname   : String (Bet_Name_Type'range) := (others => ' ');
     Sumprofit : Float_8 := 0.0;
     Count     : Integer_4 := 0;
     use Gnoga.Gui.Element.Table;
     Cnt : Integer_4 := 0;
     Control : Binary_Semaphores.Controls.Semaphore_Control(DB_Semaphore'access);
     pragma Warnings(Off,Control);
   begin
      View.Label_Text.Inner_HTML ("");
      View.Result_Table.Inner_HTML ("");
      View.Result_Table.Add_Caption("Today's result @ " & Calendar2.Clock.To_String(Milliseconds => False));
   
      View.Label_Text.Put_Line ("Will run query " & Calendar2.Clock.To_String);
      T.Start;
      Select_Profit.Prepare(
        "select " &
          "BETNAME, " &
          "sum(PROFIT) as SUMPROFIT, " &
          "count('a') as CNT " &
        "from " &
          "ABETS " &
        "where BETPLACED::date = (select CURRENT_DATE) " &
--        "where BETPLACED::date = '2014-11-23' " &
          "and BETWON is not null " &
          "and EXESTATUS = 'SUCCESS' " & 
          "and STATUS in ('SETTLED') " &
        "group by " &
          "BETNAME " &
        "order by " &
          "sum(PROFIT) desc, " &
          "BETNAME");
        
      Select_Profit_Tot.Prepare(   
        "select " &
          "sum(PROFIT) as SUMPROFIT, " &
          "count('a') as CNT " &
        "from " &
          "ABETS " &
        "where BETPLACED::date = (select CURRENT_DATE) " &
--        "where BETPLACED::date = '2014-11-23' " &
          "and BETWON is not null " &
          "and EXESTATUS = 'SUCCESS' " & 
          "and STATUS in ('SETTLED')");
        
      Select_Profit.Open_Cursor;  
      loop
        Select_Profit.Fetch(Eos);  
        exit when Eos;
        Select_Profit.Get("BETNAME", Betname);  
        Select_Profit.Get("SUMPROFIT", Sumprofit);  
        Select_Profit.Get("CNT", Count);          
        declare
           Row  : Table_Row_Access := new Table_Row_Type;
           Col1 : Table_Column_Access := new Table_Column_Type;
           Col2 : Table_Column_Access := new Table_Column_Type;
           Col3 : Table_Column_Access := new Table_Column_Type;
        begin
           Cnt := Cnt +1;
           Row.Dynamic;
           Col1.Dynamic;
           Col2.Dynamic;  
           Col3.Dynamic;  
           Row.Create (View.Result_Table);
           if Cnt mod 2 = Integer_4(0) then
             Row.Background_Color("skyblue");
           end if;
           Col1.Create (Row.all, Utils.Trim(Betname));
           Col2.Create (Row.all, Utils.F8_Image(Sumprofit));
           if Sumprofit < 0.0 then
             Col2.Background_Color("red");
           else 
             Col2.Background_Color("palegreen");
           end if;
           Col3.Create (Row.all, Count'Img);
           Col2.Text_Alignment(Gnoga.Gui.Element.Right);
           Col3.Text_Alignment(Gnoga.Gui.Element.Right);
        end;        
      end loop;  
      Select_Profit.Close_Cursor;  
      
      Select_Profit_Tot.Open_Cursor;  
      loop
        Select_Profit_Tot.Fetch(Eos);  
        exit when Eos;
        Select_Profit_Tot.Get("SUMPROFIT", Sumprofit);  
        Select_Profit_Tot.Get("CNT", Count);          
        declare
           use Gnoga.Gui.Element;
           Row  : Table_Row_Access := new Table_Row_Type;
           Col1 : Table_Column_Access := new Table_Column_Type;
           Col2 : Table_Column_Access := new Table_Column_Type;
           Col3 : Table_Column_Access := new Table_Column_Type;
        begin
           Cnt := Cnt +1;
           Row.Dynamic;
           Col1.Dynamic;
           Col2.Dynamic;  
           Col3.Dynamic;  
           Row.Create (View.Result_Table);
           Row.Font(Weight => Weight_Bold);
           if Cnt mod 2 = Integer_4(0) then
             Row.Background_Color("skyblue");
           end if;           
           Col1.Create (Row.all, "Grand Total");
           Col2.Create (Row.all, Utils.F8_Image(Sumprofit));
           Col3.Create (Row.all, Count'Img);
           
           Col2.Text_Alignment(Gnoga.Gui.Element.Right);
           Col3.Text_Alignment(Gnoga.Gui.Element.Right);
           
        end;        
      end loop;  
      Select_Profit_Tot.Close_Cursor;  
      View.Result_Table.Border;
        
      T.Commit;
      
      View.Label_Text.Put_Line ("Has run query " & Calendar2.Clock.To_String);
   end On_Click_Run_Query;   
   -------------------------------------------
   procedure Default
     (Main_Window : in out Gnoga.Gui.Window.Window_Type'Class;
      Connection  : access
        Gnoga.Application.Multi_Connect.Connection_Holder_Type)
   is
      pragma Unreferenced(Connection);
      View : Bot_Gui.View.Default_View_Access :=
               new Bot_Gui.View.Default_View_Type;
      Updater : Updater_Type_Access := new Updater_Task_Type;             
   begin
   
      View.Dynamic;
      View.Create (Main_Window);
      View.Click_Button.On_Click_Handler (On_Click'access);
      View.Connect_Db.On_Click_Handler (On_Click_Connect_Db'access);
      View.Disconnect_DB.On_Click_Handler (On_Click_Disconnect_DB'access);
      View.Run_Query.On_Click_Handler (On_Click_Run_Query'access);
      

      View.Label_Text.Put_Line ("Connect db");
      Sql.Connect (Host     => "db.nonodev.com",
                   Port     => 5432,
                   Db_Name  => "bnl",
                   Login    => "bnl",
                   Password => "BettingFotboll1$");   
      View.Label_Text.Put_Line ("db Connected");
      Updater.Set_View(View); -- will start update

      
   end Default;

begin
   -- we arrive her if we call the web server with no path
   Gnoga.Application.Multi_Connect.On_Connect_Handler
     (Default'access, "default");   
end Bot_Gui.Controller;
