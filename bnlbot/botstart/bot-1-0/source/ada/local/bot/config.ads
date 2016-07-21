with Bot_Types     ; use Bot_Types;
with Types; use Types;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Calendar2;

package Config is

  type Bet_Type is (
      Back_1_31_1_35_05_07_1_2_WIN_1_20,
      Back_1_41_1_45_08_10_1_2_WIN_1_30,
      Back_1_96_2_00_01_04_1_2_WIN_1_70,
      Back_1_21_1_25_01_04_1_2_PLC_1_10,
      Back_1_26_1_30_01_04_1_2_PLC_1_10,
      Back_1_31_1_35_01_04_1_2_PLC_1_10,
      Back_1_31_1_35_05_07_1_2_PLC_1_10,
      Back_1_36_1_40_01_04_1_2_PLC_1_10,
      Back_1_41_1_45_01_04_1_2_PLC_1_10,
      Back_1_46_1_50_01_04_1_2_PLC_1_10,
      Back_1_51_1_55_01_04_1_2_PLC_1_10,
      Back_1_56_1_60_01_04_1_2_PLC_1_10,
      Back_1_61_1_65_01_04_1_2_PLC_1_10,
      Back_1_76_1_80_01_04_1_2_PLC_1_10,
      Back_1_96_2_00_01_04_1_2_PLC_1_20,
      Back_1_10_07_1_2_PLC_1_01,
      Back_1_10_10_1_2_PLC_1_01,
      Back_1_10_07_1_2_PLC_1_02,
      Back_1_10_10_1_2_PLC_1_02 --,
     -- Lay_160_200,
     -- Lay_1_10_25_4
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
