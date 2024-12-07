
--with Text_io;
with Table_Aevents;
with Table_Alinks;
with Sql;
with Logging ; use Logging;
--with Types; use Types;
--with Calendar2; use Calendar2;
--with Ada.Strings ; use Ada.Strings;
--with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
--with General_Routines; use General_Routines;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Stacktrace;

--with Simple_List_Class;
--pragma Elaborate_All(Simple_List_Class);

procedure Remove_Duplicates_From_Events is
--  Bad_Input : exception;
 
  Me : constant String := "Main."; 
 
  Event_List : Table_Aevents.Aevents_List_Pack.List_Type := 
            Table_Aevents.Aevents_List_Pack.Create;
  Event_Data : Table_Aevents.Data_Type;
  Link_Data  : Table_Alinks.Data_Type;
  
  T : Sql.Transaction_Type;
  Update_Eventid_1,
  Update_Alinks_Md5_1,
  Update_Alinks_Md5_2 : Sql.Statement_Type;
 
  Config           : Command_Line_Configuration;
  Sa_Par_Database  : aliased Gnat.Strings.String_Access;
  Sa_Par_Hostname  : aliased Gnat.Strings.String_Access;
  Sa_Par_Username  : aliased Gnat.Strings.String_Access;
  Sa_Par_Password  : aliased Gnat.Strings.String_Access;

  
  ------------------------------------------------------------------------------------------

  procedure Update_Alinks_Md5 is
  begin  
    Log(Me & "Update_Alinks_Md5", "start");
    Update_Alinks_Md5_1.Prepare("update ALINKS set MD5SUM = md5(trim(EVENTNAME))");
    Update_Alinks_Md5_1.Execute;
    Update_Alinks_Md5_2.Prepare("update ALINKS set TMPEVENTID = substring(MD5SUM,1,11)");
    Update_Alinks_Md5_2.Execute;
    Log(Me & "Update_Alinks_Md5", "stop");
  exception
    when Sql.No_Such_Row =>
    Log(Me & "Update_Alinks_Md5", "nothing to update");
  end Update_Alinks_Md5;
  ---------------------------------------------------
  procedure Update_Eventid_Amarkets is
  begin  
    Log(Me & "Update_Eventid_Amarkets", "start");
    Update_Eventid_1.Prepare("update AMARKETS set EVENTID = (select TMPEVENTID from ALINKS where EVENTID = AMARKETS.EVENTID)");
    Update_Eventid_1.Execute;
    Log(Me & "Update_Eventid_Amarkets", "stop");
  exception
    when Sql.No_Such_Row =>
    Log(Me & "Update_Eventid_Amarkets", "nothing to update");
  end Update_Eventid_Amarkets;
  ---------------------------------------------------
    
  Eos : Boolean := False;
  Cnt, Tot : Integer := 0;
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
  Update_Alinks_Md5;
  Update_Eventid_Amarkets;
  
  Log(Me, "start read all");
  Table_Aevents.Read_All(Event_List);
  Tot := Table_Aevents.Aevents_List_Pack.Get_Count(Event_List);
  Log(Me, "all are read, found" & Tot'Img );
  
  while not Table_Aevents.Aevents_List_Pack.Is_Empty(Event_List) loop
    Table_Aevents.Aevents_List_Pack.Remove_From_Head(Event_List, Event_Data); 
    
    Cnt := Cnt +1;
    if Cnt rem 10_000 = 0 then
      Log(Me, Cnt'Img & "/" & Tot'Img); 
    end if;
    
    Link_Data.Eventid := Event_Data.Eventid;
    Table_Alinks.Read(Link_Data, Eos);
    if not Eos then
      Table_Aevents.Delete_Withcheck(Event_Data);
      Event_Data.Eventid := Link_Data.Tmpeventid;
      Table_Aevents.Read(Event_Data, Eos);
      if Eos then
        Table_Aevents.Insert(Event_Data);    
      end if;
    end if;       
  end loop;
   
  T.Commit;
 
  Log(Me, "close db");
  Sql.Close_Session;

exception
--  when  Gnat.Command_Line.Invalid_Switch =>
--    Display_Help(Config);
  when E: others => 
    Stacktrace.Tracebackinfo(E);  
end Remove_Duplicates_From_Events;
