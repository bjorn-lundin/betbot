with Bot_Types     ; use Bot_Types;
with Types; use Types;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Calendar2;

package Config is

  type Bet_Type is (
      Lay_2_90_20_WIN_8_00,
      Lay_2_30_10_WIN_4_02,
      Lay_1_80_10_WIN_4_10,
      Lay_1_30_05_WIN_2_00,
      Lay_1_80_15_WIN_7_15,
      Lay_1_70_10_WIN_6_20,
      Lay_1_40_10_WIN_5_20,
      Lay_1_80_09_WIN_3_01,
      Lay_1_20_09_WIN_3_07,
      Lay_1_80_20_WIN_4_15,
      Back_1_96_2_00_08_10_1_2_WIN_1_70, 
      Back_1_11_1_15_01_04_1_2_PLC_1_01,
      Back_1_11_1_15_05_07_1_2_PLC_1_01,
      Back_1_11_1_15_08_10_1_2_PLC_1_01,
      Back_1_11_1_15_11_13_1_2_PLC_1_01,
      Back_1_10_07_1_2_PLC_1_01,
      Back_1_10_10_1_2_PLC_1_01,
      Back_1_10_07_1_2_PLC_1_02,
      Back_1_10_10_1_2_PLC_1_02
  );

  type Allowed_Days_Array is array(Calendar2.Week_Day_Type'range) of Boolean;

  type Bet_Config_Type is tagged record
    Size                       : Bet_Size_Type    := 30.0;
    Max_Loss_Per_Day           : Float_8          := -500.0;
    Min_Price                  : Unbounded_String := Null_Unbounded_String;
    Enabled                    : Boolean          := False;
  end record;

  type Bet_Config_Array_Type is array(Bet_Type'range) of Bet_Config_Type;

  type Config_Type is tagged record
    --Size                       : Bet_Size_Type    := 30.0;
    --Max_Loss_Per_Day           : Float_8          := -500.0;
    Max_Turns_Not_Started_Race : Integer_4        := 102;  --102*5s -> 8,5 min
    Enabled                    : Boolean          := False;
    Allowed_Countries          : Unbounded_String := Null_Unbounded_String;
    Allowed_Days               : Allowed_Days_Array     := (others => False);
    Bet                        : Bet_Config_Array_Type;
  end record;

  function Create(Filename : String) return Config_Type;
  function Country_Is_Ok (Cfg : Config_Type; Country_Code : String) return Boolean;
  function To_String(Cfg : Config_Type) return String ;

  procedure Print_Strategies;

end Config;
