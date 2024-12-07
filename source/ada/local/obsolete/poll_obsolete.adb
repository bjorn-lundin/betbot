


package body poll_obsolete is


  Global_Best_Runners  : array (Market_Type'Range) of Best_Runners_Array_Type := (others => (others => Prices.Empty_Data));



 -------------------------------------------------------------------------------------------------------------------
  procedure Save_Candidates(Br : Best_Runners_Array_Type) is  -- global Best_Runners
  begin
    Global_Best_Runners(Win) := Br;
    Global_Best_Runners(Place) := Br;
  end Save_Candidates;
  -----------------------------------------------------------------------------------



  procedure Send_Lay_Bet (Selectionid    : Integer_4;
                          Main_Bet       : Bet_Type;
                          Max_Price      : Max_Lay_Price_Type;
                          Marketid       : Marketid_Type;
                          Match_Directly : Boolean := False;
                          Fill_Or_Kill   : Boolean := False) is

    Plb             : Bot_Messages.Place_Lay_Bet_Record;
    Did_Bet         : array (1 .. 1) of Boolean := (others => False);
    Receiver        : Process_Io.Process_Type := Get_Bet_Placer (Main_Bet);
  begin
    declare
      -- only bet on allowed days
      Now : Time_Type := Clock;
      Day : Week_Day_Type := Week_Day_Of (Now);
    begin
      if not Cfg.Allowed_Days (Day) then
        Log ("No bet layed, bad weekday" );
        return;
      end if;
    end;

    if not Cfg.Bet (Main_Bet).Enabled then
      Log ("Not enbled bet in poll.ini " & Main_Bet'Img );
      return;
    end if;

    if Selectionid = Bad_Selection_Id then
      Log ("Bad selectionid, = 0 ");
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


    Plb.Bet_Name := Bets_Allowed (Main_Bet).Bet_Name;
    Move (Marketid, Plb.Market_Id);
    Move (F8_Image (Fixed_Type (Max_Price)), Plb.Price); --abs max
    Plb.Selection_Id := Selectionid;

    if not Bets_Allowed (Main_Bet).Has_Betted and then
      Bets_Allowed (Main_Bet).Is_Allowed_To_Bet then
      Move (F8_Image (Fixed_Type (Bets_Allowed (Main_Bet).Bet_Size)), Plb.Size);
      Bot_Messages.Send (Receiver, Plb);

      Bets_Allowed (Main_Bet).Has_Betted := True;

      Did_Bet (1) := True;
    end if;

    if Did_Bet (1) then
      Log ("Send_Lay_Bet called with " &
             " Selectionid=" & Selectionid'Img &
             " Main_Bet=" & Main_Bet'Img &
             " Marketid= '" & Marketid & "'" &
             " Receiver= '" & Receiver.Name & "'");
      Log ("pinged '" &  Trim (Receiver.Name) & "' with bet '" & Trim (Plb.Bet_Name) & "' sel.id:" &  Plb.Selection_Id'Img );
    end if;

  end Send_Lay_Bet;
  --------------------------------------------------------------




  procedure Try_To_Make_Lay_Bet (Bettype         : Config.Bet_Type;
                                 Br              : Best_Runners_Array_Type;
                                 Marketid        : Marketid_Type;
                                 Match_Directly  : Boolean := False) is
    Max_Backprice_1  : Fixed_Type;
    Min_Backprice_N  : Fixed_Type;
    Layed_Num        : Integer;
    Tmp              : String (1 .. 5) := (others => ' ');
    Image            : String := Bettype'Img;
    Max_Price        : String (1 .. 4) := (others => ' ');
  begin          --1         2
    --  12345678901234567890123456789012345
    --  HORSE_Lay_1_10_20_1_2_WIN_3_25
    Tmp (1) := Image (11);
    Tmp (2) := '.';
    Tmp (3 .. 4) := Image (13 .. 14);
    Max_Backprice_1 := Fixed_Type'Value (Tmp);

    Min_Backprice_N := Fixed_Type'Value (Image (16 .. 17));
    Layed_Num := Integer'Value (Image (27 .. 27));

    Max_Price (1 .. 2) := Image (29 .. 30);

    if Br (1).Backprice <= Max_Backprice_1 and then
      Br (1).Backprice >= Fixed_Type (1.01) and then
      Br (2).Backprice >= Min_Backprice_N and then
      Br (2).Backprice < Fixed_Type (10_000.0) and then
      Br (Layed_Num).Layprice <= Fixed_Type'Value (Max_Price) and then
      Br (Layed_Num).Layprice >= Fixed_Type (1.01) and then
      Br (Layed_Num).Backprice < Fixed_Type (10_000.0) then  -- so it exists

      -- lay #2 or #3 in win market...

      Send_Lay_Bet (Selectionid     => Br (Layed_Num).Selectionid,
                    Main_Bet        => Bettype,
                    Marketid        => Marketid,
                    Max_Price       => Max_Lay_Price_Type'Value (Max_Price),
                    Match_Directly  => Match_Directly);
    end if;
  end Try_To_Make_Lay_Bet;

  -----------------------------------------------------------------------------------



  ------------------------------------------------------
  procedure Try_To_Make_Back_Bet_4_Bounds (Bettype         : Config.Bet_Type;
                                           Br              : Best_Runners_Array_Type;
                                           Marketid        : Marketid_Type;
                                           Match_Directly  : Boolean := False) is

    Max_Backprice_1 : Fixed_Type;
    Min_Backprice_1 : Fixed_Type;
    Min_Backprice_N : Fixed_Type;
    Max_Backprice_N : Fixed_Type;
    Backed_Num      : Integer;
    Next_Num        : Integer;
    Tmp             : String (1 .. 5) := (others => ' ');
    Image           : String := Bettype'Img;
    Min_Price       : String (1 .. 4) := (others => '.');
  begin          --1         2         3
    --  123456789012345678901234567890123456789
    --  HORSE_BACK_1_36_1_40_01_04_1_2_PLC_1_10

    Tmp (1) := Image (12);
    Tmp (2) := '.';
    Tmp (3 .. 4) := Image (14 .. 15);
    Min_Backprice_1 := Fixed_Type'Value (Tmp);

    Tmp (1) := Image (17);
    Tmp (2) := '.';
    Tmp (3 .. 4) := Image (19 .. 20);
    Max_Backprice_1 := Fixed_Type'Value (Tmp);

    Min_Backprice_N := Fixed_Type'Value (Image (22 .. 23));
    Max_Backprice_N := Fixed_Type'Value (Image (25 .. 26));

    Backed_Num := Integer'Value (Image (28 .. 28));
    Next_Num := Integer'Value (Image (30 .. 30));

    Min_Price (1)    := Image (36);
    Min_Price (3 .. 4) := Image (38 .. 39);

    if Br (Backed_Num).Backprice <= Max_Backprice_1 and then
      Br (Backed_Num).Backprice >= Min_Backprice_1 and then
      Br (Next_Num).Backprice >= Min_Backprice_N and then
      Br (Next_Num).Backprice <= Max_Backprice_N and then
      Br (3).Backprice < Fixed_Type (10_000.0) then  -- so it exists
      -- Back The leader in PLC market...

      Send_Back_Bet (Selectionid     => Br (Backed_Num).Selectionid,
                     Main_Bet        => Bettype,
                     Marketid        => Marketid,
                     Min_Price       => Back_Price_Type'Value (Min_Price),
                     Match_Directly  => Match_Directly);
    end if;
  end Try_To_Make_Back_Bet_4_Bounds;


  procedure  Try_To_Back_Win_High_To_Low(Bettype        : Config.Bet_Type;
                                         Br             : Best_Runners_Array_Type;
                                         Marketid       : Marketid_Type;
                                         Match_Directly : Boolean := False) is
    use Ada.Strings.Unbounded;
    Start_Price_S   : String (1 .. 5) := (others => '.');
    Bet_Price_S     : String (1 .. 5) := (others => '.');
    Image           : String := Bettype'Img;
    Start_Price     : Fixed_Type := 0.0;
    Bet_Price       : Fixed_Type := 0.0;
  begin
    --  0         1        2         3
    --  123456789012345678901234567890123456789
    --  Horse_Back_Win_High_To_Low_08_40_03_00

    Start_Price_S(1) := Image(28);
    Start_Price_S(2) := Image(29);
    Start_Price_S(4) := Image(31);
    Start_Price_S(5) := Image(32);
    Start_Price := Fixed_Type'Value(Start_Price_S);

    Bet_Price_S(1) := Image(34);
    Bet_Price_S(2) := Image(35);
    Bet_Price_S(4) := Image(37);
    Bet_Price_S(5) := Image(38);
    Bet_Price := Fixed_Type'Value(Bet_Price_S);


    -- do we have a case?
    for Gbr of Global_Best_Runners(Win) loop
      for Cbr of Br loop
        if Gbr.Selectionid = Cbr.Selectionid and then
          Start_Price = Gbr.Backprice and then
          Cbr.Backprice <= Bet_Price then -- made a nice run
          -- make win bet
          Log ("Try_To_Back_Win_High_To_Low place bet " & Image);
          Log ("Try_To_Back_Win_High_To_Low start   price " & Gbr.To_String   );
          Log ("Try_To_Back_Win_High_To_Low current price " & Cbr.To_String   );

          Send_Back_Bet (Selectionid     => Cbr.Selectionid,
                         Main_Bet        => Bettype,
                         Marketid        => Marketid,
                         Min_Price       => Back_Price_Type(Cbr.Backprice), --Back_Price_Type'Value ("1.01"),
                         -- later, when active Min_Price       => Back_Price_Type'Value (To_String(Cfg.Bet(Bettype).Min_Price)),
                         Match_Directly  => Match_Directly);
          -- Reset the global runner not to bet again on it
          Gbr := Prices.Empty_Data;
        end if;
      end loop;
    end loop;
  end Try_To_Back_Win_High_To_Low;
  -----------------------------------------------------------------------------------
  procedure Try_To_Back_Place_High_To_Low(Bettype        : Config.Bet_Type;
                                          Br             : Best_Runners_Array_Type;
                                          Marketid       : Marketid_Type;
                                          Match_Directly : Boolean := False) is
    use Ada.Strings.Unbounded;
    Start_Price_S   : String (1 .. 5) := (others => '.');
    Bet_Price_S     : String (1 .. 5) := (others => '.');
    Image           : String := Bettype'Img;
    Start_Price     : Fixed_Type := 0.0;
    Bet_Price       : Fixed_Type := 0.0;
  begin
    --  0        1         2         3         4
    --  1234567890123456789012345678901234567890
    --  Horse_Back_Place_High_To_Low_08_40_03_00

    Start_Price_S(1) := Image(30);
    Start_Price_S(2) := Image(31);
    Start_Price_S(4) := Image(33);
    Start_Price_S(5) := Image(34);
    Start_Price := Fixed_Type'Value(Start_Price_S);

    Bet_Price_S(1) := Image(36);
    Bet_Price_S(2) := Image(37);
    Bet_Price_S(4) := Image(39);
    Bet_Price_S(5) := Image(40);
    Bet_Price := Fixed_Type'Value(Bet_Price_S);

    -- do we have a case?
    for Gbr of Global_Best_Runners(Place) loop  -- not really place odds, but odds for this place stratey. It's really win odds
      for Cbr of Br loop
        if Gbr.Selectionid = Cbr.Selectionid and then
          Start_Price = Gbr.Backprice and then
          Cbr.Backprice <= Bet_Price then -- made a nice run
          -- make win bet
          Log ("Try_To_Back_Place_High_To_Low place bet " & Image);
          Log ("Try_To_Back_Place_High_To_Low start   price " & Gbr.To_String   );
          Log ("Try_To_Back_Place_High_To_Low current price " & Cbr.To_String   );

          Send_Back_Bet (Selectionid     => Cbr.Selectionid,
                         Main_Bet        => Bettype,
                         Marketid        => Marketid,
                         Min_Price       => Back_Price_Type'Value (To_String(Cfg.Bet(Bettype).Min_Price)),
                         Match_Directly  => Match_Directly);
          -- Reset the global runner not to bet again on it
          Gbr := Prices.Empty_Data;
        end if;
      end loop;
    end loop;
  end Try_To_Back_Place_High_To_Low;
  -----------------------------------------------------------------------------------
      Worst_Runner      : Prices.Price_Type := Prices.Empty_Data;


      Worst_Runner.Layprice := 10_000.0;


      for Tmp of Price_List loop
        if Tmp.Status (1 .. 6) = "ACTIVE" and then
          Tmp.Backprice > Fixed_Type (1.0) and then
          Tmp.Layprice < Fixed_Type (1_000.0) and then
          Tmp.Selectionid /= Best_Runners (1).Selectionid and then
          Tmp.Selectionid /= Best_Runners (2).Selectionid then

          Worst_Runner := Tmp;
        end if;
      end loop;



      if First_Poll then
        Save_Candidates(Br => Best_Runners); -- save into global Best_Runners
      end if;

        for I in Bet_Type'Range loop
         Log ("Animal " & Animal'Img & " betname " & I'Img & " First_Poll " & First_Poll'Img);
          case Animal is
            when Horse =>
              case I is


--                  when Horse_Lay_1_05_10_1_2_Win_3_40 .. Horse_Lay_1_05_10_1_2_Win_3_50   =>
--                    --  12345678901234567890
--                    --  Horse_Lay_1_09_02_1_2_Win_3_25
--                    Try_To_Make_Lay_Bet (
--                                         Bettype         => I,
--                                         Br              => Best_Runners,
--                                         Marketid        => Markets_Array (Win).Marketid,
--                                         Match_Directly  => True);



--                  when Horse_Back_1_11_1_15_05_07_1_2_Plc_1_01  =>
--                    declare
--                      M_Type     : Market_Type := Win;
--                      Image      : String := I'Img;
--                      Do_Try_Bet : Boolean := True;
--                    begin
--                      --           1         2         3
--                      --  123456789012345678901234567890123456789
--                      --  Back_1_61_1_65_01_04_1_2_PLC_1_10
--                      if Utils.Position (Image, "PLC") > Integer (0) then
--                        M_Type := Place;
--                        Do_Try_Bet := Found_Place and then Markets_Array (Place).Numwinners >= Integer_4 (3) ;
--                        Match_Directly := True;
--                      elsif Utils.Position (Image, "WIN") > Integer (0) then
--                        M_Type         := Win;
--                        Match_Directly := True;
--                      end if;
--                      if Do_Try_Bet and then
--                        Has_Been_In_Play then
--                        Try_To_Make_Back_Bet_4_Bounds (Bettype         => I,
--                                                       Br              => Best_Runners,
--                                                       Marketid        => Markets_Array (M_Type).Marketid,
--                                                       Match_Directly  => Match_Directly);
--                      end if;
--                    end;
--
--                  when Horse_Back_Win_High_To_Low_08_00_03_00 .. Horse_Back_Win_High_To_Low_21_00_13_00 =>
--                    Try_To_Back_Win_High_To_Low(Bettype         => I,
--                                                Br              => Best_Runners,
--                                                Marketid        => Markets_Array (Win).Marketid,
--                                                Match_Directly  => True);
--
--                  when Horse_Back_Place_High_To_Low_03_40_03_00 .. Horse_Back_Place_High_To_Low_12_00_03_00 =>
--                    Try_To_Back_Place_High_To_Low(Bettype         => I,
--                                                  Br              => Best_Runners,
--                                                  Marketid        => Markets_Array (Place).Marketid,
--                                                  Match_Directly  => True);


end poll_obsolete;
