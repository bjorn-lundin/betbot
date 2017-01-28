
with Sim;
with Stacktrace;
with Sql;
with Calendar2;  use Calendar2;
with Logging; use Logging;
with Bot_Types;
procedure Create_Cache is

  Start        : Time_Type := Clock;
  One_Day      : Interval_Type := (1,0,0,0,0);
  Date_Start   : Time_Type := (2017,1,5,00,00,00,000); --Start - One_Day; -- (2016,02,25,00,00,00,000);
  Date_Stop    : Time_Type := Start + One_Day; -- (2016,12,01,00,00,00,000);
  Current_Date : Time_Type := Date_Start - One_Day;

begin

    Log ("Connect db");
    Sql.Connect
      (Host     => "localhost",
       Port     => 5432,
       Db_Name  => "dry",
       Login    => "bnl",
       Password => "bnl");
    Log ("Connected to db");

  loop
    Current_Date := Current_Date + (1,0,0,0,0);
    exit when Current_Date >= Date_Stop;
    Sim.Fill_Data_Maps(Current_Date, Animal => Bot_Types.Horse);
  end loop;
  Log("Started : " & Start.To_String);
  Log("Done : " & Calendar2.Clock.To_String);
  Sql.Close_Session;


  exception
   when E: others =>
      Stacktrace.Tracebackinfo(E);
end Create_Cache;
