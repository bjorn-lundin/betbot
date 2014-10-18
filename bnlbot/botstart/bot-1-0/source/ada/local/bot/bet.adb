
with Sql;
with Calendar2; use Calendar2;
with Logging; use Logging;
with Table_Abets;
with Utils;
package body Bet is
  Me : constant String := "Bet.";
  Select_Exists,
  Select_Profit_Today : Sql.Statement_Type;
  ------------------------------------------------------------
  function Profit_Today(Bet_Name : Bet_Name_Type) return Float_8 is
    T : Sql.Transaction_Type;
    Eos : Boolean := False;
    Start_Date, End_Date : Time_Type := Clock;
    Profit : Float_8 := 0.0;
  begin
    T.Start;
      Start_Date := Calendar2.Clock;
      End_Date := Calendar2.Clock;

      Start_Date.Hour        := 0;
      Start_Date.Minute      := 0;
      Start_Date.Second      := 0;
      Start_Date.MilliSecond := 0;

      End_Date.Hour        := 23;
      End_Date.Minute      := 59;
      End_Date.Second      := 59;
      End_Date.MilliSecond := 999;

      Select_Profit_Today.Prepare(
        "select sum(PROFIT) " &
        "from ABETS " &
        "where STARTTS >= :STARTOFDAY " &
        "and STARTTS <= :ENDOFDAY " &
        "and BETWON is not null " &
        "and BETNAME = :BETNAME " );

      Select_Profit_Today.Set("BETNAME", Bet_Name);
      Select_Profit_Today.Set_Timestamp( "STARTOFDAY",Start_Date);
      Select_Profit_Today.Set_Timestamp( "ENDOFDAY",End_Date);
      Select_Profit_Today.Open_Cursor;
      Select_Profit_Today.Fetch(Eos);
      if not Eos then
        Select_Profit_Today.Get(1, Profit);
      else
        Profit := 0.0;
      end if;
      Select_Profit_Today.Close_Cursor;
    T.Commit;
    Log(Me & "Profit_Today", Utils.Trim(Bet_Name) & " :" & " HAS earned " & Utils.F8_Image(Profit) & " today: " & Calendar2.String_Date(Start_Date));
    return Profit;
  end Profit_Today;
  ------------------------------------------------------------
  function Exists(Bet_Name : Bet_Name_Type; Market_Id : Market_Id_Type) return Boolean is
    T    : Sql.Transaction_Type;
    Eos  : Boolean := False;
    Abet : Table_Abets.Data_Type;
  begin
    T.Start;
      Select_Exists.Prepare(
         "select * " &
         "from " &
           "ABETS " &
         "where MARKETID = :MARKETID " &
         "and BETNAME = :BETNAME ");

      Select_Exists.Set("BETNAME",  Bet_Name);
      Select_Exists.Set("MARKETID", Market_Id);

      Select_Exists.Open_Cursor;
      Select_Exists.Fetch( Eos);
      if not Eos then
        Abet := Table_Abets.Get(Select_Exists);
        Log(Me & "Exists", "Bet does already exist " & Table_Abets.To_String(Abet));
      else
        null;
--        Log(Me & "Exists", "Bet does not exist");
      end if;
      Select_Exists.Close_Cursor;
    T.Commit;
    return not Eos;
  end Exists;
end Bet;
