with Bot_Types     ; use Bot_Types;
with Types; use Types;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Calendar2;

package Config is

  type Bet_Type is (
                    Lay_2_2_4_11_17_Win, -- Several Bets In This Type
                    Lay_3_1_4_10_16_Win_200_700,
                    Lay_3_1_4_10_16_Win,
                    Back_3_4_4_08_14_Win,
                    Back_4_4_4_08_14_Win,
                    Back_4_4_4_09_15_Win,
                    Back_5_4_4_08_14_Win,
                    Back_5_4_4_09_15_Win,
                    Back_6_4_4_08_14_Win,
                    Lay_2_90_20_Win_8_00,
                    Back_1_96_2_00_08_10_1_2_Win_1_70,
                    Back_1_11_1_15_05_07_1_2_Plc_1_01,
                    Back_1_10_07_1_2_Plc_1_01,
                    Back_1_10_10_1_2_Plc_1_01,
                    Back_1_10_10_1_2_Plc_1_02
                   );

  type Allowed_Days_Array is array(Calendar2.Week_Day_Type'range) of Boolean;

  type Bet_Config_Type is tagged record
    Size                       : Bet_Size_Type    := 30.0;
    Max_Loss_Per_Day           : Float_8          := -200.0;
    Max_Earnings_Per_Day       : Float_8          :=  200.0;
    Min_Price                  : Unbounded_String := Null_Unbounded_String;
    Enabled                    : Boolean          := False;
  end record;

  type Bet_Config_Array_Type is array(Bet_Type'range) of Bet_Config_Type;

  type Config_Type is tagged record
    --Size                       : Bet_Size_Type    := 30.0;
    Max_Exposure               : Float_8          := 0.0;
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
