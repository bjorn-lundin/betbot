with Types;    use Types;
with Sql;
with Calendar2; use Calendar2;
with Text_IO;
with Ini;
with Ada.Environment_Variables;
--with Utils; use Utils;
with Rpc;
with Logging; use Logging;
with Table_Astarttimes;
with Gnat.Command_Line; use Gnat.Command_Line;
with Stacktrace;
with Ada.Containers;

procedure Race_Time is

  --Me : constant String := "Race_Time";
  package EV renames Ada.Environment_Variables;
  gDebug : Boolean := False;
  
  
  Cmd_Line : Command_Line_Configuration;
  Ba_Rpc : aliased Boolean := False;
  Ba_Sql : aliased Boolean := False;
  
  -------------------------------
  procedure Debug (What : String) is
  begin
     if gDebug then
       Text_Io.Put_Line (Text_Io.Standard_Error, Calendar2.String_Date_Time_ISO (Clock, " " , "") & " " & What);
     end if;
  end Debug;
  pragma Warnings(Off, Debug);
  -------------------------------
  procedure Print (What : String) is
  begin
     Text_Io.Put_Line (What);
  end Print;
  -------------------------------
   
  Start_Time_List : Table_Astarttimes.Astarttimes_List_Pack2.List;
  Arrow_Is_Printed : Boolean := False;
  Now : Time_Type := Time_Type_First;
  Select_Racetime : Sql.Statement_Type;
  Delete_Racetime : Sql.Statement_Type;
  
  type Mode_Type is (Mode_Rpc,Mode_Sql);
  
  Mode : Mode_Type;
  ------------------------------------------------------------
  procedure Insert_Starttimes(List : Table_Astarttimes.Astarttimes_List_Pack2.List) is
    T : Sql.Transaction_Type;
    Dummy : Table_Astarttimes.Data_Type;
  begin
    T.Start;
    Delete_Racetime.Prepare(
      "delete from ASTARTTIMES " & 
      "where STARTTIME::date <= (select CURRENT_DATE - 1)");
    begin
      Delete_Racetime.Execute;
    exception
      when SQl.No_Such_Row => null;
    end;
    
    for S of List loop
      Dummy := S; -- workaround gnat 4.6.3
      Dummy.Insert; 
    end loop;

    T.Commit;
  end Insert_Starttimes;
  ------------------------------------------
  procedure Get_Starttimes(List : out Table_Astarttimes.Astarttimes_List_Pack2.List) is
    T : Sql.Transaction_Type;
    Eos : Boolean := False;
    Start_Data : Table_Astarttimes.Data_Type;
  begin
    T.Start;
    Select_Racetime.Prepare(
      "select * from ASTARTTIMES " & 
      "where STARTTIME::date = (select CURRENT_DATE) " & 
      "order by STARTTIME");
    
    Select_Racetime.Open_Cursor;
    loop
      Select_Racetime.Fetch(Eos);
      exit when Eos;
      Start_Data := Table_Astarttimes.Get(Select_Racetime);
      List.Append(Start_Data);
    end loop;      
    Select_Racetime.Close_Cursor;
    T.Commit;
  end Get_Starttimes;
  ------------------------------------------
  use type Text_Io.Count;
  type String_Ptr is access String;
  Db_Service : String_Ptr := null;
  
  use type Ada.Containers.Count_Type;
  
begin

  Define_Switch
    (Config      => Cmd_Line,
     Output      => Ba_Rpc'access,
     Long_Switch => "--rpc",
     Help        => "rpc");

  Define_Switch
    (Config      => Cmd_Line,
     Output      => Ba_Sql'access,
     Long_Switch => "--sql",
     Help        => "sql");

  Getopt (Cmd_Line);  -- process the command line
  
  if Ba_Rpc then
    Mode := Mode_Rpc;
  elsif Ba_Sql then
    Mode := Mode_Sql;
  else
    Log("No Mode - Quit");
    return;
  end if;
  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");
   
--  Log(Me, "Login betfair");
  if Ev.Value("BOT_MACHINE_ROLE") = "DISPLAY" then
    Db_Service := new String'("database_race_time");
  else
    Db_Service := new String'("database");
  end if;  

  case Mode is
    when Mode_Rpc =>
      Rpc.Init(
          Username   => Ini.Get_Value("betfair","username",""),
          Password   => Ini.Get_Value("betfair","password",""),
          Product_Id => Ini.Get_Value("betfair","product_id",""),
          Vendor_Id  => Ini.Get_Value("betfair","vendor_id",""),
          App_Key    => Ini.Get_Value("betfair","appkey","")
      );
    when Mode_Sql => null;
  end case;
 
  Days : loop        
    begin
      Start_Time_List.Clear;
      
      case Mode is
        when Mode_Rpc =>
          Rpc.Login;
          Rpc.Get_Starttimes(List => Start_Time_List);
          Sql.Connect
              (Host     => Ini.Get_Value("database", "host", ""),
               Port     => Ini.Get_Value("database", "port", 5432),
               Db_Name  => Ini.Get_Value("database", "name", ""),
               Login    => Ini.Get_Value("database", "username", ""),
               Password =>Ini.Get_Value("database", "password", ""));
          Insert_Starttimes(List => Start_Time_List);
          Rpc.Logout;
          Sql.Close_Session;
          exit Days;
        when Mode_Sql =>
          Sql.Connect
              (Host     => Ini.Get_Value(Db_Service.all, "host", ""),
               Port     => Ini.Get_Value(Db_Service.all, "port", 5432),
               Db_Name  => Ini.Get_Value(Db_Service.all, "name", ""),
               Login    => Ini.Get_Value(Db_Service.all, "username", ""),
               Password => Ini.Get_Value(Db_Service.all, "password", ""));
          Get_Starttimes(List => Start_Time_List);
          Sql.Close_Session;
      end case;
    
      Day : loop
        Arrow_Is_Printed := False;
        Now := Calendar2.Clock;
        Text_Io.New_Line(Text_Io.Count(Start_Time_List.Length) +1);   
        for S of Start_Time_List loop
          if not Arrow_Is_Printed and then
            Now <= S.Starttime then
               Print(
                 S.Starttime.String_Time(Seconds => False) & " | " &
                 S.Venue(1..15) & " <----"
               ) ;
            Arrow_Is_Printed := True;
          else
               Print(
                 S.Starttime.String_Time(Seconds => False) & " | " &
                 S.Venue(1..15)
               ) ;
          end if;      
        end loop;
        for i in 1 .. 30 loop
          Text_Io.Put('.');   
          delay 1.0;
        end loop;  
        -- new day, get new list after it is written to db
        exit Day when (Now.Hour = 5 and then Now.Minute = 30) or else 
                       Start_Time_List.Length = 0 ;
      end loop Day;    
    exception
      when Sql.Not_Connected =>
        Text_Io.Put_Line("Sql.Not_Connected, wait for 120 s");   
        delay 120.0;
    end;  
  end loop Days; 
exception
  when E: others =>
    Stacktrace.Tracebackinfo(E);
end Race_Time;
