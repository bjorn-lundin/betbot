
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
  Date_Start   : Time_Type := (2016, 3, 25, 00, 00, 00, 000);
  Date_Stop    : Time_Type := Start + One_Day;
  Current_Date : Time_Type := Date_Start - One_Day; -- 1 day

      Cmd_Line     : Command_Line_Configuration;
  --    IA_Day       : aliased Integer := 0;
  --    IA_Month     : aliased Integer := 0;
  --    IA_Year      : aliased Integer := 0;
  Sa_Animal        : aliased Gnat.Strings.String_Access;
  Animal           : Animal_Type := Horse;
  package EV renames Ada.Environment_Variables;

begin

  if not EV.Exists ("BOT_NAME") then
    EV.Set ("BOT_NAME", "create_cache");
  end if;

  Log ("Connect db dry");
  Sql.Connect
    (Host     => "localhost",
     Port     => 5432,
     Db_Name  => "dry",
     Login    => "bnl",
     Password => "bnl");
  Log ("Connected to db");

  Define_Switch
    (Cmd_Line,
     Sa_Animal'Access,
     Long_Switch => "--year=",
     Help        => "year of date");
  --    Define_Switch
  --       (Cmd_Line,
  --        Ia_Year'access,
  --        Long_Switch => "--year=",
  --        Help        => "year of date");
  --
  --    Define_Switch
  --       (Cmd_Line,
  --        Ia_Month'access,
  --        Long_Switch => "--month=",
  --        Help        => "month of date");
  --
  --    Define_Switch
  --       (Cmd_Line,
  --        Ia_Day'access,
  --        Long_Switch => "--day=",
  --        Help        => "day of date");
  --
  Getopt (Cmd_Line);  -- process the command line


  if Sa_Animal.all = "horse" then
    Animal := Horse;
  elsif Sa_Animal.all = "hound" then
    Animal := Hound;
  elsif Sa_Animal.all = "human" then
    Animal := Human;
  end if;

  case Animal is
    when Horse =>
      Log ("Connect db dry");
      Sql.Connect
        (Host     => "localhost",
         Port     => 5432,
         Db_Name  => "dry",
         Login    => "bnl",
         Password => "bnl");
      Log ("Connected to db");

      loop
        Current_Date := Current_Date + One_Day;
        exit when Current_Date >= Date_Stop;
        Sim.Fill_Data_Maps (Current_Date, Animal => Bot_Types.Horse);
      end loop;

      Log ("Started : " & Start.To_String);
      Log ("Done : " & Calendar2.Clock.To_String);
      Sql.Close_Session;

    when Hound =>


      Current_Date := Date_Start - One_Day;
      Log ("Connect db ghd");
      Sql.Connect
        (Host     => "localhost",
         Port     => 5432,
         Db_Name  => "ghd",
         Login    => "bnl",
         Password => "bnl");
      Log ("Connected to db");

      loop
        Current_Date := Current_Date + One_Day;
        exit when Current_Date >= Date_Stop;
        Sim.Fill_Data_Maps (Current_Date, Animal => Bot_Types.Hound);
      end loop;
      Log ("Started : " & Start.To_String);
      Log ("Done : " & Calendar2.Clock.To_String);
      Sql.Close_Session;

    when Human => null;
  end case;


exception
  when E : others =>
    Stacktrace.Tracebackinfo (E);
end Create_Cache;
