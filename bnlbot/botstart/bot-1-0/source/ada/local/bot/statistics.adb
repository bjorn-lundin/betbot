
with Text_Io;
with Utils;

package body Statistics is

--    Cnt                 : Natural := 0 ;
--    Cnt_Won             : Natural:= 0 ;
--    Cnt_Matched         : Natural:= 0 ;
--    Hitrate             : Float_8 := 0.0;
--    Needed_Hitrate      : Float_8 := 0.0;
--    Hitrate_Times_Count : Float_8 := 0.0;


  Commission : constant Float_8 := 0.065;

  function Needed_Hitrate(O : Float_8) return Float_8 is
    -- =1/(K6-(K6-1)*$A$2)
  begin
    return 1.0/(O - (O-1.0)* Commission) ;
  end Needed_Hitrate;
  ------------------------------------------------------------
  procedure Treat(Self : in out Stats_Type; Bet : Table_Abets.Data_Type) is

  begin

    Self.Needed_Hitrate := Needed_Hitrate(Bet.Pricematched);

    Self.Cnt := Self.Cnt +1;

    if Bet.Betwon then
      Self.Cnt_Won := Self.Cnt_Won +1;
    end if;

    if Bet.Status(1) = 'M' then
      Self.Cnt_Matched := Self.Cnt_Matched +1;
    end if;

    Self.Hitrate := Float_8(Self.Cnt_Won)/Float_8(Self.Cnt);
    Self.Hitrate_Times_Count := Self.Hitrate * Float_8(Self.Cnt);
  end Treat;
  ------------------------------------------------------------
  procedure Print_Result(Self   : in out Stats_Type;
                         First  : in First_Odds_Range_Type;
                         Second : in Second_Odds_Range_Type;
                         Market : in Market_Type) is
    use Text_Io;
    use Utils;
    -- 123456789012345
    -- A_1_01_1_05,
    -- A_01_07,

  begin
    -- first/second/cnt/
    Put_Line(First'Img(3)  & "." & First'Img(5..6) & "_" & First'Img(8)  & "." & First'Img(10..11) & "|" &
             Second'Img(3..4) & "_" & Second'Img(6..7) & "|" &
    --Put_Line(First'Img(8)  & "." & First'Img(10..11) & "|" &
    --         Second'Img(6..7) & "|" &
--             F8_Image(Self.Needed_Hitrate) & "|" &
--             Self.Cnt'Img & "|" &
--             Self.Cnt_Won'Img & "|" &
--             Self.Cnt_Matched'Img & "|" &
--             F8_Image(Self.Hitrate) & "|" &
--             F8_Image(Self.Hitrate_Times_Count) & "|" &
             F8_Image((Self.Hitrate - Self.Needed_Hitrate)*Float_8(Self.Cnt))
    );
--    if Second = Second_Odds_Range_Type'last then
--      New_Line;    
--    end if;
    
  end Print_Result;
  ------------------------------------------------------------

  function Get_First_Odds_Range(Betname : String) return First_Odds_Range_Type is
  begin --      1         2
    -- 1234567890123456789012345678
    -- BACK_1_01_1_05_11_13_1_2_WIN
      return First_Odds_Range_Type'Value("A_" & Betname(6..14));
  exception
    when Constraint_Error =>
     Text_io.Put_Line (Betname);
     raise;
  end Get_First_Odds_Range;
  ------------------------------------------------------------

  function Get_Second_Odds_Range(Betname : String) return Second_Odds_Range_Type is
  begin --      1         2
    -- 1234567890123456789012345678
    -- BACK_1_01_1_05_11_13_1_2_WIN
      return Second_Odds_Range_Type'Value("A_" & Betname(16..20) );
  exception
    when Constraint_Error =>
     Text_io.Put_Line (Betname);
     raise;
  end Get_Second_Odds_Range;
  ------------------------------------------------------------
  function Get_Market_Type(Betname : String) return Market_Type is
  begin --      1         2
    -- 1234567890123456789012345678
    -- BACK_1_01_1_05_11_13_1_2_WIN
      return Market_Type'Value(Betname(26..28) );
  exception
    when Constraint_Error =>
     Text_io.Put_Line (Betname);
     raise;
  end Get_Market_Type;
  ------------------------------------------------------------

end Statistics;






