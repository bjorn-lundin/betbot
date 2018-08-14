
with Sim;
with Stacktrace;
with Sql;
with Calendar2;  use Calendar2;
with Logging; use Logging;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Ada.Environment_Variables;
with Bot_Types; use Bot_Types;

procedure Create_Cache is

  One_Day      : Interval_Type :=  (1, 0, 0, 0, 0); -- 1 day
  Start        : Time_Type := Clock;
  Date_Start   : Time_Type := (2016, 2, 25, 00, 00, 00, 000);
  Date_Stop    : Time_Type := Start + One_Day;
  Current_Date : Time_Type := Date_Start - One_Day; -- 1 day

  Cmd_Line     : Command_Line_Configuration;
  Ia_Start_Day     : aliased Integer := 0;
  Ia_Start_Month   : aliased Integer := 0;
  Ia_Start_Year    : aliased Integer := 0;
  Ia_Stop_Day      : aliased Integer := 0;
  Ia_Stop_Month    : aliased Integer := 0;
  Ia_Stop_Year     : aliased Integer := 0;
  Sa_Animal        : aliased Gnat.Strings.String_Access;
  Animal           : Animal_Type := Horse;
  package Ev renames Ada.Environment_Variables;
  Db           : String (1..3) := (others => ' ');
begin

  if not Ev.Exists ("BOT_NAME") then
    Ev.Set ("BOT_NAME", "create_cache");
  end if;

  Define_Switch
    (Cmd_Line,
     Sa_Animal'Access,
     Long_Switch => "--animal=",
     Help        => "horse|hound|human");
  Define_Switch
    (Cmd_Line,
     Ia_Start_Year'Access,
     Long_Switch => "--startyear=",
     Help        => "year of date");

  Define_Switch
    (Cmd_Line,
     Ia_Start_Month'Access,
     Long_Switch => "--startmonth=",
     Help        => "month of date");

  Define_Switch
    (Cmd_Line,
     Ia_Start_Day'Access,
     Long_Switch => "--startday=",
     Help        => "day of date");

  Define_Switch
    (Cmd_Line,
     Ia_Stop_Year'Access,
     Long_Switch => "--stopyear=",
     Help        => "year of date");

  Define_Switch
    (Cmd_Line,
     Ia_Stop_Month'Access,
     Long_Switch => "--stopmonth=",
     Help        => "month of date");

  Define_Switch
    (Cmd_Line,
     Ia_Stop_Day'Access,
     Long_Switch => "--stopday=",
     Help        => "day of date");

  Getopt (Cmd_Line);  -- process the command line

  Date_Start.Year := Year_Type(Ia_Start_Year);
  Date_Start.Month := Month_Type(Ia_Start_Month);
  Date_Start.Day := Day_Type(Ia_Start_Day);

  if Ia_Stop_Year > Integer(0) then
    Date_Stop.Year := Year_Type(Ia_Stop_Year);
    Date_Stop.Month := Month_Type(Ia_Stop_Month);
    Date_Stop.Day := Day_Type(Ia_Stop_Day);
  else
    Date_Stop  := Calendar2.Clock;
  end if;

  Current_Date := Date_Start; -- 1 day

  if Sa_Animal.all = "horse" then
    Animal := Horse;
    Db := "bnl";
  elsif Sa_Animal.all = "hound" then
    Animal := Hound;
    Db := "ghd";
  elsif Sa_Animal.all = "human" then
    Animal := Human;
  end if;
  Log ("animal2 " & Animal'Img);

  Sql.Connect
    (Host     => "localhost",
     Port     => 5432,
     Db_Name  => Db,
     Login    => "bnl",
     Password => "bnl");
  Log ("Connected to db: " & Db);

  Log ("Current date='" & Current_Date.String_Date_Iso & "' Date_Stop='" & Date_Stop.String_Date_Iso & "'");

  case Animal is
    when Horse | Hound =>
      loop
        exit when Current_Date > Date_Stop;
        Sim.Fill_Data_Maps (Current_Date, Animal => Animal);
        Current_Date := Current_Date + One_Day;
      end loop;

    when Human => null;
  end case;
  Log ("Started : " & Start.To_String);
  Log ("Done : " & Calendar2.Clock.To_String);
  Sql.Close_Session;


exception
  when E : others =>
    Stacktrace.Tracebackinfo (E);
end Create_Cache;
