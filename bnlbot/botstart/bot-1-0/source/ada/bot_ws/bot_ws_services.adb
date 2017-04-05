with Types; use Types;
with Bot_Types; use Bot_Types;
--with Ada.Exceptions;
with Sql;
with Calendar2;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
--with Ada.Characters.Handling;
with Utils;
with Logging; use Logging;
with Gnatcoll.Json; use Gnatcoll.Json;
with Table_Abets;


package body Bot_Ws_Services is

  Object : constant String := "Bot_Ws_Services.";


  Select_Bets : Sql.Statement_Type;
  Select_Sum_Bets : Sql.Statement_Type;
  Select_Sum_Bets_Named : Sql.Statement_Type;

  ------------------------------------------------------------------


  function Positive_Answer( Context : in String)  return String is
    JSON_Reply      : JSON_Value := Create_Object;
    Service         : constant String := "Positive_Answer";
  begin
    JSON_Reply.Set_Field (Field_Name => "result",  Field => "OK");
    JSON_Reply.Set_Field (Field_Name => "context", Field => Context);          -- ???
    Log(Object & Service, "Return " & JSON_Reply.Write);
    return JSON_Reply.Write;
  end Positive_Answer;
  ------------------------------------------------------------

  function Negative_Answer(Text, Context : in String) return String is
    JSON_Reply      : JSON_Value := Create_Object;
    Service         : constant String := "Negative_Answer";
  begin
    JSON_Reply.Set_Field (Field_Name => "result",  Field => "FAILED");
    JSON_Reply.Set_Field (Field_Name => "context", Field => Context);          -- ???
    JSON_Reply.Set_Field (Field_Name => "text",  Field => Text);          -- ???
    Log(Object & Service, "Return " & JSON_Reply.Write);
    return JSON_Reply.Write;
  end Negative_Answer;

   --------------------------------------
  function Login_Os(User, Password : String) return Boolean is
    pragma Warnings(Off,User);
    pragma Warnings(Off,PAssword);
  begin
    return True;
  end Login_Os;
  ------------------------------------------------------------

  function Operator_Login(Username    : in String;
                          Password   : in String;
                          Context     : in String) return String is
    Error_Message   : Unbounded_String := Null_Unbounded_String;
    Is_Login_Ok       : Boolean := false;
    Service         : constant String := "Operator_Login";
  begin
    Log(Object & Service, "User '" & Username & "' Login");
    if not Login_Os(Username,Password) then
      Log(Object & Service, "User " & Username & " Login OS failed");
      Error_Message := To_Unbounded_String("Login OS failed");
      return Negative_Answer(Text => To_String(Error_Message), Context => Context);
    else
      Is_Login_Ok := True;
    end if;

    if Is_Login_Ok then
      return Positive_Answer(Context => Context);
    else
      return Negative_Answer(Text => To_String(Error_Message), Context => Context);
    end if;
  end Operator_Login;
  ------------------------------------------------------------
  function Operator_Logout(Username : in String;
                           Context  : in String) return String is
    Service        : constant String := "Operator_Logout";
  begin
      Log(Object & Service, "User '" & Username & "' Logout");
    return Positive_Answer(Context => Context);
  end Operator_Logout;

  ------------------------------------------------------------

  procedure Prepare_Bets is
  begin
    Select_Bets.Prepare(
      "select * " &
      "from ABETS " &
      "where STARTTS >= :START " &
      "and STARTTS <= :STOP " &
      "and STATUS = 'SETTLED' " &
      "order by BETPLACED "
    );
    Select_Sum_Bets.Prepare(
      "select sum(PROFIT) " &
      "from ABETS " &
      "where STARTTS >= :START " &
      "and STARTTS <= :STOP " &
      "and STATUS = 'SETTLED'"
    );
    Select_Sum_Bets_Named.Prepare(
      "select sum(PROFIT) " &
      "from ABETS " &
      "where STARTTS >= :START " &
      "and STARTTS <= :STOP " &
      "and BETNAME = :BETNAME " &
      "and STATUS = 'SETTLED'"
    );
  end Prepare_Bets;
  ------------------------------------------------------------


  function Settled_Bets(Username  : in String;
                      Context   : in String) return String is
    Service         : constant String := "Settled_Bets";
    T               : Sql.Transaction_Type;
    End_Of_Set      : Boolean := False;
    Start           : Calendar2.Time_Type := Calendar2.Clock;
    Stop            : Calendar2.Time_Type := Start;
    Bet_List        : Table_Abets.Abets_List_Pack2.List;
    JSON_Reply      : JSON_Value := Create_Object;
    Bets            : JSON_Array := Empty_Array;
    Total_Profit    : Fixed_Type    := 0.0;
    use Calendar2;
  begin

    Log(Object & Service, "User '" & Username & "' Context '" & Context & "'");

    Start.Hour        := 0;
    Start.Minute      := 0;
    Start.Second      := 0;
    Start.Millisecond := 0;

    Stop.Hour        := 23;
    Stop.Minute      := 59;
    Stop.Second      := 59;
    Stop.Millisecond := 0;

    T.Start;
    Prepare_Bets;

    if Context = "todays_bets" then
      null; -- is ok already
    elsif Context = "yesterdays_bets" then
      Start := Start - (1,0,0,0,0);
      Stop  := Stop  - (1,0,0,0,0);
    elsif Context = "thisweeks_bets" then
      declare
        Dow : Week_Day_Type := Week_Day_Of (Start) ;
      begin
        case Dow is
          when Monday =>
            Stop := Stop  + (6,0,0,0,0);
          when Tuesday =>
            Start:= Start - (1,0,0,0,0);
            Stop := Stop  + (5,0,0,0,0);
          when Wednesday =>
            Start:= Start - (2,0,0,0,0);
            Stop := Stop  + (4,0,0,0,0);
          when Thursday =>
            Start:= Start - (3,0,0,0,0);
            Stop := Stop  + (3,0,0,0,0);
          when Friday =>
            Start:= Start - (4,0,0,0,0);
            Stop := Stop  + (2,0,0,0,0);
          when Saturday =>
            Start:= Start - (5,0,0,0,0);
            Stop := Stop  + (1,0,0,0,0);
          when Sunday =>
            Start:= Start - (6,0,0,0,0);
        end case ;
      end;
    elsif Context = "lastweeks_bets" then
      declare
        Dow : Week_Day_Type := Week_Day_Of (Start) ;
      begin
        case Dow is
          when Monday =>
            Stop := Stop  + (6+7,0,0,0,0);
          when Tuesday =>
            Start:= Start - (1+7,0,0,0,0);
            Stop := Stop  + (5+7,0,0,0,0);
          when Wednesday =>
            Start:= Start - (2+7,0,0,0,0);
            Stop := Stop  + (4+7,0,0,0,0);
          when Thursday =>
            Start:= Start - (3+7,0,0,0,0);
            Stop := Stop  + (3+7,0,0,0,0);
          when Friday =>
            Start:= Start - (4+7,0,0,0,0);
            Stop := Stop  + (2+7,0,0,0,0);
          when Saturday =>
            Start:= Start - (5+7,0,0,0,0);
            Stop := Stop  + (1+7,0,0,0,0);
          when Sunday =>
            Start:= Start - (6+7,0,0,0,0);
        end case ;
      end;
    else
      JSON_Reply.Set_Field (Field_Name => "result",  Field => "FAIL");
      JSON_Reply.Set_Field (Field_Name => "context", Field => Context);
      JSON_Reply.Set_Field (Field_Name => "text",    Field => "Bad context");          -- ???
      Log(Object & Service, "Return " & JSON_Reply.Write);
      return JSON_Reply.Write;
    end if;

    Log(Object & Service, "Start " & Start.String_Date_And_Time & " Stop '" & Stop.String_Date_And_Time);


    Select_Bets.Set("START", Start);
    Select_Bets.Set("STOP", Stop);
    Select_Sum_Bets.Set("START", Start);
    Select_Sum_Bets.Set("STOP", Stop);

    Table_Abets.Read_List(Select_Bets, Bet_List);
    JSON_Reply.Set_Field (Field_Name => "result",  Field => "OK");
    JSON_Reply.Set_Field (Field_Name => "context", Field => Context);

    -- betname, marketid, betwon, profit, betplaced, pricematched, sizematched

    for B of Bet_List loop
      declare
        Bet : JSON_Value := Create_Object;
      begin
        Bet.Set_Field (Field_Name => "betname",      Field => Utils.Trim(B.Betname));
        Bet.Set_Field (Field_Name => "marketid",     Field => B.Marketid);
        Bet.Set_Field (Field_Name => "won",          Field => B.Betwon);
        Bet.Set_Field (Field_Name => "profit",       Field => Float(B.Profit));
        Bet.Set_Field (Field_Name => "betplaced",    Field => B.Betplaced.String_Date_And_Time(Milliseconds => True));
        Bet.Set_Field (Field_Name => "pm",           Field => Float(B.Pricematched));
        Bet.Set_Field (Field_Name => "sm",           Field => Float(B.Sizematched));
        Append(Bets, Bet);
      end ;
    end loop;

    Select_Sum_Bets.Open_Cursor;
    Select_Sum_Bets.Fetch(End_Of_Set);
    if not End_Of_Set then
      Select_Sum_Bets.Get(1,Total_Profit);
    end if;
    Select_Sum_Bets.Close_Cursor;
    JSON_Reply.Set_Field (Field_Name => "total", Field =>  Float(Total_Profit));
    JSON_Reply.Set_Field (Field_Name => "datatable", Field => Bets);

    T.Commit;
    Log(Object & Service, "Return " & JSON_Reply.Write);
    return JSON_Reply.Write;

  end Settled_Bets;
