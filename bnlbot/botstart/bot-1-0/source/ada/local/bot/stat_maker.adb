with Ada.Exceptions;
with Ada.Command_Line;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Environment_Variables;
with Text_io;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;


with Stacktrace;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Sql;
with Calendar2; use Calendar2;
with Ini;
with Statistics;
with Utils; use Utils;
with Table_Abets;

procedure  Stat_Maker is
  package EV renames Ada.Environment_Variables;
  
  
  s : Statistics.Stats_Array_Type;
  
  T : Sql.Transaction_Type;
  
  Bet_List : Table_Abets.Abets_List_Pack2.List;
  
  FO: Statistics.First_Odds_Range_Type;
  SO: Statistics.Second_Odds_Range_Type;
  GMT,MT: Statistics.Market_Type;

  Cmd_Line           : Command_Line_Configuration;
  Sa_Par_Market_Type : aliased Gnat.Strings.String_Access;

  
begin

   Define_Switch
    (Cmd_Line,
     Sa_Par_Market_Type'access,
     Long_Switch => "--market_type=",
     Help        => "win or plc");

  Getopt (Cmd_Line);  -- process the command line

  GMT := Statistics.Market_Type'Value(Sa_Par_Market_Type.all);
     
     

  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
  Sql.Connect
        (Host     => Ini.Get_Value("stats", "host", ""),
         Port     => Ini.Get_Value("stats", "port", 5432),
         Db_Name  => Ini.Get_Value("stats", "name", ""),
         Login    => Ini.Get_Value("stats", "username", ""),
         Password =>Ini.Get_Value("stats", "password", ""));

         
         
  T.Start;
  Table_Abets.Read_All(Bet_List);
  T.Commit;
  
  for b of Bet_List loop
    FO := Statistics.Get_First_Odds_Range(B.Betname);
    SO := Statistics.Get_Second_Odds_Range(B.Betname);
    MT:= Statistics.Get_Market_Type(B.Betname);
    S(FO,SO,MT).Treat(B);  
  end loop;
         
  for fi in Statistics.First_Odds_Range_Type'range loop
    for sn in Statistics.Second_Odds_Range_Type'range loop
      Statistics.Print_Result( S(Fi, Sn, GMT),Fi, Sn, GMT);
    end loop;  
  end loop;  
         
  Sql.Close_Session;
         
         
exception
  when E: others =>
    declare
      Last_Exception_Name     : constant String  := Ada.Exceptions.Exception_Name(E);
      Last_Exception_Messsage : constant String  := Ada.Exceptions.Exception_Message(E);
      Last_Exception_Info     : constant String  := Ada.Exceptions.Exception_Information(E);
    begin
      Text_io.Put_Line(Last_Exception_Name);
      Text_io.Put_Line("Message : " & Last_Exception_Messsage);
      Text_io.Put_Line(Last_Exception_Info);
      Text_io.Put_Line("addr2line" & " --functions --basenames --exe=" &
           Ada.Command_Line.Command_Name & " " & Stacktrace.Pure_Hexdump(Last_Exception_Info));
    end ;

end Stat_Maker;

