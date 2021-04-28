with Ada.Exceptions;
with Ada.Command_Line;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Environment_Variables;
with Gnat.Command_Line; use Gnat.Command_Line;
with Gnat.Strings;
with Stacktrace;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Sql;
with Calendar2; use Calendar2;
with Bot_Messages;
with Rpc;
with Lock ;
with Posix;
with Ini;
with Logging; use Logging;
with Process_Io;
with Core_Messages;
with Markets;
with Events;
with Prices;
with Balances;
with Bot_Svn_Info;
with Bets;
with Config;
with Utils; use Utils;
with Sim;
with Tics;

procedure Poll is
  package Ev renames Ada.Environment_Variables;
  -- use type Rpc.Result_Type;

  Me              : constant String := "Poll.";
  Timeout         : Duration := 1200.0;
  My_Lock         : Lock.Lock_Type;
  Msg             : Process_Io.Message_Type;
  Find_Plc_Market : Sql.Statement_Type;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line        : Command_Line_Configuration;
  Now             : Calendar2.Time_Type;
  Ok,
  Is_Time_To_Exit : Boolean := False;
  Cfg             : Config.Config_Type;
  use Config;

  type Market_Type is (Win, Place);
  type Best_Runners_Array_Type is array (1 .. 16) of Prices.Price_Type ;

  Global_Bet_Placer    : Integer := 0;

  Data            : Bot_Messages.Poll_State_Record ;
  This_Process    : Process_Io.Process_Type := Process_Io.This_Process;
  Markets_Fetcher : Process_Io.Process_Type := (("markets_fetcher"), (others => ' '));
  Bad_Selection_Id : constant Integer_4 := 0;

  -------------------------------------------------------------
  -- type-of-bet_bet-number_placement-in-race-at-time-of-bet
  --Back_1_40_30_1_4_PLC_1_01 : back leader when leader <=1.4 and 4th >=30 min price= 1.01
  --Back_1_40_30_1_4_PLC_1_02 : back leader when leader <=1.4 and 2nd >=30 min price= 1.02

  type Allowed_Type is record
    Bet_Name             : Betname_Type := (others => ' ');
    Bet_Size             : Bet_Size_Type := 0.0;
    Is_Allowed_To_Bet    : Boolean       := False;
    Has_Betted           : Boolean       := False;
    Max_Loss_Per_Day     : Bet_Size_Type := 0.0;
    Max_Earnings_Per_Day : Bet_Size_Type := 0.0;
    Bet_Size_Portion     : Bet_Size_Portion_Type := 1.0;
  end record;

  Bets_Allowed : array (Bet_Type'Range) of Allowed_Type;
  --------------------------------------------------------------
  function Get_Bet_Placer(Bettype : Config.Bet_Type) return Process_Io.Process_Type is
  begin
    Global_Bet_Placer := Global_Bet_Placer + 1;
    -- we start 10 bet_placers
    if Global_Bet_Placer > Integer(10) then
      Global_Bet_Placer := 1;
    end if;

    case Global_Bet_Placer is
      when   1 ..   9 => return Process_Io.To_Process_Type("bet_placer_00" & Trim(Global_Bet_Placer'Img, Both));
      when  10 ..  99 => return Process_Io.To_Process_Type("bet_placer_0"  & Trim(Global_Bet_Placer'Img, Both));
      when others     => raise Constraint_Error with "No bet_placer found " & Bettype'Img & " " & Global_Bet_Placer'Img;
    end case;

end Get_Bet_Placer;

  ----------------------------------------------------------

  procedure Set_Bet_Names is
  begin
    for I in Bet_Type'Range loop
      case I is
        when others => Move(I'Img, Bets_Allowed(I).Bet_Name);
      end case;
    end loop;
  end Set_Bet_Names;

  ----------------------------------------------------------------------------

  procedure Send_Back_Bet(Selectionid    : Integer_4;
                          Main_Bet       : Bet_Type;
                          Min_Price      : Back_Price_Type;
                          Marketid       : Marketid_Type;
                          Match_Directly : Boolean := False;
                          Back_Size      : Fixed_Type := 0.0;
                          Fill_Or_Kill   : Boolean := False) is


    Pbb             : Bot_Messages.Place_Back_Bet_Record;
    Did_Bet         : array(1 .. 1) of Boolean := (others => False);
    Receiver        : Process_Io.Process_Type := Get_Bet_Placer(Main_Bet);
    Local_Back_Size : Fixed_Type := Back_Size;
  begin

    declare
      -- only bet on allowed days
      Now : Time_Type := Clock;
      Day : Week_Day_Type := Week_Day_Of(Now);
    begin
      if not Cfg.Bet(Main_Bet).Allowed_Days(Day) then
        Log("No bet layed, bad weekday for this bet" );
        return;
      end if;
    end;

    if not Cfg.Bet(Main_Bet).Enabled then
      Log("Not enbled bet in poll.ini " & Main_Bet'Img );
      return;
    end if;

    if Selectionid = Bad_Selection_Id then
      Log("Bad selectionid, = 0 ");
      return;
    end if;

    case Match_Directly is
      when False => Pbb.Match_Directly := 0;
      when True  => Pbb.Match_Directly := 1;
    end case;

    case Fill_Or_Kill is
      when False => Pbb.Fill_Or_Kill := 0;
      when True  => Pbb.Fill_Or_Kill := 1;
    end case;

    Pbb.Bet_Name := Bets_Allowed(Main_Bet).Bet_Name;
    Move(Marketid, Pbb.Market_Id);

    if Local_Back_Size = 0.0 then
      Move(F8_Image(Fixed_Type(Bets_Allowed(Main_Bet).Bet_Size)), Pbb.Size);
    else
      Move(F8_Image(Local_Back_Size), Pbb.Size);
    end if;

    Move(F8_Image(Fixed_Type(Min_Price)), Pbb.Price); --abs max
    Pbb.Selection_Id := Selectionid;

    if not Bets_Allowed(Main_Bet).Has_Betted and then
      Bets_Allowed(Main_Bet).Is_Allowed_To_Bet then
      Bot_Messages.Send(Receiver, Pbb);

      case Main_Bet is
      -- checks in calling proc - may be several bets
        when others => Bets_Allowed(Main_Bet).Has_Betted := True;
      end case;

      Did_Bet(1) := True;
    end if;

    if Did_Bet(1) then
      Log("Send_Back_Bet called with " &
            " Selectionid=" & Selectionid'Img &
            " Main_Bet=" & Main_Bet'Img &
            " Marketid= '" & Marketid & "'" &
            " Receiver= '" & Receiver.Name & "'");
      Log("pinged '" &  Trim(Receiver.Name) & "' with bet '" & Trim(Pbb.Bet_Name) & "' sel.id:" &  Pbb.Selection_Id'Img );
    end if;

  end Send_Back_Bet;
  ----------------------------------------------------------------------------

  procedure Send_Lay_Bet(Selectionid    : Integer_4;
                         Main_Bet       : Bet_Type;
                         Max_Price      : Lay_Price_Type;
                         Marketid       : Marketid_Type;
                         Match_Directly : Boolean := False;
                         Size           : Fixed_Type := 0.0;
                         Fill_Or_Kill   : Boolean := False) is


    Plb             : Bot_Messages.Place_Lay_Bet_Record;
    Did_Bet         : array(1 .. 1) of Boolean := (others => False);
    Receiver        : Process_Io.Process_Type := Get_Bet_Placer(Main_Bet);
    Local_Size      : Fixed_Type := Size;
  begin
    declare
      -- only bet on allowed days
      Now : Time_Type := Clock;
      Day : Week_Day_Type := Week_Day_Of(Now);
    begin
      if not Cfg.Bet(Main_Bet).Allowed_Days(Day) then
        Log("No bet layed, bad weekday for this bet" );
        return;
      end if;
    end;

    if not Cfg.Bet(Main_Bet).Enabled then
      Log("Not enbled bet in poll.ini " & Main_Bet'Img );
      return;
    end if;

    if Selectionid = Bad_Selection_Id then
      Log("Bad selectionid, = 0 ");
      return;
    end if;

    case Match_Directly is
      when False => Plb.Match_Directly := 0;
      when True  => Plb.Match_Directly := 1;
    end case;

    case Fill_Or_Kill is
      when False => Plb.Fill_Or_Kill := 0;
      when True  => Plb.Fill_Or_Kill := 1;
    end case;

    Plb.Bet_Name := Bets_Allowed(Main_Bet).Bet_Name;
    Move(Marketid, Plb.Market_Id);

    if Local_Size = 0.0 then
      Move(F8_Image(Fixed_Type(Bets_Allowed(Main_Bet).Bet_Size)), Plb.Size);
    else
      Move(F8_Image(Local_Size), Plb.Size);
    end if;

    Move(F8_Image(Fixed_Type(Max_Price)), Plb.Price); --abs max
    Plb.Selection_Id := Selectionid;

    if not Bets_Allowed(Main_Bet).Has_Betted and then
      Bets_Allowed(Main_Bet).Is_Allowed_To_Bet then
      Bot_Messages.Send(Receiver, Plb);

      case Main_Bet is
      -- checks in calling proc - may be several bets
      -- when Horse_Lay_19_00_29_00_At_Start_1_Win => null;
        when others => Bets_Allowed(Main_Bet).Has_Betted := True;
      end case;

      Did_Bet(1) := True;
    end if;

    if Did_Bet(1) then
      Log("Send_Lay_Bet called with " &
            " Selectionid=" & Selectionid'Img &
            " Main_Bet=" & Main_Bet'Img &
            " Marketid= '" & Marketid & "'" &
            " Receiver= '" & Receiver.Name & "'");
      Log("pinged '" &  Trim(Receiver.Name) & "' with bet '" & Trim(Plb.Bet_Name) & "' sel.id:" &  Plb.Selection_Id'Img );
    end if;

  end Send_Lay_Bet;

  --------------------------------------------------------------------
--  not complete yet, too volatile
--
--    procedure Try_To_Greenup_Lay_At_Start(Bettype         : Config.Bet_Type;
--                                  Br              : Best_Runners_Array_Type;
--                                  Marketid        : Marketid_Type;
--                                          Match_Directly  : Boolean := False) is
--      Layprice  : Fixed_Type;
--      Filter    : Integer;
--      Image     : String := Bettype'Img;
--      Backprice : Lay_Price_Type ;
--      Delta_Tic : Tics.Tics_Type;
--      use type Tics.Tics_Type;
--    begin        --1         2         3         4
--      --  12345678901234567890123456789012345678901
--      --  Horse_Greenup_Lay_First_38_00_20_F2_Win
--      Layprice  := Fixed_Type'Value(Image(25..26) & "." & Image(28..29));
--      Delta_Tic := Tics.Tics_Type'Value(Image(31..32));
--      Filter    := Integer'Value(Image(35..35));
--
--      case Filter is
--        when 0 => null; --no filter
--        when 2 =>
--          declare
--            M   : Markets.Market_Type;
--            Eos : Boolean := False;
--          begin
--            M.Marketid := Marketid;
--            M.Read(Eos);
--            if not Eos then
--              if not M.Marketname_Ok2 then -- only Hcp versions - all lengths
--                Log("Try_To_Greenup_Lay_At_Start", "bad marketname - filter " & Filter'Img);
--                return;
--              end if;
--            else
--              Log("Try_To_Greenup_Lay_At_Start", "market gone ! '" & Marketid & "'");
--              return;
--            end if;
--          end;
--        when others =>
--          Log("Try_To_Greenup_Lay_At_Start", "Filter undefined, returning doing nothing" & Filter'Img);
--          return;
--      end case;
--
--      for R of Br loop
--
--        if Layprice = R.Layprice
--          and then R.Backprice < Fixed_Type(10_000.0)  -- so it exists
--        then
--
--          --add delta_tic to cur price
--          Tic := Tics.Get_Tic_Index(R.Layprice);
--          Backprice := Lay_Price_Type(Tics.Get_Tic_Price(Tic + Delta_Tic));
--          La yprice := Lay_Price_Type(Tics.Get_Tic_Price(Tic + 1));
--
--          if Layprice > Lay_Price_Type(Max_Layprice) then
--            Layprice := Lay_Price_Type(Max_Layprice);
--          end if;
--
--          --lay all wih startodds within range ... (call this
--
--          Send_Lay_Bet(Selectionid      => R.Selectionid,
--                       Main_Bet         => Bettype,
--                       Marketid         => Marketid,
--                       Max_Price        => Layprice,
--                       Match_Directly   => Match_Directly);
--        end if;
--
--      end loop;
--      Bets_Allowed(Bettype).Has_Betted := True;
--
--    end Try_To_Greenup_Lay_At_Start;


  procedure Try_To_Make_Back_Bet_On_Diff(Bettype         : Config.Bet_Type;
                                         Br              : Best_Runners_Array_Type;
                                         Marketid        : Marketid_Type;
                                         Match_Directly  : Boolean := False) is

    Max_Backprice_1 : Fixed_Type;
    Min_Backprice_1 : Fixed_Type;
    --   Min_Backprice_N : Fixed_Type;
    Diff_Runners    : Fixed_Type;
    Backed_Num      : Integer;
    Next_Num        : Integer;
    Tmp             : String (1 .. 5) := (others => ' ');
    Image           : String := Bettype'Img;
    Min_Price       : String (1 .. 4) := "1.01";

  begin        --1         2         3         4
    --  12345678901234567890123456789012345678901
    --  Horse_Back_Diff_R1_R4_005_00_001_70_Plc_2
    Tmp(1) := Image(32);
    Tmp(2) := '.';
    Tmp(3 .. 4) := Image(34 .. 35);
    Max_Backprice_1 := Fixed_Type'Value(Tmp);

    --  Min_Backprice_N := Fixed_Type'Value(Image(17 .. 18));
    Backed_Num   := Integer'Value(Image(18 .. 18));
    Next_Num     := Integer'Value(Image(21 .. 21));
    Diff_Runners := Fixed_Type'Value(Image(23..25));

    --  Min_Price(1)    := Image(28);
    --  Min_Price(3 .. 4) := Image(30 .. 31);

    case Bettype is
      when others  => Min_Backprice_1 := 1.01;
    end case;

    if Min_Backprice_1 <= Br(Backed_Num).Backprice and then Br(Backed_Num).Backprice <= Max_Backprice_1 and then
      Br(Next_Num).Backprice - Br(Backed_Num).Backprice >= Diff_Runners and then
      Br(Next_Num).Backprice < Fixed_Type(10_000.0) then  -- so it exists
      -- Back The leader in PLC market...

      Send_Back_Bet(Selectionid     => Br(Backed_Num).Selectionid,
                    Main_Bet        => Bettype,
                    Marketid        => Marketid,
                    Min_Price       => Back_Price_Type'Value(Min_Price),
                    Match_Directly  => Match_Directly);
    end if;
  end Try_To_Make_Back_Bet_On_Diff;
  pragma Unreferenced(Try_To_Make_Back_Bet_On_Diff);
  ------------------------------------------------------

  procedure Try_To_Lay_Favorite(Bettype         : Config.Bet_Type;
                                Br              : Best_Runners_Array_Type;
                                Marketid        : Marketid_Type;
                                Match_Directly  : Boolean := False) is

    Max_Layprice : Lay_Price_Type;
    Lay_Num      : Integer;
    Filter       : Integer;
    Image        : String := Bettype'Img;
    Layprice     : Lay_Price_Type ;
    Tic          : Tics.Tics_Type;
    use type Tics.Tics_Type;
  begin        --1         2         3         4
    --  12345678901234567890123456789012345678901
    --  Horse_Lay_Fav_2_0_12_Win
    Max_Layprice := Lay_Price_Type'Value(Image(19..20));
    Lay_Num := Integer'Value(Image(15 .. 15));
    Filter  := Integer'Value(Image(17 .. 17));

    case Filter is
      when 0 => null; --no filter
      when 1 =>
        declare
          M   : Markets.Market_Type;
          Eos : Boolean := False;
        begin
          M.Marketid := Marketid;
          M.Read(Eos);
          if not Eos then
            if not M.Marketname_Ok then
              Log("Try_To_Lay_Favorite", "bad marketname - filter " & Filter'Img);
              return;
            end if;
          else
            Log("Try_To_Lay_Favorite", "market gone ! '" & Marketid & "'");
            return;
          end if;
        end;

      when 2 =>
        declare
          M   : Markets.Market_Type;
          Eos : Boolean := False;
        begin
          M.Marketid := Marketid;
          M.Read(Eos);
          if not Eos then
            if not M.Marketname_Ok2 then
              Log("Try_To_Lay_Favorite", "bad marketname - filter " & Filter'Img);
              return;
            end if;
          else
            Log("Try_To_Lay_Favorite", "market gone ! '" & Marketid & "'");
            return;
          end if;
        end;

      when others =>
        Log("Try_To_Lay_Favorite", "Filter undefined, returning doing nothing" & Filter'Img);
        return;
    end case;

    --add 1 tic to cur price if ok
    if Fixed_Type(1.01) <= Br(Lay_Num).Layprice and then Br(Lay_Num).Layprice < Fixed_Type(1000.0) then
      Tic := Tics.Get_Tic_Index(Br(Lay_Num).Layprice);
      Layprice := Lay_Price_Type(Tics.Get_Tic_Price(Tic +1));

      if Layprice > Max_Layprice then
        Layprice := Max_Layprice;
      end if;

      -- lay The nth fav in WIN market...

      Send_Lay_Bet(Selectionid      => Br(Lay_Num).Selectionid,
                   Main_Bet         => Bettype,
                   Marketid         => Marketid,
                   Max_Price        => Layprice,
                   Match_Directly   => Match_Directly);
    else
        Log("Try_To_Lay_Favorite", "bad layods #" & Lay_Num'Img & " " & Br(Lay_Num).To_String);
    end if;
  end Try_To_Lay_Favorite;
  pragma Unreferenced(Try_To_Lay_Favorite);
  ------------------------------------------------------


  procedure Try_To_Lay_At_Start(Bettype         : Config.Bet_Type;
                                Br              : Best_Runners_Array_Type;
                                Marketid        : Marketid_Type;
                                Match_Directly  : Boolean := False) is

    Max_Layprice : Fixed_Type;
    Min_Layprice : Fixed_Type;
    Filter       : Integer;
    Image        : String := Bettype'Img;
    Layprice     : Lay_Price_Type ;
    Tic          : Tics.Tics_Type;
    use type Tics.Tics_Type;
  begin        --1         2         3         4
    --  12345678901234567890123456789012345678901
    --  Horse_Lay_19_00_29_00_At_Start_1
    Max_Layprice := Fixed_Type'Value(Image(17..18) & "." & Image(20..21));
    Min_Layprice := Fixed_Type'Value(Image(11..12) & "." & Image(14..15));
    Filter  := Integer'Value(Image(32 .. 32));

    case Filter is
      when 0 => null; --no filter
      when 1 =>
        declare
          M   : Markets.Market_Type;
          Eos : Boolean := False;
        begin
          M.Marketid := Marketid;
          M.Read(Eos);
          if not Eos then
            if not M.Marketname_Ok3 then -- only 5f,6f,7f,1m,1m1f Hcp versions
              Log("Try_To_Lay_At_Start", "bad marketname - filter " & Filter'Img);
              return;
            end if;
          else
            Log("Try_To_Lay_At_Start", "market gone ! '" & Marketid & "'");
            return;
          end if;
        end;
      when others =>
        Log("Try_To_Lay_At_Start", "Filter undefined, returning doing nothing" & Filter'Img);
        return;
    end case;


    for R of Br loop

      if Min_Layprice <= R.Layprice and then R.Layprice <= Max_Layprice
        and then R.Backprice < Fixed_Type(10_000.0)  -- so it exists
      then

        --add 1 tic to cur price
        Tic := Tics.Get_Tic_Index(R.Layprice);
        Layprice := Lay_Price_Type(Tics.Get_Tic_Price(Tic +1));

        if Layprice > Lay_Price_Type(Max_Layprice) then
          Layprice := Lay_Price_Type(Max_Layprice);
        end if;

        --lay all wih startodds within range ... (call this

        Send_Lay_Bet(Selectionid      => R.Selectionid,
                     Main_Bet         => Bettype,
                     Marketid         => Marketid,
                     Max_Price        => Layprice,
                     Match_Directly   => Match_Directly);
      end if;

    end loop;
    Bets_Allowed(Bettype).Has_Betted := True;


  end Try_To_Lay_At_Start;
  pragma Unreferenced(Try_To_Lay_At_Start);
  ------------------------------------------------------



  procedure Try_To_Make_Back_Bet(Bettype         : Config.Bet_Type;
                                 Br              : Best_Runners_Array_Type;
                                 Marketid        : Marketid_Type;
                                 Match_Directly  : Boolean := False) is

    Max_Backprice_1 : Fixed_Type;
    Min_Backprice_1 : Fixed_Type;
    Min_Backprice_N : Fixed_Type;
    Backed_Num      : Integer;
    Next_Num        : Integer;
    Tmp             : String (1 .. 5) := (others => ' ');
    Image           : String := Bettype'Img;
    Min_Price       : String (1 .. 4) := (others => '.');

  begin          --1         2       3
    --  12345678901234567890123456789012345
    --  HORSE_Back_1_10_20_1_4_WIN_1_02
    Tmp(1) := Image(12);
    Tmp(2) := '.';
    Tmp(3 .. 4) := Image(14 .. 15);
    Max_Backprice_1 := Fixed_Type'Value(Tmp);

    Min_Backprice_N := Fixed_Type'Value(Image(17 .. 18));
    Backed_Num := Integer'Value(Image(20 .. 20));
    Next_Num := Integer'Value(Image(22 .. 22));

    Min_Price(1)    := Image(28);
    Min_Price(3 .. 4) := Image(30 .. 31);

    case Bettype is
      when others  => Min_Backprice_1 := 1.01;
    end case;

    if Min_Backprice_1 <= Br(Backed_Num).Backprice and then Br(Backed_Num).Backprice <= Max_Backprice_1 and then
      Br(Next_Num).Backprice >= Min_Backprice_N and then
      Br(3).Backprice <  Fixed_Type(10_000.0) then  -- so it exists
      -- Back The leader in PLC market...

      Send_Back_Bet(Selectionid     => Br(Backed_Num).Selectionid,
                    Main_Bet        => Bettype,
                    Marketid        => Marketid,
                    Min_Price       => Back_Price_Type'Value(Min_Price),
                    Match_Directly  => Match_Directly);
    end if;
  end Try_To_Make_Back_Bet;
  ------------------------------------------------------
  procedure Try_To_Make_Back_Bet_Delta(Bettype         : Config.Bet_Type;
                                       Br              : Best_Runners_Array_Type;
                                       Marketid        : Marketid_Type;
                                       Match_Directly  : Boolean := False) is

    Max_Backprice_1 : Fixed_Type;
    Delta_Price     : Fixed_Type;
    Backed_Num      : Integer;
    Next_Num        : Integer;
    Tmp             : String (1 .. 5) := (others => ' ');
    Image           : String := Bettype'Img;
    Min_Price       : String (1 .. 4) := (others => '.');

  begin          --1         2       3
    --  12345678901234567890123456789012345
    --  HORSE_Back_1_10_20_1_4_WIN_1_02
    Tmp(1) := Image(12);
    Tmp(2) := '.';
    Tmp(3 .. 4) := Image(14 .. 15);
    Max_Backprice_1 := Fixed_Type'Value(Tmp);

    Delta_Price := Fixed_Type'Value(Image(17 .. 18));
    Backed_Num := Integer'Value(Image(20 .. 20));
    Next_Num := Integer'Value(Image(22 .. 22));

    Min_Price(1)    := Image(28);
    Min_Price(3 .. 4) := Image(30 .. 31);


    if Br(Next_Num).Selectionid > Integer_4(0) and then  -- sanity
      Br(Next_Num).Backprice    >= Fixed_Type(1.0) and then  -- sanity
      Br(Next_Num).Layprice     >= Fixed_Type(1.0) and then  -- sanity
      Br(Next_Num).Backprice    >= Br(Backed_Num).Backprice + Delta_Price and then
      Br(Backed_Num).Backprice    <= Max_Backprice_1 and then
      Br(Backed_Num).Backprice    > Fixed_Type(1.0) then  -- sanity

      Send_Back_Bet(Selectionid     => Br(Backed_Num).Selectionid,
                    Main_Bet        => Bettype,
                    Marketid        => Marketid,
                    Min_Price       => Back_Price_Type'Value(Min_Price),
                    Match_Directly  => Match_Directly);
    end if;
  end Try_To_Make_Back_Bet_Delta;
  pragma Unreferenced(Try_To_Make_Back_Bet_Delta);

  ------------------------------------------------------
  --    procedure Try_To_Make_Lay_Bet(Bettype         : Config.Bet_Type;
  --                                   Br              : Best_Runners_Array_Type;
  --                                   Marketid        : Marketid_Type;
  --                                   Match_Directly  : Boolean := False) is
  --
  --      Max_Lay_Price    : Fixed_Type := 0.0;
  --      Min_Lay_Price    : Fixed_Type := 0.0;
  --      Max_Leader_Price : Fixed_Type := 0.0;
  --      Lay_At_Price     : Lay_Price_Type := 0.0;
  --      Tmp             : String (1 .. 4) := (others => ' ');
  --      Image           : String := Bettype'Img;
  --      Two : constant Fixed_Type := 2.0;
  --
  --    begin        --1         2       3
  --      --  12345678901234567890123456789012345
  --      --  Horse_Lay_05_15_1_14_55_Win
  --
  --      Min_Lay_Price := Fixed_Type'Value(Image(11 .. 12));
  --      Max_Lay_Price := Fixed_Type'Value(Image(14 .. 15));
  --      Tmp(1) := Image(17);
  --      Tmp(2) := '.';
  --      Tmp(3 .. 4) := Image(19 .. 20);
  --
  --      Max_Leader_Price := Fixed_Type'Value(Tmp);
  --      Lay_At_Price := Lay_Price_Type'Value(Image(22 .. 23));
  --
  --      if not Bets_Allowed(Bettype).Has_Betted then -- set in send_lay_bet
  --        for R of Br loop
  --          -- sim was run with looking at backprice - not layprice
  --          if R.Backprice    >= Fixed_Type(1.0) and then  -- sanity
  --            R.Layprice      >= Fixed_Type(1.0) and then  -- sanity
  --            R.Layprice      <= Fixed_Type(Two * R.Backprice) and then -- sanity not too big difference allowed
  --            Br(1).Backprice >  Fixed_Type(1.0) and then  --  sanity so it exists
  --            Min_Lay_Price   <= R.Backprice and then R.Backprice <= Max_Lay_Price and then
  --            Br(1).Backprice <= Max_Leader_Price then
  --
  --            Send_Lay_Bet(Selectionid     => R.Selectionid,
  --                         Main_Bet        => Bettype,
  --                         Marketid        => Marketid,
  --                         Max_Price       => Lay_At_Price,
  --                         Match_Directly  => Match_Directly);
  --            exit; -- only one bet allowed
  --          end if;
  --        end loop;
  --      end if;
  --    end Try_To_Make_Lay_Bet;
  --    pragma Unreferenced(Try_To_Make_Lay_Bet);


  --    -- from rev 1897
  --    procedure Try_To_Make_Lay_Bet (Bettype         : Config.Bet_Type;
  --                                   BR              : Best_Runners_Array_Type;
  --                                   Marketid        : Marketid_Type;
  --                                   Match_Directly  : Boolean := False) is
  --      Max_Backprice_1  : Fixed_Type;
  --      Min_Backprice_N  : Fixed_Type;
  --      Layed_Num        : Integer;
  --      Tmp              : String (1 .. 5) := (others => ' ');
  --      Image            : String := Bettype'Img;
  --      Max_Price        : String (1 .. 4) := (others => ' ');
  --    begin       -- 0         1         2         3
  --	      --  12345678901234567890123456789012345
  --	      --  HORSE_Lay_1_10_20_1_2_WIN_3_25
  --      Tmp(1) := Image(11);
  --      Tmp(2) := '.';
  --      Tmp(3..4) := Image(13..14);
  --      Max_Backprice_1 := Fixed_Type'Value(Tmp);
  --
  --      Min_Backprice_N := Fixed_Type'Value(Image(16..17));
  --      Layed_Num := Integer'Value(Image(27..27));
  --
  --      Max_Price(1..2) := Image(29..30);
  --
  --      if BR(1).Backprice <= Max_Backprice_1 and then
  --        BR(1).Backprice >= Fixed_Type (1.01) and then
  --        BR(2).Backprice >= Min_Backprice_N and then
  --        BR(2).Backprice < Fixed_Type (10_000.0) and then
  --        BR(Layed_Num).Layprice <= Fixed_Type'Value(Max_Price) and then
  --        BR(Layed_Num).Layprice >= Fixed_Type(1.01) and then
  --        BR (Layed_Num).Backprice <  Fixed_Type (10_000.0) then  -- so it exists
  --
  --	      -- lay #2 or #3 in win market...
  --
  --        Send_Lay_Bet (Selectionid     => BR (Layed_Num).Selectionid,
  --                      Main_Bet        => Bettype,
  --                      Marketid        => Marketid,
  --                      Max_Price       => Lay_Price_Type'Value (Max_Price),
  --                      Match_Directly  => Match_Directly);
  --      end if;
  --    end Try_To_Make_Lay_Bet;
  --
  --
  --    ------------------------------------------------------



  function Distance_Left(Market       : in out Markets.Market_Type;
                         Start_Time   : Calendar2.Time_Type;
                         Current_Time : Calendar2.Time_Type) return Integer_4 is
    Total_Distance   : Fixed_Type;
    Covered_Distance : Fixed_Type;
    Total_Time       : Fixed_Type;
    Total_Time2      : Integer_4 ;
  begin

    Total_Distance := Fixed_Type( Market.Distance);
    Total_Time2 := Sim.Racetime_Map(Market.Marketname);
    Total_Time := Fixed_Type(Total_Time2);
    Covered_Distance := Total_Distance * Fixed_Type(To_Seconds(Current_Time-Start_Time)) / Total_Time;

    -- Log("Distace_Left", "To_Seconds(Current_Time-Start_Time)/Total_Time" & To_Seconds(Current_Time-Start_Time)'img & "/" & Total_Time'Img);
    --  Log("Distace_Left", "Start_Time/Current_Time" & Start_Time.To_String & "/" & Current_Time.To_String);
    --  Log("Distace_Left", "Covered_Distance/Total_Distance" & Covered_Distance'Img & "/" & Total_Distance'Img);
    -- Log("Distace_Left", "Distance_Left" & Integer_4(Total_Distance - Covered_Distance)'Img);

    return Integer_4(Total_Distance - Covered_Distance);

  end Distance_Left;
  -----------------------------------------------------------

  procedure Try_To_Make_Back_Bet_Distance_Left(Bettype         : in     Config.Bet_Type;
                                               Br              : in     Best_Runners_Array_Type;
                                               Winmarket       : in out Markets.Market_Type;
                                               Plcmarket       : in out Markets.Market_Type;
                                               Went_In_Play    : in     Calendar2.Time_Type;
                                               Match_Directly  : in     Boolean := False) is

    Max_Backprice_1       : Fixed_Type;
    Min_Backprice_1       : Fixed_Type;
    Distance_Left_To_Go   : Integer_4 := Integer_4'Last;
    Distance_Bet          : Integer_4 := Integer_4'Last;
    Tmp                   : String (1 .. 5) := (others => ' ');
    Image                 : String := Bettype'Img;
    Min_Price             : String (1 .. 4) := (others => '.');

  begin          --1         2       3
    --  12345678901234567890123456789012345
    --  HORSE_BACK_1_55_800M_PLC_1_01
    Tmp(1) := Image(12);
    Tmp(2) := '.';
    Tmp(3 .. 4) := Image(14 .. 15);
    Max_Backprice_1 := Fixed_Type'Value(Tmp);

    Distance_Bet := Integer_4'Value(Image(17..19));

    Min_Price(1)      := Image(26);
    Min_Price(3 .. 4) := Image(28 .. 29);

    case Bettype is
      when others  => Min_Backprice_1 := 1.01;
    end case;

    Distance_Left_To_Go := Distance_Left(Winmarket, Went_In_Play, Br(1).Pricets);

    if Min_Backprice_1 <= Br(1).Backprice and then Br(1).Backprice <= Max_Backprice_1 and then
      Distance_Left_To_Go <= Distance_Bet then
      -- Back The leader in PLC market...

      Send_Back_Bet(Selectionid     => Br(1).Selectionid,
                    Main_Bet        => Bettype,
                    Marketid        => Plcmarket.Marketid,
                    Min_Price       => Back_Price_Type'Value(Min_Price),
                    Match_Directly  => Match_Directly);
      Log("Try_To_Make_Back_Bet_Distance_Left", "Distance_Left_To_Go" & Distance_Left_To_Go'Img & "total distance " & Winmarket.Distance'Img);
    end if;
  end Try_To_Make_Back_Bet_Distance_Left;
  pragma Unreferenced(Try_To_Make_Back_Bet_Distance_Left);
  ------------------------------------------------------



  procedure Run(Market_Notification : in Bot_Messages.Market_Notification_Record) is
    Market     : Markets.Market_Type;
    Event      : Events.Event_Type;
    Price_List : Prices.Lists.List;
    --------------------------------------------
    function "<" (Left, Right : Prices.Price_Type) return Boolean is
    begin
      return Left.Backprice < Right.Backprice;
    end "<";
    --------------------------------------------
    package Backprice_Sorter is new Prices.Lists.Generic_Sorting("<");
    Animal            : Animal_Type := Human;
    Price             : Prices.Price_Type;
    Has_Been_In_Play,
    In_Play           : Boolean := False;
    First_Poll        : Boolean := True;
    Best_Runners      : Best_Runners_Array_Type := (others => Prices.Empty_Data);

    Eos               : Boolean := False;
    type Markets_Array_Type is array(Market_Type'Range) of Markets.Market_Type;
    Markets_Array     : Markets_Array_Type;
    Found_Place       : Boolean := True;
    T                 : Sql.Transaction_Type;
    Current_Turn_Not_Started_Race : Integer_4 := 0;
    Betfair_Result    : Rpc.Result_Type := Rpc.Result_Type'First;
    Saldo             : Balances.Balance_Type;
    Match_Directly    : Boolean := False;
    -- Ts_In_Play        : Calendar2.Time_Type := Calendar2.Time_Type_First;
  begin
    Log(Me & "Run", "Treat market: " &  Market_Notification.Market_Id);
    Market.Marketid := Market_Notification.Market_Id;

    Set_Bet_Names;

    --set values from cfg
    for I in Bets_Allowed'Range loop
      Bets_Allowed(I).Bet_Size   := Cfg.Bet(I).Size;
      Bets_Allowed(I).Has_Betted := False;
      Bets_Allowed(I).Max_Loss_Per_Day := Bet_Size_Type(Cfg.Bet(I).Max_Loss_Per_Day);
      Bets_Allowed(I).Max_Earnings_Per_Day := Bet_Size_Type(Cfg.Bet(I).Max_Earnings_Per_Day);
    end loop;

    declare
      -- only bet on allowed days
      Now : Time_Type := Clock;
      Day : Week_Day_Type := Week_Day_Of(Now);
    begin
      if not Cfg.Allowed_Days(Day) then
        Log("No bet layed, bad weekday globally" );
        return;
      end if;
    end;

    -- check if ok to bet and set bet size
    Rpc.Get_Balance(Betfair_Result => Betfair_Result, Saldo => Saldo);

    if abs(Saldo.Exposure) > Cfg.Max_Exposure then
      Log(Me & "Run", "Too much exposure - skip this race " & Saldo.To_String);
      Log(Me & "Run", "max exposure is " & F8_Image(Cfg.Max_Exposure));
      return;
    end if;

    for I in Bets_Allowed'Range loop
      if 0.0 < Bets_Allowed(I).Bet_Size and then Bets_Allowed(I).Bet_Size < 1.0 then
        -- to have the size = a portion of the saldo.
        Bets_Allowed(I).Bet_Size := Bets_Allowed(I).Bet_Size * Saldo.Balance * Bets_Allowed(I).Bet_Size_Portion;
        if Bets_Allowed(I).Bet_Size < 30.0 then
          Log(Me & "Run", "Bet_Size too small, set to 30.0, was " & F8_Image(Fixed_Type( Bets_Allowed(I).Bet_Size)) & " " & Saldo.To_String);
          Bets_Allowed(I).Bet_Size := 30.0;
        end if;
      end if;
      Log(Me & "Run", "Bet_Size " & F8_Image(Fixed_Type( Bets_Allowed(I).Bet_Size)) & " " & Saldo.To_String);

      if -10.0 <= Bets_Allowed(I).Max_Loss_Per_Day and then Bets_Allowed(I).Max_Loss_Per_Day < 0.0 then
        Bets_Allowed(I).Max_Loss_Per_Day := Bets_Allowed(I).Max_Loss_Per_Day * Bets_Allowed(I).Bet_Size;
      end if;

      declare
        Todays_Profit : Fixed_Type := Bets.Profit_Today(Bets_Allowed(I).Bet_Name);
      begin
        Bets_Allowed(I).Is_Allowed_To_Bet := Todays_Profit >= Fixed_Type(Bets_Allowed(I).Max_Loss_Per_Day);
        Log(Me & "Run", Trim(Bets_Allowed(I).Bet_Name) & " max allowed loss set to " & F8_Image(Fixed_Type(Bets_Allowed(I).Max_Loss_Per_Day)));
        if not Bets_Allowed(I).Is_Allowed_To_Bet then
          Log(Me & "Run", Trim(Bets_Allowed(I).Bet_Name) & " is BACK bet OR has lost too much today, max loss is " & F8_Image(Fixed_Type(Bets_Allowed(I).Max_Loss_Per_Day)));
        end if;

        if Bets_Allowed(I).Is_Allowed_To_Bet then
          declare
            Max_Daily : Fixed_Type := Fixed_Type(Bets_Allowed(I).Max_Earnings_Per_Day);
          begin
            if Max_Daily <= Fixed_Type(5.0) then
              -- below 5 the amount is a percentage of bet_size
              Max_Daily := Fixed_Type(Bets_Allowed(I).Max_Earnings_Per_Day) * Fixed_Type(Bets_Allowed(I).Bet_Size);
            end if;

            Bets_Allowed(I).Is_Allowed_To_Bet := Todays_Profit <= Max_Daily;

            Log(Me & "Run", Trim(Bets_Allowed(I).Bet_Name) & " max allowed earnings (greed) set to " & F8_Image(Max_Daily));
            if not Bets_Allowed(I).Is_Allowed_To_Bet then
              Log(Me & "Run", Trim(Bets_Allowed(I).Bet_Name) & " has won too much today, limit is " & F8_Image(Max_Daily));
            end if;
          end;
        end if;
      end;
    end loop;

    --check for total loss today
    declare
      Todays_Profit_So_Far : Fixed_Type := 0.0;
    begin
      for I in Bets_Allowed'Range loop
        Todays_Profit_So_Far := Todays_Profit_So_Far + Bets.Profit_Today(Bets_Allowed(I).Bet_Name);
        if Todays_Profit_So_Far < Cfg.Max_Total_Loss_Per_Day then
          Log(Me & "Run", "today's profit is  " & F8_Image(Todays_Profit_So_Far));
          Log(Me & "Run", "we have lost too much today, max total loss is " & F8_Image(Cfg.Max_Total_Loss_Per_Day));
          Log(Me & "Run", "No more bets today ...");
          return;
        end if;

      end loop;
    end;

    Market.Read(Eos);
    if not Eos then
      if Market.Markettype(1 .. 3) /= "WIN"  then
        Log(Me & "Run", "not a WIN market: " &  Market_Notification.Market_Id);
        return;
      elsif not Market.Marketname_Ok2 then -- check Hrd/Chs in each bet
        Log(Me & "Run", "not an OK Marketname: " & Market.To_String);
        return;
      else
        Event.Eventid := Market.Eventid;
        Event.Read( Eos);
        if not Eos then
          if Event.Eventtypeid = Integer_4(7) then
            Animal := Horse;
          elsif Event.Eventtypeid = Integer_4(4339) then
            Animal := Hound;
          else
            Log(Me & "Run", "not a HORSE, nor a HOUND market: " &  Market_Notification.Market_Id);
            return;
          end if;

          if not Cfg.Country_Is_Ok(Event.Countrycode) then
            Log(Me & "Run", "not an OK country,  market: " &  Market_Notification.Market_Id);
            return;
          end if;
        else
          Log(Me & "Run", "no event found");
          return;
        end if;
      end if;
    else
      Log(Me & "Run", "no market found");
      return;
    end if;
    Markets_Array(Win) := Market;

    T.Start;
    Find_Plc_Market.Prepare(
                            "select MP.* from AMARKETS MW, AMARKETS MP " &
                              "where MW.EVENTID = MP.EVENTID " &
                              "and MW.STARTTS = MP.STARTTS " &
                              "and MW.MARKETID = :WINMARKETID " &
                              "and MP.MARKETTYPE = 'PLACE' " &
                              "and MP.NUMWINNERS = :NUM " &
                              "and MW.MARKETTYPE = 'WIN' " &
                              "and MP.STATUS = 'OPEN'" );

    case Animal is
      when Horse => Find_Plc_Market.Set("NUM", Integer_4(3));
      when Hound => Find_Plc_Market.Set("NUM", Integer_4(2));
      when Human => Find_Plc_Market.Set("NUM", Integer_4(1));
    end case;

    Find_Plc_Market.Set("WINMARKETID", Markets_Array(Win).Marketid);
    Find_Plc_Market.Open_Cursor;
    Find_Plc_Market.Fetch(Eos);
    if not Eos then
      Markets_Array(Place) := Markets.Get(Find_Plc_Market);
      if Markets_Array(Win).Startts /= Markets_Array(Place).Startts then
        Log(Me & "Make_Bet", "Wrong PLACE market found, give up");
        Found_Place := False;
      end if;
    else
      Log(Me & "Make_Bet", "no PLACE market found with 3 winners - exit poll loop");
      Found_Place := False;
    end if;
    Find_Plc_Market.Close_Cursor;
    T.Commit;

    -- do the poll
    Poll_Loop : loop

      exit Poll_Loop when not Found_Place;

      Price_List.Clear;
      Rpc.Get_Market_Prices(Market_Id  => Market_Notification.Market_Id,
                            Market     => Market,
                            Price_List => Price_List,
                            In_Play    => In_Play);

      exit Poll_Loop when Market.Status(1 .. 4) /= "OPEN" and then Has_Been_In_Play;

      if not Has_Been_In_Play then
        -- toggle the first time we see in-play=true
        -- makes us insensible to Betfair toggling bug
        Has_Been_In_Play := In_Play;
        -- Ts_In_Play := Price_List.First_Element.Pricets;
      end if;

      if not Has_Been_In_Play then
        if Current_Turn_Not_Started_Race >= Cfg.Max_Turns_Not_Started_Race then
          Log(Me & "Make_Bet", "Market took too long time to start, give up");
          exit Poll_Loop;
        else
          Current_Turn_Not_Started_Race := Current_Turn_Not_Started_Race + 1;
          delay 5.0; -- no need for heavy polling before start of race
        end if;
      else
        -- delay 0.05; -- to avoid more than 20 polls/sec
        delay 0.0;  -- pi need all cpu time it can get ... and network slow ..
      end if;

      -- ok find the runner with lowest backprice:
      Backprice_Sorter.Sort(Price_List);

      Price.Backprice := 10_000.0;
      Best_Runners := (others => Price);

      declare
        Idx : Integer := 0;
      begin
        for Tmp of Price_List loop
          if Tmp.Status(1 .. 6) = "ACTIVE" then
            Idx := Idx + 1;
            exit when Idx > Best_Runners'Last;
            Best_Runners(Idx) := Tmp;
          end if;
        end loop;
      end ;

      for I in Best_Runners'Range loop
        Log("Best_Runners(i)" & I'Img & " " & Best_Runners(I).To_String);
      end loop;

      if Best_Runners(1).Backprice >= Fixed_Type(1.01) then
        for I in Bet_Type'Range loop
          Log("Animal " & Animal'Img & " betname " & I'Img & " First_Poll " & First_Poll'Img);
          case Animal is
            when Horse =>
              case I is
                when Horse_Back_1_10_07_1_2_Plc_1_01 .. Horse_Back_1_56_00_1_4_Plc_1_01 =>
                  declare
                    M_Type     : Market_Type := Win;
                    Image      : String := I'Img;
                    Do_Try_Bet : Boolean := True;
                    use Markets;
                  begin
                    --  12345678901234567890
                    --  Back_1_10_20_1_4_WIN
                    if Utils.Position(Image, "PLC") > Integer(0) then
                      M_Type := Place;
                      Do_Try_Bet := Found_Place and then Markets_Array(Place).Numwinners >= Integer_4(3) ;
                      Match_Directly := False;
                    elsif Utils.Position(Image, "WIN") > Integer(0) then
                      Do_Try_Bet := Markets_Array(Place).Numwinners >= Integer_4(3) ;
                      M_Type         := Win;
                      Match_Directly := False;
                    end if;

                    if Do_Try_Bet then
                      case Markets_Array(Win).Market_Subtype is
                        when Plain  => Do_Try_Bet := not (Cfg.Bet(I).Chase_Allowed or Cfg.Bet(I).Hurdle_Allowed);
                        when Chase  => Do_Try_Bet := Cfg.Bet(I).Chase_Allowed;
                        when Hurdle => Do_Try_Bet := Cfg.Bet(I).Hurdle_Allowed;
                      end case;
                    end if;


                    if Do_Try_Bet and then
                      Has_Been_In_Play then

                      Try_To_Make_Back_Bet(Bettype         => I,
                                           Br              => Best_Runners,
                                           Marketid        => Markets_Array(M_Type).Marketid,
                                           Match_Directly  => Match_Directly);
                    end if;
                  end;


--                  when  Horse_Lay_Fav_2_0_12_Win .. Horse_Lay_Fav_9_0_30_Win =>
--                    declare
--                      M_Type     : Market_Type := Win;
--                      Image      : String := I'Img;
--                      Do_Try_Bet : Boolean := True;
--                      --use Markets;
--                    begin
--                      --  12345678901234567890
--                      --  Back_1_10_20_1_4_WIN
--                      if Utils.Position(Image, "PLC") > Integer(0) then
--                        M_Type := Place;
--                        Do_Try_Bet := Found_Place and then Markets_Array(Place).Numwinners >= Integer_4(3) ;
--                        Match_Directly := False;
--                      elsif Utils.Position(Image, "WIN") > Integer(0) then
--                        M_Type         := Win;
--                        Match_Directly := False;
--                      end if;
--
--                      --                      if Do_Try_Bet then
--                      --                        case Markets_Array(Win).Market_Subtype is
--                      --                          when Plain  => Do_Try_Bet := not (Cfg.Bet(I).Chase_Allowed or Cfg.Bet(I).Hurdle_Allowed);
--                      --                          when Chase  => Do_Try_Bet := Cfg.Bet(I).Chase_Allowed;
--                      --                          when Hurdle => Do_Try_Bet := Cfg.Bet(I).Hurdle_Allowed;
--                      --                        end case;
--                      --                      end if;
--
--
--                      if Do_Try_Bet
--                        and then First_Poll
--                      -- and then Has_Been_In_Play  since bet placed before race starts, it has NOT been in play
--                      then
--                        Try_To_Lay_Favorite(Bettype         => I,
--                                            Br              => Best_Runners,
--                                            Marketid        => Markets_Array(M_Type).Marketid,
--                                            Match_Directly  => Match_Directly);
--                      end if;
--                    end;
--
--
--                  when  Horse_Lay_19_00_29_00_At_Start_1_Win =>
--                    declare
--                      M_Type     : Market_Type := Win;
--                      Image      : String := I'Img;
--                      Do_Try_Bet : Boolean := True;
--                      --use Markets;
--                    begin
--                      --  12345678901234567890
--                      --  Back_1_10_20_1_4_WIN
--                      if Utils.Position(Image, "PLC") > Integer(0) then
--                        M_Type := Place;
--                        Do_Try_Bet := Found_Place and then Markets_Array(Place).Numwinners >= Integer_4(3) ;
--                        Match_Directly := False;
--                      elsif Utils.Position(Image, "WIN") > Integer(0) then
--                        M_Type         := Win;
--                        Match_Directly := False;
--                      end if;
--
--                      if Do_Try_Bet
--                        and then First_Poll
--                      -- and then Has_Been_In_Play  since bet placed before race starts, it has NOT been in play
--                      then
--                        Try_To_Lay_At_Start(Bettype         => I,
--                                            Br              => Best_Runners,
--                                            Marketid        => Markets_Array(M_Type).Marketid,
--                                            Match_Directly  => Match_Directly);
--                      end if;
--                    end;

                  --when Horse_Back_1_55_800m_Plc_1_01 =>
                  --  declare
                  --    Image      : String := I'Img;
                  --    Do_Try_Bet : Boolean := True;
                  --    use Markets;
                  --  begin
                  --    --  12345678901234567890
                  --    --  Back_1_10_20_1_4_WIN
                  --    if Utils.Position(Image, "PLC") > Integer(0) then
                  --      Do_Try_Bet := Found_Place and then Markets_Array(Place).Numwinners >= Integer_4(3) ;
                  --      Match_Directly := False;
                  --    elsif Utils.Position(Image, "WIN") > Integer(0) then
                  --      Match_Directly := False;
                  --    end if;
                  --
                  --    if Do_Try_Bet then
                  --      case Markets_Array(Win).Market_Subtype is
                  --        when Plain  => Do_Try_Bet := not (Cfg.Bet(I).Chase_Allowed or Cfg.Bet(I).Hurdle_Allowed);
                  --        when Chase  => Do_Try_Bet := Cfg.Bet(I).Chase_Allowed;
                  --        when Hurdle => Do_Try_Bet := Cfg.Bet(I).Hurdle_Allowed;
                  --      end case;
                  --    end if;
                  --
                  --
                  --    if Do_Try_Bet and then
                  --      Has_Been_In_Play then
                  --      begin
                  --
                  --        Try_To_Make_Back_Bet_Distance_Left(Bettype         => I,
                  --                                           Br              => Best_Runners,
                  --                                           Winmarket       => Markets_Array(Win),
                  --                                           Plcmarket       => Markets_Array(Place),
                  --                                           Went_In_Play    => Ts_In_Play,
                  --                                           Match_Directly  => Match_Directly);
                  --      exception
                  --        when Constraint_Error =>
                  --          Log ("main - in poll-loop", "Constraint_Error - market in map? " & Markets_Array(Win).To_String);
                  --      end;
                  --
                  --    end if;
                  --  end;
                  --


                  --                  when Horse_Back_Diff_R1_R4_005_00_001_70_Plc_1  |
                  --                       Horse_Back_Diff_R1_R4_005_00_001_70_Plc_2  =>
                  --                    declare
                  --                      M_Type     : Market_Type := Win;
                  --                      Image      : String := I'Img;
                  --                      Do_Try_Bet : Boolean := True;
                  --                      use Markets;
                  --                    begin
                  --                      --  12345678901234567890
                  --                      --  Back_1_10_20_1_4_WIN
                  --                      if Utils.Position(Image, "PLC") > Integer(0) then
                  --                        M_Type := Place;
                  --                        Do_Try_Bet := Found_Place and then Markets_Array(Place).Numwinners >= Integer_4(3) ;
                  --                        Match_Directly := False;
                  --                      elsif Utils.Position(Image, "WIN") > Integer(0) then
                  --                        M_Type         := Win;
                  --                        Match_Directly := False;
                  --                      end if;
                  --
                  --                      if Do_Try_Bet then
                  --                        case Markets_Array(Win).Market_Subtype is
                  --                          when Plain  => Do_Try_Bet := not (Cfg.Bet(I).Chase_Allowed or Cfg.Bet(I).Hurdle_Allowed);
                  --                          when Chase  => Do_Try_Bet := Cfg.Bet(I).Chase_Allowed;
                  --                          when Hurdle => Do_Try_Bet := Cfg.Bet(I).Hurdle_Allowed;
                  --                        end case;
                  --                      end if;
                  --
                  --
                  --                      if Do_Try_Bet and then
                  --                        Has_Been_In_Play then
                  --                        Try_To_Make_Back_Bet_On_Diff(Bettype         => I,
                  --                                                     Br              => Best_Runners,
                  --                                                     Marketid        => Markets_Array(M_Type).Marketid,
                  --                                                     Match_Directly  => Match_Directly);
                  --                      end if;
                  --                    end;

                  --when Horse_Back_1_55_800m_Plc_1_01 =>
                  --  declare
                  --    Image      : String := I'Img;
                  --    Do_Try_Bet : Boolean := True;
                  --    use Markets;
                  --  begin
                  --    --  12345678901234567890
                  --    --  Back_1_10_20_1_4_WIN
                  --    if Utils.Position(Image, "PLC") > Integer(0) then
                  --      Do_Try_Bet := Found_Place and then Markets_Array(Place).Numwinners >= Integer_4(3) ;
                  --      Match_Directly := False;
                  --    elsif Utils.Position(Image, "WIN") > Integer(0) then
                  --      Match_Directly := False;
                  --    end if;
                  --
                  --    if Do_Try_Bet then
                  --      case Markets_Array(Win).Market_Subtype is
                  --        when Plain  => Do_Try_Bet := not (Cfg.Bet(I).Chase_Allowed or Cfg.Bet(I).Hurdle_Allowed);
                  --        when Chase  => Do_Try_Bet := Cfg.Bet(I).Chase_Allowed;
                  --        when Hurdle => Do_Try_Bet := Cfg.Bet(I).Hurdle_Allowed;
                  --      end case;
                  --    end if;
                  --
                  --
                  --    if Do_Try_Bet and then
                  --      Has_Been_In_Play then
                  --      begin
                  --
                  --        Try_To_Make_Back_Bet_Distance_Left(Bettype         => I,
                  --                                           Br              => Best_Runners,
                  --                                           Winmarket       => Markets_Array(Win),
                  --                                           Plcmarket       => Markets_Array(Place),
                  --                                           Went_In_Play    => Ts_In_Play,
                  --                                           Match_Directly  => Match_Directly);
                  --      exception
                  --        when Constraint_Error =>
                  --          Log ("main - in poll-loop", "Constraint_Error - market in map? " & Markets_Array(Win).To_String);
                  --      end;
                  --
                  --    end if;
                  --  end;
                  --

                  --                when Horse_Back_1_26_00_1_2_Win_1_01 =>
                  --                  declare
                  --                    Image      : String := I'Img;
                  --                    Do_Try_Bet : Boolean := True;
                  --                  begin
                  --                    --  12345678901234567890
                  --                    --  Back_1_10_20_1_4_WIN
                  --                    if Utils.Position(Image, "PLC") > Integer(0) then
                  --                      Do_Try_Bet := False;
                  --                      Match_Directly := False;
                  --                    elsif Utils.Position(Image, "WIN") > Integer(0) then
                  --                      Do_Try_Bet := True ;
                  --                      Match_Directly := False;
                  --                    end if;
                  --                    if Do_Try_Bet and then
                  --                      Has_Been_In_Play then
                  --
                  --                      Try_To_Make_Back_Bet_Delta(Bettype         => I,
                  --                                                 Br              => Best_Runners,
                  --                                                 Marketid        => Markets_Array(Win).Marketid,
                  --                                                 Match_Directly  => Match_Directly);
                  --                    end if;
                  --                  end;
                  --
                  --                    when Horse_Lay_1_05_05_1_2_Win_2_15 =>
                  --                    if Markets_Array(Win).Marketname_Ok2 and then
                  --                       Has_Been_In_Play then
                  --
                  --                          Try_To_Make_Lay_Bet(Bettype         => I,
                  --                                              Br              => Best_Runners,
                  --                                              Marketid        => Markets_Array(Win).Marketid,
                  --                                              Match_Directly  => False);
                  --
                  --                      end if;

              end case;

            when Hound => null;
            when Human => null;
          end case;
        end loop;

      end if; -- Best_Runner(1).Backodds >= 1.01

      First_Poll := False;
    end loop Poll_Loop;

  end Run;
  ---------------------------------------------------------------------
  use type Sql.Transaction_Status_Type;
  ------------------------------ main start -------------------------------------

begin

  Define_Switch
    (Cmd_Line,
     Sa_Par_Bot_User'Access,
     Long_Switch => "--user=",
     Help        => "user of bot");

  Define_Switch
    (Cmd_Line,
     Ba_Daemon'Access,
     Long_Switch => "--daemon",
     Help        => "become daemon at startup");

  Define_Switch
    (Cmd_Line,
     Sa_Par_Inifile'Access,
     Long_Switch => "--inifile=",
     Help        => "use alternative inifile");

  Getopt(Cmd_Line);  -- process the command line

  if Ba_Daemon then
    Posix.Daemonize;
  end if;

  --must take lock AFTER becoming a daemon ...
  --The parent pid dies, and would release the lock...
  My_Lock.Take(Ev.Value("BOT_NAME"));

  Logging.Open(Ev.Value("BOT_HOME") & "/log/" & Ev.Value("BOT_NAME") & ".log");

  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  Cfg := Config.Create(Ev.Value("BOT_HOME") & "/" & Sa_Par_Inifile.all);
  Log(Cfg.To_String);
  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");

  Log(Me, "Login betfair");
  Rpc.Init (
            Username   => Ini.Get_Value("betfair", "username", ""),
            Password   => Ini.Get_Value("betfair", "password", ""),
            Product_Id => Ini.Get_Value("betfair", "product_id", ""),
            Vendor_Id  => Ini.Get_Value("betfair", "vendor_id", ""),
            App_Key    => Ini.Get_Value("betfair", "appkey", "")
           );
  Rpc.Login;
  Log(Me, "Login betfair done");



  if Cfg.Enabled then
    Cfg.Enabled := Ev.Value("BOT_MACHINE_ROLE") = "PROD";
  end if;

  Sim.Fill_Race_Times(Horse, Sim.Racetime_Map);

  Main_Loop : loop

    --notfy markets_fetcher that we are free
    Data := (Free => 1, Name => This_Process.Name , Node => This_Process.Node);
    Bot_Messages.Send(Markets_Fetcher, Data);

    begin
      Log(Me, "Start receive");
      Process_Io.Receive(Msg, Timeout);
      Log(Me, "msg : " & Process_Io.Identity(Msg)'Img & " from " & Trim(Process_Io.Sender(Msg).Name));
      if Sql.Transaction_Status /= Sql.None then
        raise Sql.Transaction_Error with "Uncommited transaction in progress !! BAD!";
      end if;
      case Process_Io.Identity(Msg) is
        when Core_Messages.Exit_Message                  =>
          exit Main_Loop;
        when Bot_Messages.Market_Notification_Message    =>
          if Cfg.Enabled then
            --notfy markets_fetcher that we are busy
            Data := (Free => 0, Name => Process_Io.This_Process.Name , Node => Process_Io.This_Process.Node);
            Bot_Messages.Send(Markets_Fetcher, Data);

            Log(Me, "Connect Db");
            Sql.Connect
              (Host     => Ini.Get_Value("database", "host", ""),
               Port     => Ini.Get_Value("database", "port", 5432),
               Db_Name  => Ini.Get_Value("database", "name", ""),
               Login    => Ini.Get_Value("database", "username", ""),
               Password => Ini.Get_Value("database", "password", ""));
            Log(Me, "db Connected");

            Run(Bot_Messages.Data(Msg));

            Log(Me, "Close Db");
            Sql.Close_Session;

          else
            Log(Me, "Poll is not enabled in poll.ini");
          end if;
        when others =>
          Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Rpc.Keep_Alive(Ok);
        if not Ok then
          begin
            Rpc.Login;
          exception
            when Rpc.Login_Failed =>
              Log(Me, "login failed, but will try again");
          end;
        end if;
    end;
    Now := Calendar2.Clock;

    --restart every day
    Is_Time_To_Exit := Now.Hour = 01 and then
      ( Now.Minute = 00 or Now.Minute = 01) ; -- timeout = 2 min

    exit Main_Loop when Is_Time_To_Exit;

  end loop Main_Loop;

  Rpc.Logout;
  Logging.Close;
  Posix.Do_Exit(0); -- terminate

exception
  when Lock.Lock_Error =>
    Log(Me, "lock error, exit");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
  when E : others =>
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
end Poll;

