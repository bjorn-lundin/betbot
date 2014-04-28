--with Text_Io;
with Sattmate_Exception;
with Sql;
with Sattmate_Types; use Sattmate_Types;
--with General_Routines; use General_Routines;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
--with Sattmate_Calendar; use Sattmate_Calendar;
--with Ada.Strings; use Ada.Strings;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Lock ;
with Ini;
with Logging; use Logging;
with Ada.Environment_Variables;
--with Process_IO;
--with Core_Messages;
--with Table_Araceprices;
--with Table_Aracepricesold;
with Bot_Svn_Info;
with Posix;

procedure Race_Price_Mover is
  package EV renames Ada.Environment_Variables;


  Me : constant String := "Poll.";

--  Timeout  : Duration := 120.0;
  My_Lock  : Lock.Lock_Type;

--  Msg      : Process_Io.Message_Type;
  Select_Araceprices_To_Move : Sql.Statement_Type;
  Select_Araceprices_To_Delete : Sql.Statement_Type;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line : Command_Line_Configuration;

  -------------------------------------------------------------

  -------------------------------------------------------------
  procedure Run is
--    Price_List : Table_Araceprices.Araceprices_List_Pack.List_Type := Table_Araceprices.Araceprices_List_Pack.Create;
--    Price : Table_Araceprices.Data_Type;
--    Old_Price : Table_Aracepricesold.Data_Type;
    T : Sql.Transaction_Type;
    Num : Integer_4 := 50;
    Rows_Inserted,
    Rows_Deleted : Natural := 0;
  begin

    Outer_Loop : loop
      Log("about to insert into Apricesfinishold in chunks of 1 days worth of data, Num =" & Num'Img);
    
      T.Start;
        
        Select_Araceprices_To_Move.Prepare(
          "insert into ARACEPRICESOLD " &
          "select * from ARACEPRICES " &
          "where PRICETS < current_timestamp - interval ':NUM day' "
        );
       Select_Araceprices_To_Move.Set("NUM",Num); 
       begin 
         Select_Araceprices_To_Move.Execute(Rows_Inserted);
       exception
         when Sql.No_Such_Row => Rows_Inserted := 0;
       end ;       
       
       Select_Araceprices_To_Delete.Prepare(
          "delete from ARACEPRICES " &
          "where PRICETS < current_timestamp - interval ':NUM day' " 
        );
       Select_Araceprices_To_Delete.Set("NUM",Num); 
       begin 
         Select_Araceprices_To_Delete.Execute(Rows_Deleted);
       exception
         when Sql.No_Such_Row => Rows_Deleted := 0;
       end ;       
       
      T.Commit;
      Log("chunk ready, Moved" & Rows_Inserted'Img & " and deleted" & Rows_Deleted'Img);
      Num := Num -1;
      exit Outer_Loop when Num = 2;               
               
               
       
-- way too slow       
--       Select_Araceprices_To_Move.Prepare(
--         "select * from ARACEPRICES where PRICETS < current_timestamp - interval '1 day' order by PRICETS limit 100000"
--       );
--       Log ("Start read max 100_000 records");
--       Table_Araceprices.Read_List(Select_Araceprices_To_Move,Price_List);
--       Log ("stop read, got:" & Table_Araceprices.Araceprices_List_Pack.Get_Count(Price_List)'Img );
--       
--       exit Outer_Loop when Table_Araceprices.Araceprices_List_Pack.Get_Count(Price_List) = 0;
--       
--       while not Table_Araceprices.Araceprices_List_Pack.Is_Empty(Price_List) loop
--        Cnt := Cnt +1;
--        if Cnt mod 1_000 = 0 then
--          Log ("inserted 1000, " &  Table_Araceprices.Araceprices_List_Pack.Get_Count(Price_List)'Img & " left");
--        end if;
--        Table_Araceprices.Araceprices_List_Pack.Remove_From_Head(Price_List,Price);
--        Old_Price := (
--             Pricets      =>  Price.Pricets,
--             Marketid     =>  Price.Marketid,
--             Selectionid  =>  Price.Selectionid,
--             Status       =>  Price.Status,
--             Backprice    =>  Price.Backprice,
--             Layprice     =>  Price.Layprice,
--             Ixxlupd      =>  Price.Ixxlupd,
--             Ixxluts      =>  Price.Ixxluts
--        );
--        Old_Price.Insert;
--        Price.Delete_Withcheck;
--       end loop;
       

    end loop Outer_Loop ;
  end Run;
  ---------------------------------------------------------------------
  use type Sql.Transaction_Status_Type;
------------------------------ main start -------------------------------------

begin

   Define_Switch
    (Cmd_Line,
     Sa_Par_Bot_User'access,
     Long_Switch => "--user=",
     Help        => "user of bot");

   Define_Switch
     (Cmd_Line,
      Ba_Daemon'access,
      Long_Switch => "--daemon",
      Help        => "become daemon at startup");

   Define_Switch
     (Cmd_Line,
      Sa_Par_Inifile'access,
      Long_Switch => "--inifile=",
      Help        => "use alternative inifile");

  Getopt (Cmd_Line);  -- process the command line

  if Ba_Daemon then
    Posix.Daemonize;
  end if;
  Logging.Open(EV.Value("BOT_HOME") & "/log/race_price_mover.log");

   --must take lock AFTER becoming a daemon ...
   --The parent pid dies, and would release the lock...
  My_Lock.Take(EV.Value("BOT_NAME"));


  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("database", "host", ""),
         Port     => Ini.Get_Value("database", "port", 5432),
         Db_Name  => Ini.Get_Value("database", "name", ""),
         Login    => Ini.Get_Value("database", "username", ""),
         Password =>Ini.Get_Value("database", "password", ""));
  Log(Me, "db Connected");
  
  Run;
  
  Log(Me, "Close Db");
  Sql.Close_Session;
  Logging.Close;
  Posix.Do_Exit(0); -- terminate

exception
  when Lock.Lock_Error =>
    Log(Me, "lock error, exit");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
  when E: others => Sattmate_Exception.Tracebackinfo(E);
--    Log(Me, "Close Db");
--    Sql.Close_Session;
    Log(Me, "Closed log and die");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
end Race_Price_Mover;

