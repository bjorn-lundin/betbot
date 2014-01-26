
--with Sattmate_Types; use Sattmate_Types;
with Sql;
with Sattmate_Calendar; use Sattmate_Calendar;
with Logging; use Logging;
with General_Routines; use General_Routines;


package body Bet is
  Me : constant String := "Bet.";
  Select_Profit_Today : Sql.Statement_Type;
  ------------------------------------------------------------
  function Profit_Today(Bet_Name : String) return Float_8 is
    T : Sql.Transaction_Type;
    Eos : Boolean := False;
    Start_Date, End_Date : Time_Type := Clock;
    Profit : Float_8 := 0.0;
  begin
    T.Start;
      Start_Date := Sattmate_Calendar.Clock;
      End_Date := Sattmate_Calendar.Clock;

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
--        "and BETMODE = :BOTMODE " &
--        "and PROFIT < 0.0 " &
        "and BETWON is not null " &
        "and BETNAME = :BETNAME " );

--      Select_Profit_Today.Set("BOTMODE",  Bot_Mode(Bot_Config.Config.System_Section.Bot_Mode));
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
    Log(Me & "Profit_Today", Bet_Name & " :" & " HAS earned " & F8_Image(Profit) & " today: " & Sattmate_Calendar.String_Date(Start_Date));
    return Profit;
  end Profit_Today;
  ------------------------------------------------------------

end Bet;
