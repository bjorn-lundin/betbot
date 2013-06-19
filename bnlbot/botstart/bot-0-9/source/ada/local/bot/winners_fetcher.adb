--with Unchecked_Conversion;
--with Sattmate_Exception;
with Sattmate_Types; use Sattmate_Types;
with Sql;
with Logging; use Logging;
--with Text_Io;
with Simple_List_Class;
pragma Elaborate_All(Simple_List_Class);
with Aws;
with Aws.Client;
with Aws.Response;
with Sax;

with Unicode.CES.Basic_8bit;

with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Sax.Readers;        use Sax.Readers;
with Input_Sources.Strings; use Input_Sources.Strings;
with Unicode.CES;
with Sax.Attributes;

with Sattmate_Exception;
with General_Routines;


with Table_Awinners;
with Table_Anonrunners;

procedure Winners_Fetcher is

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

  procedure Print(Handler : in out Reader) ;
  procedure Insert_Into_Db(Handler : in out Reader) ;

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





  overriding procedure Start_Document (Handler : in out Reader) is
    pragma Unreferenced(Handler);
  begin
    Change_Indent(2);
    Log(Indent & "--------------------------" );
    Log(Indent & "Start_Document" );
  end Start_Document;

  overriding procedure End_Document (Handler : in out Reader) is
    pragma Unreferenced(Handler);
  begin
    Log(Indent & "--------------------------" );
    Log(Indent & "End_Document"  );
    Change_Indent(-2);
  end End_Document;



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
--    Print(Handler);
    Insert_Into_Db(Handler);
    end if;

  end End_Element;
  --++--++--++--++--++--++--++--++--++--++--++--++--++--

  procedure Characters(Handler : in out Reader;
                       Ch      : Unicode.CES.Byte_Sequence := "") is
    The_Tag   : constant String := To_String(Handler.Current_Tag);
    use General_Routines;
  begin
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

  begin
    Log(Indent & "Ignorable_Whitespace event " & The_Tag & " The_Value  |" & Ch & "|");
  end Ignorable_Whitespace;
----------------------------------------------

  procedure Print(Handler : in out Reader) is
  --  use Logging;
    Eol : Boolean := False;
  begin
    Log("-------------------------------");
    Log("Market_Id    " & Handler.Market.Market_Id'Img);
    Log("Display_Name " & To_String(Handler.Market.Display_Name));
    Log("Market_Type " & To_String(Handler.Market.Market_Type));
    
    Selections.Get_First(Handler.Market.Selection_List,Handler.Market.Selection,Eol);
    loop
      exit when Eol;
      Log("Selection" & Handler.Market.Selection.Id'Img & " " & To_String(Handler.Market.Selection.Name));
      Selections.Get_Next(Handler.Market.Selection_List,Handler.Market.Selection,Eol);
    end loop;
    
    Non_Runners.Get_First(Handler.Market.Non_Runner_List,Handler.Market.Non_Runner,Eol);
    loop
      exit when Eol;
      Log("Non_Runner " & To_String(Handler.Market.Non_Runner.Name));
      Non_Runners.Get_Next(Handler.Market.Non_Runner_List,Handler.Market.Non_Runner,Eol);
    end loop; 
    
    Print("");
  end Print;
  
  
  procedure Insert_Into_Db(Handler : in out Reader) is
    T          : Sql.Transaction_Type;
    Winner     : Table_Awinners.Data_Type;
    Non_Runner : Table_Anonrunners.Data_Type;
    type Eos_Type is (Awinners, Anonrunners);
    Eos : array (Eos_Type'range) of Boolean := (others => False);
    Eol : Boolean := False;
  begin
    Log("----------- Insert_Into_Db start --------------------");
    Sql.Start_Read_Write_Transaction (T);
    Selections.Get_First(Handler.Market.Selection_List,Handler.Market.Selection,Eol);
    loop
      exit when Eol;
      Winner.Marketid := "1." & General_Routines.Trim(Handler.Market.Market_Id'Img);      
      Winner.Selectionid := Handler.Market.Selection.Id;
      Table_Awinners.Read(Winner, Eos(Awinners));
      if not Eos(Awinners) then
        Table_Awinners.Insert(Winner);
        Log("Selection" & Handler.Market.Selection.Id'Img & " " & To_String(Handler.Market.Selection.Name));
      end if;            
      Selections.Get_Next(Handler.Market.Selection_List,Handler.Market.Selection,Eol);
    end loop;
    
    Non_Runners.Get_First(Handler.Market.Non_Runner_List,Handler.Market.Non_Runner,Eol);
    loop
      exit when Eol;
      Non_Runner.Marketid := "1." & General_Routines.Trim(Handler.Market.Market_Id'Img);      
      Move(To_String(Handler.Market.Non_Runner.Name),Non_Runner.Name);
      Table_Anonrunners.Read(Non_Runner, Eos(Anonrunners));
      if not Eos(Anonrunners) then
        Table_Anonrunners.Insert(Non_Runner);
        Log("Non_Runner " & To_String(Handler.Market.Non_Runner.Name));
      end if;      
      Non_Runners.Get_Next(Handler.Market.Non_Runner_List,Handler.Market.Non_Runner,Eol);
    end loop; 
    
    Sql.Commit (T);    
    Log("----------- Insert_Into_Db stop --------------------");
  exception
    when Sql.Duplicate_Index =>
      Sql.Rollback(T);
      Log("Duplicate index on");
      Print(Handler);
  end Insert_Into_Db;

  
----------------------------------------------

  My_Reader   : Reader;
  Input       : String_Input;

  URL : String := "http://rss.betfair.com/RSS.aspx?format=xml&sportID=";
  URL_HORSES : String := URL & "7";
  URL_HOUNDS : String := URL & "4339";
--  URL_SOCCER : String := URL & "1";
  get_horses : Boolean := True;
  get_hounds : Boolean := True;
--  get_soccer : Boolean := False;
  R : Aws.Response.Data;
  
begin

    Sql.Connect
        (Host     => "192.168.0.13",
         Port     => 5432,
         Db_Name  => "betting",
         Login    => "bnl",
         Password => "bnl");


    if Get_Horses then
      R := Aws.Client.Get(URL => URL_HORSES);
      Log("----------- Start Horses -----------------" );
      My_Reader.Current_Tag := Null_Unbounded_String;
      Open(Aws.Response.Message_Body(R), Unicode.CES.Basic_8bit.Basic_8bit_Encoding,Input);
      My_Reader.Set_Feature(Validation_Feature,False);
      My_Reader.Parse(Input);
      Close(Input);
      Log("----------- Stop Horses -----------------" );
      Log("");
    end if;

    if Get_Hounds then    
      R := Aws.Client.Get(URL => URL_HOUNDS);
      Log("----------- Start Hounds -----------------" );
      My_Reader.Current_Tag := Null_Unbounded_String;
      Open(Aws.Response.Message_Body(R), Unicode.CES.Basic_8bit.Basic_8bit_Encoding,Input);
      My_Reader.Set_Feature(Validation_Feature,False);
      My_Reader.Parse(Input);
      Close(Input);
      Log("----------- Stop Hounds -----------------" );
      Log("");
    end if;

    Sql.Close_Session;
    
exception
  when E: others =>
    Sattmate_Exception. Tracebackinfo(E);
end Winners_Fetcher;

