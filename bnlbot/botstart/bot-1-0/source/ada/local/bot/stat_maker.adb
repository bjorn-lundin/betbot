with Ada.Exceptions;
with Ada.Command_Line;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
--with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Environment_Variables;
with Text_io;

with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Logging; use Logging;


with Stacktrace;
with Types; use Types;
--with Bot_Types; use Bot_Types;
with Sql;
with Calendar2; use Calendar2;
with Ini;
with Statistics;
with Utils; use Utils;
with Table_Abets;
with Table_Apriceshistory;
with Ada.Containers;

procedure  Stat_Maker is
  package EV renames Ada.Environment_Variables;
  package CLI renames Ada.Command_Line;

  s : Statistics.Stats_Array_Type;

  T : Sql.Transaction_Type;

  Bet_List  : Table_Abets.Abets_List_Pack2.List;
  Tmp_Price : Table_Apriceshistory.Data_Type;
  Eos       : Boolean := False;


  FO: Statistics.First_Odds_Range_Type;
  SO: Statistics.Second_Odds_Range_Type;
  GMT,MT: Statistics.Market_Type;

  Cmd_Line           : Command_Line_Configuration;
  Sa_Par_Market_Type : aliased Gnat.Strings.String_Access;
  Ba_Par_Update_Only : aliased Boolean := False;

  Select_Untreated_Bets : Sql.Statement_Type;
  Select_Prices_From_Dry : Sql.Statement_Type;

  Cnt : Natural := 0;
  Me : constant String := "Stat_Maker.Main";
  use type Ada.Containers.Count_Type;