----------------------------------------------------------------


----------------------------------------------------------------

  function Todays_Total(Username  : in String;
                        Context   : in String) return String is
    Service         : constant String := "Todays_Total";
    T               : Sql.Transaction_Type;
    End_Of_Set      : Boolean := False;
    Start           : Calendar2.Time_Type := Calendar2.Clock;
    Stop            : Calendar2.Time_Type := Start;
    JSON_Reply      : JSON_Value := Create_Object;
    Total_Profit    : Fixed_Type    := 0.0;
    use Calendar2;
  begin

    Log(Object & Service, "User '" & Username & "' Context '" & Context & "'");

    Start.Hour        := 0;
    Start.Minute      := 0;
    Start.Second      := 0;
    Start.Millisecond := 0;

    Stop.Hour        := 23;
    Stop.Minute      := 59;
    Stop.Second      := 59;
    Stop.Millisecond := 0;

    T.Start;
    Prepare_Bets;
    Select_Sum_Bets.Set("START", Start);
    Select_Sum_Bets.Set("STOP", Stop);

    JSON_Reply.Set_Field (Field_Name => "result",  Field => "OK");
    JSON_Reply.Set_Field (Field_Name => "context", Field => Context);

    Select_Sum_Bets.Open_Cursor;
    Select_Sum_Bets.Fetch(End_Of_Set);
    if not End_Of_Set then
      Select_Sum_Bets.Get(1,Total_Profit);
    end if;
    Select_Sum_Bets.Close_Cursor;
    JSON_Reply.Set_Field (Field_Name => "total", Field =>  Float(Total_Profit));

    T.Commit;
    Log(Object & Service, "Return " & JSON_Reply.Write);
    return JSON_Reply.Write;

  end Todays_Total;
