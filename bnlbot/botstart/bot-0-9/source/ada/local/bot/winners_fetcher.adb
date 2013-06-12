--with Unchecked_Conversion;
--with Sattmate_Exception;
with Sattmate_Types; use Sattmate_Types;
with Sql;
with Logging; use Logging;
with Races;
with Text_Io;
with Simple_List_Class;
pragma Elaborate_All(Simple_List_Class);
with Aws;
with Aws.Client;
with Aws.Response;
with Sax;
with ada.strings.unbounded ; use ada.strings.unbounded;

with Ada.Text_Io;

with Unicode.CES.Basic_8bit;

with Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Sax.Readers;        use Sax.Readers;
with Input_Sources.Strings; use Input_Sources.Strings;
with Unicode.CES;
with Sax.Attributes;

with Sattmate_Exception;

with General_Routines;

procedure Winners_Fetcher is




  type Selection_Type is record
    Id   : Integer_4 := 0;
    Name : Unbounded_String     := Null_Unbounded_String;
  end record;
  Empty_Selection : Selection_Type;
  package Selections is new Simple_List_Class(Selection_Type);

  type Non_Runner_Type is record
    Name      : Unbounded_String     := Null_Unbounded_String;
  end record;
  Empty_Non_Runner : Non_Runner_Type;

  package Non_Runners is new Simple_List_Class(Non_Runner_Type);

  --------------------------
  Global_Indent : Integer := 0;

  procedure Change_Indent(How_Much : Integer) is
  begin
    Global_Indent := Global_Indent + How_Much;
  end Change_Indent;

  function Indent return String is
    S : String (1..Global_Indent) := (others => ' ');
  begin
    return S;
  end Indent;


  type Market_Type is record
     Market_Id          : Integer_4           := 0;
     Display_Name      : Unbounded_String     := Null_Unbounded_String;
     Market_Type       : Unbounded_String     := Null_Unbounded_String;
--     Country_Id        : Unbounded_String     := Null_Unbounded_String;
--     Country_Name      : Unbounded_String     := Null_Unbounded_String;
     Selection         : Selection_Type ;
     Selection_List    : Selections.List_Type := Selections.Create;
     Non_Runner        : Non_Runner_Type;
     Non_Runner_List   : Non_Runners.List_Type := Non_Runners.Create;
--     Bet_Type          : Unbounded_String     := Null_Unbounded_String;
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

  procedure Print(Handler : in out Reader) ;




  overriding procedure Start_Document (Handler : in out Reader) is
  begin
    Change_Indent(2);
    Ada.Text_Io.Put_Line(Indent & "--------------------------" );
    Ada.Text_Io.Put_Line(Indent & "Start_Document" );
  end Start_Document;

  overriding procedure End_Document (Handler : in out Reader) is
  begin
    Ada.Text_Io.Put_Line(Indent & "--------------------------" );
    Ada.Text_Io.Put_Line(Indent & "End_Document"  );
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
--    Change_Indent(2);
--    Ada.Text_Io.Put_Line(Indent & "--------------------------" );
--    Ada.Text_Io.Put_Line(Indent & "Start_Element " & The_Tag );
--    for i in 0 .. Atts.Get_Length -1 loop
--      Ada.Text_Io.Put_Line(Indent & "Dynamic check : Attribute: " & Atts.Get_Local_Name(i) & " has value: " & Atts.Get_Value(i));
--    end loop;




    if The_Tag = "market" then
      Handler.Market := Empty_Market ;-- reset
      Handler.Market.Market_Id := Integer_4'Value(Atts.Get_Value("id"));
      Handler.Market.Display_Name := To_Unbounded_String(Atts.Get_Value("displayName"));
