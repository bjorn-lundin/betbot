
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
--with Ada.Environment_Variables;
with Ada.Containers;
--with Ada.Characters.Handling;
--with Ada.Exceptions;

with Ada.Containers.Doubly_Linked_Lists;


--flowers
with Ada.Characters;
with Ada.Characters.Latin_1;

with AWS;
with AWS.SMTP;
--with AWS.SMTP.Authentication;
--with AWS.SMTP.Authentication.Plain;
with AWS.SMTP.Client;
with Ada.Directories;
with GNAT.Sockets;
with Ada.Environment_Variables;

with Table_Airreadings;
with Table_Freadings;
with Table_Fsensors;

--with Types; use Types;
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
with Markets;


package body Bot_Ws_Services is

  Object : constant String := "Bot_Ws_Services.";


  Select_Bets                     : Sql.Statement_Type;
  Select_Sum_Bets                 : Sql.Statement_Type;
  Select_Sum_Bets_Named           : Sql.Statement_Type;
  Select_Sum_Bets_Grouped_By_Name : Sql.Statement_Type;
  Select_Sum_Bets_Grouped_By_Week : Sql.Statement_Type;
  Select_Sum_Bets_Grouped_By_Month : Sql.Statement_Type;
  Select_Distict_Betnames         : Sql.Statement_Type;
  
  Global_Initiated                : Boolean := False;
  Global_Start_Time_List          : Table_Astarttimes.Astarttimes_List_Pack2.List;

  
  package Betnames_List_Package is new Ada.Containers.Doubly_Linked_Lists(Bot_Types.Betname_Type);
  
  ------------------------------------------------------------------

  Is_Initialized : Boolean := False;
  

  package body Global is
    
     procedure Initialize is
     begin
       if not Is_Initialized then
         Host.Set(Ini.Get_Value("database", "host", ""));
         Port := Ini.Get_Value("database", "port", 5432);
         Login.Set(Ini.Get_Value("database", "username", ""));
         Password.Set(Ini.Get_Value("database", "password", ""));
         Is_Initialized := True;
       end if;
     end Initialize;
   end Global;
   ----------------------------------------
  
  
  
  
  
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
    Service           : constant String := "Operator_Login";
  begin
    Log(Object & Service, "User '" & Username & "' Login");
    if Login_Os(Username,Password) then
      return Positive_Answer(Context => Context);
    else
      Log(Object & Service, "User " & Username & " Login OS failed");
      Error_Message := To_Unbounded_String("Login OS failed");
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
                            "select round(sum( " &
                              "    case when BETWON " &
                              "       then abets.PROFIT * 0.98 " &
                              "       else abets.PROFIT " &
                              "    end)::numeric,2) PROFIT, " &
                              "sum(SIZEMATCHED) SIZEMATCHED " &
                              "from ABETS " &
                              "where STARTTS >= :START " &
                              "and STARTTS <= :STOP " &
                              "and STATUS = 'SETTLED'"
                           );
    Select_Sum_Bets_Named.Prepare(
                                  "select " & "round(sum( " &
                                    "    case when BETWON " &
                                    "       then abets.PROFIT * 0.98 " &
                                    "       else abets.PROFIT " &
                                    "    end)::numeric,2) PROFIT, " &
                                    "from ABETS " &
                                    "where STARTTS >= :START " &
                                    "and STARTTS <= :STOP " &
                                    "and BETNAME = :BETNAME " &
                                    "and STATUS = 'SETTLED'"
                                 );

    Select_Sum_Bets_Grouped_By_Name.Prepare(
                                              "select BETNAME, " &
                                              "round(sum( " &
                                              "    case when BETWON " &
                                              "       then abets.PROFIT * 0.98 " &
                                              "       else abets.PROFIT " &
                                              "    end)::numeric,2) PROFIT, " &
                                              "sum(SIZEMATCHED) SIZEMATCHED, count('a') CNT, " &
                                              "SIDE side, " &
                                              "round((case SIDE " &
                                              "   when 'BACK' then " &
                                              "     round((100.0 * " &
                                              "     sum( " &
                                              "        case when betwon " &
                                              "          then abets.profit*0.98 " &
                                              "          else abets.profit " &
                                              "        end)/sum(sizematched)),2) " &
                                              "    when 'LAY'  then " &
                                              "      round((100.0 * " &
                                              "      sum( " &
                                              "         case when betwon " &
                                              "           then 0.98* (abets.profit/((pricematched-1) * sizematched)) " &
                                              "           else       (abets.profit/((pricematched-1) * sizematched)) " &
                                              "         end))/sum(sizematched),2) " &
                                              "    else 0.0 " &
                                              "end)::numeric,2) as RATIO, " &
                                              "round(sum(abets.PROFIT)/count('a'),2) PROFITPERBET " &
                                              "from ABETS " &
                                              "where STARTTS >= :START " &
                                              "and STARTTS <= :STOP " &
                                              "and STATUS = 'SETTLED' " &
                                              "group by BETNAME,SIDE " &
                                              "order by BETNAME" );
    
    
    Select_Sum_Bets_Grouped_By_Week.Prepare(
                                             "select " &
                                               "BETNAME, " &
                                               "round(sum( " &
                                                  "case when BETWON " &
                                                     "then PROFIT * 0.98 " &
                                                     "else PROFIT " &
                                                  "end),2) PROFIT2, " &
                                               "round((100.0 * sum( " &
                                                  "case when BETWON " &
                                                     "then PROFIT * 0.98 " &
                                                     "else PROFIT " &
                                                  "end)/ " &
                                                  "sum(SIZEMATCHED)),2) rate2 " &
                                             "from abets " &
                                             "where true " &
                                             "and BETNAME = :BETNAME " &
                                             "and status = 'SETTLED' " &
                                             "and startts > '2018-11-15' " &
                                             "and extract(year from BETPLACED) = :YEAR " &
                                             "and extract(week from BETPLACED) = :WEEK " &
                                             "group by BETNAME " &
                                             "having max(STARTTS) > '2018-11-15' " &
                                             "order by BETNAME");
    
    
    Select_Sum_Bets_Grouped_By_Month.Prepare(
                                             "select " &
                                               "BETNAME, " &
                                               "round(sum( " &
                                                  "case when BETWON " &
                                                     "then PROFIT * 0.98 " &
                                                     "else PROFIT " &
                                                  "end),2) PROFIT2, " &
                                               "round((100.0 * sum( " &
                                                  "case when BETWON " &
                                                     "then PROFIT * 0.98 " &
                                                     "else PROFIT " &
                                                  "end)/ " &
                                                  "sum(SIZEMATCHED)),2) rate2 " &
                                             "from abets " &
                                             "where true " &
                                             "and BETNAME = :BETNAME " &
                                             "and status = 'SETTLED' " &
                                             "and startts > '2018-11-15' " &
                                             "and extract(year from BETPLACED) = :YEAR " &
                                             "and extract(month from BETPLACED) = :MONTH " &
                                             "group by BETNAME " &
                                             "having max(STARTTS) > '2018-11-15' " &
                                             "order by BETNAME");
    
    
    Select_Distict_Betnames.Prepare(    
                                    "select " &
                                      "betname " &
                                    "from abets " &
                                    "where true " &
                                    "and status = 'SETTLED' " &
                                    "and startts > '2018-11-15' " &
                                    "group by betname " &
                                    "having max(startts) > '2018-11-15' " &
                                    "order by betname");
  end Prepare_Bets;

  ------------------------------------------------------------

  function Settled_Bets(Username   : in String;
                        Context    : in String;
                        Total_Only : in Boolean := False) return String is
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

    Log(Object & Service, "User '" & Username & "' Context '" & Context & "' Total " & Total_Only'img );

    Start.Hour        := 0;
    Start.Minute      := 0;
    Start.Second      := 0;
    Start.Millisecond := 0;

    T.Start;
    Prepare_Bets;

    if Context = "todays_bets" or Context = "todays_bets_total" then
      null; -- is ok already
    elsif Context = "yesterdays_bets" then
      Start := Start - (1,0,0,0,0);
      Stop  := Stop  - (1,0,0,0,0);
    elsif Context = "thisweeks_bets" or Context = "thisweeks_bets_total" then
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
        Stop := Start + (6,0,0,0,0);
      end;
    elsif Context = "lastweeks_bets" or Context = "lastweeks_bets_total" then
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
        Stop := Start + (6,0,0,0,0);
      end;
    elsif Context = "thismonths_bets" or Context = "thismonths_bets_total" then
      begin
        loop -- find first of this month
          case Start.Day is
            when 1 => exit ;
            when others => Start := Start - (1,0,0,0,0);
          end case ;
        end loop;
      end;
    elsif Context = "lastmonths_bets" or Context = "lastmonths_bets_total" then
      declare
        Passed_1st_First_Time : Boolean := False;
        Passed_1st_Second_Time : Boolean := False;
        Date_This_Month_1st : Calendar2.Time_Type := Calendar2.Time_Type_First;
      begin
        loop -- find first of this month, and then first of last month
         -- Log(Object & Service, "start " & Start.String_Date_And_Time & " Stop '" & Stop.String_Date_And_Time);
          case Start.Day is
            when 1 =>
              Passed_1st_First_Time := True;
              exit when Passed_1st_Second_Time ;
              
              if Passed_1st_First_Time then
                Passed_1st_Second_Time := True;
              end if;
              
              Date_This_Month_1st := Start;              
            when others => null;
          end case ;
          Start := Start - (1,0,0,0,0);
        end loop;
        Stop := Date_This_Month_1st - (1,0,0,0,0);
        
        Log(Object & Service, "start " & Start.String_Date_And_Time & " Stop '" & Stop.String_Date_And_Time);
      end;
    else
      Json_Reply.Set_Field (Field_Name => "result",  Field => "FAIL");
      Json_Reply.Set_Field (Field_Name => "context", Field => Context);
      Json_Reply.Set_Field (Field_Name => "text",    Field => "Bad context");          -- ???
      Log(Object & Service, "Return " & Json_Reply.Write);
      return Json_Reply.Write;
    end if;

    Stop.Hour        := 23;
    Stop.Minute      := 59;
    Stop.Second      := 59;
    Stop.Millisecond := 999;

    Select_Sum_Bets.Set("START", Start);
    Select_Sum_Bets.Set("STOP", Stop);
    
    if not Total_Only then
      Select_Bets.Set("START", Start);
      Select_Bets.Set("STOP", Stop);

      Bets.Read_List(Select_Bets, Bet_List);
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
      Json_Reply.Set_Field (Field_Name => "datatable", Field => Json_Bets);    
    end if;

    Select_Sum_Bets.Open_Cursor;
    Select_Sum_Bets.Fetch(End_Of_Set);
    if not End_Of_Set then
      Select_Sum_Bets.Get("PROFIT",Total_Profit);
    end if;
    Select_Sum_Bets.Close_Cursor;
    
    Json_Reply.Set_Field (Field_Name => "result",  Field => "OK");
    Json_Reply.Set_Field (Field_Name => "context", Field => Context);
    Json_Reply.Set_Field (Field_Name => "total", Field =>  Float(Total_Profit));

    T.Commit;
    Log(Object & Service, "Return " & Json_Reply.Write);
    Log(Object & Service, "Start " & Start.String_Date_And_Time & " Stop '" & Stop.String_Date_And_Time);
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
    Stop.Millisecond := 999;

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
    end;
    Stop := Start + (6,0,0,0,0);
    Stop.Hour        := 23;
    Stop.Minute      := 59;
    Stop.Second      := 59;
    Stop.Millisecond := 999;

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
  pragma Unreferenced(Weekly_Total);
  ----------------------------------------------------------------

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

    T.Start;
    Prepare_Bets;

    if Context = "sum_todays_bets" then
      null; -- is ok already
    elsif Context = "sum_7_days_bets" then
      Start := Start - (6,0,0,0,0);
    elsif Context = "sum_thisweeks_bets" then
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
        Stop := Start + (6,0,0,0,0);
      end;
    elsif Context = "sum_total_bets" then
      Start := (2018,11,1,0,0,0,0);
    else
      Json_Reply.Set_Field (Field_Name => "result",  Field => "FAIL");
      Json_Reply.Set_Field (Field_Name => "context", Field => Context);
      Json_Reply.Set_Field (Field_Name => "text",    Field => "Bad context");          -- ???
      Log(Object & Service, "Return " & Json_Reply.Write);
      return Json_Reply.Write;
    end if;

    Stop.Hour        := 23;
    Stop.Minute      := 59;
    Stop.Second      := 59;
    Stop.Millisecond := 999;

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


        Bet.Set_Field (Field_Name => "betname", Field => Utils.Trim(Betname));
        Bet.Set_Field (Field_Name => "profit",  Field => Float(Profit));
        Bet.Set_Field (Field_Name => "sm",      Field => Float(Sizematched));
        Bet.Set_Field (Field_Name => "count",   Field => Long_Long_Integer(Count));
        Bet.Set_Field (Field_Name => "p/b",     Field => Float(Profit_Per_Bet));
        Bet.Set_Field (Field_Name => "ratio",   Field => Float(Ratio));
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
    Initiated := False;

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
      when Rpc.Login_Failed => Log(Object & Service, "Start Rpc.Login_Failed, give up ");
                               return;     
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
      declare
        Start_Time : Json_Value := Create_Object;
        Market     : Markets.Market_Type;
        OK         : Boolean := False;
      begin
        Market.Marketname := S.Marketname;
        OK := Market.Marketname_Ok2(Allow_Chase => False, Allow_Hurdle => False);

        if OK then
          if not Arrow_Is_Printed and then Now <= S.Starttime then
            Arrow_Is_Printed := True;
            Arrow := "-->";
          --elsif not OK then
          --  Arrow := "-|-";
          else
            Arrow := "---";
          end if;
            
          Start_Time.Set_Field (Field_Name => "starttime",  Field => S.Starttime.String_Time(Seconds => False));
          Start_Time.Set_Field (Field_Name => "venue",      Field => S.Venue);
          Start_Time.Set_Field (Field_Name => "marketname", Field => S.Marketname);
          Start_Time.Set_Field (Field_Name => "next",       Field => Arrow);
          Append(Json_Start_Times, Start_Time);
        end if;  
      end;
    end loop;

    Json_Reply.Set_Field (Field_Name => "datatable", Field => Json_Start_Times);

    return Json_Reply.Write;

  end Get_Starttimes;
  
  
  procedure Get_Distinct_Betnames(Names : out Betnames_List_Package.List ) is 
    End_Of_Set      : Boolean := False;
    Betname         : Betname_Type := (others => ' ');
  begin
  
    Select_Distict_Betnames.Open_Cursor;
    loop
      Select_Distict_Betnames.Fetch(End_Of_Set);
      exit when End_Of_Set ;
      Select_Distict_Betnames.Get("BETNAME", Betname);
      Names.Append(Betname);
    end loop;
    Select_Distict_Betnames.Close_Cursor;
    
  end Get_Distinct_Betnames;

  
  function Bet_Color( Name : String ) return String is
    Service : constant String := "Bet_Color";
  begin
    if    Name = "HORSE_BACK_1_10_07_1_2_PLC_1_01"     then return "Lavender" ; 
    elsif Name = "HORSE_BACK_1_10_07_1_2_PLC_1_01_CHS" then return "Plum" ; 
    elsif Name = "HORSE_BACK_1_10_07_1_2_PLC_1_01_HRD" then return "Orchid" ; 
    elsif Name = "HORSE_BACK_1_10_13_1_2_WIN_1_01"     then return "LightPink" ; 
    elsif Name = "HORSE_BACK_1_28_02_1_2_PLC_1_01"     then return "MediumAquamarine" ; 
    elsif Name = "HORSE_BACK_1_28_02_1_2_PLC_1_01_CHS" then return "PaleGreen" ; 
    elsif Name = "HORSE_BACK_1_28_02_1_2_PLC_1_01_HRD" then return "Lime" ; 
    elsif Name = "HORSE_BACK_1_38_00_1_2_PLC_1_01"     then return "DeepSkyBlue" ; 
    elsif Name = "HORSE_BACK_1_38_00_1_2_PLC_1_01_CHS" then return "Cornflowerblue" ; 
    elsif Name = "HORSE_BACK_1_38_00_1_2_PLC_1_01_HRD" then return "Blue" ; 
    elsif Name = "HORSE_BACK_1_56_00_1_4_PLC_1_01"     then return "Wheat" ; 
    elsif Name = "HORSE_BACK_1_56_00_1_4_PLC_1_01_CHS" then return "RosyBrown" ; 
    elsif Name = "HORSE_BACK_1_56_00_1_4_PLC_1_01_HRD" then return "DarkGoldenrod" ; 
    elsif Name = "HORSE_LAY_1_05_05_1_2_WIN_2_15"      then return "DeepPink" ; 
    elsif Name = "HORSE_LAY_1_05_05_1_2_WIN_2_40"      then return "MediumVioletRed" ; 
    elsif Name = "HORSE_BACK_1_55_800M_PLC_1_01"       then return "Orange" ; 
    else    
      Log(Object & Service, "bet '" & Name & "' has no color");    
      return "Black" ; 
    end if;
  end Bet_Color;
    
  
  
  ----------------------------------------------------------
  function Get_Weeks(Username  : in String;
                     Context   : in String) return String is 
    --pragma Unreferenced(Username);
    Service : constant String := "Get_Weeks";

    T               : Sql.Transaction_Type;
    End_Of_Set      : Boolean := False;
    Start           : Calendar2.Time_Type := (2018,11,15,0,0,0,0);
    Stop            : Calendar2.Time_Type := Calendar2.Clock;
    Json_Reply      : Json_Value := Create_Object;
    Labels          : Json_Array := Empty_Array;
    Betname_List    : Betnames_List_Package.List;
    Json_Bets       : Json_Array := Empty_Array;
    Labels_Are_Appended : Boolean := False;
    use Calendar2;
  begin
    Log(Object & Service, "User '" & Username & "' Context '" & Context & "'");

    T.Start;
    Prepare_Bets;
    Get_Distinct_Betnames(Betname_List);
    Log(Object & Service, "Start " & Start.String_Date_And_Time & " Stop '" & Stop.String_Date_And_Time);
    
    Json_Reply.Set_Field (Field_Name => "result",  Field => "OK");
    Json_Reply.Set_Field (Field_Name => "context", Field => Context);

    Betnames_Loop  : for Betname of Betname_List loop 
      declare
        Bet       : Json_Value   := Create_Object;
        Data      : Json_Array := Empty_Array;
        Profit    : Fixed_Type   := 0.0;
      begin
      
        Select_Sum_Bets_Grouped_By_Week.Set("BETNAME", Utils.Trim(Betname));
              
        Year_Loop : for Year in 2018 .. 2022 loop 
          Week_Loop : for Week in 1 .. 53 loop           
        
            if (2018,11,15,0,0,0,0) <= Calendar2.To_Time(Year => Year_Type(Year), Week => Week_Type(Week), Day => Week_Day_Type'First) and then   
              Calendar2.To_Time(Year => Year_Type(Year), Week => Week_Type(Week), Day => Week_Day_Type'First) <= Stop then
        
              Select_Sum_Bets_Grouped_By_Week.Set("YEAR", Integer_4(Year));
              Select_Sum_Bets_Grouped_By_Week.Set("WEEK", Integer_4(Week));
              declare
                String_Week    : String(1..7) := (others => ' ');
              begin
                Move(Utils.Trim(Year'Img) & "-" & Utils.Trim(Week'Img), String_Week);
        
                if String_Week(7) = ' ' then 
                  String_Week(7) := String_Week(6);
                  String_Week(6) := '0';
                end if;
        
                Select_Sum_Bets_Grouped_By_Week.Open_Cursor;
                Select_Sum_Bets_Grouped_By_Week.Fetch(End_Of_Set);
                if not End_Of_Set then 
                   Select_Sum_Bets_Grouped_By_Week.Get("PROFIT2", Profit);
                else
                  Profit := 0.0;
                end if;
                Select_Sum_Bets_Grouped_By_Week.Close_Cursor;

                Append(Data,Create(Float(Profit)));
                
                if not Labels_Are_Appended then 
                  Append(Labels, Create(String_Week));
                end if;
                
                Bet.Set_Field (Field_Name => "label", Field => Utils.Trim(Betname));
                Bet.Set_Field (Field_Name => "backgroundColor", Field => Bet_Color(Utils.Trim(Betname)));
                Bet.Set_Field (Field_Name => "hoverBackgroundColor", Field => Bet_Color(Utils.Trim(Betname)));
                
              end ;
            end if;
          end loop Week_Loop;
        end loop Year_Loop;
        Labels_Are_Appended := True;
        Bet.Set_Field (Field_Name => "data", Field => Data);
        Append(Json_Bets, Bet);
       end;
    end loop Betnames_Loop;

    --Json_Reply.Set_Field (Field_Name => "datatable", Field => Json_Bets);
    Json_Reply.Set_Field (Field_Name => "labels", Field => Labels);
    Json_Reply.Set_Field (Field_Name => "datasets", Field => Json_Bets);

    T.Commit;
    Log(Object & Service, "Return " & Json_Reply.Write);
    return Json_Reply.Write;
    
    end Get_Weeks;
  ----------------------------------------------------------
  ----------------------------------------------------------
  function Get_Months(Username  : in String;
                     Context   : in String) return String is 
    --pragma Unreferenced(Username);
    Service : constant String := "Get_Months";

    T               : Sql.Transaction_Type;
    End_Of_Set      : Boolean := False;
    Start           : Calendar2.Time_Type := (2018,10,15,0,0,0,0);
    Stop            : Calendar2.Time_Type := Calendar2.Clock;
    Now             : Calendar2.Time_Type := Calendar2.Clock;
    Json_Reply      : Json_Value := Create_Object;
    Labels          : Json_Array := Empty_Array;
    Betname_List    : Betnames_List_Package.List;
    Json_Bets       : Json_Array := Empty_Array;
    Labels_Are_Appended : Boolean := False;
    use Calendar2;
  begin
    Log(Object & Service, "User '" & Username & "' Context '" & Context & "'");

    T.Start;
    Prepare_Bets;
    Get_Distinct_Betnames(Betname_List);
    Log(Object & Service, "Start " & Start.String_Date_And_Time & " Stop '" & Stop.String_Date_And_Time);
    
    Json_Reply.Set_Field (Field_Name => "result",  Field => "OK");
    Json_Reply.Set_Field (Field_Name => "context", Field => Context);

    Betnames_Loop  : for Betname of Betname_List loop 
      declare
        Bet       : Json_Value   := Create_Object;
        Data      : Json_Array := Empty_Array;
        Profit    : Fixed_Type   := 0.0;
      begin
      
        Select_Sum_Bets_Grouped_By_Month.Set("BETNAME", Utils.Trim(Betname));
              
        Year_Loop : for Year in 2018 .. 2022 loop 
          Month_Loop : for Month in 1 .. 12 loop           
            Stop.Year := Year_Type(Year);
            Stop.Month := Month_Type(Month);
            Stop.Day := 1;
        
            if Start < Stop and then Stop < Now then
        
              Select_Sum_Bets_Grouped_By_Month.Set("YEAR", Integer_4(Year));
              Select_Sum_Bets_Grouped_By_Month.Set("MONTH", Integer_4(Month));
              declare
                String_Month    : String(1..7) := (others => ' ');
              begin
                Move(Utils.Trim(Year'Img) & "-" & Utils.Trim(Month'Img), String_Month);
        
                if String_Month(7) = ' ' then 
                  String_Month(7) := String_Month(6);
                  String_Month(6) := '0';
                end if;
        
                Select_Sum_Bets_Grouped_By_Month.Open_Cursor;
                Select_Sum_Bets_Grouped_By_Month.Fetch(End_Of_Set);
                if not End_Of_Set then 
                   Select_Sum_Bets_Grouped_By_Month.Get("PROFIT2", Profit);
                else
                  Profit := 0.0;
                end if;
                Select_Sum_Bets_Grouped_By_Month.Close_Cursor;

                Append(Data,Create(Float(Profit)));
                
                if not Labels_Are_Appended then 
                  Append(Labels, Create(String_Month));
                end if;
                
                Bet.Set_Field (Field_Name => "label", Field => Utils.Trim(Betname));
                Bet.Set_Field (Field_Name => "backgroundColor", Field => Bet_Color(Utils.Trim(Betname)));
                Bet.Set_Field (Field_Name => "hoverBackgroundColor", Field => Bet_Color(Utils.Trim(Betname)));
                
              end ;
            end if;
          end loop Month_Loop;
        end loop Year_Loop;
        Labels_Are_Appended := True;
        Bet.Set_Field (Field_Name => "data", Field => Data);
        Append(Json_Bets, Bet);
       end;
    end loop Betnames_Loop;

    --Json_Reply.Set_Field (Field_Name => "datatable", Field => Json_Bets);
    Json_Reply.Set_Field (Field_Name => "labels", Field => Labels);
    Json_Reply.Set_Field (Field_Name => "datasets", Field => Json_Bets);

    T.Commit;
    Log(Object & Service, "Return " & Json_Reply.Write);
    return Json_Reply.Write;
    
    end Get_Months;
  ----------------------------------------------------------
  
  
  -- for moisture in flowers
  -----------------------------------------------------  

  function Log_Data(Id : String; 
                    Moisture : Integer_4;
                    Moisture_Pct : out integer_4;
                    Sensor : in out String_Object) return Boolean is
                    
    Service       : constant String := "MMR.Log_Data";
    T             : Sql.Transaction_Type;
    Freading_Data :  Table_Freadings.Data_Type;
    Fsensor_Data  :  Table_Fsensors.Data_Type;
    type Eos_Type is (Fsensor); --,Freading);
    Eos           : array (Eos_Type'Range) of Boolean := (others => False);    
    Result        : Boolean := False;
    Now           : Calendar2.Time_Type := Calendar2.Clock;
    use Calendar2;    
  begin
    if Sql.Is_Session_Open then
      Logging.Log(Service, "was already connected, disconnect!");
      Sql.Close_Session;
      Logging.Log(Service, "did disconnect!");
    end if;      
      
    Sql.Connect
      (Host     => Global.Host.Fix_String,
       Port     => Global.Port,
       Db_Name  => "flowers",
       Login    => Global.Login.Fix_String, -- always bnl
       Password => Global.Password.Fix_String);
    
    Logging.Log(Service, "did connect to flowers");
    T.Start;
    Move(Id, Freading_Data.Macaddress);
    Freading_Data.Created := Now;
    Freading_Data.Reading := Moisture;
    Freading_Data.Insert;
    
    Move(Id, Fsensor_Data.Macaddress);
    Fsensor_Data.Read(Eos(Fsensor));
    
    if not Eos(Fsensor) then
      Logging.Log(Service, Fsensor_Data.To_String);
      if Moisture > Fsensor_Data.Threshold -- reversed ratio . 1024 = dry, 550= wet. above ca 900 -> time to mail 
        and then Now - Fsensor_Data.Lastnotify > (1,0,0,0,0) --one day ago
      then
        Result := True;
        Fsensor_Data.Lastnotify := Now;
        Fsensor_Data.Update_Withcheck;
        Sensor.Set(Fsensor_Data.Potname);
      else
        Result := False;
      end if;
      Logging.Log(Service, "result " & Result'Img);
    end if;
        
    Moisture_Pct := Integer_4(100 * (1024 - Moisture)/ 1024);
    T.Commit;
    Sql.Close_Session;

    return Result; 
  end Log_Data;
  -----------------------------------------------------  

  Function Mail_Moisture_Report(Id : String; Moisture : Integer_4) return Boolean is
     T       : Calendar2.Time_Type := Calendar2.Clock;
    use AWS;
    Service : constant String := "Mail_Moisture_Report";
    SMTP_Server_Name : constant String := "mailout.telia.com";
    Status           : SMTP.Status;
    Subject          : String :="Dags att vattna blommorna";
    Should_Send_Mail : Boolean := False;
    Moisture_Pct     : Integer_4 := 0;
    Sensorname       : String_Object;
  begin
    Ada.Directories.Set_Directory(Ada.Environment_Variables.Value("BOT_CONFIG") & "/sslcert");
    
    Should_Send_Mail := Log_Data(Id, Moisture, Moisture_Pct, Sensorname);
    
    if Should_Send_Mail then 
      declare
        -- Auth : aliased constant SMTP.Authentication.Plain.Credential :=
        --                            SMTP.Authentication.Plain.Initialize ("AKIAYGPN2VOGCGGBI4XE",
        --                                            "Ag9otCKVee7ObYIO0Np2A6avUmZfjIGAUupYkPOB1sQf"); -- fixed by java-tool

        Smtp_Server : Smtp.Receiver := Smtp.Client.Initialize
          (Smtp_Server_Name,
           Port       => 465,
           Secure     => True);
        --Credential => Auth'Unchecked_Access);
        use Ada.Characters.Latin_1;
        Msg : constant String := 
                "Fuktnivå :" & Moisture_Pct'Img & "% för blomma " & Sensorname.Fix_String & Cr & Lf &
                "tid : " & Calendar2.String_Date_Time_Iso (T, " ", " ") & Cr & Lf &
                "sent from: " & Gnat.Sockets.Host_Name ;

        Receivers : constant Smtp.Recipients :=  (1 =>
                                                    Smtp.E_Mail("B Lundin", "b.f.lundin@gmail.com")
                                                 );
      begin
        Smtp.Client.Send(Server  => Smtp_Server,
                         From    => Smtp.E_Mail ("Blomsterkollen", "betbot@lundin.duckdns.com"),
                         To      => Receivers,
                         Subject => Subject,
                         Message => Msg,
                         Status  => Status);
        Log (Object & Service, "subject: " & Subject);
        Log (Object & Service, "body: " & Msg);
      end;
      if not Smtp.Is_Ok (Status) then
        Log (Object & Service, "Can't send message: " & Smtp.Status_Message (Status));
      end if;
    end if;
    return True;
  exception
    when others =>
      return False;
  end Mail_Moisture_Report;
  --------------------------------
  
  
  -- for airquality
  -----------------------------------------------------  

  procedure Log_Air_Quality(Id : String; 
                    Temperature : Fixed_Type;
                    Pressure    : Integer_4;
                    Humidity    : Fixed_Type;
                    Gasresistance : Integer_4) is
                    
    Service       : constant String := ".Log_Air_Quality";
    T             : Sql.Transaction_Type;
    pragma Warnings(Off,T);
    Airreading_Data    :  Table_Airreadings.Data_Type;
    pragma Warnings(Off,Airreading_Data);
    Now           : Calendar2.Time_Type := Calendar2.Clock;
    --use Calendar2;    
  begin
    if Sql.Is_Session_Open then
      Logging.Log(Service, "was already connected, disconnect!");
      Sql.Close_Session;
      Logging.Log(Service, "did disconnect!");
    end if;      
      
    Sql.Connect
      (Host     => Global.Host.Fix_String,
       Port     => Global.Port,
       Db_Name  => "flowers",
       Login    => Global.Login.Fix_String, -- always bnl
       Password => Global.Password.Fix_String);
    
    Logging.Log(Service, "did connect to flowers");
    T.Start;
    Move(Id, Airreading_Data.Macaddress);
    Airreading_Data.Created := Now;
    Airreading_Data.Temperature := Temperature;
    Airreading_Data.Pressure := Pressure;
    Airreading_Data.Humidity := Humidity;
    Airreading_Data.Gasresistance := Gasresistance;
    Airreading_Data.Insert;
    
    T.Commit;
    Sql.Close_Session;

  end Log_Air_Quality;
  -----------------------------------------------------  
  

  procedure Log_C02 (Id    : String;
                     Level : Integer_4) is
                    
    Service       : constant String := ".Log_Co2";
    T             : Sql.Transaction_Type;
    pragma Warnings(Off,T);
    Airreading_Data    :  Table_Airreadings.Data_Type;
    pragma Warnings(Off,Airreading_Data);
    Now           : Calendar2.Time_Type := Calendar2.Clock;
    --use Calendar2;    
  begin
    if Sql.Is_Session_Open then
      Logging.Log(Service, "was already connected, disconnect!");
      Sql.Close_Session;
      Logging.Log(Service, "did disconnect!");
    end if;      
      
    Sql.Connect
      (Host     => Global.Host.Fix_String,
       Port     => Global.Port,
       Db_Name  => "flowers",
       Login    => Global.Login.Fix_String, -- always bnl
       Password => Global.Password.Fix_String);
    
    Logging.Log(Service, "did connect to flowers");
    T.Start;
    Move(Id, Airreading_Data.Macaddress);
    Airreading_Data.Created := Now;
    Airreading_Data.Temperature := 0.0;
    Airreading_Data.Pressure := Level;
    Airreading_Data.Humidity := 0.0;
    Airreading_Data.Gasresistance := 0;
    Airreading_Data.Insert;
    
    T.Commit;
    Sql.Close_Session;

  end Log_C02;
  -----------------------------------------------------  
  
  
end Bot_Ws_Services;
