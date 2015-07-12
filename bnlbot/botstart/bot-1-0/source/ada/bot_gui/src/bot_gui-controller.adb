with Gnoga.Gui.Base;
with Bot_Gui.View;
with Gnoga.Gui.Element.Table;
with Binary_Semaphores.Controls;
with Calendar2;
with Sql;
with Types     ; use Types;
with Bot_Types ; use Bot_Types;
with Utils;
with Ada.Command_Line;
with Stacktrace;
with Ada.Exceptions;
with Logging; use Logging;

package body Bot_Gui.Controller is


   New_Buffer,
   Old_Buffer : Bot_Gui.View.Double_Buffer_Type := Bot_Gui.View.Double_Buffer_Type'First;


   DB_Semaphore : aliased Binary_Semaphores.Semaphore_Type;
   Select_Weekly_Profit : Sql.Statement_Type;
   Select_Daily_Profit : Sql.Statement_Type;

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

   -------------------------------------------
   procedure On_Click_Run_Query (Object : in out Gnoga.Gui.Base.Base_Type'Class) is
      View : Bot_Gui.View.Default_View_Access :=
               Bot_Gui.View.Default_View_Access (Object.Parent);
     T : Sql.Transaction_Type;
     Eos : Boolean := True;
     use Gnoga.Gui.Element.Table;
     use Bot_Gui.View;
     Control : Binary_Semaphores.Controls.Semaphore_Control(DB_Semaphore'access);
     pragma Warnings(Off,Control);
     Ts : Calendar2.Time_Type := Calendar2.Clock;

     type Table_Type_Type is (Tbl_Date, Tbl_Week);


     procedure Draw_Table(Tbl : in out Gnoga.Gui.Element.Table.Table_Type;
                          Stm : in out Sql.Statement_Type;
                          Table_Type : in Table_Type_Type;
                          Caption,Hdr1,Hdr2,Hdr3 : in String ) is
       Betname   : String (Bet_Name_Type'range) := (others => ' ');
       Sumprofit : Float_8 := 0.0;
       Week      : Integer_4 := 0;
       Date      : Calendar2.Time_Type := Calendar2.Time_Type_First;
       Cnt : Integer_4 := 0;
     begin

      Tbl.Add_Caption(Caption);
      Tbl.Border;

      declare
        Row  : Table_Row_Access := new Table_Row_Type;
        Col1 : Table_Heading_Access := new Table_Heading_Type;
        Col2 : Table_Heading_Access := new Table_Heading_Type;
        Col3 : Table_Heading_Access := new Table_Heading_Type;
      begin
        Row.Dynamic;
        Col1.Dynamic;
        Col2.Dynamic;
        Col3.Dynamic;
        Row.Create (Tbl);
        Col1.Create (Row.all, Hdr1); --betname
        Col2.Create (Row.all, Hdr2); --sum(profit)
        Col3.Create (Row.all, Hdr3); --Date/Week
      end;
      Stm.Open_Cursor;
      loop
        Stm.Fetch(Eos);
        exit when Eos;
        Stm.Get("BETNAME", Betname);
        Stm.Get("SUMPROFIT", Sumprofit);
        case Table_Type is
          when Tbl_Date => Stm.Get_Date("DATE", Date);
          when Tbl_Week => Stm.Get("WEEK", Week);
        end case;
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
          Row.Create (Tbl);
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
          case Table_Type is
            when Tbl_Date => Col3.Create (Row.all, Date.String_Date_ISO);
            when Tbl_Week => Col3.Create (Row.all, "Week");
          end case;
          Col2.Text_Alignment(Gnoga.Gui.Element.Right);
        end;
      end loop;
      Stm.Close_Cursor;
     end Draw_Table;
     --------------------------------------



   begin
      -- reset old tables
      View.Label_Text.Inner_HTML ("");

      T.Start;
      Select_Daily_Profit.Prepare(
        "select BETNAME, sum(B.PROFIT) as SUMPROFIT, B.STARTTS::date as DATE " &
        "from ABETS B " &
        "where B.BETNAME = 'HORSES_PLC_BACK_FINISH_1.10_7.0_1' " &
        "and B.BETWON is not NULL " &
        "and B.STARTTS >= (select CURRENT_DATE - interval '6 days') " &
        "and extract(year from B.STARTTS) = extract(year from (select CURRENT_DATE )) " &
        "group by BETNAME, B.STARTTS::date " &
        "order by B.STARTTS::date desc, BETNAME");


      Select_Weekly_Profit.Prepare(
         "select BETNAME, sum(B.PROFIT) as SUMPROFIT, extract(week from B.STARTTS) as WEEK " &
         "from ABETS B " &
         "where B.BETNAME = 'HORSES_PLC_BACK_FINISH_1.10_7.0_1' " &
         "and B.BETWON is not NULL " &
         "and extract(week from B.STARTTS) >= extract(week from (select CURRENT_DATE - interval '5 weeks')) " &
         "and extract(year from B.STARTTS) = extract(year from (select CURRENT_DATE )) " &
         "group by BETNAME, extract(week from B.STARTTS) " &
         "order by extract(week from B.STARTTS) desc, BETNAME");


      --View.Weekly_Table(Buffer_Two).Inner_HTML("");
      --View.Daily_Table(Buffer_Two).Inner_HTML("");
      View.Weekly_Table(Buffer_One).Inner_HTML("");
      View.Daily_Table(Buffer_One).Inner_HTML("");

      Draw_Table(Tbl => View.Daily_Table(Buffer_One),
                 Stm => Select_Daily_Profit,
                 Table_Type => Tbl_Date,
                 Caption => "Last week's result @ " & Ts.String_Date_And_Time(Milliseconds => False),
                 Hdr1 => "Betname",
                 Hdr2 => "Sum(Profit)",
                 Hdr3 => "Date");


      Draw_Table(Tbl => View.Weekly_Table(Buffer_One),
                 Stm => Select_Weekly_Profit,
                 Table_Type => Tbl_Week,
                 Caption => "Last 6 week's result @ " & Ts.String_Date_And_Time(Milliseconds => False),
                 Hdr1 => "Betname",
                 Hdr2 => "Sum(Profit)",
                 Hdr3 => "Week");


      --View.Daily_Table(Buffer_Two).Place_Inside_Top_Of (View.Weekly_Table(Buffer_One));
      --View.Weekly_Table(Buffer_Two).Place_Inside_Top_Of (View.Weekly_Table(Buffer_One));

      --View.Daily_Table(Buffer_One).Place_Inside_Top_Of (View.Weekly_Table(Buffer_Two));
      --View.Weekly_Table(Buffer_One).Place_Inside_Top_Of (View.Weekly_Table(Buffer_Two));


      T.Commit;

      View.Label_Text.Put_Line ("Has run query " & Calendar2.Clock.To_String);
      View.Label_Text.Put_Line ("start update imgs " & Calendar2.Clock.To_String);
      View.Matched_Image.URL_Source("img/profit_vs_matched_182.png?TS=" &
        Utils.Trim(Ts.Millisecond'img));
      View.Lapsed_Image.URL_Source("img/settled_vs_lapsed_182.png?TS=" &
        Utils.Trim(Ts.Millisecond'img));

      View.Label_Text.Put_Line ("Has updated imgs " & Calendar2.Clock.To_String);
    exception
        when E: others =>
          declare
            Last_Exception_Name     : constant String  := Ada.Exceptions.Exception_Name(E);
            Last_Exception_Messsage : constant String  := Ada.Exceptions.Exception_Message(E);
            Last_Exception_Info     : constant String  := Ada.Exceptions.Exception_Information(E);
          begin
            Log(Last_Exception_Name);
            Log("Message : " & Last_Exception_Messsage);
            Log(Last_Exception_Info);
            Log("addr2line" & " --functions --basenames --exe=" &
                 Ada.Command_Line.Command_Name & " " & Stacktrace.Pure_Hexdump(Last_Exception_Info));
          end ;
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
      View.Run_Query.On_Click_Handler (On_Click_Run_Query'access);

      View.Label_Text.Put_Line ("Connect db");
      Sql.Connect (Host     => "db.nonodev.com",
                   Port     => 5432,
                   Db_Name  => "bnl",
                   Login    => "bnl",
                   Password => "ld4BC9Q51FU9CYjC21gp");
      View.Label_Text.Put_Line ("db Connected");
      Updater.Set_View(View); -- will start update


   end Default;

begin
   -- we arrive her if we call the web server with no path
   Gnoga.Application.Multi_Connect.On_Connect_Handler
     (Default'access, "default");
end Bot_Gui.Controller;
