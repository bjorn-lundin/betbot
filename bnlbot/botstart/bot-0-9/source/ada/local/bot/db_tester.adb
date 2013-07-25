with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Bot_Config;
--with Lock; 
--with Text_io;
with Sql;
with Logging; use Logging;
with Table_Abets;
with Table_Aprices;

with Bet_Handler;

procedure Db_Tester is
  Me : constant String := "Db_Tester.";  

  T               : Sql.Transaction_Type;
  Select_Exists   : Sql.Statement_Type;
  Eos             : Boolean := False;
  Aprices         : Table_Aprices.Data_Type;
  Abet            : Table_Abets.Data_Type;
  Sel_All : Sql.Statement_Type;
begin

  Bot_Config.Config.Read; -- even from cmdline

  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => To_String(Bot_Config.Config.Database_Section.Host),
         Port     => 5432,
         Db_Name  => To_String(Bot_Config.Config.Database_Section.Name),
         Login    => To_String(Bot_Config.Config.Database_Section.Username),
         Password => To_String(Bot_Config.Config.Database_Section.Password));
  Log(Me, "db Connected");


  T.Start;
  
      Select_Exists.Prepare(
         "select * " & 
         "from " &
           "ABETS " &
         "where MARKETID = :MARKETID " & 
         " and BETNAME = :BETNAME");
           
      Select_Exists.Set("BETNAME", "DR_HOUNDS_WINNER_BACK_BET_45_07");
      Select_Exists.Set("MARKETID", "1.110172643");
 
      Select_Exists.Open_Cursor;     
      Select_Exists.Fetch( Eos);     
      Select_Exists.Close_Cursor;     
      Log(Me & "Exists", "Eos: " & Eos'Img);
      if not Eos then
        Abet := Table_Abets.Get(Select_Exists);
        Log(Me & "Exists", "Bet does exist " & Table_Abets.To_String(Abet));
      else  
        Log(Me & "Exists", "Bet does not exist");
      end if;

      Bet_Handler.Test_Bet;
  T.Commit;
  
  Log(Me, "Close Db");
  Sql.Close_Session;
  Log(Me, "Db Closed");
  Logging.Close;
end Db_Tester;