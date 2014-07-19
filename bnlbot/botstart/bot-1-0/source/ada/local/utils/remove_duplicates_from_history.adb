
--with Text_io;
with Table_History;
with Sql;
with Logging ; use Logging;
with Types; use Types;
--with Calendar2; use Calendar2;
--with Ada.Strings ; use Ada.Strings;
--with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
--with General_Routines; use General_Routines;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Stacktrace;

with Simple_List_Class;
pragma Elaborate_All(Simple_List_Class);

procedure Remove_Duplicates_From_History is
--  Bad_Input : exception;
 
  Me : constant String := "Main."; 
 
  History_List : Table_History.History_List_Pack.List_Type := 
            Table_History.History_List_Pack.Create;
  History_Data : Table_History.Data_Type;            
  
  T : Sql.Transaction_Type;
  Delete_All,
  Delete_Non_PE,
  Select_Order_By_Firsttaken,
  Select_Keys : Sql.Statement_Type;
 
  Config           : Command_Line_Configuration;
  Sa_Par_Database  : aliased Gnat.Strings.String_Access;
  Sa_Par_Hostname  : aliased Gnat.Strings.String_Access;
  Sa_Par_Username  : aliased Gnat.Strings.String_Access;
  Sa_Par_Password  : aliased Gnat.Strings.String_Access;
  
  type Key_Type is record
    Eventid : Integer_4 := 0;
    Selectionid : Integer_4 := 0;
  end record;
  
  package Key_Pkg is new Simple_List_Class(Key_Type);
  Key_List : Key_Pkg.List_Type := Key_Pkg.Create;
  Key : Key_Type;
  ------------------------------------------------------------------------------------------
  procedure Read_Keys(List : Key_Pkg.List_Type) is
    Key : Key_Type;
    Eos : Boolean := False;
  begin
    Log(Me & "Read_Keys", "start");
    Select_Keys.Prepare("select EVENTID,SELECTIONID from HISTORY group by EVENTID,SELECTIONID order by EVENTID,SELECTIONID");
    Select_Keys.Open_Cursor;
    loop
      Select_Keys.Fetch(Eos);
      exit when Eos;
      Select_Keys.Get("EVENTID", Key.Eventid);
      Select_Keys.Get("SELECTIONID", Key.Selectionid);
      Key_Pkg.Insert_At_Tail(List,Key);
    end loop;
    Select_Keys.Close_Cursor;    
    Log(Me & "Read_Keys", "num keys:" & Key_Pkg.Get_Count(Key_List)'Img);
  end Read_Keys;
  --------------------------------------------------------
  procedure Delete_Non_PE_Records is
  begin  
    Log(Me & "Delete_Non_PE_Records", "start");
    Delete_Non_PE.Prepare("delete from HISTORY where inplay <> 'PE'");
    Delete_Non_PE.Execute;
    Log(Me & "Delete_Non_PE_Records", "stop");
  exception
    when Sql.No_Such_Row =>
    Log(Me & "Delete_Non_PE_Records", "nothing to delete");
  end Delete_Non_PE_Records;
  ---------------------------------------------------
  procedure Delete_All_Records is
  begin  
    Log(Me & "Delete_All_Records", "start");
    Delete_All.Prepare("delete from HISTORY");
    Delete_All.Execute;
    Log(Me & "Delete_All_Records", "stop");
  exception
    when Sql.No_Such_Row =>
    Log(Me & "Delete_All_Records", "nothing to delete");
  end Delete_All_Records;
  ---------------------------------------------------
    
  Eos : Boolean := False;
  Cnt : Integer := 0;
begin 
 
  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Hostname'access,
     Long_Switch => "--hostname=",
     Help        => "hostname");
     
  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Database'access,
     Long_Switch => "--database=",
     Help        => "database");
     
  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Username'access,
     Long_Switch => "--username=",
     Help        => "username");

  Define_Switch
    (Config      => Config,
     Output      => Sa_Par_Password'access,
     Long_Switch => "--password=",
     Help        => "password");

   Getopt (Config);  -- process the command line

  if Sa_Par_Hostname.all = "" or else 
    Sa_Par_Database.all = "" or else 
    Sa_Par_Username.all = "" or else 
    Sa_Par_Password.all = "" then
    Display_Help (Config);
    return;
  end if;
 
  Log(Me, "log into database");
  Sql.Connect
     (Host     => Sa_Par_Hostname.all,
      Port     => 5432,
      Db_Name  => Sa_Par_Database.all,
      Login    => Sa_Par_Username.all,
      Password => Sa_Par_Password.all);
  Log(Me, "db Connected");
  
  T.Start;
  Delete_Non_PE_Records;
  
  Read_Keys(Key_List);
 
  Select_Order_By_Firsttaken.Prepare(
      "select * from HISTORY where EVENTID =:EVENTID and SELECTIONID =:SELECTIONID and INPLAY='PE' order by FIRSTTAKEN desc");
  while not Key_Pkg.Is_Empty(Key_List) loop
    Key_Pkg.Remove_From_Head(Key_List,Key); 
    
    Cnt := Cnt +1;
    if Cnt rem 10_000 = 0 then
      Log(Me, Cnt'Img); 
    end if;
  
    Select_Order_By_Firsttaken.Set("EVENTID", Key.Eventid);
    Select_Order_By_Firsttaken.Set("SELECTIONID", Key.Selectionid);
    Select_Order_By_Firsttaken.Open_Cursor;
    Select_Order_By_Firsttaken.Fetch(Eos);
    if not Eos then
      History_Data := Table_History.Get(Select_Order_By_Firsttaken);
      Table_History.History_List_Pack.Insert_At_Tail(History_List, History_Data);
    end if;
    Select_Order_By_Firsttaken.Close_Cursor;  
  end loop;
  
  Delete_All_Records;
  
  while not Table_History.History_List_Pack.Is_Empty(History_List) loop
    Table_History.History_List_Pack.Remove_From_Head(History_List, History_Data);
    Table_History.Insert(History_Data);
  end loop;
   
  T.Commit;
 
  Log(Me, "close db");
  Sql.Close_Session;

exception
--  when  Gnat.Command_Line.Invalid_Switch =>
--    Display_Help(Config);
  when E: others => 
    Stacktrace.Tracebackinfo(E);  
end Remove_Duplicates_From_History;
