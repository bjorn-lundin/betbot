
with Types ; use Types;
with Bot_Types ; use Bot_Types;
with Stacktrace;
with Sql;
with Bets;
with Calendar2; use Calendar2;
with Logging; use Logging;
--with General_Routines; use General_Routines;
with Tics;
with Utils; use Utils;

procedure Profit_Min_Max is
  Bet_List     : Bets.Lists.List;
  Bets_A_Day   : Sql.Statement_Type;
  T : Sql.Transaction_Type;
  Daily_Profit , Global_Profit : Profit_Type := 0.0;
  Start_Date   : Calendar2.Time_Type := (2016,12,19,0,0,0,0);
  Stop_Date    : Calendar2.Time_Type := (2017,1,8,0,0,0,0);
  Current_Date : Calendar2.Time_Type := Start_Date;
  One_Day      : Calendar2.Interval_Type := (1,0,0,0,0);
  Global_Max   : Profit_Type := 500.0;
  Global_Min   : Profit_Type := -200.0;
  Global_Size  : Bet_Size_Type   := 100.0;

  ------------------------------------------------------------
  procedure Profit_Per_Bet_And_Day(Bet_List : Bets.Lists.List;
                                   Min      : Profit_Type;
                                   Max      : Profit_Type;
                                   Profit   : out Profit_Type) is
    Local_Profit : Profit_Type := 0.0;
  begin -- TODO fix correct commision
    for Bet of Bet_List loop
      Local_Profit := Local_Profit + Profit_Type(Bet.Profit);
      Log(F8_Image(Float_8(Local_Profit)));
      if Local_Profit > Max then
        exit;
      elsif Local_Profit < Min then
        exit;
      end if;
    end loop;
    Profit := Local_Profit;
  end Profit_Per_Bet_And_Day;

  ------------------------------------------------------------
  procedure Fix_Bets_In_List(Bet_List : in out Bets.Lists.List) is
    Tic : Integer := 0;
  begin
    for Bet of Bet_List loop
      Bet.Size := Float_8(Global_Size);
      if    Bet.Side(1..3) = "LAY" then
        -- to get back to original legal odds
        Tic := Tics.Get_Nearest_Higher_Tic_Index(Bet.Price);
        Bet.Pricematched := Tics.Get_Tic_Price(Tic-3); -- some small margin to get the bet
        if Bet.Betwon then
          Bet.Profit := Bet.Size;
        else
          Bet.Profit := -Bet.Size * (Bet.Pricematched -1.0);
        end if;
      elsif Bet.Side(1..4) = "BACK" then
        -- to get back to original legal odds
        Tic := Tics.Get_Nearest_Higher_Tic_Index(Bet.Price);
        Bet.Pricematched := Tics.Get_Tic_Price(Tic+3); -- some small margin to get the bet
        if Bet.Betwon then
          Bet.Profit := Bet.Size * (Bet.Pricematched -1.0);
        else
          Bet.Profit := -Bet.Size;
        end if;
      else
        Log("WTF! " & Bet.To_String);
      end if ;
    end loop;
  end Fix_Bets_In_List;
  ------------------------------------------------------------




begin
  Log ("Connect db");
  Sql.Connect
    (Host     => "betbot.nonobet.com",
     Port     => 5432,
     Db_Name  => "bnl",
     Login    => "bnl",
     Password => "ld4BC9Q51FU9CYjC21gp");
--    Sql.Connect
--      (Host     => "192.168.1.20",
--       Port     => 5432,
--       Db_Name  => "dry",
--       Login    => "bnl",
--       Password => "bnl");


  T.Start;
  Bets_A_Day.Prepare("select * from ABETS " &
                       "where BETNAME=:BETNAME " &
                       "and STARTTS >=:START " &
                       "and STARTTS <=:STOP " &
                       "order by BETPLACED"
                    );

  loop
    Bets_A_Day.Set("BETNAME","BACK_4_4_4_09_15_WIN");
    Bets_A_Day.Set("START",Current_Date);
    Bets_A_Day.Set("STOP",Current_Date+One_Day);
    Bet_List.Clear;
    Bets.Read_List(Bets_A_Day,Bet_List);
    Log("num bets" & Bet_List.Length'Img);
    Fix_Bets_In_List(Bet_List);
    Profit_Per_Bet_And_Day(Bet_List => Bet_List,
                           Min      => Global_Min,
                           Max      => Global_Max,
                           Profit   => Daily_Profit) ;

    Global_Profit := Global_Profit + Daily_Profit;
    Log("daily profit = " & Current_Date.To_String & " " & Integer_4(Daily_Profit)'Img);
    Current_Date := Current_Date + One_Day;
    exit when Current_Date > Stop_Date;
  end loop;


  T.Commit ;
  Sql.Close_Session;

  Log("Total profit = " & Integer_4(Global_Profit)'Img);
exception
  when E: others =>
    Stacktrace.Tracebackinfo(E);
end Profit_Min_Max;
