with Bot_Types     ; use Bot_Types;
with Types; use Types;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Calendar2;

package Config is

  type Bet_Type is (
                    HORSE_BACK_03_04_04_08_14_WIN_500_800, -- Several Bets In This Type
                    HORSE_BACK_04_04_04_08_14_WIN_500_900, -- Several Bets In This Type
                    HORSE_BACK_05_04_04_09_15_WIN_500_900, -- Several Bets In This Type
                    HORSE_BACK_06_04_04_08_14_WIN_600_900, -- Several Bets In This Type
                    HORSE_Back_1_11_1_15_05_07_1_2_Plc_1_01,
                    HORSE_Back_1_10_07_1_2_Plc_1_01,
                    HORSE_Back_1_10_10_1_2_Plc_1_01,
                    HOUND_LAY_01_03_04_06_08_WIN_999_999,
                    HOUND_LAY_01_06_04_07_09_WIN_999_999,
                    HOUND_LAY_02_01_01_02_04_WIN_999_999,
                    HOUND_LAY_03_04_06_07_09_WIN_999_999                    
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