--    elsif The_Tag = "country" then
--      Handler.Market.Country_Id := To_Unbounded_String(Atts.Get_Value("countryID"));
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
--    Ada.Text_Io.Put_Line(Indent & "End_Element " & The_Tag );
--    Ada.Text_Io.Put_Line(Indent & "--------------------------" );
--    Change_Indent(-2);

    if The_Tag = "winner" then
      Selections.Insert_At_Tail(Handler.Market.Selection_List,Handler.Market.Selection);
    elsif The_Tag = "nonRunner" then
      Non_Runners.Insert_At_Tail(Handler.Market.Non_Runner_List,Handler.Market.Non_Runner);
    elsif The_Tag = "market" then
    Print(Handler);
    end if;

  end End_Element;
  --++--++--++--++--++--++--++--++--++--++--++--++--++--

  procedure Characters(Handler : in out Reader;
                       Ch      : Unicode.CES.Byte_Sequence := "") is
    The_Tag   : constant String := To_String(Handler.Current_Tag);
    use General_Routines;
  begin
--    Change_Indent(2);
--    Ada.Text_Io.Put_Line(Indent & "Characters event " & The_Tag & " The_Value  |" & Ch & "|");
--    Change_Indent(-2);

--    if The_Tag = "country" then
--      Handler.Market.Country_Name := Handler.Market.Country_Name & To_Unbounded_String(Trim(Ch));
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
    Ada.Text_Io.Put_Line(Indent & "Ignorable_Whitespace event " & The_Tag & " The_Value  |" & Ch & "|");
  end Ignorable_Whitespace;
----------------------------------------------

  procedure Print(Handler : in out Reader) is
    use Text_Io;
  begin
    Put_Line("-------------------------------");
    Put_Line("Market_Id    " & Handler.Market.Market_Id'Img);
    Put_Line("Display_Name " & To_String(Handler.Market.Display_Name));
    Put_Line("Market_Type " & To_String(Handler.Market.Market_Type));
--    Put_Line("Country_Id " & To_String(Handler.Market.Country_Id));
--    Put_Line("Country_Name " & To_String(Handler.Market.Country_Name));
--    Put_Line("Bet_Type " & To_String(Handler.Market.Bet_Type));
    while not Selections.Is_Empty(Handler.Market.Selection_List) loop
      Selections.Remove_From_Head(Handler.Market.Selection_List,Handler.Market.Selection);
      Put_Line("Selection" & Handler.Market.Selection.Id'Img & " " & To_String(Handler.Market.Selection.Name));
    end loop;

    while not Non_Runners.Is_Empty(Handler.Market.Non_Runner_List) loop
      Non_Runners.Remove_From_Head(Handler.Market.Non_Runner_List,Handler.Market.Non_Runner);
      Put_Line("Non_Runner " & To_String(Handler.Market.Non_Runner.Name));
    end loop;
    New_Line;
  end Print;



  My_Reader   : Reader;
  Input       : String_Input;

  URL : String := "http://rss.betfair.com/RSS.aspx?format=xml&sportID=";
  URL_HORSES : String := URL & "7";
  URL_HOUNDS : String := URL & "4339";
  URL_SOCCER : String := URL & "1";
  get_horses : Boolean := True;
  get_hounds : Boolean := True;
  get_soccer : Boolean := False;
  R : Aws.Response.Data;
begin

       R :=  Aws.Client.Get(URL => URL_HORSES);

--    Ada.Text_Io.Put_Line("Xml :" );
--    Ada.Text_Io.Put_Line(Xml_Str);
--    Ada.Text_Io.New_Line;
--    Ada.Text_Io.New_Line;

    Ada.Text_Io.Put_Line("----------- Start 1 -----------------" );
    My_Reader.Current_Tag := Null_Unbounded_String;
    Open(Aws.Response.Message_Body(R), Unicode.CES.Basic_8bit.Basic_8bit_Encoding,Input);
    My_Reader.Set_Feature(Validation_Feature,False);
    My_Reader.Parse(Input);
    Close(Input);
    Ada.Text_Io.Put_Line("----------- Stop 1 -----------------" );
    Ada.Text_Io.Put_Line("");

exception
  when E: others =>
    Sattmate_Exception. Tracebackinfo(E);
end Winners_Fetcher;

