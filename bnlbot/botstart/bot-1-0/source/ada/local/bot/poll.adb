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
with Process_IO;
with Core_Messages;
with Markets;
with Events;
with Prices;
with Balances;
with Bot_Svn_Info;
with Bets;
with Config;
with Utils; use Utils;
with Tics;

procedure Poll is
  package EV renames Ada.Environment_Variables;
  use type Rpc.Result_Type;

  Me              : constant String := "Poll.";
  Timeout         : Duration := 120.0;
  My_Lock         : Lock.Lock_Type;
  Msg             : Process_Io.Message_Type;
  Find_Plc_Market : Sql.Statement_Type;
--  Select_Bet_Size_Portion_Back : Sql.Statement_Type;
  --Select_Bet_Profit : Sql.Statement_Type;

  Sa_Par_Bot_User : aliased Gnat.Strings.String_Access;
  Sa_Par_Inifile  : aliased Gnat.Strings.String_Access;
  Ba_Daemon       : aliased Boolean := False;
  Cmd_Line        : Command_Line_Configuration;
  Now             : Calendar2.Time_Type;
  Ok,
  Is_Time_To_Exit : Boolean := False;
  Cfg : Config.Config_Type;
  use Config;

  type Market_Type is (Win, Place);
  type Best_Runners_Array_Type is array (1..16) of Prices.Price_Type ;

  Data : Bot_Messages.Poll_State_Record ;
  This_Process    : Process_Io.Process_Type := Process_IO.This_Process;
  Markets_Fetcher : Process_Io.Process_Type := (("markets_fetcher"),(others => ' '));


  -------------------------------------------------------------
  -- type-of-bet_bet-number_placement-in-race-at-time-of-bet
  --Back_1_40_30_1_4_PLC_1_01 : back leader when leader <=1.4 and 4th >=30 min price= 1.01
  --Back_1_40_30_1_4_PLC_1_02 : back leader when leader <=1.4 and 2nd >=30 min price= 1.02


  type Allowed_Type is record
    Bet_Name          : Betname_Type := (others => ' ');
    Bet_Size          : Bet_Size_Type := 0.0;
    Is_Allowed_To_Bet : Boolean       := False;
    Has_Betted        : Boolean       := False;
    Max_Loss_Per_Day  : Bet_Size_Type := 0.0;
    Max_Earnings_Per_Day  : Bet_Size_Type := 0.0;
    Bet_Size_Portion  : Bet_Size_Portion_Type := 1.0;
  end record;

  Bets_Allowed : array (Bet_Type'range) of Allowed_Type;
  --------------------------------------------------------------
  function Get_Bet_Placer(Bettype : Config.Bet_Type) return Process_Io.Process_Type is
    Num : Integer := Config.Bet_Type'Pos(Bettype) +1;
  begin
    case Num is
      when 1 ..9     => return Process_Io.To_Process_Type("bet_placer_00" & Trim(Num'Img, Both));
      when 10 ..99   => return Process_Io.To_Process_Type("bet_placer_0"  & Trim(Num'Img, Both));
      when 100 ..999 => return Process_Io.To_Process_Type("bet_placer_"   & Trim(Num'Img, Both));
      when others    => raise Constraint_Error with "To many processes" & Num'Img;
    end case;
  end Get_Bet_Placer;
  ----------------------------------------------------------

  procedure Set_Bet_Names is
  begin
    for i in Bet_Type'range loop
      case i is
        when others => Move(I'Img, Bets_Allowed(i).Bet_Name);
      end case;
    end loop;
  end Set_Bet_Names;
  ----------------------------------------------------------------------------


  procedure Send_Lay_Bet(Selectionid    : Integer_4;
                         Main_Bet       : Bet_Type;
                         Max_Price      : Max_Lay_Price_Type;
                         Marketid       : Marketid_Type;
                         Match_Directly : Boolean := False) is

    PLB             : Bot_Messages.Place_Lay_Bet_Record;
    Did_Bet : array(1..1) of Boolean := (others => False);
    Receiver : Process_Io.Process_Type := Get_Bet_Placer(Main_Bet);
  begin
    declare
      -- only bet on allowed days
      Now : Time_Type := Clock;
      Day : Week_Day_Type := Week_Day_Of(Now);
    begin
      if not Cfg.Allowed_Days(Day) then
        Log("No bet layed, bad weekday" );
        return;
      end if;
    end;

    if not Cfg.Bet(Main_Bet).Enabled then
      Log("Not enbled bet in poll.ini " & Main_Bet'Img );
      return;
    end if;

    case Match_Directly is
      when False => PLB.Match_Directly := 0;
      when True  => PLB.Match_Directly := 1;
    end case;

    PLB.Bet_Name := Bets_Allowed(Main_Bet).Bet_Name;
    Move(Marketid, PLB.Market_Id);
    Move(F8_Image(Float_8(Max_Price)), PLB.Price); --abs max
    PLB.Selection_Id := Selectionid;

    if not Bets_Allowed(Main_Bet).Has_Betted and then
           Bets_Allowed(Main_Bet).Is_Allowed_To_Bet then
      Move(F8_Image(Float_8(Bets_Allowed(Main_Bet).Bet_Size)), PLB.Size);
      Bot_Messages.Send(Receiver, PLB);

      case Main_Bet is -- some bets have several runners ...
        when HORSE_LAY_02_02_04_10_16_WIN_600_900 .. HORSE_BACK_06_04_04_08_14_WIN_600_900 => null;
        when HOUND_LAY_06_01_01_04_06_WIN_999_999 .. HOUND_LAY_06_01_01_04_06_WIN_999_999 => null;
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
      Log("pinged '" &  Trim(Receiver.Name) & "' with bet '" & Trim(PLB.Bet_Name) & "' sel.id:" &  PLB.Selection_Id'Img );
    end if;

  end Send_Lay_Bet;
  --------------------------------------------------------------


  procedure Send_Back_Bet(Selectionid    : Integer_4;
                         Main_Bet       : Bet_Type;
                         Min_Price      : Back_Price_Type;
                         Marketid       : Marketid_Type;
                         Match_Directly : Boolean := False) is

    PBB             : Bot_Messages.Place_Back_Bet_Record;
    Did_Bet : array(1..1) of Boolean := (others => False);
    Receiver : Process_Io.Process_Type := Get_Bet_Placer(Main_Bet);
  begin
    declare
      -- only bet on allowed days
      Now : Time_Type := Clock;
      Day : Week_Day_Type := Week_Day_Of(Now);
    begin
      if not Cfg.Allowed_Days(Day) then
        Log("No bet layed, bad weekday" );
        return;
      end if;
    end;

    if not Cfg.Bet(Main_Bet).Enabled then
      Log("Not enbled bet in poll.ini " & Main_Bet'Img );
      return;
    end if;

    case Match_Directly is
      when False => PBB.Match_Directly := 0;
      when True  => PBB.Match_Directly := 1;
    end case;

    PBB.Bet_Name := Bets_Allowed(Main_Bet).Bet_Name;
    Move(Marketid, PBB.Market_Id);
    Move(F8_Image(Float_8(Min_Price)), PBB.Price); --abs max
    PBB.Selection_Id := Selectionid;

    if not Bets_Allowed(Main_Bet).Has_Betted and then
           Bets_Allowed(Main_Bet).Is_Allowed_To_Bet then
      Move(F8_Image(Float_8(Bets_Allowed(Main_Bet).Bet_Size)), PBB.Size);
      Bot_Messages.Send(Receiver, PBB);

      case Main_Bet is -- some bets have several runners ...
        when HORSE_LAY_02_02_04_10_16_WIN_600_900 .. HORSE_BACK_06_04_04_08_14_WIN_600_900 => null;
        when HOUND_LAY_06_01_01_04_06_WIN_999_999 .. HOUND_LAY_06_01_01_04_06_WIN_999_999 => null;
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
      Log("pinged '" &  Trim(Receiver.Name) & "' with bet '" & Trim(PBB.Bet_Name) & "' sel.id:" &  PBB.Selection_Id'Img );
    end if;

  end Send_Back_Bet;
  --------------------------------------------------------------

  procedure Send_Bet(Selectionid     : Integer_4;
                     Main_Bet        : Bet_Type;
                     Marketid        : Marketid_Type;
                     Min_Price       : String := "1.01";
                     Match_Directly  : Boolean := False) is

    PBB             : Bot_Messages.Place_Back_Bet_Record;
    Did_Bet : array(1..1) of Boolean := (others => False);
    Receiver : Process_Io.Process_Type := Get_Bet_Placer(Main_Bet);
  begin

    declare
      -- only bet on allowed days
      Now : Time_Type := Clock;
      Day : Week_Day_Type := Week_Day_Of(Now);
    begin
      if not Cfg.Allowed_Days(Day) then
        Log("No bet layed, bad weekday" );
        return;
      end if;
    end;

    if not Cfg.Bet(Main_Bet).Enabled then
      Log("Not enbled bet in poll.ini" );
      return;
    end if;

    case Match_Directly is
      when False => PBB.Match_Directly := 0;
      when True  => PBB.Match_Directly := 1;
    end case;

    PBB.Bet_Name := Bets_Allowed(Main_Bet).Bet_Name;
    Move(Marketid, PBB.Market_Id);
    Move(Min_Price, PBB.Price);
    PBB.Selection_Id := Selectionid;

    if not Bets_Allowed(Main_Bet).Has_Betted and then
           Bets_Allowed(Main_Bet).Is_Allowed_To_Bet then
      Move(F8_Image(Float_8(Bets_Allowed(Main_Bet).Bet_Size)), PBB.Size);
      Bot_Messages.Send(Receiver, PBB);
      Bets_Allowed(Main_Bet).Has_Betted := True;
      Did_Bet(1) := True;
    end if;

    if Did_Bet(1) then
      Log("Send_Bet called with " &
         " Selectionid=" & Selectionid'Img &
         " Main_Bet=" & Main_Bet'Img &
         " Marketid= '" & Marketid & "'" &
         " Receiver= '" & Receiver.Name & "'" );
      Log("pinged '" &  Trim(Receiver.Name) & "' with bet '" & Trim(PBB.Bet_Name) & "' sel.id:" &  PBB.Selection_Id'Img );
    end if;

  end Send_Bet;

  -------------------------------------------------------------------------------------------------------------------

  procedure Try_To_Make_Back_Bet(
    Bettype         : Config.Bet_Type;
    BR              : Best_Runners_Array_Type;
    Marketid        : Marketid_Type;
    Match_Directly : Boolean := False) is
    Max_Backprice_1 : Float_8;
    Min_Backprice_1 : Float_8;
    Min_Backprice_n : Float_8;
    Backed_Num    : Integer;
    Next_Num      : Integer;
    Tmp : String (1..5) := (others => ' ');
    Image : String := Bettype'Img;
    Min_Price       : String(1..4) := (others => '.');

  begin          --1         2
      --  12345678901234567890123456789012345
      --  HORSE_Back_1_10_20_1_4_WIN_1_02
    Tmp(1) := Image(12);
    Tmp(2) := '.';
    Tmp(3..4) := Image(14..15);
    Max_Backprice_1 := Float_8'Value(Tmp);

    Min_Backprice_n := Float_8'Value(Image(17..18));
    Backed_Num := Integer'Value(Image(20..20));
    Next_Num := Integer'Value(Image(22..22));

    Min_Price(1)    := Image(28);
    Min_Price(3..4) := Image(30..31);

    case Bettype is
   --   when Back_1_50_30_1_4_PLC => Min_Backprice_1 := 1.41;
   --   when Back_1_10_20_1_2_WIN |
   --        Back_1_10_16_1_2_WIN |
   --        Back_1_10_13_1_2_WIN => Min_Backprice_1 := 1.04;
      when others               => Min_Backprice_1 := 1.01;
    end case;

    if BR(Backed_Num).Backprice <= Max_Backprice_1 and then
       BR(Backed_Num).Backprice >= Min_Backprice_1 and then
       BR(Next_Num).Backprice >= Min_Backprice_n and then
       BR(3).Backprice <  Float_8(10_000.0) then  -- so it exists
      -- Back The leader in PLC market...

      Send_Bet(Selectionid     => BR(Backed_Num).Selectionid,
               Main_Bet        => Bettype,
               Marketid        => Marketid,
               Min_Price       => Min_Price,
               Match_Directly  => Match_Directly);
    end if;
  end Try_To_Make_Back_Bet;

  ------------------------------------------------------
  procedure Try_To_Make_Back_Bet_4_Bounds(
      Bettype         : Config.Bet_Type;
      BR              : Best_Runners_Array_Type;
      Marketid        : Marketid_Type;
      Match_Directly : Boolean := False) is

    Max_Backprice_1 : Float_8;
    Min_Backprice_1 : Float_8;
    Min_Backprice_n : Float_8;
    Max_Backprice_n : Float_8;
    Backed_Num    : Integer;
    Next_Num      : Integer;
    Tmp : String (1..5) := (others => ' ');
    Image : String := Bettype'Img;
    Min_Price       : String(1..4) := (others => '.');
  begin          --1         2         3
      --  123456789012345678901234567890123456789
      --  HORSE_BACK_1_36_1_40_01_04_1_2_PLC_1_10

    Tmp(1) := Image(12);
    Tmp(2) := '.';
    Tmp(3..4) := Image(14..15);
    Min_Backprice_1 := Float_8'Value(Tmp);

    Tmp(1) := Image(17);
    Tmp(2) := '.';
    Tmp(3..4) := Image(19..20);
    Max_Backprice_1 := Float_8'Value(Tmp);

    Min_Backprice_n := Float_8'Value(Image(22..23));
    Max_Backprice_n := Float_8'Value(Image(25..26));

    Backed_Num := Integer'Value(Image(28..28));
    Next_Num := Integer'Value(Image(30..30));

    Min_Price(1)    := Image(36);
    Min_Price(3..4) := Image(38..39);

    if BR(Backed_Num).Backprice <= Max_Backprice_1 and then
       BR(Backed_Num).Backprice >= Min_Backprice_1 and then
       BR(Next_Num).Backprice >= Min_Backprice_n and then
       BR(Next_Num).Backprice <= Max_Backprice_n and then
       BR(3).Backprice < Float_8(10_000.0) then  -- so it exists
      -- Back The leader in PLC market...

      Send_Bet(Selectionid     => BR(Backed_Num).Selectionid,
               Main_Bet        => Bettype,
               Marketid        => Marketid,
               Min_Price       => Min_Price,
               Match_Directly  => Match_Directly);
    end if;
  end Try_To_Make_Back_Bet_4_Bounds;

  -------------------------------------------------------------------------------------------------------------------
--    procedure Try_To_Make_Lay_Bet(
--        Bettype         : Config.Bet_Type;
--        BR              : Best_Runners_Array_Type;
--        Marketid        : Marketid_Type;
--        Match_Directly : Boolean := False) is
--
--      Max_Backprice_1       : Float_8;
--      Max_Layprice_n        : Max_Lay_Price_Type;
--      Additional_Layprice_n : Max_Lay_Price_Type;
--      Layed_Num             : Integer;
--      Tmp : String (1..4) := (others => ' ');
--      Image : String := Bettype'Img;
--    begin          --1         2         3
--        --  123456789012345678901234567890123456789
--        --  Lay_2_30_10_WIN_4_02
--        --  Lay_1_80_10_WIN_4_10,
--
--      Tmp(1)    := Image(5);
--      Tmp(2)    := '.';
--      Tmp(3..4) := Image(7..8);
--      Max_Backprice_1 := Float_8'Value(Tmp);
--
--      Tmp := (others => ' ');
--      Tmp(1..2) := Image(10..11);
--      Max_Layprice_n := Max_Lay_Price_Type'Value(Tmp);
--
--      Tmp := (others => ' ');
--      Tmp(1) := Image(17);
--      Layed_Num := Integer'Value(Tmp);
--
--      Tmp := (others => ' ');
--      Tmp(1..2) := Image(19..20);
--      Additional_Layprice_n :=  Max_Lay_Price_Type'Value(Tmp);
--
--      if BR(1).Backprice <= Max_Backprice_1 and then
--         BR(1).Backprice >= Float_8(1.01) and then
--         BR(Layed_Num).Backprice < Float_8(10_000.0)  and then  -- so it exists
--         BR(3).Backprice < Float_8(10_000.0) then  -- so it exists
--        -- lay n in WIN market...
--
--        Send_Lay_Bet(Selectionid     => BR(Layed_Num).Selectionid,
--                     Main_Bet        => Bettype,
--                     Marketid        => Marketid,
--                     Max_Price       => Max_Layprice_n + Additional_Layprice_n,
--                     Match_Directly  => Match_Directly);
--      end if;
--    end Try_To_Make_Lay_Bet;

  -------------------------------------------------------------------------------------------------------------------
  procedure Do_Place_Lay_Bets_At_Start(
      Bettype         : Config.Bet_Type;
      BR              : Best_Runners_Array_Type;
      Marketid        : Marketid_Type;
      Match_Directly : Boolean := False) is

    Max_Back_Price       : Float_8;
    Max_Lay_Price        : Max_Lay_Price_Type;
    First_Bet           : Integer := 0;
    Place_Num           : Integer := 0;
    Num_Bets            : Integer := 0;
    Lay_Price           : Float_8 := 0.0;
    Tic                 : Integer := 0;
    Image : String := Bettype'Img;
    Service : String := "Do_Place_Lay_Bets_At_Start";
  begin          --1         2         3
      --  123456789012345678901234567890123456789
      --  HORSE_Lay_02_02_04_11_17_Win

    Num_Bets  := Integer'Value(Image(11..12));
    First_Bet := Integer'Value(Image(14..15));
    Place_Num := Integer'Value(Image(17..18));
    Max_Back_Price := Float_8'Value(Image(20..21));
    Max_Lay_Price := Max_Lay_Price_Type'Value(Image(23..24));

    if Place_Num <= Br'Last and then
      BR(1).Backprice >= Float_8(1.01) and then
      BR(Place_Num).Backprice < Float_8(10_000.0) and then  -- so it exists
      Br (Place_Num).Backprice <= Max_Back_Price and then
      Br (Place_Num).Layprice <= Max_Lay_Price then

      for I in Br'Range loop

        Log(Service & " " & Bettype'Img & " I=" & I'Img &
              " Num_Bets=" & Num_Bets'Img &
              " First_Bet=" & First_Bet'Img &
              " Place_Num=" & Place_Num'Img &
              " Max_Back_Price=" & F8_Image(Max_Back_Price) &
              " Max_Lay_Price=" & F8_Image(Float_8(Max_Lay_Price)) &
              " Br (I).Layprice=" & F8_Image(Br (I).Layprice) &
              " Br (I).Backprice=" & F8_Image(Br (I).Backprice));

        if I >= First_Bet then
          if I < First_Bet + Num_Bets then
            if Br (I).Layprice <= Max_Lay_Price then
              if Br (I).Backprice <= Max_Back_Price then
                -- to get legal odds
                Tic := Tics.Get_Nearest_Higher_Tic_Index(Br(I).Layprice);
                Lay_Price := Tics.Get_Tic_Price(Tic+4); -- some small margin to get the bet

                Send_Lay_Bet(Selectionid     => Br(I).Selectionid,
                             Main_Bet        => Bettype,
                             Marketid        => Marketid,
                             Max_Price       => Max_Lay_Price_Type(Lay_Price),
                             Match_Directly  => Match_Directly);
              else
                Log (Service & " " & Bettype'Img & ": I =" & I'Img & " Br (I).Backprice <= Max_Back_Price= " & Boolean'Image(Br (I).Backprice <= Max_Back_Price));
              end if;
            else
              Log (Service & " " & Bettype'Img & ": I =" & I'Img & " Br (I).Layprice <= Max_Lay_Price= " & Boolean'Image(Br (I).Layprice <= Max_Lay_Price));
            end if;
          else
            Log (Service & " " & Bettype'Img & ": I =" & I'Img & " I < First_Bet + Num_Bets= " & Boolean'Image(I < First_Bet + Num_Bets));
          end if;
        else
          Log (Service & " " & Bettype'Img & ": I =" & I'Img & " I >= First_Bet= " & Boolean'Image(I >= First_Bet));
        end if;
      end loop;
    end if;
    Bets_Allowed(Bettype).Has_Betted := True; -- disabled in send_lay_bet for this type of bets
  end Do_Place_Lay_Bets_At_Start;
  -----------------------------------------------
  procedure Do_Place_Back_Bets_At_Start(
      Bettype         : Config.Bet_Type;
      BR              : Best_Runners_Array_Type;
      Marketid        : Marketid_Type;
      Match_Directly : Boolean := False) is

    Service : String := "Do_Place_Back_Bets_At_Start";
    Max_Back_Price       : Float_8;
    Max_Lay_Price        : Max_Lay_Price_Type;
    First_Bet            : Integer := 0;
    Place_Num            : Integer := 0;
    Num_Bets             : Integer := 0;
    Back_Price           : Float_8 := 0.0;
    Tic                  : Integer := 0;
    Image : String := Bettype'Img;
  begin          --1         2         3
      --  123456789012345678901234567890123456789
      --  HORSE_Back_02_02_04_11_17_Win

    Num_Bets  := Integer'Value(Image(12..13));
    First_Bet := Integer'Value(Image(15..16));
    Place_Num := Integer'Value(Image(18..19));
    Max_Back_Price := Float_8'Value(Image(21..22));
    Max_Lay_Price := Max_Lay_Price_Type'Value(Image(24..25));

    if Place_Num <= Br'Last and then
      BR(1).Backprice >= Float_8(1.01) and then
      BR(Place_Num).Backprice < Float_8(10_000.0) and then  -- so it exists
      Br (Place_Num).Backprice <= Max_Back_Price and then
      Br (Place_Num).Layprice <= Max_Lay_Price then

      for I in Br'Range loop

        Log(Service & " " & Bettype'Img & " I=" & I'Img &
              " Num_Bets=" & Num_Bets'Img &
              " First_Bet=" & First_Bet'Img &
              " Place_Num=" & Place_Num'Img &
              " Max_Back_Price=" & F8_Image(Max_Back_Price) &
              " Max_Lay_Price=" & F8_Image(Float_8(Max_Lay_Price)) &
              " Br (I).Layprice=" & F8_Image(Br (I).Layprice) &
              " Br (I).Backprice=" & F8_Image(Br (I).Backprice));

        if I >= First_Bet then
          if I < First_Bet + Num_Bets then
            if Br (I).Layprice <= Max_Lay_Price then
              if Br (I).Backprice <= Max_Back_Price then
                -- to get legal odds
                Tic := Tics.Get_Nearest_Higher_Tic_Index(Br(I).Backprice);
                Back_Price := Tics.Get_Tic_Price(Tic-4); -- some small margin to get the bet

                Send_Back_Bet (Selectionid     => Br (I).Selectionid,
                               Main_Bet        => Bettype,
                               Marketid        => Marketid,
                               Min_Price       => Back_Price_Type (Back_Price),
                               Match_Directly  => Match_Directly);
              else
                Log (Service & ": I =" & I'Img & " Br (I).Backprice <= Max_Back_Price= " & Boolean'Image(Br (I).Backprice <= Max_Back_Price));
              end if;
            else
              Log (Service & ": I =" & I'Img & " Br (I).Layprice <= Max_Lay_Price= " & Boolean'Image(Br (I).Layprice <= Max_Lay_Price));
            end if;
          else
            Log (Service & ": I =" & I'Img & " I < First_Bet + Num_Bets= " & Boolean'Image(I < First_Bet + Num_Bets));
          end if;
        else
          Log (Service & ": I =" & I'Img & " I >= First_Bet= " & Boolean'Image(I >= First_Bet));
        end if;
      end loop;
    end if;
    Bets_Allowed(Bettype).Has_Betted := True; -- disabled in send_lay_bet for this type of bets
  end Do_Place_Back_Bets_At_Start;
  -----------------------------------------------



  procedure Run(Market_Notification : in Bot_Messages.Market_Notification_Record) is
    Market    : Markets.Market_Type;
    Event     : Events.Event_Type;
    Price_List : Prices.Lists.List;
    --------------------------------------------
    function "<" (Left,Right : Prices.Price_Type) return Boolean is
    begin
      return Left.Backprice < Right.Backprice;
    end "<";
    --------------------------------------------
    package Backprice_Sorter is new Prices.Lists.Generic_Sorting("<");
    Animal            : Animal_Type := Human;
    Price             : Prices.Price_Type;
    Has_Been_In_Play,
    In_Play           : Boolean := False;
    First_Time        : Boolean := True;
    Best_Runners      : Best_Runners_Array_Type := (others => Prices.Empty_Data);

    Worst_Runner      : Prices.Price_Type := Prices.Empty_Data;

    Eos               : Boolean := False;
    type Markets_Array_Type is array (Market_Type'range) of Markets.Market_Type;
    Markets_Array     : Markets_Array_Type;
    Found_Place       : Boolean := True;
    T                 : Sql.Transaction_Type;
    Current_Turn_Not_Started_Race : Integer_4 := 0;
    Betfair_Result    : Rpc.Result_Type := Rpc.Result_Type'first;
    Saldo             : Balances.Balance_Type;
    Match_Directly : Boolean := False;
  begin
    Log(Me & "Run", "Treat market: " &  Market_Notification.Market_Id);
    Market.Marketid := Market_Notification.Market_Id;

    Set_Bet_Names;

    --set values from cfg
    for i in Bets_Allowed'range loop
      Bets_Allowed(i).Bet_Size   := Cfg.Bet(i).Size;
      Bets_Allowed(i).Has_Betted := False;
      Bets_Allowed(i).Max_Loss_Per_Day := Bet_Size_Type(Cfg.Bet(i).Max_Loss_Per_Day);
      Bets_Allowed(i).Max_Earnings_Per_Day := Bet_Size_Type(Cfg.Bet(i).Max_Earnings_Per_Day);
    end loop;

    -- check if ok to bet and set bet size
    Rpc.Get_Balance(Betfair_Result => Betfair_Result, Saldo => Saldo);

    if abs(Saldo.Exposure) > Cfg.Max_Exposure then
       Log(Me & "Run", "Too much exposure - skip this race " & Saldo.To_String);
       Log(Me & "Run", "max exposure is " & F8_Image(Cfg.Max_Exposure));
       return;
    end if;

    for i in Bets_Allowed'range loop
      if 0.0 < Bets_Allowed(i).Bet_Size and then Bets_Allowed(i).Bet_Size < 1.0 then
        -- to have the size = a portion of the saldo.
        Bets_Allowed(i).Bet_Size := Bets_Allowed(i).Bet_Size * Bet_Size_Type(Saldo.Balance) * Bet_Size_Type(Bets_Allowed(i).Bet_Size_Portion);
        if Bets_Allowed(i).Bet_Size < 30.0 then
          Log(Me & "Run", "Bet_Size too small, set to 30.0, was " & F8_Image(Float_8( Bets_Allowed(i).Bet_Size)) & " " & Saldo.To_String);
          Bets_Allowed(i).Bet_Size := 30.0;
        end if;
      end if;
      Log(Me & "Run", "Bet_Size " & F8_Image(Float_8( Bets_Allowed(i).Bet_Size)) & " " & Saldo.To_String);
      if -10.0 <= Bets_Allowed(i).Max_Loss_Per_Day and then Bets_Allowed(i).Max_Loss_Per_Day < 0.0 then
        Bets_Allowed(i).Max_Loss_Per_Day := Bets_Allowed(i).Max_Loss_Per_Day * Bets_Allowed(i).Bet_Size;
      end if;

      declare
        Todays_Profit : Float_8 := Bets.Profit_Today (Bets_Allowed (I).Bet_Name);
      begin
        Bets_Allowed (I).Is_Allowed_To_Bet := Todays_Profit >= Float_8 (Bets_Allowed (I).Max_Loss_Per_Day);
        Log (Me & "Run", Trim (Bets_Allowed (I).Bet_Name) & " max allowed loss set to " & F8_Image (Float_8 (Bets_Allowed (I).Max_Loss_Per_Day)));
        if not Bets_Allowed (I).Is_Allowed_To_Bet then
          Log (Me & "Run", Trim (Bets_Allowed (I).Bet_Name) & " is BACK bet OR has lost too much today, max loss is " & F8_Image (Float_8 (Bets_Allowed (I).Max_Loss_Per_Day)));
        end if;

        if Bets_Allowed (I).Is_Allowed_To_Bet then
          Bets_Allowed (I).Is_Allowed_To_Bet := Todays_Profit <= Float_8 (Bets_Allowed (I).Max_Earnings_Per_Day);
          Log (Me & "Run", Trim (Bets_Allowed (I).Bet_Name) & " max allowed earnings set to " & F8_Image (Float_8 (Bets_Allowed (I).Max_Earnings_Per_Day)));
          if not Bets_Allowed (I).Is_Allowed_To_Bet then
            Log (Me & "Run", Trim (Bets_Allowed (I).Bet_Name) & " has won too much today, limit is " & F8_Image (Float_8 (Bets_Allowed (I).Max_Earnings_Per_Day)));
          end if;
        end if;
      end;
    end loop;

    Market.Read(Eos);
    if not Eos then
      if  Market.Markettype(1..3) /= "WIN"  then
        Log(Me & "Run", "not a WIN market: " &  Market_Notification.Market_Id);
        return;
      else
        Event.Eventid := Market.Eventid;
        Event.Read( Eos);
        if not Eos then
          if Event.Eventtypeid = Integer_4(7) then
            Animal := Horse;
          elsif Event.Eventtypeid = Integer_4 (4339) then
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
    Markets_Array(Win):= Market;

    T.Start;
      Find_Plc_Market.Prepare(
        "select MP.* from AMARKETS MW, AMARKETS MP " &
        "where MW.EVENTID = MP.EVENTID " &
        "and MW.STARTTS = MP.STARTTS " &
        "and MW.MARKETID = :WINMARKETID " &
        "and MP.MARKETTYPE = 'PLACE' " &
        "and MP.NUMWINNERS = :NUM " &
        "and MW.MARKETTYPE = 'WIN' " &
        "and MP.STATUS = 'OPEN'" ) ;

      case Animal is
        when Horse => Find_Plc_Market.Set ("NUM", Integer_4 (3));
        when Hound => Find_Plc_Market.Set ("NUM", Integer_4 (2));
        when Human => Find_Plc_Market.Set ("NUM", Integer_4 (1));
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
        Log(Me & "Make_Bet", "no PLACE market found");
        Found_Place := False;
      end if;
      Find_Plc_Market.Close_Cursor;
    T.Commit;

    -- do the poll
    Poll_Loop : loop

      case Animal is
        when Horse =>
          if Markets_Array (Place).Numwinners < Integer_4 (3) then
            Log ("Animal " & Animal'Img & " Markets_Array (Place).Numwinners " & Markets_Array (Place).Numwinners'Img & " no bet here - exit poll loop");
            exit Poll_Loop;
          end if;
        when Hound => null;
        when Human => null;
      end case;

      --Table_Aprices.Aprices_List_Pack.Remove_All(Price_List);
      Price_List.Clear;
      Rpc.Get_Market_Prices (Market_Id  => Market_Notification.Market_Id,
                             Market     => Market,
                             Price_List => Price_List,
                             In_Play    => In_Play);

      exit Poll_Loop when Market.Status (1 .. 4) /= "OPEN" and then Has_Been_In_Play;

      if not Has_Been_In_Play then
        -- toggle the first time we see in-play=true
        -- makes us insensible to Betfair toggling bug
        Has_Been_In_Play := In_Play;
      end if;

      if not Has_Been_In_Play then
        if Current_Turn_Not_Started_Race >= Cfg.Max_Turns_Not_Started_Race then
          Log (Me & "Make_Bet", "Market took too long time to start, give up");
          exit Poll_Loop;
        else
          Current_Turn_Not_Started_Race := Current_Turn_Not_Started_Race + 1;
          delay 5.0; -- no need for heavy polling before start of race
        end if;
      else
        delay 0.05; -- to avoid more than 20 polls/sec
      end if;

      -- ok find the runner with lowest backprice:
      Backprice_Sorter.Sort (Price_List);

      Price.Backprice := 10_000.0;
      Best_Runners := (others => Price);
      Worst_Runner.Layprice := 10_000.0;

      declare
        Idx : Integer := 0;
      begin
        for Tmp of Price_List loop
          if Tmp.Status (1 .. 6) = "ACTIVE" then
            Idx := Idx + 1;
            exit when Idx > Best_Runners'Last;
            Best_Runners (Idx) := Tmp;
          end if;
        end loop;
      end ;

      for Tmp of Price_List loop
        if Tmp.Status (1 .. 6) = "ACTIVE" and then
          Tmp.Backprice > Float_8 (1.0) and then
          Tmp.Layprice < Float_8 (1_000.0) and then
          Tmp.Selectionid /= Best_Runners (1).Selectionid and then
          Tmp.Selectionid /= Best_Runners (2).Selectionid then

          Worst_Runner := Tmp;
        end if;
      end loop;

      for I in Best_Runners'Range loop
        Log ("Best_Runners(i)" & I'Img & " " & Best_Runners (I).To_String);
      end loop;
      Log ("Worst_Runner " & Worst_Runner.To_String);

      if Best_Runners (1).Backprice >= Float_8 (1.01) then
        for I in Bet_Type'Range loop
          Log ("Animal " & Animal'Img & " betname " & i'Img & " First_Time " & First_Time'Img);
          case Animal is
            when Horse =>
              case I is
                --when Lay_160_200        => null; -- treat later
                --when Lay_1_10_25_4      => null; -- treat later

              when HORSE_LAY_02_02_04_10_16_WIN_600_900 .. HORSE_LAY_10_01_04_10_12_WIN_999_999 =>
                if First_Time then
                  Log ("Treating Animal " & Animal'Img & " betname " & i'Img);
                  Do_Place_Lay_Bets_At_Start (
                                              Bettype         => I,
                                              BR              => Best_Runners,
                                              Marketid        => Markets_Array (Win).Marketid,
                                              Match_Directly  => True);
                end if;

              when HORSE_BACK_03_04_04_08_14_WIN_500_800 .. HORSE_BACK_06_04_04_08_14_WIN_600_900 =>
                if First_Time then
                  Log ("Treating Animal " & Animal'Img & " betname " & i'Img);
                  Do_Place_Back_Bets_At_Start (
                                               Bettype         => I,
                                               BR              => Best_Runners,
                                               Marketid        => Markets_Array (Win).Marketid,
                                               Match_Directly  => True);
                end if;

                -- when Lay_2_90_20_WIN_8_00 ..
                --      Lay_2_90_20_WIN_8_00   =>
                --   declare
                --     M_Type     : Market_Type := Win;
                --     Image      : String      := i'Img;
                --     Do_Try_Bet : Boolean     := True;
                --   begin
                --    --  12345678901234567890
                --    --  Back_1_10_20_1_4_WIN
                --     if Image(12..14) = "PLC" then
                --       M_Type := Place;
                --       Do_Try_Bet := Found_Place and then Markets_Array(Place).Numwinners >= Integer_4(3) ;
                --       Match_Directly := True;
                --     elsif Image(18..20) = "WIN" then
                --       Match_Directly := True;
                --     end if;
                --     if Do_Try_Bet then
                --       Try_To_Make_Lay_Bet (
                --             Bettype         => i,
                --             BR              => Best_Runners,
                --             Marketid        => Markets_Array(M_Type).Marketid,
                --             Match_Directly  => Match_Directly);
                --     end if;
                --   end;
                --
              when HORSE_Back_1_10_07_1_2_PLC_1_01 ..
                  HORSE_Back_1_10_10_1_2_PLC_1_01   =>
                declare
                  M_Type     : Market_Type := Win;
                  Image      : String := I'Img;
                  Do_Try_Bet : Boolean := True;
                begin
                  --  12345678901234567890
                  --  Back_1_10_20_1_4_WIN
                  if Image (18 .. 20) = "PLC" then
                    M_Type := Place;
                    Do_Try_Bet := Found_Place and then Markets_Array (Place).Numwinners >= Integer_4 (3) ;
                    --Match_Directly := False;
                    Match_Directly := True;
                  elsif Image (18 .. 20) = "WIN" then
                    Match_Directly := True;
                  end if;
                  if Do_Try_Bet then
                    Try_To_Make_Back_Bet (
                                          Bettype         => I,
                                          BR              => Best_Runners,
                                          Marketid        => Markets_Array (M_Type).Marketid,
                                          Match_Directly  => Match_Directly);
                  end if;
                end;
              when HORSE_Back_1_96_2_00_08_10_1_2_WIN_1_70 ..
                  HORSE_BACK_1_11_1_15_05_07_1_2_PLC_1_01   =>
                declare
                  M_Type     : Market_Type := Win;
                  Image      : String := I'Img;
                  Do_Try_Bet : Boolean := True;
                begin
                  --           1         2         3
                  --  123456789012345678901234567890123456789
                  --  Back_1_61_1_65_01_04_1_2_PLC_1_10
                  if Image (26 .. 28) = "PLC" then
                    M_Type := Place;
                    Do_Try_Bet := Found_Place and then Markets_Array (Place).Numwinners >= Integer_4 (3) ;
                    --Match_Directly := False;
                    Match_Directly := True;
                  elsif Image (26 .. 28) = "WIN" then
                    Match_Directly := True;
                  end if;
                  if Do_Try_Bet then
                    Try_To_Make_Back_Bet_4_Bounds (
                                                   Bettype         => I,
                                                   BR              => Best_Runners,
                                                   Marketid        => Markets_Array (M_Type).Marketid,
                                                   Match_Directly  => Match_Directly);
                  end if;
                  end;
                  when HOUND_LAY_06_01_01_04_06_WIN_999_999 => null;
              end case;
            when Hound =>
              case I is
                when HOUND_LAY_06_01_01_04_06_WIN_999_999 .. HOUND_LAY_06_01_01_04_06_WIN_999_999 =>
                  if First_Time then
                    Log ("Treating Animal " & Animal'Img & " betname " & i'Img);
                    Do_Place_Lay_Bets_At_Start (
                                                Bettype         => I,
                                                BR              => Best_Runners,
                                                Marketid        => Markets_Array (Win).Marketid,
                                                Match_Directly  => True);
                  end if;
                when HORSE_LAY_02_02_04_10_16_WIN_600_900 .. HORSE_Back_1_10_10_1_2_Plc_1_01 => null;
              end case ;
            when Human => null;
          end case;

        end loop;
        First_Time := False;
      end if; -- Best_Runner(1).Backodds >= 1.01
    end loop Poll_Loop;

  end Run;
  ---------------------------------------------------------------------
  use type Sql.Transaction_Status_Type;
------------------------------ main start -------------------------------------

begin

   Define_Switch
    (Cmd_Line,
     Sa_Par_Bot_User'access,
     Long_Switch => "--user=",
     Help        => "user of bot");

   Define_Switch
     (Cmd_Line,
      Ba_Daemon'access,
      Long_Switch => "--daemon",
      Help        => "become daemon at startup");

   Define_Switch
     (Cmd_Line,
      Sa_Par_Inifile'access,
      Long_Switch => "--inifile=",
      Help        => "use alternative inifile");

  Getopt (Cmd_Line);  -- process the command line

  if Ba_Daemon then
    Posix.Daemonize;
  end if;

   --must take lock AFTER becoming a daemon ...
   --The parent pid dies, and would release the lock...
  My_Lock.Take(EV.Value("BOT_NAME"));

  Logging.Open(EV.Value("BOT_HOME") & "/log/" & EV.Value("BOT_NAME") & ".log");

  Log("Bot svn version:" & Bot_Svn_Info.Revision'Img);

  Cfg := Config.Create(Ev.Value("BOT_HOME") & "/" & Sa_Par_Inifile.all);
  Log(Cfg.To_String);
  Ini.Load(Ev.Value("BOT_HOME") & "/" & "login.ini");
  Log(Me, "Connect Db");
  Sql.Connect
        (Host     => Ini.Get_Value("database", "host", ""),
         Port     => Ini.Get_Value("database", "port", 5432),
         Db_Name  => Ini.Get_Value("database", "name", ""),
         Login    => Ini.Get_Value("database", "username", ""),
         Password =>Ini.Get_Value("database", "password", ""));
  Log(Me, "db Connected");

  Log(Me, "Login betfair");
  Rpc.Init(
            Username   => Ini.Get_Value("betfair","username",""),
            Password   => Ini.Get_Value("betfair","password",""),
            Product_Id => Ini.Get_Value("betfair","product_id",""),
            Vendor_Id  => Ini.Get_Value("betfair","vendor_id",""),
            App_Key    => Ini.Get_Value("betfair","appkey","")
          );
  Rpc.Login;
  Log(Me, "Login betfair done");

  if Cfg.Enabled then
    Cfg.Enabled := Ev.Value("BOT_MACHINE_ROLE") = "PROD";
  end if;

  Main_Loop : loop

    --notfy markets_fetcher that we are free
    Data := (Free => 1, Name => This_Process.Name , Node => This_Process.Node);
    Bot_Messages.Send(Markets_Fetcher, Data);

    begin
      Log(Me, "Start receive");
      Process_Io.Receive(Msg, Timeout);
      Log(Me, "msg : "& Process_Io.Identity(Msg)'Img & " from " & Trim(Process_Io.Sender(Msg).Name));
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
            Run(Bot_Messages.Data(Msg));
          else
            Log(Me, "Poll is not enabled in poll.ini");
          end if;
        when others =>
          Log(Me, "Unhandled message identity: " & Process_Io.Identity(Msg)'Img);  --??
      end case;
    exception
      when Process_Io.Timeout =>
        Rpc.Keep_Alive(OK);
        if not OK then
          Rpc.Login;
        end if;
    end;
    Now := Calendar2.Clock;

    --restart every day
    Is_Time_To_Exit := Now.Hour = 01 and then
                     ( Now.Minute = 00 or Now.Minute = 01) ; -- timeout = 2 min

    exit Main_Loop when Is_Time_To_Exit;

  end loop Main_Loop;

  Log(Me, "Close Db");
  Sql.Close_Session;
  Rpc.Logout;
  Logging.Close;
  Posix.Do_Exit(0); -- terminate

exception
  when Lock.Lock_Error =>
    Log(Me, "lock error, exit");
    Logging.Close;
    Posix.Do_Exit(0); -- terminate
  when E: others =>
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
