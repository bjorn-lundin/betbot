with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;

with Sql;
with Calendar2; use Calendar2;

with Logging; use Logging;
with Utils;
with Bot_System_Number;
with Bot_Svn_Info;
with Price_History;


package body Bet is
  Me : constant String := "Bet.";
  Select_Exists,
  Select_Profit_Today : Sql.Statement_Type;
  Select_Ph           : Sql.Statement_Type;

  ------------------------------------------------------------
  function Profit_Today(Bet_Name : Betname_Type) return Float_8 is
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
  function Exists(Bet_Name : Betname_Type; Market_Id : Marketid_Type) return Boolean is
    T    : Sql.Transaction_Type;
    Eos  : Boolean := False;
    Abet : Table_Abets.Data_Type;
  begin
    T.Start;
      Select_Exists.Prepare(
         "select * " &
         "from ABETS " &
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
  ------------------------
  function Empty_Data return Bet_Type is
    ED : Bet_Type;
  begin
    return ED;
  end Empty_Data;

  ----------------------------------------
  procedure Clear(Self : in out Bet_Type) is
  begin
    Self := Empty_Data;
  end Clear;
  ----------------------------------------
  procedure Check_Outcome(Self : in out Bet_Type) is
    The_Runner : Runner.Runner_Type;
    Eos : Boolean := False;
  begin
    if Self.Pricematched < 0.5 then
      Self.Profit := 0.0;
      return;
    end if;

    The_Runner.Marketid := Self.Marketid;
    The_Runner.Selectionid := Self.Selectionid;
    The_Runner.Read(Eos);
    if Eos then
      Log(Me & "Check_Outcome", "Runner does not exist");
      return;
    end if;

    if The_Runner.Status(1..7) = "REMOVED" then
       Self.Status(1..7) := "REMOVED";
       Self.Betwon := True;
       Self.Profit := 0.0;
      return;
    end if;

    Self.Runnername := The_Runner.Runnernamestripped;
    if Self.Side(1..4) = "BACK" then
        if The_Runner.Status(1..6) = "WINNER" then
          Self.Betwon := True;
        elsif The_Runner.Status(1..5) = "LOSER" then
          Self.Betwon := False;
        end if;

        if Self.Betwon then
          Self.Profit := (1.0 - Commission) * Self.Sizematched * (Self.Pricematched - 1.0);
        else
          Self.Profit := -Self.Sizematched;
        end if;

    elsif Self.Side(1..3) = "LAY" then
        if The_Runner.Status(1..6) = "WINNER" then
          Self.Betwon := False;
        elsif The_Runner.Status(1..5) = "LOSER" then
          Self.Betwon := True;
        end if;

        if Self.Betwon then
          Self.Profit := (1.0 - Commission) * Self.Sizematched;
        else
          Self.Profit := -Self.Sizematched * (Self.Pricematched - 1.0);
        end if;
    end if;
  end Check_Outcome;

  ------------------------
  
  procedure Match_Directly(Self : in out Bet_Type; Value : Boolean ) is
  begin
    if Value then
      Self.Powerdays := Integer_4(1);
    else
      Self.Powerdays := Integer_4(0);
    end if;    
  end Match_Directly;
  ------------------------
  function Match_Directly(Self : in out Bet_Type) return Boolean is
  begin
    return Self.Powerdays /= Integer_4(0);
  end Match_Directly;
  
  ------------------------

  function Create(Name : Betname_Type;
                  Side : Bet_Side_Type;
                  Size : Bet_Size_Type;
                  Price : Price_Type;
                  Placed : Calendar2.Time_Type;
                  The_Runner : Runner.Runner_Type;
                  The_Market : Market.Market_Type) return Bet_Type is

    Now        : Calendar2.Time_Type      := Calendar2.Clock;
    Self : Bet_Type;
    Local_Side : String (Self.Side'range) := (others => ' ');

  begin
    Move (Side'Img,Local_Side);
    Self := (
        Betid          => Integer_8(Bot_System_Number.New_Number(Bot_System_Number.Betid)),
        Marketid       => The_Market.Marketid,
        Betmode        => Bot_Mode(Simulation),
        Powerdays      => 0,
        Selectionid    => The_Runner.Selectionid,
        Reference      => (others => '-'),
        Size           => Float_8(Size),
        Price          => Float_8(Price),
        Side           => Local_Side,
        Betname        => Name,
        Betwon         => False,
        Profit         => 0.0,
        Status         => (others => ' '),
        Exestatus      => (others => ' '),
        Exeerrcode     => (others => ' '),
        Inststatus     => (others => ' '),
        Insterrcode    => (others => ' '),
        Startts        => The_Market.Startts,
        Betplaced      => Placed,
        Pricematched   => Float_8(0.0),
        Sizematched    => Float_8(Size),
        Runnername     => The_Runner.Runnernamestripped,
        Fullmarketname => The_Market.Marketname,
        Svnrevision    => Bot_Svn_Info.Revision,
        Ixxlupd        => (others => ' '), --set by insert
        Ixxluts        => Now              --set by insert
      );
      return Self;
  end Create;
  -------------------------
  procedure Check_Matched(Self : in out Bet_Type) is
    List : Price_History.List_Pack.List;
  begin
    Select_Ph.Prepare(
        "select * " &
        "from " &
        "APRICESHISTORY " &
        "where MARKETID = :MARKETID " &
        "and SELECTIONID = :SELECTIONID " &
        "and PRICETS >= :PRICETS1 " &
        "and PRICETS <= :PRICETS2 " &
        "order by PRICETS"
    );

    Select_Ph.Set("MARKETID", Self.Marketid);
    Select_Ph.Set("SELECTIONID", Self.Selectionid);
    Select_Ph.Set("PRICETS1", Self.Betplaced + (0,0,0,1,0)); -- 1 s
    if Self.Match_Directly then
      Select_Ph.Set("PRICETS2", Self.Betplaced + (0,0,0,2,0)); -- data 1s..2s from betplaced
    else -- get the whole race, assume shorter than 9 days
      Select_Ph.Set("PRICETS2", Self.Betplaced + (9,0,0,0,0)); -- data 1s .. 9 days from betplaced
    end if;
    Price_History.Read_List(Select_Ph,List);

    for PH of List loop
      if Self.Side(1..4) = "BACK" then
        if PH.Backprice >= Self.Price and then -- Match ok
           PH.Backprice <= Float_8(1000.0) then -- Match ok
           Self.Pricematched := PH.Backprice;
           Self.Status(1..7) := "MATCHED";
        end if;
      elsif Self.Side(1..3) = "LAY" then
        if PH.Layprice <= Self.Price and then -- Match ok
           PH.Layprice >= Float_8(1.01) then
           Self.Pricematched := PH.Layprice;
           Self.Status(1..7) := "MATCHED";
        end if;
      end if;
      exit when Self.Match_Directly or else -- match directly
                Self.Pricematched >= Float_8(1.01);     -- matched
    end loop;
    if Self.Status(1) /= 'M' then
       Self.Status(1..7) := "LAPSED ";
       Self.Pricematched := Float_8(0.0);
       Self.Profit := 0.0;
    end if;
  end Check_Matched;
  ----------------------------------

end Bet;
