with Stacktrace;
with Types; use Types;
with Calendar2; use Calendar2;
--with General_Routines; use General_Routines;
with GNAT; use GNAT;
with GNAT.AWK;
with Text_Io; use Text_Io;
with Sql;
with Table_Araceprices;
with Logging; use Logging;

with Ada.Strings;       use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Utils; use Utils;

procedure Prices_During_Race is
  Me : String := "Prices_During_Race";
  Computer_File : AWK.Session_Type;
  T : Sql.Transaction_Type;
  -----------------------------------------------------
  function To_Time(S2: String) return Calendar2.Time_Type is
    Tmp : Time_Type;
    S : String (1 .. S2'Last - S2'First + 1) := S2;
  begin
    -- '2014-03-22 18:15:40.188'
    Tmp.Year  := Year_Type'Value (S (1 .. 4));
    Tmp.Month := Month_Type'Value (S (6 .. 7));
    Tmp.Day   := Day_Type'Value (S (9 .. 10));

    Tmp.Hour   := Hour_Type'Value (S (12 .. 13));
    Tmp.Minute := Minute_Type'Value (S (15 .. 16));
    Tmp.Second := Second_Type'Value (S (18 .. 19));
    Tmp.MilliSecond := MilliSecond_Type'Value (S (21 .. 23));
    return Tmp;
  end To_Time;
  -----------------------------------------------------
  function Value(s: String) return String is
    Pos : Integer := 0;
  begin
    for i in s'range loop
      case S(i) is
        when '=' => pos := i; 
                    exit;
        when others => null;
      end case;
    end loop;
    return S(Pos+1..S'Last);
  end Value;
  ------------------------------------
  Cnt : Integer_4 := 0;
  Rec : Table_Araceprices.Data_Type;
begin
  AWK.Set_Current (Computer_File);
  AWK.Open (Separators => "|",
            Filename   => "/home/bnl/bnlbot/botstart/bot-1-0/history/data/prices_during_horse_race/result121.dat");

  Log(Me, "log in to new database");
  Sql.Connect
     (Host   => "localhost",
      Port   => 5432,
      Db_Name => "bnl",
      Login  => "bnl",
      Password => "bnl");
  Log(Me, "db Connected");
  
  T.Start;
  while not AWK.End_Of_File loop
    Cnt := Cnt +1;
    AWK.Get_Line;
    Rec := Table_Araceprices.Empty_Data;
    Rec.Pricets := To_Time(AWK.Field (1));
    Move(Trim(Value(AWK.Field (2))), Rec.Marketid);
    Rec.Selectionid := Integer_4'Value(Value(AWK.Field (3)));
    Move(Trim(Value(AWK.Field (5))), Rec.Status);
    Rec.Backprice := Float_8'Value(Value(AWK.Field (7)));
    Rec.Layprice:= Float_8'Value(Value(AWK.Field (8)));
    
    Table_Araceprices.Insert(Rec); 
    
    if Cnt mod 10_000 = 0 then
      Log (Cnt'Img);
      Set_Col(1);   Put(Trim(AWK.Field (1)) & " |");  -- time
      Set_Col(27);  Put(Trim(Value(AWK.Field (2))) & " |");  -- marketid
      Set_Col(41);  Put(Trim(Value(AWK.Field (3))) & " |");  -- selectionid
  --    Set_Col(50);  Put(Trim(AWK.Field (4)) & "|"); -- pricets (in F1)
      Set_Col(51); Put(Trim(Value(AWK.Field (5))) & " |");  -- Status
  --    Set_Col(105); Put(Trim(AWK.Field (6)) & "|"); -- Totalmached
      Set_Col(60); Put(Trim(Value(AWK.Field (7)))); -- Backprice
      Set_Col(67); Put("|"); 
      Set_Col(69); Put(Trim(Value(AWK.Field (8))) ); -- Layprice
      New_Line;
      T.Commit;
      T.Start;           
    end if;
    
  end loop;
  T.Commit;

  AWK.Close (Computer_File);
  Log(Me, "close new db");
  Sql.Close_Session;

exception
  when E: others =>
    Stacktrace.Tracebackinfo(E);
end Prices_During_Race;