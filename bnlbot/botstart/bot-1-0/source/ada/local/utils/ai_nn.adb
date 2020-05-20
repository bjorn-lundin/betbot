with Gnat.Command_Line; use Gnat.Command_Line;
with Types;    use Types;
with Gnat.Strings;
with Sql;
with Calendar2; use Calendar2;
--with Logging;               use Logging;
with Text_Io;
with Ini;
with  Ada.Environment_Variables;
--with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
--with Bot_Types;
--with Utils; use Utils;

with Ada.Strings ; use Ada.Strings;
with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
with Stacktrace;
with Table_Amarkets;
with Table_Arunners;

with Ada.Containers.Doubly_Linked_Lists;
with Table_Apriceshistory;


procedure Ai_Nn is
  package Ev renames Ada.Environment_Variables;
  Cmd_Line              : Command_Line_Configuration;
  T                     : Sql.Transaction_Type;
  Select_Runner_With_Price        : Sql.Statement_Type;
  Select_Markets        : Sql.Statement_Type;

  Sa_Startdate        : aliased Gnat.Strings.String_Access;
  Sa_Side             : aliased Gnat.Strings.String_Access;
  Ba_Train_Set        : aliased Boolean := False;

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


  procedure Print(L  : R_Pkg.List ) is
    Cnt         : Integer_4 := 0;
    Winners : array (1..3) of Integer_4 := (others => -1);
  begin
    -- winner but use placeindex instead to get 1-16 for nn and Python uses 0-based arrays
    for R of L loop
      if R.Runner.Status(1) = 'W' then  -- fix for Place later on
        Winners(1) := R.Runner.Sortprio -1;
        Winners(2) := R.Runner.Sortprio -1;
        Winners(3) := R.Runner.Sortprio -1;
        exit;
      end if;
    end loop;

    for R of L loop
      Cnt := Cnt + 1;
      if Cnt = 1 then
        for I in Winners'Range loop
          Text_Io.Put(Winners(I)'img);
          Text_Io.Put(",");
        end loop;
        Text_Io.Put(R.Market.Markettype(1));
        Text_Io.Put(",");
        Text_Io.Put(R.Market.Marketid);
        Text_Io.Put(",");
      end if;

      Text_Io.Put(Float'Image(Float(R.History.Backprice)/1000.0));
      if Cnt < 16 then
        Text_Io.Put(",");
      end if;

      if R.Market.Numrunners < 16 then
        if Cnt = R.Market.Numrunners then
          loop
            Text_Io.Put("0.0"); --No-one, fill up to 16
            if Cnt < 15 then
              Text_Io.Put(",");
            end if;
            Cnt := Cnt +1;
            exit when Cnt = 16;
          end loop;
        end if;

      elsif R.Market.Numrunners = 16 then
        if Cnt > R.Market.Numrunners then
          loop
            Text_Io.Put("0.0"); --No-one, fill up to 16
            if Cnt < 15 then
              Text_Io.Put(",");
            end if;
            Cnt := Cnt +1;
            exit when Cnt = 16;
          end loop;
        end if;
      end if;



      if Cnt = 16 then
        Text_Io.Put_Line("");
        Cnt := 0;
      end if;
    end loop;


  end Print;


  --------------------------------------------------------
  procedure Get_Runner_Data(Market_Data : Table_Amarkets.Data_Type) is
    Eos                : Boolean := False;
    R_List             : R_Pkg.List;
    R_Data             : R_Type;
  begin

    Select_Runner_With_Price.Prepare("select * " &
                                       "from ARUNNERS R, APRICESHISTORY H, AMARKETS M " &
                                       "where 1 = 1 " &
                                       "and H.MARKETID = R.MARKETID " &
                                       "and M.MARKETID = R.MARKETID " &
                                       "and R.MARKETID = :MARKETID " &
                                       "and H.SELECTIONID = R.SELECTIONID " &
                                       "order by H.PRICETS, R.SORTPRIO " );

    Select_Runner_With_Price.Set("MARKETID", Market_Data.Marketid);
    Select_Runner_With_Price.Open_Cursor;
    loop
      Select_Runner_With_Price.Fetch(Eos);
      exit when Eos;
      R_Data.Runner  := Table_Arunners.Get(Select_Runner_With_Price);
      R_Data.History := Table_Apriceshistory.Get(Select_Runner_With_Price);
      R_Data.Market := Table_Amarkets.Get(Select_Runner_With_Price);
      R_List.Append(R_Data);
    end loop;
    Select_Runner_With_Price.Close_Cursor;
    Print(R_List);
  end Get_Runner_Data;
  ------------------------------------------------------

  procedure Get_Market_Data(Market_List  : in out Table_Amarkets.Amarkets_List_Pack2.List) is

  begin

    if Ba_Train_Set then
      Select_Markets.Prepare( "select M.* " &
                               "from AMARKETS M " &
                               "where true " &
                               "and M.MARKETTYPE = 'WIN' " &
                             --  "and M.MARKETID = '1.151516839' " &
                               "and M.NUMRUNNERS >= 8 " &
                               "and M.NUMRUNNERS <= 16 " &
                               "and M.EVENTID not like '%2' " & --use the ones that and with 2 as test sample
                               "order by M.STARTTS");
    else -- to verify with - just 10 %
      Select_Markets.Prepare("select M.* " &
                               "from AMARKETS M " &
                               "where true " &
                               "and M.MARKETTYPE = 'WIN' " &
                           --    "and M.MARKETID = '1.151516839' " &
                               "and M.NUMRUNNERS >= 8 " &
                               "and M.NUMRUNNERS <= 16 " &
                               "and M.EVENTID like '%2' " & --use the ones that and with 2 as test sample
                               "order by M.STARTTS");
    end if;

    Table_Amarkets.Read_List(Select_Markets, Market_List);
  end Get_Market_Data;
  ------------------------------------------------------

  Mlist  :  Table_Amarkets.Amarkets_List_Pack2.List;

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
  Get_Market_Data(Mlist);

  for M of Mlist loop
    Get_Runner_Data(M);
  end loop;

  T.Commit;
  Sql.Close_Session;

exception
  when E: others =>
    Stacktrace.Tracebackinfo(E);
end Ai_Nn;
