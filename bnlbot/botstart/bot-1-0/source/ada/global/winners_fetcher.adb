with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Environment_Variables;
with Ada.Calendar;
with Types; use Types;
with Sql;
with Simple_List_Class;
pragma Elaborate_All(Simple_List_Class);
with Aws;
with Aws.Client;
with Aws.Response;
with Sax;
with Unicode.CES.Basic_8bit;
with Sax.Readers;        use Sax.Readers;
with Input_Sources.Strings; use Input_Sources.Strings;
with Unicode.CES;
with Sax.Attributes;
with Stacktrace;
with General_Routines;
with Lock ;
with Table_Awinners;
with Table_Anonrunners;
with Posix;
--with Ada.Directories;
with Logging; use Logging;
with Bot_Messages;
with Process_Io;
with Ini;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

procedure Winners_Fetcher is
  Bad_Data : exception;
  package EV renames Ada.Environment_Variables;
--  package AD renames Ada.Directories;
  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Cmd_Line : Command_Line_Configuration;


  Me : constant String := "Main.";
  type Selection_Type is record
    Id   : Integer_4 := 0;
    Name : Unbounded_String := Null_Unbounded_String;
  end record;
  Empty_Selection : Selection_Type;
  package Selections is new Simple_List_Class(Selection_Type);

  type Non_Runner_Type is record
    Name : Unbounded_String := Null_Unbounded_String;
  end record;
  Empty_Non_Runner : Non_Runner_Type;

  package Non_Runners is new Simple_List_Class(Non_Runner_Type);

  --------------------------

  type Market_Type is record
     Market_Id         : Integer_4           := 0;
     Display_Name      : Unbounded_String     := Null_Unbounded_String;
     Market_Type       : Unbounded_String     := Null_Unbounded_String;
     Selection         : Selection_Type ;
     Selection_List    : Selections.List_Type := Selections.Create;
     Non_Runner        : Non_Runner_Type;
     Non_Runner_List   : Non_Runners.List_Type := Non_Runners.Create;
  end record;

  Empty_Market :  Market_Type;

  type Reader is new Sax.Readers.Reader with record
    Current_Tag      : Unbounded_String := Null_Unbounded_String;
    Market           : Market_Type;
  end record;

  overriding procedure Start_Document (Handler : in out Reader);

  overriding procedure End_Document (Handler : in out Reader);

  overriding procedure Start_Element(Handler       : in out Reader;
                                     Namespace_URI : Unicode.CES.Byte_Sequence := "";
                                     Local_Name    : Unicode.CES.Byte_Sequence := "";
                                     Qname         : Unicode.CES.Byte_Sequence := "";
                                     Atts          : Sax.Attributes.Attributes'Class) ;

  overriding procedure End_Element(Handler         : in out Reader;
                                   Namespace_URI   : Unicode.CES.Byte_Sequence := "";
                                   Local_Name      : Unicode.CES.Byte_Sequence := "";
                                   Qname           : Unicode.CES.Byte_Sequence := "") ;

  overriding procedure Characters(Handler          : in out Reader;
                                  Ch               : Unicode.CES.Byte_Sequence := "");


  overriding procedure Ignorable_Whitespace(Handler : in out Reader;
                                            Ch      : Unicode.CES.Byte_Sequence);



  Has_Inserted_Winner : Boolean := False;


  overriding procedure Start_Document (Handler : in out Reader) is
    pragma Unreferenced(Handler);
  begin
    null;
    --Log(Me, "Start_Document");
  end Start_Document;

  overriding procedure End_Document (Handler : in out Reader) is
    pragma Unreferenced(Handler);
  begin
    null;
    --Log(Me, "End_Document");
  end End_Document;

  My_Lock  : Lock.Lock_Type;


  procedure Start_Element(Handler       : in out Reader;
                          Namespace_URI : Unicode.CES.Byte_Sequence := "";
                          Local_Name    : Unicode.CES.Byte_Sequence := "";
                          Qname         : Unicode.CES.Byte_Sequence := "";
                          Atts          : Sax.Attributes.Attributes'Class) is
    pragma Warnings(Off,Namespace_URI);
    pragma Warnings(Off,Qname);
    pragma Warnings(Off,Atts);
    The_Tag : constant String := Local_Name;
  begin
    --Log(Me, "Start_Element");
    Handler.Current_Tag := To_Unbounded_String(The_Tag);

    if The_Tag = "market" then
      Selections.Remove_All(Handler.Market.Selection_List);
      Non_Runners.Remove_All(Handler.Market.Non_Runner_List);
      Handler.Market := Empty_Market ;-- reset
      Handler.Market.Market_Id := Integer_4'Value(Atts.Get_Value("id"));
      Handler.Market.Display_Name := To_Unbounded_String(Atts.Get_Value("displayName"));
    elsif The_Tag = "winner" then
      Handler.Market.Selection := Empty_Selection;
      Handler.Market.Selection.Id:= Integer_4'Value(Atts.Get_Value("selectionId"));
    elsif The_Tag = "nonRunner" then
      Handler.Market.Non_Runner := Empty_Non_Runner;
    end if;

  end Start_Element;

  procedure Insert_Into_Db(Handler : in out Reader) ; -- forward only. Not dispatching...

  --++--++--++--++--++--++--++--++--++--++--++--++--++--
  procedure End_Element(Handler       : in out Reader;
                        Namespace_URI : Unicode.CES.Byte_Sequence := "";
                        Local_Name    : Unicode.CES.Byte_Sequence := "";
                        Qname         : Unicode.CES.Byte_Sequence := "") is
    pragma Warnings(Off,Namespace_URI);
    pragma Warnings(Off,Qname);
    The_Tag : constant String := Local_Name;

    --------------------------------------------

  begin
    Handler.Current_Tag := To_Unbounded_String(The_Tag);
    if The_Tag = "winner" then
      Selections.Insert_At_Tail(Handler.Market.Selection_List,Handler.Market.Selection);
    elsif The_Tag = "nonRunner" then
      Non_Runners.Insert_At_Tail(Handler.Market.Non_Runner_List,Handler.Market.Non_Runner);
    elsif The_Tag = "market" then
    Insert_Into_Db(Handler);
    end if;
    --Log(Me,"End_Element");
  end End_Element;
  --++--++--++--++--++--++--++--++--++--++--++--++--++--

  procedure Characters(Handler : in out Reader;
                       Ch      : Unicode.CES.Byte_Sequence := "") is
    The_Tag   : constant String := To_String(Handler.Current_Tag);
    use General_Routines;
  begin
    --Log (Me, "Characters");
    if The_Tag = "marketType" then
      Handler.Market.Market_Type := Handler.Market.Market_Type & To_Unbounded_String(Trim(Ch));
    elsif The_Tag = "winner" then
      Handler.Market.Selection.Name := Handler.Market.Selection.Name & To_Unbounded_String(Trim(Ch));
    elsif The_Tag = "nonRunner" then
      Handler.Market.Non_Runner.Name := Handler.Market.Non_Runner.Name & To_Unbounded_String(Trim(Ch));
    end if;
  end Characters;

  --++--++--++--++--++--++--++--++--++--++--++--++--++--

  procedure Ignorable_Whitespace(Handler : in out Reader;
                                 Ch      : Unicode.CES.Byte_Sequence ) is
    The_Tag   : constant String := To_String(Handler.Current_Tag);
    pragma Unreferenced(Ch);
    pragma Unreferenced(The_Tag);
  begin
    null;
   -- Log (Me, "Ignorable_Whitespace " & The_Tag & " The_Value  |" & Ch & "|");
  end Ignorable_Whitespace;
----------------------------------------------

  procedure Insert_Into_Db(Handler : in out Reader) is
    T          : Sql.Transaction_Type;
    Winner     : Table_Awinners.Data_Type;
    Non_Runner : Table_Anonrunners.Data_Type;
    type Eos_Type is (Awinners, Anonrunners);
    Eos : array (Eos_Type'range) of Boolean := (others => False);
    Eol : Boolean := False;
  begin
--    Log("----------- Insert_Into_Db start --------------------");
    Sql.Start_Read_Write_Transaction (T);
    Selections.Get_First(Handler.Market.Selection_List,Handler.Market.Selection,Eol);
    loop
      exit when Eol;
      Winner.Marketid := "1." & General_Routines.Trim(Handler.Market.Market_Id'Img);
      Winner.Selectionid := Handler.Market.Selection.Id;
      Table_Awinners.Read(Winner, Eos(Awinners));
      if Eos(Awinners) then
        Has_Inserted_Winner := True;
        Table_Awinners.Insert(Winner);
        Log (Me, "Selection" & Handler.Market.Selection.Id'Img & " " & To_String(Handler.Market.Selection.Name));
      end if;
      Selections.Get_Next(Handler.Market.Selection_List,Handler.Market.Selection,Eol);
    end loop;

    Non_Runners.Get_First(Handler.Market.Non_Runner_List,Handler.Market.Non_Runner,Eol);
    loop
      exit when Eol;
      Non_Runner.Marketid := "1." & General_Routines.Trim(Handler.Market.Market_Id'Img);
      Move(To_String(Handler.Market.Non_Runner.Name),Non_Runner.Name);
      Table_Anonrunners.Read(Non_Runner, Eos(Anonrunners));
      if Eos(Anonrunners) then
        Has_Inserted_Winner := True;
        Table_Anonrunners.Insert(Non_Runner);
        Log (Me,"Non_Runner " & To_String(Handler.Market.Non_Runner.Name));
      end if;
      Non_Runners.Get_Next(Handler.Market.Non_Runner_List,Handler.Market.Non_Runner,Eol);
    end loop;

    Sql.Commit (T);
--    Log("----------- Insert_Into_Db stop --------------------");
  exception
    when Sql.Duplicate_Index =>
      Sql.Rollback(T);
      Log (Me, "Duplicate index");
  end Insert_Into_Db;

----------------------------------------------

  My_Reader   : Reader;
  Input       : String_Input;
  Sec         : Ada.Calendar.Day_Duration := Ada.Calendar.Seconds(Ada.Calendar.Clock);
  Ts          : String := "&ts=" & General_Routines.Trim(Integer(Sec)'Img);
  URL : String := "http://rss.betfair.com/RSS.aspx?format=xml" & Ts & "&sportID=";
  URL_HORSES : String := URL & "7";
  URL_HOUNDS : String := URL & "4339";
--  URL_SOCCER : String := URL & "1";
  get_horses : Boolean := True;
  get_hounds : Boolean := True;
--  get_soccer : Boolean := False;
  R : Aws.Response.Data;
begin


    Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");

    Logging.Open(EV.Value("BOT_HOME") & "/log/winners_fetcher.log");
    Logging.New_Log_File_On_Exit(False);

    Define_Switch
     (Cmd_Line,
      Sa_Par_Bot_User'access,
      Long_Switch => "--user=",
      Help        => "user of bot");
    Getopt (Cmd_Line);  -- process the command line

    
    Posix.Daemonize;
    My_Lock.Take(EV.Value("BOT_NAME"));    

    
    
--    Log (Me, "connect db");
  Sql.Connect
        (Host     => Ini.Get_Value("database","host",""),
         Port     => Ini.Get_Value("database","port",5432),
         Db_Name  => Ini.Get_Value("database","name",""),
         Login    => Ini.Get_Value("database","username",""),
         Password => Ini.Get_Value("database","password",""));
--    Log (Me, "connected to db");
--    Log (Me, "Get horses: " & Get_Horses'Img & " Get Hounds: " & Get_Hounds'Img );

    if Get_Horses then
      Log (Me, "Get horses");
      R := Aws.Client.Get(URL      => URL_HORSES,
                          Timeouts =>  Aws.Client.Timeouts (Each => 240.0));

      if String'(Aws.Response.Message_Body(R)) = "Get Timeout" then
        raise Bad_Data with "Get Timout at " & URL_HORSES;
      end if;


      Log (Me, "we have the horses");
--      Log("----------- Start Horses -----------------" );
      My_Reader.Current_Tag := Null_Unbounded_String;
      Open(Aws.Response.Message_Body(R), Unicode.CES.Basic_8bit.Basic_8bit_Encoding,Input);
      My_Reader.Set_Feature(Validation_Feature,False);
      Log (Me, "parse horses");
      My_Reader.Parse(Input);
      Log (Me, "horses parsed");
      Close(Input);
--      Log("----------- Stop Horses -----------------" );
--      Log("");
    end if;

    if Get_Hounds then
      Log (Me, "Get hounds");
      R := Aws.Client.Get(URL      => URL_HOUNDS,
                          Timeouts =>  Aws.Client.Timeouts (Each => 240.0));
      if String'(Aws.Response.Message_Body(R)) = "Get Timeout" then
        raise Bad_Data with "Get Timout at " & URL_HOUNDS;
      end if;

      Log (Me, "we have the hounds");
--      Log("----------- Start Hounds -----------------" );
      My_Reader.Current_Tag := Null_Unbounded_String;
      Open(Aws.Response.Message_Body(R), Unicode.CES.Basic_8bit.Basic_8bit_Encoding,Input);
      My_Reader.Set_Feature(Validation_Feature,False);
      Log (Me, "parse hounds");
      My_Reader.Parse(Input);
      Log (Me, "hounds parsed");
      Close(Input);
--      Log("----------- Stop Hounds -----------------" );
    end if;

    Sql.Close_Session;
--    Log (Me, "db closed");

    if Has_Inserted_Winner then
      declare
          NWARNR      : Bot_Messages.New_Winners_Arrived_Notification_Record;
          Receiver : Process_IO.Process_Type := ((others => ' '), (others => ' '));
      begin
          Move("bot", Receiver.Name);
          Log(Me, "Notifying 'bot' of that new winners are arrived");
          Bot_Messages.Send(Receiver, NWARNR);
      end;
    end if;

    Logging.Close;
    Posix.Do_Exit(0); -- terminate

    exception
  when Lock.Lock_Error =>
    Posix.Do_Exit(0); -- terminate
  when E: others =>
    Stacktrace. Tracebackinfo(E);
    Logging.Close;
--    if Sql.Is_Session_Open then
--      Sql.Close_Session;
--      Log (Me, "db closed");
--    end if;
    Posix.Do_Exit(0); -- terminate
end Winners_Fetcher;