begin

   Define_Switch
    (Cmd_Line,
     Sa_Par_Market_Type'access,
     Long_Switch => "--market_type=",
     Help        => "win or plc");

   Define_Switch
    (Cmd_Line,
     Ba_Par_Update_Only'access,
     Long_Switch => "--update_only",
     Help        => "update database and exit");

  Getopt (Cmd_Line);  -- process the command line

  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");

  if Ba_Par_Update_Only then
    Log(Me, "Login ael");
    Sql.Connect
        (Host     => Ini.Get_Value("stats", "host", ""),
         Port     => Ini.Get_Value("stats", "port", 5432),
         Db_Name  => Ini.Get_Value("stats", "name", ""),
         Login    => Ini.Get_Value("stats", "username", ""),
         Password => Ini.Get_Value("stats", "password", ""));
    
    T.Start;
    Select_Untreated_Bets.Prepare("select * from ABETS where STATUS = '-'");
    Table_Abets.Read_List(Select_Untreated_Bets, Bet_List);
    Log(Me, "Num bets to update" & Bet_List.Length'Img);
    T.Commit;
    Sql.Close_Session;
    Log(Me, "logged out ael");
  
  
    if Bet_List.Length > 0 then
      -- update with info from dry
      Sql.Connect
            (Host     => Ini.Get_Value("dry", "host", ""),
             Port     => Ini.Get_Value("dry", "port", 5432),
             Db_Name  => Ini.Get_Value("dry", "name", ""),
             Login    => Ini.Get_Value("dry", "username", ""),
             Password => Ini.Get_Value("dry", "password", ""));
      Log(Me, "logged in dry");
      T.Start;

      for b of Bet_List loop
        Cnt := Cnt +1;
        if Cnt rem 100 = 0 then
          Log(Me, F8_Image(Float_8(cnt)*100.0/Float_8(Bet_List.Length)) & '%');
        end if;
        if B.Status(1) = '-' then
          Select_Prices_From_Dry.Prepare(
            "select * " &
            "from APRICESHISTORY " &
            "where MARKETID = :MARKETID " &
            "and SELECTIONID = :SELECTIONID " &
            "and PRICETS >= :ONESECAFTER " &
            "and PRICETS <= :TWOSECSAFTER " &
            "order by PRICETS ");
  
          Select_Prices_From_Dry.Set("MARKETID", B.Marketid);
          Select_Prices_From_Dry.Set("SELECTIONID", B.Selectionid);
          Select_Prices_From_Dry.Set("ONESECAFTER", B.Betplaced + (0,0,0,1,0));
          Select_Prices_From_Dry.Set("TWOSECSAFTER", B.Betplaced + (0,0,0,2,0));
          Select_Prices_From_Dry.Open_Cursor;
          Select_Prices_From_Dry.Fetch(Eos);
          if not Eos then
            Tmp_Price := Table_Apriceshistory.Get(Select_Prices_From_Dry);
            if Ada.Strings.Fixed.Index(B.Betname, "WIN") > Natural(0) then
              if Tmp_Price.Backprice >= B.Price then
                B.Status(1) := 'M';
                B.Pricematched := Tmp_Price.Backprice;
              else
                B.Status(1) := 'U';
              end if;
            elsif Ada.Strings.Fixed.Index(B.Betname, "PLC") > Natural(0) then
              if Tmp_Price.Backprice >= 1.02 then
                B.Status(1) := 'M';
                B.Pricematched := Tmp_Price.Backprice;
              else
                B.Status(1) := 'U';
              end if;
            end if;
          else
            B.Status(1) := 'U';
          end if;
  
          case B.Status(1) is
            when 'M' =>
              if B.Betwon then
                B.Profit := (B.Pricematched -1.0) * B.Sizematched;
              else
                B.Profit := -B.Sizematched;
              end if;
            when others =>
                B.Profit := 0.0;
          end case;
          Select_Prices_From_Dry.Close_Cursor;
        end if;
      end loop;
      T.Commit;
      Sql.Close_Session;
      Log(Me, "logged out dry");
  
      Log(Me, "Login ael");
      Sql.Connect
          (Host     => Ini.Get_Value("stats", "host", ""),
           Port     => Ini.Get_Value("stats", "port", 5432),
           Db_Name  => Ini.Get_Value("stats", "name", ""),
           Login    => Ini.Get_Value("stats", "username", ""),
           Password => Ini.Get_Value("stats", "password", ""));
  
      T.Start;
      Cnt := 0;
      for b of Bet_List loop
        Cnt := Cnt +1;
        if Cnt rem 100 = 0 then
          Log(Me, F8_Image(Float_8(cnt)*100.0/Float_8(Bet_List.Length) ) & '%');
        end if;
        B.Update_Withcheck;
      end loop;
      T.Commit;
      Sql.Close_Session;
      Log(Me, "logged out ael and exit");
      CLI.Set_Exit_Status(CLI.Success);
    else  
      CLI.Set_Exit_Status(CLI.Failure);
    end if; -- bet_list.length > 0 
    return;
  end if ; --update only

  GMT := Statistics.Market_Type'Value(Sa_Par_Market_Type.all);

  Bet_List.Clear;
  Log(Me, "Login ael");
  Sql.Connect
        (Host     => Ini.Get_Value("stats", "host", ""),
         Port     => Ini.Get_Value("stats", "port", 5432),
         Db_Name  => Ini.Get_Value("stats", "name", ""),
         Login    => Ini.Get_Value("stats", "username", ""),
         Password => Ini.Get_Value("stats", "password", ""));

  T.Start;
  Log(Me, "read all bets");
  Table_Abets.Read_All(Bet_List);
  T.Commit;
  Sql.Close_Session;
  Log(Me, "logged out");

  for b of Bet_List loop
    FO := Statistics.Get_First_Odds_Range(B.Betname);
    SO := Statistics.Get_Second_Odds_Range(B.Betname);
    MT:= Statistics.Get_Market_Type(B.Betname);
    S(FO,SO,MT).Treat(B);
  end loop;

  for fi in Statistics.First_Odds_Range_Type'range loop
    for sn in Statistics.Second_Odds_Range_Type'range loop
       S(Fi,Sn,GMT).Calculate_Avg_Odds;    
      Statistics.Print_Result( S(Fi, Sn, GMT),Fi, Sn, GMT);
    end loop;
  end loop;

  Log(Me, "Done");


exception
  when E: others =>
    declare
      Last_Exception_Name     : constant String  := Ada.Exceptions.Exception_Name(E);
      Last_Exception_Messsage : constant String  := Ada.Exceptions.Exception_Message(E);
      Last_Exception_Info     : constant String  := Ada.Exceptions.Exception_Information(E);
    begin
      Text_io.Put_Line(Last_Exception_Name);
      Text_io.Put_Line("Message : " & Last_Exception_Messsage);
      Text_io.Put_Line(Last_Exception_Info);
      Text_io.Put_Line("addr2line" & " --functions --basenames --exe=" &
           Ada.Command_Line.Command_Name & " " & Stacktrace.Pure_Hexdump(Last_Exception_Info));
    end ;

end Stat_Maker;

