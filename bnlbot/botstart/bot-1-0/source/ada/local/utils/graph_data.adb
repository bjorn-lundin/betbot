with Gnat.Command_Line; use Gnat.Command_Line;
with Types;    use Types;
--with Gnat.Strings;
with Sql;
with Calendar2; use Calendar2;
--with Logging;               use Logging;
with Text_IO;
with Ini;
with Ada.Containers.Doubly_Linked_Lists;
with  Ada.Environment_Variables;
--with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded;
--with Bot_Types;
with Utils; use Utils;

procedure Graph_Data is
  package EV renames Ada.Environment_Variables;
   Cmd_Line             : Command_Line_Configuration;
   T                    : Sql.Transaction_Type;
   Select_Lapsed_Date   : Sql.Statement_Type;
   Select_Profit_Date   : Sql.Statement_Type;
   
   Ba_Profit       : aliased Boolean := False;
   Ba_Lapsed       : aliased Boolean := False;

   gDebug : Boolean := False;
   Days : Integer_4 := 42;

   type Days_Result_Type is record
     Lapsed       : Integer_4 := 0;
     Settled      : Integer_4 := 0;
     Ts           : Calendar2.Time_Type := Calendar2.Time_Type_First;
   end record;

   type Profit_Result_Type is record
     Profit       : Float_8   := 0.0;
     Size_Matched : Float_8   := 0.0;     
     Ts           : Calendar2.Time_Type := Calendar2.Time_Type_First;
   end record;

   package Days_Result_Pack is new Ada.Containers.Doubly_Linked_Lists(Days_Result_Type);
   Days_Result_List   : Days_Result_Pack.List;
   Days_Result_Record : Days_Result_Type;

   package Profit_Result_Pack is new Ada.Containers.Doubly_Linked_Lists(Profit_Result_Type);
   Profit_Result_List   : Profit_Result_Pack.List;
   Profit_Result_Record : Profit_Result_Type;
   
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
   
   procedure Day_Statistics_Lapsed_vs_Settled(
                 Days   : in     Integer_4;
                 A_List : in out Days_Result_Pack.List) is
     Eos : Boolean := False;
   begin
     Select_Lapsed_Date.Prepare(
       "select count('a'), STARTTS::date " &
       "from ABETS " &
       "where BETNAME='HORSES_PLC_BACK_FINISH_1.10_7.0_1' " &
       "and STATUS = :STATUS " &
       "and STARTTS::date > (select CURRENT_DATE - interval ':SOME days') " &
       "group by STARTTS::date " &
       "order by STARTTS::date " );
 
     Select_Lapsed_Date.Set("STATUS", "SETTLED");
     Select_Lapsed_Date.Set("SOME", Days);
 
     Debug("Start reading dates 1");
     Select_Lapsed_Date.Open_Cursor;
     loop
       Select_Lapsed_Date.Fetch(Eos);
       exit when Eos;
       Select_Lapsed_Date.Get(1,Days_Result_Record.Settled);
       Select_Lapsed_Date.Get_Date(2,Days_Result_Record.Ts);
       A_List.Append(Days_Result_Record);
     end loop;
     Select_Lapsed_Date.Close_Cursor;
     Debug("Stop reading dates 1");
     
     Select_Lapsed_Date.Set("STATUS", "LAPSED");
     Debug("Start reading dates 2");
     Select_Lapsed_Date.Open_Cursor;
     loop
       Select_Lapsed_Date.Fetch(Eos);
       exit when Eos;
       Select_Lapsed_Date.Get(1,Days_Result_Record.Lapsed);
       Select_Lapsed_Date.Get_Date(2,Days_Result_Record.Ts);
       
       for r of A_List loop
         if R.Ts = Days_Result_Record.Ts then
           R.Lapsed := Days_Result_Record.Lapsed;
         end if;
       end loop;
     end loop;
     Select_Lapsed_Date.Close_Cursor;
     Debug("Stop reading dates 2");
   
   end Day_Statistics_Lapsed_vs_Settled;
   
   --------------------------------------------------------
   procedure Day_Statistics_Profit_Vs_Matched(
                 Days   : in     Integer_4;
                 A_List : in out Profit_Result_Pack.List) is
     Eos : Boolean := False;
   begin
     Select_Profit_Date.Prepare(
       "select sum(PROFIT), sum(SIZEMATCHED), STARTTS::date " &
       "from ABETS " &
       "where BETNAME='HORSES_PLC_BACK_FINISH_1.10_7.0_1' " &
       "and STATUS = :STATUS " &
       "and STARTTS::date > (select CURRENT_DATE - interval ':SOME days') " &
       "group by STARTTS::date " &
       "order by STARTTS::date " );
 
     Select_Profit_Date.Set("STATUS", "SETTLED");
     Select_Profit_Date.Set("SOME", Days);
 
     Debug("Start reading dates 1");
     Select_Profit_Date.Open_Cursor;
     loop
       Select_Profit_Date.Fetch(Eos);
       exit when Eos;
       Select_Profit_Date.Get(1,Profit_Result_Record.Profit);
       Select_Profit_Date.Get(2,Profit_Result_Record.Size_Matched);
       Select_Profit_Date.Get_Date(3,Profit_Result_Record.Ts);
       A_List.Append(Profit_Result_Record);
     end loop;
     Select_Profit_Date.Close_Cursor;
     Debug("Stop reading dates 1");
   end Day_Statistics_Profit_Vs_Matched;
   
   

begin

   Define_Switch
     (Cmd_Line,
      Ba_Profit'access,
      Long_Switch => "--profit",
      Help        => "profit stats");

   Define_Switch
     (Cmd_Line,
      Ba_Lapsed'access,
      Long_Switch => "--lapsed",
      Help        => "lapsed stats");

  Getopt (Cmd_Line);  -- process the command line

  Ini.Load(Ev.Value("BOT_HOME") & "/login.ini");

  Debug("Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("database","host",""),
         Port     => Ini.Get_Value("database","port", 5432),
         Db_Name  => Ini.Get_Value("database","name",""),
         Login    => Ini.Get_Value("database","username",""),
         Password => Ini.Get_Value("database","password",""));
  Debug("db Connected");



  T.Start;
    if Ba_Lapsed then
      Day_Statistics_Lapsed_vs_Settled(Days => Days, A_List => Days_Result_List);
    end if;
    if Ba_Profit then   
      Day_Statistics_Profit_Vs_Matched(Days => Days, A_List => Profit_Result_List);
    end if;
  T.Commit;
  Sql.Close_Session;


  for r of Days_Result_List loop
    Print(
      R.Ts.String_Date_ISO & " | " &
      R.Lapsed'img   & " | " &
      R.Settled'img   & " | " &
      F8_Image(Float_8(R.Settled) * 100.0 / Float_8( R.Settled + R.Lapsed )) 
    ) ;
  end loop;

  for r of Profit_Result_List loop
    Print(
      R.Ts.String_Date_ISO & " | " &
      F8_Image(R.Profit) & " | " &
      F8_Image(R.Size_Matched) & " | " &
      F8_Image(R.Profit * 100.0 / R.Size_Matched )        
    ) ;
  end loop;





end Graph_Data;