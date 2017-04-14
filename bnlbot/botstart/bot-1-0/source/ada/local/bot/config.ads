with Bot_Types     ; use Bot_Types;
with Types; use Types;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Calendar2;

package Config is

  type Bet_Type is (
                    --Horse_Back_03_04_04_08_14_Win_500_800, -- Several Bets In This Type
                    --Horse_Back_04_04_04_08_14_Win_500_900, -- Several Bets In This Type
                    --Horse_Back_05_04_04_09_15_Win_500_900, -- Several Bets In This Type
                    --Horse_Back_06_04_04_08_14_Win_600_900, -- Several Bets In This Type
                    Horse_Back_1_11_1_15_05_07_1_2_Plc_1_01,
                    --Horse_Back_1_12_1_14_06_07_1_2_Win_1_01,
                    Horse_Back_1_03_01_1_2_Plc_1_01,
                    Horse_Back_1_10_07_1_2_Plc_1_01,
                    Horse_Back_1_19_01_1_2_Plc_1_01,
                    HORSE_LAY_1_04_11_1_2_WIN_2_30,
                    HORSE_LAY_1_09_02_1_2_WIN_3_30
                    --Horse_Back_1_12_06_1_2_Win_1_01,
                    --Horse_Back_1_13_07_1_2_Win_1_01,
                    --Horse_Back_1_14_07_1_2_Win_1_01,
                    --Horse_Back_1_16_17_1_2_Win_1_01,
                    --Horse_Back_1_19_02_1_2_Win_1_01,
                    --Hound_Lay_01_06_04_07_09_Win_999_999,
                    --Hound_Lay_03_04_06_07_09_Win_999_999
                   );


  type Allowed_Days_Array is array(Calendar2.Week_Day_Type'range) of Boolean;

  type Bet_Config_Type is tagged record
    Size                       : Bet_Size_Type    := 30.0;
    Max_Loss_Per_Day           : Fixed_Type          := -200.0;
    Max_Earnings_Per_Day       : Fixed_Type          :=  200.0;
    Min_Price                  : Unbounded_String := Null_Unbounded_String;
    Enabled                    : Boolean          := False;
  end record;

  type Bet_Config_Array_Type is array(Bet_Type'range) of Bet_Config_Type;

  type Config_Type is tagged record
    --Size                       : Bet_Size_Type    := 30.0;
    Max_Exposure               : Fixed_Type          := 0.0;
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
