with Bot_Types     ; use Bot_Types;
with Types; use Types;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Calendar2;

package Config is

  type Bet_Type is (
                    Horse_Back_1_11_1_15_05_07_1_2_Plc_1_01,
                    Horse_Back_1_10_07_1_2_Plc_1_01,
                    Horse_Lay_1_05_10_1_2_Win_3_40,
                    Horse_Lay_1_05_10_1_2_Win_3_50,
                    Horse_Back_Plc_04_00,
                    Horse_Back_Plc_04_10,
                    Horse_Back_Plc_04_20,
                    Horse_Back_Plc_04_30,
                    Horse_Back_Plc_04_40,
                    Horse_Back_Plc_04_50,
                    Horse_Back_Plc_04_60,
                    Horse_Back_Plc_04_70,
                    Horse_Back_Plc_04_80,
                    Horse_Back_Plc_04_90,
                    Horse_Back_Plc_05_00,
                    Horse_Back_Plc_05_10,
                    Horse_Back_Plc_05_20,
                    Horse_Back_Plc_05_30,
                    Horse_Back_Plc_05_40,
                    Horse_Back_Plc_05_50,
                    Horse_Back_Plc_05_60,
                    Horse_Back_Plc_05_70,
                    Horse_Back_Plc_05_80,
                    Horse_Back_Plc_05_90,
                    Horse_Back_Plc_06_00,
                    Horse_Back_Plc_06_20,
                    Horse_Back_Plc_06_40,
                    Horse_Back_Plc_06_60,
                    Horse_Back_Plc_06_80,
                    Horse_Back_Plc_07_00,
                    Horse_Back_Plc_07_20,
                    Horse_Back_Plc_07_40,
                    Horse_Back_Plc_07_60,
                    Horse_Back_Plc_07_80,
                    Horse_Back_Plc_08_00,
                    Horse_Back_Plc_08_20,
                    Horse_Back_Plc_08_40,
                    Horse_Back_Plc_08_60,
                    Horse_Back_Plc_08_80,
                    Horse_Back_Plc_09_00,
                    Horse_Back_Plc_09_20,
                    Horse_Back_Plc_09_40,
                    Horse_Back_Plc_09_60,
                    Horse_Back_Plc_09_80,
                    Horse_Back_Plc_10_00,
                    Horse_Back_Plc_10_50,
                    Horse_Back_Plc_11_00,
                    Horse_Back_Plc_11_50,
                    Horse_Back_Plc_12_00,
                    Horse_Back_Plc_12_50,
                    Horse_Back_Plc_13_00,
                    Horse_Back_Plc_13_50,
                    Horse_Back_Plc_14_00,
                    Horse_Back_Plc_14_50,
                    Horse_Back_Plc_15_00,
                    Horse_Back_Plc_15_50,
                    Horse_Back_Plc_16_00,
                    Horse_Back_Plc_16_50,
                    Horse_Back_Plc_17_00,
                    Horse_Back_Plc_17_50,
                    Horse_Back_Plc_18_00,
                    Horse_Back_Plc_18_50,
                    Horse_Back_Plc_19_00,
                    Horse_Back_Plc_19_50,
                    Horse_Back_Plc_20_00,
                    Horse_Back_Plc_21_00,
                    Horse_Back_Plc_22_00,
                    Horse_Back_Plc_23_00,
                    Horse_Back_Plc_24_00
                   );


  type Allowed_Days_Array is array(Calendar2.Week_Day_Type'Range) of Boolean;

  type Bet_Config_Type is tagged record
    Size                       : Bet_Size_Type    := 30.0;
    Max_Loss_Per_Day           : Fixed_Type       := -200.0;
    Max_Earnings_Per_Day       : Fixed_Type       :=  200.0;
    Min_Price                  : Unbounded_String := Null_Unbounded_String;
    Enabled                    : Boolean          := False;
  end record;

  type Bet_Config_Array_Type is array(Bet_Type'Range) of Bet_Config_Type;

  type Config_Type is tagged record
    --Size                       : Bet_Size_Type    := 30.0;
    Max_Exposure               : Fixed_Type          := 0.0;
    Max_Turns_Not_Started_Race : Integer_4           := 102;  --102*5s -> 8,5 min
    Enabled                    : Boolean             := False;
    Allowed_Countries          : Unbounded_String    := Null_Unbounded_String;
    Allowed_Days               : Allowed_Days_Array  := (others => False);
    Bet                        : Bet_Config_Array_Type;
  end record;

  function Create(Filename : String) return Config_Type;
  function Country_Is_Ok (Cfg : Config_Type; Country_Code : String) return Boolean;
  function To_String(Cfg : Config_Type) return String ;

  procedure Print_Strategies;

end Config;
