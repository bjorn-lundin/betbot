with Bot_Types     ; use Bot_Types;
with Types; use Types;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Calendar2;

package Config is

  type Bet_Type is (
                    Horse_Back_1_10_07_1_2_Plc_1_01,
                    Horse_Back_1_28_02_1_2_Plc_1_01,
                    Horse_Back_1_38_00_1_2_Plc_1_01,
                    Horse_Back_1_56_00_1_4_Plc_1_01 --,
--                      Horse_Back_1_10_07_1_2_Plc_1_01_Chs,
--                      Horse_Back_1_28_02_1_2_Plc_1_01_Chs,
--                      Horse_Back_1_38_00_1_2_Plc_1_01_Chs,
--                      Horse_Back_1_56_00_1_4_Plc_1_01_Chs
--                      Horse_Back_1_10_07_1_2_Plc_1_01_Hrd,
--                      Horse_Back_1_28_02_1_2_Plc_1_01_Hrd,
--                      Horse_Back_1_38_00_1_2_Plc_1_01_Hrd,
--                      Horse_Back_1_56_00_1_4_Plc_1_01_Hrd
                   );


  type Allowed_Days_Array is array(Calendar2.Week_Day_Type'Range) of Boolean;

  type Bet_Config_Type is tagged record
    Size                       : Bet_Size_Type    := 30.0;
    Max_Loss_Per_Day           : Fixed_Type       := -200.0;
    Max_Earnings_Per_Day       : Fixed_Type       := 999_999.0;
    Min_Price                  : Unbounded_String := Null_Unbounded_String;
    Enabled                    : Boolean          := False;
    Chase_Allowed              : Boolean          := False;
    Hurdle_Allowed             : Boolean          := False;
    Allowed_Days               : Allowed_Days_Array  := (others => False);
  end record;

  type Bet_Config_Array_Type is array(Bet_Type'Range) of Bet_Config_Type;

  type Config_Type is tagged record
    --Size                       : Bet_Size_Type    := 30.0;
    Max_Exposure               : Fixed_Type          := 0.0;
    Max_Turns_Not_Started_Race : Integer_4           := 800;  --*5s ->  66 min
    Enabled                    : Boolean             := False;
    Allowed_Countries          : Unbounded_String    := Null_Unbounded_String;
    Allowed_Days               : Allowed_Days_Array  := (others => False);
    Bet                        : Bet_Config_Array_Type;
    Max_Total_Loss_Per_Day     : Fixed_Type          := -800.0;
  end record;

  function Create(Filename : String) return Config_Type;
  function Country_Is_Ok (Cfg : Config_Type; Country_Code : String) return Boolean;
  function To_String(Cfg : Config_Type) return String ;

  procedure Print_Strategies;

end Config;
