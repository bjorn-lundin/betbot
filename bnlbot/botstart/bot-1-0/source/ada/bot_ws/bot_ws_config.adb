------------------------------------------------------------------------------
--
--	COPYRIGHT	Consafe Logistics AB
--
--	FILE NAME	Mobile_Ws_CONFIG.ADB
--
--	RESPONSIBLE	Ann-Charlotte Andersson
--
--	DESCRIPTION	Body of the Mobile WebServer configuration package
--
-------------------------------------------------------------------------------
--Version     Author    Date      Description
--------------------------------------------------------------------------------
-- 9.23500    AEA       8-Dec-11 Original version
--------------------------------------------------------------------------------
with Input_Sources.File; use Input_Sources.File;
with DOM.Readers; use DOM.Readers;
with DOM.Core; use DOM.Core;
with DOM.Core.Nodes; use DOM.Core.Nodes;
with Mckae.Xml.XPath.XIA;
with Ada.Characters.Handling;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
use Ada.Strings;
with System_Services;
with Log_Handler;
with Sattmate_Types; use Sattmate_Types;
with SattMate_Exception;
with Sattmate_Calendar;
with Text_Io;
with Process_Io;

package body Mobile_Ws_Config is

  package Xpath renames Mckae.Xml.XPath.XIA; 

  type Process_Log_Record_Type is
    record
      Enabled   : Boolean               := TRUE;
      File_Type : Log_Handler.File_Type := Log_Handler.Circular;
      Filename  : String(1..80)         := (others => ' ');
      Max_Lines : Natural               := 10000;
      Level     : Natural               := 1;
    end record;
 
  
  type Login_Record_Type is 
    record
      Host           : Unbounded_String := Null_Unbounded_String;
      Port           : Natural := 0;
      Db_Profile_Key : Unbounded_String := Null_Unbounded_String;
    end record;

  Process_Log_Record        : Process_log_Record_Type;
  Server_Port               : Natural := 0;
  Max_Connections           : Positive := 10;
  Session_Cleanup_Interval  : Duration := 900.0;
  Session_Lifetime          : Duration := 3600.0;
  UseSession                : Boolean := false;
  UseLogfile                : Boolean := false;
  Root_Directory            : String(1..120) := (others => ' ');
  Default_Page              : String(1..80) := (others => ' ');
  Xml_Header                : String(1..300) := (others => ' ');
  WSLog_Directory           : String(1..120) := (others => ' ');
  Login_Record              : Login_Record_Type;
  Default_Language          : String(1..3) := (others => ' ');
  Mobile_Noun               : Natural := 0;
  Mobile_Verb               : Natural := 0;
  Encoding_Name             : String(1..20) := (others => ' ');

  --v10.2#2550 New function
  function Resolve_Port(Str_Port : string ) return natural is
    ------
    function Expand_Env(Str_Port : string ) return natural is
      pragma Warnings(Off, Str_Port);
      My_Port_Name : constant String := "SATTMATE_PORT_" & Trim(Process_Io.This_Process.Name, both);
    begin
      return Natural'Value(System_Services.Get_Symbol(My_Port_Name));
    exception
      when others => raise Configuration_Error; 
    end;
    ------
  begin
    return Natural'Value(Str_Port);
  exception
    when Constraint_Error => 
      return Expand_Env(Str_Port);
  end Resolve_Port;

  procedure Read_Configuration_File is
    type Parent_Node_Type is (Process_Log, Webserver, Filepaths, Login, UserData, Encoding);
  
    Input      : File_Input;
    Reader     : Tree_Reader;
    Doc        : Document;
    Config_Dir : constant string := System_Services.Expand_File_Path(
                                       System_Services.Get_Symbol("SATTMATE_CONFIG") & "/processes/");
    My_Name : constant String := Process_Io.This_Process.Name;  

    procedure Get_Boolean(S : in String; B : in out boolean) is
    begin
      B := Boolean'value(S);
    exception
      when E: others => Sattmate_Exception.Tracebackinfo (E, Abort_Program => False);
    end Get_Boolean;

    procedure Get_Natural(S : in String; N : in out natural) is
    begin
      N := Natural'value(S);
    exception
      when E: others => Sattmate_Exception.Tracebackinfo (E, Abort_Program => False);
    end Get_Natural;

    procedure Get_Duration(S : in String; D : in out duration) is
    begin
      D :=  duration(Sattmate_Types.float_8'value(S));
    exception
      when E: others => Sattmate_Exception.Tracebackinfo (E, Abort_Program => False);
    end Get_Duration;

    procedure Get_Positive(S : in String; P : in out positive) is
    begin
      P := Positive'value(S);
    exception
      when E: others => Sattmate_Exception.Tracebackinfo (E, Abort_Program => False);
    end Get_Positive;

    procedure Get_Configuration(Envelope : in String; P_Node : Parent_Node_Type) is

      Queried_Nodes, Children : Node_List;
      N, Child                : Node;
    begin
      Queried_Nodes := XPath.Xpath_Query(Doc, Envelope);
      for I in 0 .. Nodes.Length(Queried_Nodes) - 1 loop
        N := Dom.Core.Nodes.Item(Queried_Nodes, I);
        if N.Node_Type = Element_Node then
          Children := Child_Nodes(N);
          for J in 0..Nodes.Length(Children)-1 loop
            Child := Nodes.Item(Children, J);
            if (Has_Child_Nodes(Child)) then
              case P_Node is
                when Process_Log =>
                  if Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "FILENAME" then
                     Move(System_Services.Expand_File_Path(Node_Value (First_Child(Child))), Process_Log_Record.Filename,
                          DROP => Right);
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "LEVEL" then
                    Get_Natural(Node_Value (First_Child(Child)), Process_Log_Record.Level);
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "FILETYPE" then
                    Process_Log_Record.File_Type := Log_Handler.File_Type'value(Node_Value (First_Child(Child)));
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "MAXLINES" then
                    Get_Natural(Node_Value (First_Child(Child)), Process_Log_Record.Max_Lines);
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "ENABLED" then
                    Get_Boolean(Node_Value (First_Child(Child)), Process_Log_Record.Enabled);
                  end if; 
                when Webserver =>
                  if Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "PORT" then
                    -- v10.2#2550 Get_Natural(Node_Value (First_Child(Child)), Server_Port);
                    Server_Port := Resolve_Port(Node_Value (First_Child(Child)));  --v10.2#2550
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "MAXCONNECTIONS" then
                    Get_Positive(Node_Value (First_Child(Child)), Max_Connections);
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "SESSIONCLEANUPINTERVAL" then
                    Get_Duration(Node_Value (First_Child(Child)), Session_Cleanup_Interval);
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "SESSIONLIFETIME" then
                    Get_Duration(Node_Value (First_Child(Child)), Session_Lifetime);
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "USESESSION" then
                    Get_Boolean(Node_Value (First_Child(Child)), UseSession);
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "USELOGFILE" then
                    Get_Boolean(Node_Value (First_Child(Child)), UseLogFile);
                  end if;
                when Filepaths =>
                  if Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "DOCROOT" then
                    Move(System_Services.Expand_File_Path(Node_Value (First_Child(Child))), Root_Directory,
                         DROP => Right);
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "WEBSERVERLOGPATH" then
                    Move(System_Services.Expand_File_Path(Node_Value (First_Child(Child))), WSLog_Directory,
                         DROP => Right);
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "DEFAULTPAGE" then
                    Move(System_Services.Expand_File_Path(Node_Value (First_Child(Child))), Default_Page,
                         DROP => Right);
                  end if;
                when Login =>
                  if Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "HOST" then
                    Login_Record.Host := To_Unbounded_String(Node_Value (First_Child(Child)));
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "PORT" then
                    Get_Natural(Node_Value (First_Child(Child)), Login_Record.Port);
--                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "DBPROFILEKEY" then
--                    Login_Record.Db_Profile_Key := To_Unbounded_String(Node_Value (First_Child(Child)));
                  end if;
                when UserData =>
                  if Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "DEFAULTLANG" then
                    Move(Node_Value(First_Child(Child)), Default_Language, DROP => Right);
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "MOBILENOUN" then
                    Get_Natural(Node_Value (First_Child(Child)), Mobile_Noun);
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "MOBILEVERB" then
                    Get_Natural(Node_Value (First_Child(Child)), Mobile_Verb);
                  end if;
                when Encoding =>
                  if Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "ENCODINGNAME" then
                    Move(Node_Value(First_Child(Child)), Encoding_Name, DROP => Right);
                  elsif Ada.Characters.Handling.To_Upper(Node_Name(Child)) = "HEADER" then
                    Move(Node_Value(First_Child(Child)), Xml_Header, DROP => Right);
                  end if;
              end case;
            end if;
          end loop;
        end if;
      end loop;
      Free(Children);
      Free(Queried_Nodes);
    exception
      when E: others => 
        Sattmate_Exception.Tracebackinfo (E, Abort_Program => False);
        Free(Children);
        Free(Queried_Nodes);
    end Get_Configuration;

  begin
    Open (Config_Dir & "mobile_ws_config.xml", Input);
    DOM.Readers.Parse (Reader, Input);
    Doc := Get_Tree (Reader);
    Close(Input);                                      
    Get_Configuration("/Process/ALL/Process_Log", Process_Log);
    Get_Configuration("/Process/ALL/Encoding", Encoding);
    Get_Configuration("/Process/ALL/Filepaths", Filepaths);
    Get_Configuration("/Process/ALL/Login", Login);
    Get_Configuration("/Process/ALL/Webserver", Webserver);
    Get_Configuration("/Process/ALL/UserData", UserData);

    Get_Configuration("/Process/" & My_Name & "/Process_Log", Process_Log);
    Get_Configuration("/Process/" & My_Name & "/Encoding", Encoding);
    Get_Configuration("/Process/" & My_Name & "/Filepaths", Filepaths);
    Get_Configuration("/Process/" & My_Name & "/Login", Login);
    Get_Configuration("/Process/" & My_Name & "/Webserver", Webserver);
    Get_Configuration("/Process/" & My_Name & "/UserData", UserData);
    if (Server_Port = 0) then          -- v10.2#2550
      Server_Port := Resolve_Port(""); -- v10.2#2550
    end if;                            -- v10.2#2550
 exception
--    when Configuration_Error => raise;  -- v10.2#2550
    when E: others => Sattmate_Exception.Tracebackinfo (E, Abort_Program => False);
  end Read_Configuration_File;

  procedure Open_Process_Log is
  begin
   if Process_Log_Record.Enabled then
      Log_Handler.Open(File => Process_Log_Record.File_Type, 
                       Name => Process_Log_Record.Filename,
                       Max_Lines => Process_Log_Record.Max_Lines,
                       Level     => Process_Log_Record.Level);
    end if;
  end Open_Process_Log;

  procedure Close_Process_Log is
  begin
    if Log_handler.Is_Open(Process_Log_Record.File_Type) then
      Log_Handler.Close(File => Process_Log_Record.File_Type);
    end if;
  end Close_Process_Log;

  procedure Initiate is
  begin
    Read_Configuration_File;
    Open_Process_Log;
  end Initiate;

  procedure Close is
  begin
    Close_Process_Log;
  end Close;

  procedure Process_Log_Put(Id   : in String; Text : in String) is
  begin
    Log_Handler.Put(Process_Log_Record.Level, Id, Text);
  end Process_Log_Put;

  function Get_Port return Natural is
  begin
    return Server_Port;
  end Get_Port;

  function Get_Max_Connections return Positive is
  begin
    return Max_Connections;
  end Get_Max_Connections;

  function Get_Session_Cleanup_Interval return Duration is
  begin
    return Session_Cleanup_Interval;
  end Get_Session_Cleanup_Interval;

  function Get_Session_Lifetime return Duration is
  begin 
    return Session_Lifetime;
  end Get_Session_Lifetime;

  function DoUseSession return Boolean is
  begin
    return UseSession;
  end DoUseSession;

  function DoUseLogfile return Boolean is
  begin
    return UseLogfile;
  end DoUseLogfile;

  function Get_Default_Page return String is
  begin
    return Trim(Default_Page, Right);
  end Get_Default_Page;

  function Get_DocRoot return String is
  begin
    return Trim(Root_Directory, Right);
  end Get_DocRoot;

  function Get_WebServerLogPath return String is
  begin
    return Trim(WSLog_Directory, Right);
  end Get_WebServerLogPath;

  function Get_Xml_Header return String is
  begin
    return "<" & Trim(Xml_Header, Right) & ">";
  end Get_Xml_Header;

  procedure OutFile_Put(Id   : in String; Text : in String) is
  begin
    Text_Io.Put_Line(Sattmate_Calendar.String_Date_And_Time(Sattmate_Calendar.Clock)  &
                                                            ' ' & Id & ' ' & Text);
  end OutFile_Put;


  function Get_Login_Host return String is
  begin
    return To_String(Login_Record.Host);
  end Get_Login_Host;

  function Get_Login_Port return Natural is
  begin
    return Login_Record.Port;
  end Get_Login_Port;

  function Get_Login_Db_Profile_Key return String is
  begin
--    return To_String(Login_Record.Db_Profile_Key);
    return System_Services.Get_Symbol("APPLICATION_NAME");
  end Get_Login_Db_Profile_Key;

  function Get_Default_Language return String is
  begin
    return Default_Language;
  end Get_Default_Language;
  
  function Get_Mobile_Noun return Natural is
  begin
    return Mobile_Noun;
  end Get_Mobile_Noun;

  function Get_Mobile_Verb return Natural is
  begin
    return Mobile_Verb;
  end Get_Mobile_Verb;

  function Get_Encoding return Unicode.Encodings.Unicode_Encoding  is
  begin
    return Unicode.Encodings.Get_By_Name(Trim(Encoding_Name, Right));
  end Get_Encoding;

end Mobile_Ws_Config;