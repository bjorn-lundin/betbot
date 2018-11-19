with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
--with Ada.Environment_Variables;
with Ada.Containers;
--with Ada.Characters.Handling;
--with Ada.Exceptions;

with Types; use Types;
with Bot_Types; use Bot_Types;
with Sql;
with Calendar2;
with Rpc;
with Utils;
with Logging; use Logging;
with Gnatcoll.Json; use Gnatcoll.Json;
with Bets;
with Table_Astarttimes;
with Ini;


package body Bot_Ws_Services is

  Object : constant String := "Bot_Ws_Services.";


  Select_Bets                     : Sql.Statement_Type;
  Select_Sum_Bets                 : Sql.Statement_Type;
  Select_Sum_Bets_Named           : Sql.Statement_Type;
  Select_Sum_Bets_Grouped_By_Name : Sql.Statement_Type;
  Global_Initiated                : Boolean := False;
  Global_Start_Time_List          : Table_Astarttimes.Astarttimes_List_Pack2.List;

  ------------------------------------------------------------------


  function Positive_Answer( Context : in String)  return String is
    Json_Reply      : Json_Value := Create_Object;
    Service         : constant String := "Positive_Answer";
  begin
    Json_Reply.Set_Field (Field_Name => "result",  Field => "OK");
    Json_Reply.Set_Field (Field_Name => "context", Field => Context);          -- ???
    Log(Object & Service, "Return " & Json_Reply.Write);
    return Json_Reply.Write;
  end Positive_Answer;
  ------------------------------------------------------------

  function Negative_Answer(Text, Context : in String) return String is
    Json_Reply      : Json_Value := Create_Object;
    Service         : constant String := "Negative_Answer";
  begin
    Json_Reply.Set_Field (Field_Name => "result",  Field => "FAILED");
    Json_Reply.Set_Field (Field_Name => "context", Field => Context);          -- ???
    Json_Reply.Set_Field (Field_Name => "text",  Field => Text);          -- ???
    Log(Object & Service, "Return " & Json_Reply.Write);
    return Json_Reply.Write;
  end Negative_Answer;

  --------------------------------------
  function Login_Os(User, Password : String) return Boolean is
    pragma Warnings(Off,User);
    pragma Warnings(Off,Password);
  begin
    return True;
  end Login_Os;
  ------------------------------------------------------------

  function Operator_Login(Username    : in String;
                          Password    : in String;
                          Context     : in String) return String is
    Error_Message     : Unbounded_String := Null_Unbounded_String;
    Is_Login_Ok       : Boolean := False;
    Service           : constant String := "Operator_Login";
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
                            "select sum(PROFIT) PROFIT, sum(SIZEMATCHED) SIZEMATCHED " &
                              "from ABETS " &
                              "where STARTTS >= :START " &
                              "and STARTTS <= :STOP " &
                              "and STATUS = 'SETTLED'"
                           );
    Select_Sum_Bets_Named.Prepare(
                                  "select sum(PROFIT) PROFIT " &
                                    "from ABETS " &
                                    "where STARTTS >= :START " &
                                    "and STARTTS <= :STOP " &
                                    "and BETNAME = :BETNAME " &
                                    "and STATUS = 'SETTLED'"
                                 );

    Select_Sum_Bets_Grouped_By_Name.Prepare(
                                            "select BETNAME, sum(PROFIT) PROFIT, sum(SIZEMATCHED) SIZEMATCHED, count('a') CNT, " &
                                              "round((case sum(SIZEMATCHED) " &
                                              "    when 0 then 0.0 " &
                                              "    else 100.0 * sum(PROFIT) / sum(SIZEMATCHED) " &
                                              " end)::numeric,2) RATIO, " &
                                              "round(sum(PROFIT)/count('a'),2) PROFITPERBET " &
                                              "from ABETS " &
                                              "where STARTTS >= :START " &
                                              "and STARTTS <= :STOP " &
                                              "and STATUS = 'SETTLED' " &
                                              "group by BETNAME " &
                                              "order by BETNAME" );

  end Prepare_Bets;
  ------------------------------------------------------------


  function Settled_Bets(Username  : in String;
                        Context   : in String) return String is
    Service         : constant String := "Settled_Bets";
    T               : Sql.Transaction_Type;
    End_Of_Set      : Boolean := False;
    Start           : Calendar2.Time_Type := Calendar2.Clock;
    Stop            : Calendar2.Time_Type := Start;
    Bet_List        : Bets.Lists.List;
    Json_Reply      : Json_Value := Create_Object;
    Json_Bets       : Json_Array := Empty_Array;
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
        Dow : Week_Day_Type  ;
      begin
        loop -- find monday
          Dow := Week_Day_Of (Start) ;
          case Dow is
            when Monday => exit ;
            when others => Start := Start - (1,0,0,0,0);
          end case ;
        end loop;
        Stop := Start + (7,0,0,0,0);
      end;
    elsif Context = "lastweeks_bets" then
      declare
        Dow : Week_Day_Type  ;
      begin
        Start := Start - (7,0,0,0,0); -- get to next week
        loop -- find monday
          Dow := Week_Day_Of (Start) ;
          case Dow is
            when Monday => exit ;
            when others => Start := Start - (1,0,0,0,0);
          end case ;
        end loop;
        Stop := Start + (7,0,0,0,0);
      end;
    else
      Json_Reply.Set_Field (Field_Name => "result",  Field => "FAIL");
      Json_Reply.Set_Field (Field_Name => "context", Field => Context);
      Json_Reply.Set_Field (Field_Name => "text",    Field => "Bad context");          -- ???
      Log(Object & Service, "Return " & Json_Reply.Write);
      return Json_Reply.Write;
    end if;

    Log(Object & Service, "Start " & Start.String_Date_And_Time & " Stop '" & Stop.String_Date_And_Time);


    Select_Bets.Set("START", Start);
    Select_Bets.Set("STOP", Stop);
    Select_Sum_Bets.Set("START", Start);
    Select_Sum_Bets.Set("STOP", Stop);

    Bets.Read_List(Select_Bets, Bet_List);
    Json_Reply.Set_Field (Field_Name => "result",  Field => "OK");
    Json_Reply.Set_Field (Field_Name => "context", Field => Context);

    -- betname, marketid, betwon, profit, betplaced, pricematched, sizematched

    for B of Bet_List loop
      declare
        Bet : Json_Value := Create_Object;
      begin
        Bet.Set_Field (Field_Name => "betname",      Field => Utils.Trim(B.Betname));
        Bet.Set_Field (Field_Name => "marketid",     Field => B.Marketid);
        Bet.Set_Field (Field_Name => "won",          Field => B.Betwon);
        Bet.Set_Field (Field_Name => "profit",       Field => Float(B.Profit));
        Bet.Set_Field (Field_Name => "betplaced",    Field => B.Betplaced.String_Date_And_Time(Milliseconds => True));
        Bet.Set_Field (Field_Name => "pm",           Field => Float(B.Pricematched));
        Bet.Set_Field (Field_Name => "sm",           Field => Float(B.Sizematched));
        Append(Json_Bets, Bet);
      end ;
    end loop;

    Select_Sum_Bets.Open_Cursor;
    Select_Sum_Bets.Fetch(End_Of_Set);
    if not End_Of_Set then
      Select_Sum_Bets.Get("PROFIT",Total_Profit);
    end if;
    Select_Sum_Bets.Close_Cursor;
    Json_Reply.Set_Field (Field_Name => "total", Field =>  Float(Total_Profit));
    Json_Reply.Set_Field (Field_Name => "datatable", Field => Json_Bets);

    T.Commit;
    Log(Object & Service, "Return " & Json_Reply.Write);
    return Json_Reply.Write;

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
    Json_Reply      : Json_Value := Create_Object;
    Total_Sizematched,
    Total_Profit    : Fixed_Type    := 0.0;
    --use Calendar2;
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

    Json_Reply.Set_Field (Field_Name => "result",  Field => "OK");
    Json_Reply.Set_Field (Field_Name => "context", Field => Context);

    Select_Sum_Bets.Open_Cursor;
    Select_Sum_Bets.Fetch(End_Of_Set);
    if not End_Of_Set then
      Select_Sum_Bets.Get("PROFIT",Total_Profit);
      Select_Sum_Bets.Get("SIZEMATCHED",Total_Sizematched);
    end if;
    Select_Sum_Bets.Close_Cursor;
    Json_Reply.Set_Field (Field_Name => "total", Field =>  Float(Total_Profit));
    Json_Reply.Set_Field (Field_Name => "totalsm", Field =>  Float(Total_Sizematched));

    T.Commit;
    Log(Object & Service, "Return " & Json_Reply.Write);
    return Json_Reply.Write;

  end Todays_Total;
  ----------------------------------------------------------------
  function Weekly_Total(Username  : in String;
                        Betname   : in Betname_Type;
                        Weeks_Ago : in Integer_4) return Json_Value is
    Service         : constant String := "Weekly_Total";
    T               : Sql.Transaction_Type;
    End_Of_Set      : Boolean := False;
    Start           : Calendar2.Time_Type := Calendar2.Clock;
    Stop            : Calendar2.Time_Type := Start;
    Json_Reply      : Json_Value := Create_Object;
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
      Select_Sum_Bets_Named.Get("PROFIT",Total_Profit);
    end if;
    Select_Sum_Bets_Named.Close_Cursor;
    Json_Reply.Set_Field (Field_Name => "total", Field =>  Float(Total_Profit));
    Json_Reply.Set_Field (Field_Name => "betname", Field => Utils.Trim(Betname));
    Json_Reply.Set_Field (Field_Name => "weeks_ago", Field => Utils.Trim(Weeks_Ago'Img));

    T.Commit;
    Log(Object & Service, "Return " & Json_Reply.Write);
    return Json_Reply;

  end Weekly_Total;
  ----------------------------------------------------------------
  function Weeks(Username  : in String;
                 Context   : in String) return String is
    Service         : constant String := "Weeks";
    Json_Reply      : Json_Value := Create_Object;
    Weeks           : Json_Array := Empty_Array;
    --use Calendar2;
    Betname         : Betname_Type := (others => ' ');
    subtype Num_Weeks_Type is Integer_4 range 0 .. 6;
  begin

    Log(Object & Service, "User '" & Username & "' Context '" & Context & "'");

    for W in Num_Weeks_Type'Range loop
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

    for W in Num_Weeks_Type'Range loop
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

    Json_Reply.Set_Field (Field_Name => "result",  Field => "OK");
    Json_Reply.Set_Field (Field_Name => "datatable", Field => Weeks);

    Log(Object & Service, "returning:" & Json_Reply.Write);
    return Json_Reply.Write;

  end Weeks;
  ---------------------------------------------------

  function Sum_Settled_Bets(Username  : in String;
                            Context   : in String) return String is
    Service         : constant String := "Sum_Settled_Bets";
    T               : Sql.Transaction_Type;
    End_Of_Set      : Boolean := False;
    Start           : Calendar2.Time_Type := Calendar2.Clock;
    Stop            : Calendar2.Time_Type := Start;
    Json_Reply      : Json_Value := Create_Object;
    Json_Bets       : Json_Array := Empty_Array;

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

    if Context = "sum_todays_bets" then
      null; -- is ok already
    elsif Context = "sum_7_days_bets" then
      Start := Start - (6,0,0,0,0);
    elsif Context = "sum_thisweeks_bets" then
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
    elsif Context = "sum_total_bets" then
      Start := (2018,5,1,0,0,0,0);
    else
      Json_Reply.Set_Field (Field_Name => "result",  Field => "FAIL");
      Json_Reply.Set_Field (Field_Name => "context", Field => Context);
      Json_Reply.Set_Field (Field_Name => "text",    Field => "Bad context");          -- ???
      Log(Object & Service, "Return " & Json_Reply.Write);
      return Json_Reply.Write;
    end if;

    Log(Object & Service, "Start " & Start.String_Date_And_Time & " Stop '" & Stop.String_Date_And_Time);

    Select_Sum_Bets_Grouped_By_Name.Set("START", Start);
    Select_Sum_Bets_Grouped_By_Name.Set("STOP", Stop);

    Json_Reply.Set_Field (Field_Name => "result",  Field => "OK");
    Json_Reply.Set_Field (Field_Name => "context", Field => Context);

    Select_Sum_Bets_Grouped_By_Name.Open_Cursor;
    loop
      Select_Sum_Bets_Grouped_By_Name.Fetch(End_Of_Set);
      exit when End_Of_Set ;
      declare
        Bet            : Json_Value   := Create_Object;
        Betname        : Betname_Type := (others => ' ');
        Profit         : Fixed_Type   := 0.0;
        Sizematched    : Fixed_Type   := 0.0;
        Count          : Integer_4    := 0;
        Ratio          : Fixed_Type   := 0.0;
        Profit_Per_Bet : Fixed_Type   := 0.0;
      begin
        -- betname, profit, sizematched, count, riskratio
        Select_Sum_Bets_Grouped_By_Name.Get("BETNAME", Betname);
        Select_Sum_Bets_Grouped_By_Name.Get("PROFIT", Profit);
        Select_Sum_Bets_Grouped_By_Name.Get("SIZEMATCHED", Sizematched);
        Select_Sum_Bets_Grouped_By_Name.Get("CNT", Count);
        Select_Sum_Bets_Grouped_By_Name.Get("RATIO", Ratio);
        Select_Sum_Bets_Grouped_By_Name.Get("PROFITPERBET", Profit_Per_Bet);


        Bet.Set_Field (Field_Name => "betname",      Field => Utils.Trim(Betname));
        Bet.Set_Field (Field_Name => "profit",       Field => Float(Profit));
        Bet.Set_Field (Field_Name => "sm",           Field => Float(Sizematched));
        Bet.Set_Field (Field_Name => "count",        Field => Long_Long_Integer(Count));
        Bet.Set_Field (Field_Name => "p/b",      Field => Float(Profit_Per_Bet));
        Bet.Set_Field (Field_Name => "ratio",        Field => Float(Ratio));
        Append(Json_Bets, Bet);
      end;
    end loop;
    Select_Sum_Bets_Grouped_By_Name.Close_Cursor;

    Json_Reply.Set_Field (Field_Name => "datatable", Field => Json_Bets);

    T.Commit;
    Log(Object & Service, "Return " & Json_Reply.Write);
    return Json_Reply.Write;

  end Sum_Settled_Bets;
  ----------------------------------------------------------------

  procedure Initiate (Start_Time_List : in out Table_Astarttimes.Astarttimes_List_Pack2.List;
                      Initiated       : in out Boolean) is
    Service : constant String := "Initiate";
    use type  Ada.Containers.Count_Type;
  begin
    Start_Time_List.Clear;

    Rpc.Init(
             Username   => Ini.Get_Value("betfair","username",""),
             Password   => Ini.Get_Value("betfair","password",""),
             Product_Id => Ini.Get_Value("betfair","product_id",""),
             Vendor_Id  => Ini.Get_Value("betfair","vendor_id",""),
             App_Key    => Ini.Get_Value("betfair","appkey","")
            );

    begin
      Rpc.Login;
    exception
      when Rpc.Login_Failed => Log(Object & Service, "Start Rpc.Login_Failed ");
      when Rpc.Post_Timeout => Log(Object & Service, "Start Rpc.Post_Timeout 1");
    end;

    begin
      Rpc.Get_Starttimes(List => Start_Time_List);
    exception
      when Rpc.Post_Timeout => Log(Object & Service, "Start Rpc.Post_Timeout 2");
    end;

    begin
      Rpc.Logout;
    exception
      when others => Log(Object & Service, "caught logout issues");
    end;

    if Start_Time_List.Length = 0 then
      Log(Object & Service, "no races left today? ");
      Initiated := False;
    else
      Initiated := True;
    end if;

  end Initiate;

  --------------------------------------------------------

  function Get_Starttimes(Username  : in String;
                          Context   : in String) return String is
    pragma Unreferenced(Username);
    Service : constant String := "Get_Starttimes";
    --package Ev renames Ada.Environment_Variables;
    Arrow_Is_Printed : Boolean := False;
    Now : Calendar2.Time_Type := Calendar2.Clock;
    use type Ada.Containers.Count_Type;
    Json_Reply       : Json_Value := Create_Object;
    Json_Start_Times : Json_Array := Empty_Array;
    use type Calendar2.Time_Type;
    Arrow : String(1..3) := (others => ' ');
  begin
    if not Global_Initiated then
      Initiate(Global_Start_Time_List, Global_Initiated);
    end if;

    if Global_Start_Time_List.Length = 0 then
      Json_Reply.Set_Field (Field_Name => "result",  Field => "FAIL");
      Json_Reply.Set_Field (Field_Name => "context", Field => Context);
      Json_Reply.Set_Field (Field_Name => "text",    Field => "No races found");
      Log(Object & Service, "Return " & Json_Reply.Write);
      return Json_Reply.Write;
    else
      Json_Reply.Set_Field (Field_Name => "result",  Field => "OK");
      Json_Reply.Set_Field (Field_Name => "context", Field => Context);
    end if;

    for S of Global_Start_Time_List loop
      if not Arrow_Is_Printed and then Now <= S.Starttime then
        Arrow_Is_Printed := True;
        Arrow := "-->";
      else
        Arrow := "   ";
      end if;
      declare
        Start_Time : Json_Value := Create_Object;
      begin
        Start_Time.Set_Field (Field_Name => "starttime", Field => S.Starttime.String_Time(Seconds => False));
        Start_Time.Set_Field (Field_Name => "venue",     Field => S.Venue);
        Start_Time.Set_Field (Field_Name => "next",      Field => Arrow);
        Append(Json_Start_Times, Start_Time);
      end;
    end loop;

    Json_Reply.Set_Field (Field_Name => "datatable", Field => Json_Start_Times);

    return Json_Reply.Write;

  end Get_Starttimes;


end Bot_Ws_Services;
