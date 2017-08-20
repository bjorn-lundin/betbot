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
                    --Horse_Greenup_Lay_Back_Win_15_00_19_50,
                    --Horse_Greenup_Lay_Back_Win_20_00_29_00,
                    --Horse_Greenup_Lay_Back_Win_30_00_38_00,
                    --Horse_Greenup_Lay_Back_Win_40_00_48_00
                    Horse_Lay_Win_17_00_019_50,
                    Horse_Lay_Win_20_00_029_00,
                    Horse_Lay_Win_30_00_038_00,
                    Horse_Lay_Win_40_00_048_00,
                    Horse_Lay_Win_48_00_060_00,
                    Horse_Lay_Win_85_00_100_00
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
