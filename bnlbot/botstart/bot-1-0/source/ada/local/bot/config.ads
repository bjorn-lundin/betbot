with Bot_Types     ; use Bot_Types;
with Types; use Types;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Calendar2;

package Config is

  type Bet_Type is (
      Lay_2_3_10_WIN_4_2,
      Lay_1_8_10_WIN_4_10,
      Lay_1_3_05_WIN_2_0,
      Back_1_96_2_00_08_10_1_2_WIN_1_70, 
      Back_1_01_1_05_01_04_1_2_PLC_1_01,
      Back_1_01_1_05_08_10_1_2_PLC_1_01,
      Back_1_06_1_10_05_07_1_2_PLC_1_01,
      Back_1_06_1_10_14_17_1_2_PLC_1_01,
      Back_1_11_1_15_01_04_1_2_PLC_1_01,
      Back_1_11_1_15_05_07_1_2_PLC_1_01,
      Back_1_11_1_15_08_10_1_2_PLC_1_01,
      Back_1_11_1_15_11_13_1_2_PLC_1_01,
      Back_1_16_1_20_01_04_1_2_PLC_1_01,
      Back_1_16_1_20_05_07_1_2_PLC_1_01,
      Back_1_16_1_20_08_10_1_2_PLC_1_01,
      Back_1_21_1_25_01_04_1_2_PLC_1_01,
      Back_1_21_1_25_05_07_1_2_PLC_1_01,
      Back_1_26_1_30_01_04_1_2_PLC_1_01,
      Back_1_26_1_30_08_10_1_2_PLC_1_01,
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
