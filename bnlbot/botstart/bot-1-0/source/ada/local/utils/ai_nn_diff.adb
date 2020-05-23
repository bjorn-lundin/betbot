with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Sql;
with Calendar2; use Calendar2;
with Logging;               use Logging;
with Text_Io;
with Ini;
with  Ada.Environment_Variables;
--with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
with Gnatcoll.Json; use Gnatcoll.Json;

with Ada.Strings ; use Ada.Strings;
with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
with Stacktrace;
with Table_Amarkets;
with Table_Arunners;

with Ada.Containers.Doubly_Linked_Lists;
with Table_Apriceshistory;

with Aws;
with Aws.Headers;
--with Aws.Headers.Set;
with Aws.Response;
with Aws.Client;
pragma Elaborate_All (Aws.Headers);

with Gnat; use Gnat;
with Gnat.Awk;


procedure Ai_Nn_Diff is
  package Ev renames Ada.Environment_Variables;
  Cmd_Line              : Command_Line_Configuration;
  T                     : Sql.Transaction_Type;

  Sa_Startdate        : aliased Gnat.Strings.String_Access;
  Sa_Side             : aliased Gnat.Strings.String_Access;
  Ba_Train_Set        : aliased Boolean := False;
  Ba_Layprice         : aliased Boolean := False;

  Global_Start_Date    : Time_Type := Time_Type_First;
  pragma Unreferenced(Global_Start_Date);

  Global_Side          : String (1..4) := "BOTH";

  Gdebug : Boolean := True;



  type R_Type is record
    Runner  : Table_Arunners.Data_Type;
    --  Price   : Table_Aprices.Data_Type;
    History : Table_Apriceshistory.Data_Type;

    Market  : Table_Amarkets.Data_Type;
  end record;

  package R_Pkg is new Ada.Containers.Doubly_Linked_Lists(R_Type);

  type Odds_Type is (Previous, Current, Diff);
  Odds : array(Odds_Type'Range,1..16) of Float := (others => (others => 0.0));

  -------------------------------
  procedure Debug (What : String) is
  begin
    if Gdebug then
      Text_Io.Put_Line (Text_Io.Standard_Error, Calendar2.String_Date_Time_Iso (Clock, " " , "") & " " & What);
    end if;
  end Debug;
  pragma Warnings(Off, Debug);
  -------------------------------
  procedure Print (What : String) with Unreferenced is
  begin
    Text_Io.Put_Line (What);
  end Print;
  -------------------------------



  function  Get_Json_Reply (Query : in Json_Value) return Boolean is
    Aws_Reply    : Aws.Response.Data;
    Http_Headers : Aws.Headers.List := Aws.Headers.Empty_List;
    Data         : String := Query.Write;
    Me           : String := "Get_JSON_Reply";
    Post_Timeout :  exception;
  begin
    Aws.Headers.Add (Http_Headers, "Accept", "application/json");
    Aws.Headers.Add (Http_Headers, "Content-Length", Data'Length'Img);

    Log(Me  & "Get_JSON_Reply", "posting: " & Data);
    Aws_Reply := Aws.Client.Post (Url          => "http://192.168.1.136:8080",
                                  Data         => Data,
                                  Content_Type => "application/json",
                                  Headers      => Http_Headers,
                                  Timeouts     => Aws.Client.Timeouts (Each => 30.0));
    Log(Me & "Get_JSON_Reply", "Got reply, check it ");

    declare
      Reply : String := Aws.Response.Message_Body(Aws_Reply);
    begin

      if Reply /= "Post Timeout" then
        Log(Me & "Get_JSON_Reply", "Got reply: " & Reply  );
        return Reply = "1";
      else
        Log(Me & "Get_JSON_Reply", "Post Timeout -> Give up!");
        raise Post_Timeout ;
      end if;
    exception
      when Post_Timeout => raise;
      when others =>
        Log(Me & "Get_JSON_Reply", "***********************  Bad reply start *********************************");
        Log(Me & "Get_JSON_Reply", "Bad reply" & Aws.Response.Message_Body(Aws_Reply));
        Log(Me & "Get_JSON_Reply", "***********************  Bad reply stop  ********" );
        return False;
    end;

  end Get_Json_Reply;
  ------------------------------------------------------------------------------





  procedure Parse_File is
    Do_Bet        : Boolean := False;
    Computer_File : Awk.Session_Type;
    First         : Boolean := True;
    Cnt : Integer := 0;
  begin
    Awk.Set_Current (Computer_File);
    Awk.Open (Separators => ",",
              Filename   => Ev.Value("BOT_HISTORY") & "/data/ai/pong/lay/win/sample/1.167829004.csv");

    while not Awk.End_Of_File loop
      Awk.Get_Line;
      --declare
      if First then
        for I in 1..16 loop
          Odds(Previous,I) := 0.0;
        end loop;
        Do_Bet := False;
      end if;
      Cnt := Cnt +1;


      declare
        Params        : Json_Value := Create_Object;
        Odds_Diff     : Json_Array := Empty_Array;
        Odds_Curr     : Json_Array := Empty_Array;
      begin

        for I in 1..16 loop
          Odds(Current,I) := Float'Value(Awk.Field(Awk.Count(I+5)));
          Odds(Diff,I) := Odds(Current,I) - Odds(Previous,I);
          Append(Odds_Diff, Create(Odds(Diff,I)));
          Append(Odds_Curr, Create(Odds(Current,I)));
          Odds(Previous,I) := Odds(Current,I);
        end loop;

        Params.Set_Field (Field_Name => "odds", Field => Odds_Diff);
        Params.Set_Field (Field_Name => "curr", Field => Odds_Curr);
        Params.Set_Field (Field_Name => "winner", Field => Create(Long_Long_Integer'Value(Awk.Field(1))));

        if not First then
          Do_Bet := Get_Json_Reply(Params);
        else
          First := False;
        end if;

      end;

      exit when Do_Bet;
     -- exit when cnt >= 5;

    end loop;
    Awk.Close (Computer_File);

  end Parse_File;




  ----------------------------------

begin

  Define_Switch
    (Cmd_Line,
     Sa_Side'Access,
     Long_Switch => "--side=",
     Help        => "side (LAY/BACK) - BOTH are default");

  Define_Switch
    (Cmd_Line,
     Sa_Startdate'Access,
     Long_Switch => "--startdate=",
     Help        => "startdate");

  Define_Switch
    (Cmd_Line,
     Ba_Train_Set'Access,
     Long_Switch => "--trainset",
     Help        => "Trainset - otherwise sample set");

  Define_Switch
    (Cmd_Line,
     Ba_Layprice'Access,
     Long_Switch => "--layprice",
     Help        => "Layprices - otherwise backprices");


  Getopt (Cmd_Line);  -- process the command line

  if Sa_Startdate.all /= "" then
    declare
      S : String (1 .. Sa_Startdate.all'Length) := Sa_Startdate.all;
    begin
      Global_Start_Date.Year := Year_Type'Value(S(1..4));
      Global_Start_Date.Month := Month_Type'Value(S(6..7));
      Global_Start_Date.Day := Day_Type'Value(S(9..10));
    end;
  end if;

  if Sa_Side.all /= "" then
    Move(Sa_Side.all, Global_Side);
  end if;

  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");

  Debug("Connect Db");
  Sql.Connect
    (Host     => Ini.Get_Value("database","host",""),
     Port     => Ini.Get_Value("database","port", 5432),
     Db_Name  => Ini.Get_Value("database","name",""),
     Login    => Ini.Get_Value("database","username",""),
     Password => Ini.Get_Value("database","password",""),
     Ssl_Mode => "prefer");
  Debug("db Connected");

  T.Start;
  Parse_File;
  T.Commit;
  Sql.Close_Session;

exception
  when E: others =>
    Stacktrace.Tracebackinfo(E);
end Ai_Nn_Diff;
