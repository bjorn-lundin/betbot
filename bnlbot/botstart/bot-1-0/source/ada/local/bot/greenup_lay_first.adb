with Ada.Exceptions;
with Ada.Command_Line;
--with Ada.Strings; use Ada.Strings;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Environment_Variables;
--with Ada.Containers.Doubly_Linked_Lists;

--with Bot_System_Number;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;

with Stacktrace;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Sql;
--with Calendar2; use Calendar2;
--with Bot_Messages;
with Rpc;
with Lock ;
with Posix;
with Ini;
with Logging; use Logging;
--with Process_IO;
--with Core_Messages;
with Table_Amarkets;
with Table_Aevents;
with Table_Aprices;
--with Table_Abalances;
with Table_Apriceshistory;
with Bot_Svn_Info;
--with Config;
--with Utils; use Utils;
--with Table_Abets;
with Table_Arunners;

with Sim;
--with Simulation_Storage;

procedure Greenup_Lay_First is

--  Bad_Mode : exception;
  package EV renames Ada.Environment_Variables;
  use type Rpc.Result_Type;

  Me              : constant String := "Greenup_Lay_First.";

  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Cmd_Line        : Command_Line_Configuration;
  -------------------------------------------------------------

  procedure Run(Price_Data : in Table_Aprices.Data_Type) is
    Market    : Table_Amarkets.Data_Type;
    Event     : Table_Aevents.Data_Type;
    Eos               : Boolean := False;
    Price_During_Race_List : Table_Apriceshistory.Apriceshistory_List_Pack2.List;
    type Greenup_Result_Type is (None, Ok, Fail_Runner_Won, Fail_Runner_Lost );
    Greenup_Result : Greenup_Result_Type := Greenup_Result_Type'first;
    Runner : Table_Arunners.Data_Type;
    Bad_Data : exception;
    
    Backprice : Float_8 := Price_Data.Layprice + Float_8(10.0);
  begin
   -- Log(Me & "Run", "Treat market: " &  Price_Data.Marketid);
    Market.Marketid := Price_Data.Marketid;
    Market.Read(Eos);
    
    if not Eos then
      if Market.Markettype(1..3) /= "WIN"  then
        Log(Me & "Run", "not a WIN market: " &  Price_Data.Marketid);
        return;
      else
        Event.Eventid := Market.Eventid;
        Event.Read(Eos);
        if not Eos then
          if Event.Eventtypeid /= Integer_4(7) then
            Log(Me & "Run", "not a HORSE market: " &  Price_Data.Marketid);
            return;
          end if;
        else
          Log(Me & "Run", "no event found");
          return;
        end if;
      end if;
      
      if Market.Numrunners < Integer_4(6) then
        Log(Me & "Run", "less than 6 runners");
        return;
      end if;
      
    else
      Log(Me & "Run", "no market found");
      return;
    end if;
    
    if not Table_Apriceshistory.Is_Existing_I1(Marketid => Market.Marketid) then
      Log(Me & "Run", "no Apriceshistory found");
      return;
    end if;

    Log(Me & "Run", "market found  " & Market.To_String);
    Sim.Read_Marketid(Marketid =>  Market.Marketid, List => Price_During_Race_List) ;
    Greenup_Result := None;
    
    for Race_Data of Price_During_Race_List loop
      if Price_Data.Selectionid =  Race_Data.Selectionid then
        if Race_Data.Backprice >= Backprice then
          Greenup_Result := Ok;
          exit;
        end if;
      end if;    
    end loop ;
    
    case Greenup_Result is
      when OK => null;
      when others =>
        Runner.Marketid := Price_Data.Marketid;
        Runner.Selectionid := Price_Data.Selectionid;
        Runner.Read(Eos);
        if not Eos then
          if Runner.Status(1..6) = "WINNER" then
             Greenup_Result := Fail_Runner_Won;
          elsif Runner.Status(1..5) = "LOSER" then
             Greenup_Result := Fail_Runner_Lost;
          end if;
        else
          raise Bad_Data with Runner.To_String;
        end if;
    end case;     
    Log(Me & " Result " & Greenup_Result'Img , Price_Data.To_String);
      
  end Run;
  ---------------------------------------------------------------------
  use type Sql.Transaction_Status_Type;
------------------------------ main start -------------------------------------

begin

   Define_Switch
     (Cmd_Line,
      Sa_Par_Inifile'access,
      Long_Switch => "--inifile=",
      Help        => "use alternative inifile");

  Getopt (Cmd_Line);  -- process the command line

  Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");
  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("database", "host", ""),
         Port     => Ini.Get_Value("database", "port", 5432),
         Db_Name  => Ini.Get_Value("database", "name", ""),
         Login    => Ini.Get_Value("database", "username", ""),
         Password =>Ini.Get_Value("database", "password", ""));
  Log(Me, "db Connected");
  
  declare
    Stm : Sql.Statement_Type;
    T   : Sql.Transaction_Type;
    Price_List  : Table_Aprices.Aprices_List_Pack2.List;
  begin
    T.Start;
    Stm.Prepare(
       "select P.* " &
       "from APRICES P, AMARKETS M, AEVENTS E " &
       "where P.LAYPRICE between 15.0 and 25.0 " &
       "and E.EVENTID=M.EVENTID " &
       "and M.MARKETTYPE = 'WIN' " &
       "and E.COUNTRYCODE in ('GB','IE') " &
       "and P.MARKETID = M.MARKETID " &
       "and E.EVENTTYPEID = 7 " &
       "and M.STARTTS::date > '2014-08-01' " &
       "order by M.STARTTS, P.MARKETID, P.SELECTIONID ");
       
    Table_Aprices.Read_List(Stm, Price_List); 
    T.Commit;
       
    for Price of Price_List loop
      Log(Me & "Run", "Treat market: " & Price.To_String );
      Run(Price);
    end loop;
           
  end;           

  Log(Me, "Close Db");
  Sql.Close_Session;
  Logging.Close;
  Posix.Do_Exit(0); -- terminate

exception
  when Lock.Lock_Error =>
    Log(Me, "lock error, exit");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
  when E: others =>
    declare
      Last_Exception_Name     : constant String  := Ada.Exceptions.Exception_Name(E);
      Last_Exception_Messsage : constant String  := Ada.Exceptions.Exception_Message(E);
      Last_Exception_Info     : constant String  := Ada.Exceptions.Exception_Information(E);
    begin
      Log(Last_Exception_Name);
      Log("Message : " & Last_Exception_Messsage);
      Log(Last_Exception_Info);
      Log("addr2line" & " --functions --basenames --exe=" &
           Ada.Command_Line.Command_Name & " " & Stacktrace.Pure_Hexdump(Last_Exception_Info));
    end ;

    Log(Me, "Closed log and die");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
end Greenup_Lay_First;

