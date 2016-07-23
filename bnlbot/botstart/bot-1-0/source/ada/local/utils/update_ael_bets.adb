
with Ada.Exceptions;
with Ada.Command_Line;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
--with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Environment_Variables;
--with Ada.Containers.Doubly_Linked_Lists;

--with Gnat.Command_Line; use Gnat.Command_Line;
--with Gnat.Strings;

with Stacktrace;
with Types; use Types;
--with Bot_Types; use Bot_Types;
with Sql;
with Calendar2; use Calendar2;
--with Bot_Messages;
--with Rpc;
--with Lock ;
with Posix;
with Ini;
with Logging; use Logging;
--with Process_IO;
--with Core_Messages;
--with Table_Amarkets;
--with Table_Aevents;
--with Table_Aprices;
--with Table_Abalances;
with Table_Arunners;
with Table_Abets;
with Table_Apriceshistory;
with Bot_Svn_Info;
--with Utils; use Utils;
--with Bot_System_Number;


procedure Update_Ael_Bets is
  package EV renames Ada.Environment_Variables;

  T : Sql.Transaction_Type;
  Select_Pm     : Sql.Statement_Type;
  Rows_Affected : Natural := 0;
  Me            : constant String := "Update_Ael_Bets.";
  Comission     : constant Float_8 := 6.5 / 100.0;
  -------------------------------------------------------------

  procedure Check_Bet_Won ( R : in     Table_Arunners.Data_Type;
                            B : in out Table_Abets.Data_Type) is
  begin
    if R.Status(1..7) = "REMOVED" then
      return;
    end if;
    if B.Side(1..4) = "BACK" then
        if R.Status(1..6) = "WINNER" then
          B.Betwon := True;
        elsif R.Status(1..5) = "LOSER" then
          B.Betwon := False;
        elsif R.Status(1..7) = "REMOVED" then
          B.Status(1) := 'R';
          B.Betwon := True;
        end if;
    elsif B.Side(1..3) = "LAY" then
        if R.Status(1..6) = "WINNER" then
          B.Betwon := False;
        elsif R.Status(1..5) = "LOSER" then
          B.Betwon := True;
        elsif R.Status(1..7) = "REMOVED" then
          B.Status(1) := 'R';
          B.Betwon := True;
        end if;
    end if;
  end Check_Bet_Won;
  ----------------------------------------------------------------
  procedure Check_Bet_Profit (B : in out Table_Abets.Data_Type) is
  begin
    if B.Pricematched < 0.5 then
      B.Profit := 0.0;
      return;
    end if;

    if B.Side(1..4) = "BACK" then
      if B.Betwon then
        B.Profit := (1.0 - Comission) * B.Sizematched * (B.Pricematched - 1.0);
      else
        B.Profit := -B.Sizematched;
      end if;
    elsif B.Side(1..3) = "LAY" then
      if B.Betwon then
        B.Profit := (1.0 - Comission) * B.Sizematched;
      else
        B.Profit := -B.Sizematched * (B.Pricematched - 1.0);
      end if;
    end if;
  end Check_Bet_Profit;
  ----------------------------------------------------------------

begin
  if not EV.Exists("BOT_NAME") then
    EV.Set("BOT_NAME","update_ael_bets");
  end if;

  Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");
  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("stats", "host", ""),
         Port     => Ini.Get_Value("stats", "port", 5432),
         Db_Name  => Ini.Get_Value("stats", "name", ""),
         Login    => Ini.Get_Value("stats", "username", ""),
         Password => Ini.Get_Value("stats", "password", ""));
  Log(Me, "db Connected");

  Select_Pm.Prepare(
      "select * " &
      "from APRICESHISTORY  " &
      "where MARKETID = :MARKETID " &
      "and SELECTIONID = :SELECTIONID " &
      "and PRICETS between :BETPLACED1 and :BETPLACED2 " &
      "order by PRICETS " &
      "limit 1 "
    );

  T.Start;
    declare
      Ph_Data  : Table_Apriceshistory.Data_Type;
      type Eos_Type is (AHistory, ARunner);
      Eos      : array (Eos_Type'range) of Boolean := (others => True);
      Bet_List : Table_Abets.Abets_List_Pack2.List;
      Rows_Deleted : Natural := 0;
      Runner : Table_Arunners.Data_Type;
    begin
      Log(Me & ".Main" , "read_all start");
      Table_Abets.Read_All(Bet_List);
      Log(Me & ".Main" , "read_all done");
      Rows_Affected := 0;

      for Bet of Bet_List loop
        if Natural(Bet_List.Length) mod 1000 = 0 then
           Log(Me & ".Select_Pm" , "treat:" & Rows_Affected'Img);
        end if;
        -- check lost/won
        Runner.Marketid := Bet.Marketid;
        Runner.Selectionid := Bet.Selectionid;
        Runner.Read(Eos(Arunner));
        Check_Bet_Won(R => Runner, B=> Bet);

        -- calculate likely odds
        Select_Pm.Set("MARKETID",Bet.Marketid);
        Select_Pm.Set("SELECTIONID",Bet.Selectionid);
        Select_Pm.Set("BETPLACED1",Bet.Betplaced + (0,0,0,1,0));    --1.0 s
        Select_Pm.Set("BETPLACED2",Bet.Betplaced + (0,0,0,1,300));  --1.3 s
        -- look 1 to 1.3 secs after bet is placed
        Select_Pm.Open_Cursor;
        Select_Pm.Fetch(Eos(Ahistory));
        if not Eos(Ahistory) then
          Ph_Data := Table_Apriceshistory.Get(Select_Pm);
          Bet.Pricematched := Ph_Data.Backprice;
          Move("SUCCESS",Bet.Status);
          Rows_Affected := Rows_Affected +1;
        else
          Log(Me & ".Select_Pm" , "EOS: " & Bet.To_String );
          Bet.Pricematched := 0.0;
          Move("LAPSED",Bet.Status);
        end if;
        Select_Pm.Close_Cursor;
        -- calculate profit
        Check_Bet_Profit(B=> Bet);
        Bet.Update_Withcheck;
      end loop;
      Log(Me & ".Select_Pm" , "Rows_Affected:" & Rows_Affected'Img);
      Log(Me & ".Select_Pm" , "Rows_Deleted:" & Rows_Deleted'Img);
    end ;
  T.Commit;


exception
--  when Lock.Lock_Error =>
--    Log(Me, "lock error, exit");
--    Logging.Close;
--    Posix.Do_Exit(0); -- terminate
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

end Update_Ael_Bets;





