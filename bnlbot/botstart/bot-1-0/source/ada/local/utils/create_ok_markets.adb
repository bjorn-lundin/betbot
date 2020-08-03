--with Gnat.Command_Line; use Gnat.Command_Line;
with Types;    use Types;
with Sql;
with Calendar2; use Calendar2;
--with Logging;               use Logging;
with Text_Io;
with Ini;
with  Ada.Environment_Variables;
--with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
--with Bot_Types;
--with Utils; use Utils;

--with Ada.Strings ; use Ada.Strings;
--with Ada.Strings.Fixed ; use Ada.Strings.Fixed;
with Stacktrace;
with Table_Amarkets;
with Table_Okmarkets;



procedure Create_ok_Markets is
  package Ev renames Ada.Environment_Variables;
--  Cmd_Line              : Command_Line_Configuration;
  T                     : Sql.Transaction_Type;
  Select_Markets        : Sql.Statement_Type;
  Select_Num_Samples    : Sql.Statement_Type;


  Gdebug : Boolean := True;


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


  procedure Get_Market_Data(Market_List  : in out Table_Amarkets.Amarkets_List_Pack2.List) is

  begin

      Select_Markets.Prepare( "select M.* " &
                                "from AMARKETS M " &
                                "where true " &
                                "and M.NUMRUNNERS >= 8 " &
                                "and M.NUMRUNNERS <= 16 " &
                                "order by M.STARTTS");

    Table_Amarkets.Read_List(Select_Markets, Market_List);
  end Get_Market_Data;
  ------------------------------------------------------

  procedure Insert_Into_Ok_If_Ok(Market  : in out Table_Amarkets.Data_Type) is
    Ok_Market : Table_Okmarkets.Data_Type;
    Eos       : Boolean := False;
    Num_Samples : Integer_4 := 0;
  begin
    Select_Num_Samples.Prepare("select count('a') CNT from APRICESHISTORY where MARKETID = :MARKETID");
    Select_Num_Samples.Set("MARKETID",Market.Marketid);

    Select_Num_Samples.Open_Cursor;
    Select_Num_Samples.Fetch(Eos);
    if not Eos then
      Select_Num_Samples.Get("CNT", Num_Samples);
    end if;
    Select_Num_Samples.Close_Cursor;

    if Num_Samples / Market.Numrunners > 100 then
      Ok_Market := (
                    Marketid    => Market.Marketid,
                    Eventid     => Market.Eventid,
                    Markettype  => Market.Markettype,
                    Numwinners  => Market.Numwinners,
                    Numrunners  => Market.Numrunners,
                    Ixxlupd     => Market.Ixxlupd,
                    Ixxluts     => Market. Ixxluts);
      Ok_Market.Insert;
    else
      Debug ("Num_Samples" & Num_Samples'img & " num_runners" & Market.Numrunners'Img & " => " & Integer_4'Image( Num_Samples / Market.Numrunners)  );
    end if;

  end Insert_Into_Ok_If_Ok;



  Mlist  :  Table_Amarkets.Amarkets_List_Pack2.List;
  C : Integer_4 := 0;
begin


--  Getopt (Cmd_Line);  -- process the command line


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
    C := C +1;
    if C rem 1000 = 0 then
      Debug(C'Img & " / " & Mlist.length'Img);
    end if;

    Insert_Into_Ok_If_Ok(M);
  end loop;

  T.Commit;
  Sql.Close_Session;

exception
  when E: others =>
    Stacktrace.Tracebackinfo(E);
end Create_ok_Markets;