----------------------------------------------------------------
  function Weekly_Total(Username  : in String;
                      Betname   : in Betname_Type;
                      Weeks_Ago : in Integer_4) return JSON_Value is
    Service         : constant String := "Weekly_Total";
    T               : Sql.Transaction_Type;
    End_Of_Set      : Boolean := False;
    Start           : Calendar2.Time_Type := Calendar2.Clock;
    Stop            : Calendar2.Time_Type := Start;
    JSON_Reply      : JSON_Value := Create_Object;
    Total_Profit    : Fixed_Type    := 0.0;
    use Calendar2;
  begin

    Log(Object & Service, "User '" & Username & "' Weeks_Ago" & Weeks_Ago'Img);

    Start.Hour        := 0;
    Start.Minute      := 0;
    Start.Second      := 0;
    Start.Millisecond := 0;


    declare
      Dow : Week_Day_Type := Week_Day_Of (Start) ;
    begin
      case Dow is
        when Monday =>
          Start:= Start - (0+Weeks_Ago*7,0,0,0,0);
        when Tuesday =>
          Start:= Start - (1+Weeks_Ago*7,0,0,0,0);
        when Wednesday =>
          Start:= Start - (2+Weeks_Ago*7,0,0,0,0);
        when Thursday =>
          Start:= Start - (3+Weeks_Ago*7,0,0,0,0);
        when Friday =>
          Start:= Start - (4+Weeks_Ago*7,0,0,0,0);
        when Saturday =>
          Start:= Start - (5+Weeks_Ago*7,0,0,0,0);
        when Sunday =>
          Start:= Start - (6+Weeks_Ago*7,0,0,0,0);
      end case ;
      Stop := Start  + (6,0,0,0,0);
      Stop.Hour        := 23;
      Stop.Minute      := 59;
      Stop.Second      := 59;
      Stop.Millisecond := 0;
    end;

    Log(Object & Service, "Start:" & Start.To_String & " Stop:" & Stop.To_String);

    T.Start;
    Prepare_Bets;
    Select_Sum_Bets_Named.Set("START", Start);
    Select_Sum_Bets_Named.Set("STOP", Stop);
    Select_Sum_Bets_Named.Set("BETNAME", Betname);


    Select_Sum_Bets_Named.Open_Cursor;
    Select_Sum_Bets_Named.Fetch(End_Of_Set);
    if not End_Of_Set then
      Select_Sum_Bets_Named.Get(1,Total_Profit);
    end if;
    Select_Sum_Bets_Named.Close_Cursor;
    Json_Reply.Set_Field (Field_Name => "total", Field =>  Float(Total_Profit));
    Json_Reply.Set_Field (Field_Name => "betname", Field => Utils.Trim(Betname));
    Json_Reply.Set_Field (Field_Name => "weeks_ago", Field => Utils.Trim(Weeks_Ago'Img));

    T.Commit;
    Log(Object & Service, "Return " & JSON_Reply.Write);
    return Json_Reply;

  end Weekly_Total;
----------------------------------------------------------------
  function Weeks(Username  : in String;
                 Context   : in String) return String is
    Service         : constant String := "Weeks";
    JSON_Reply      : JSON_Value := Create_Object;
    Weeks           : JSON_Array := Empty_Array;
    use Calendar2;
    Betname : Betname_Type := (others => ' ');
    subtype Num_Weeks_Type is Integer_4 range 0 .. 6;
  begin

    Log(Object & Service, "User '" & Username & "' Context '" & Context & "'");

    for W in Num_Weeks_Type'range loop
      declare
        Result : Json_Value := Create_Object;
        Week   : Json_Value := Create_Object;
      begin
        Move("BACK_1_10_07_1_2_PLC_1_01",Betname);
        Result := Weekly_Total(Username  => Username,
                               Betname   => Betname,
                               Weeks_Ago => W);

        Week.Set_Field (Field_Name => "week", Field => Result);
       -- Append(Weeks,Week);
        Append(Weeks,Result);
      end;
    end loop;

    for W in Num_Weeks_Type'range loop
      declare
        Result : Json_Value := Create_Object;
        Week   : Json_Value := Create_Object;
      begin
        Move("BACK_1_11_1_15_05_07_1_2_PLC_1_01",Betname);
        Result := Weekly_Total(Username  => Username,
                               Betname   => Betname,
                               Weeks_Ago => W);

        Week.Set_Field (Field_Name => "week", Field => Result);
        --Append(Weeks,Week);
        Append(Weeks,Result);
      end;
    end loop;

    JSON_Reply.Set_Field (Field_Name => "result",  Field => "OK");
    JSON_Reply.Set_Field (Field_Name => "datatable", Field => Weeks);

    Log(Object & Service, "returning:" & Json_Reply.Write);
    return Json_Reply.Write;

  end Weeks;
  ---------------------------------------------------

end Bot_Ws_Services;
