with Bot_Types     ; use Bot_Types;
with Types; use Types;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Calendar2;

package Config is

  type Bet_Type is (
      Back_1_10_07_1_2_PLC,
      Back_1_50_30_1_4_PLC,
      --Back_1_50_30_1_2_WIN, 
      --Back_1_50_20_1_2_WIN, 
      --Back_1_50_16_1_2_WIN, Back_1_50_13_1_2_WIN, 
      --Back_1_50_10_1_2_WIN, Back_1_50_07_1_2_WIN, 
      --Back_1_40_16_1_2_WIN, Back_1_40_13_1_2_WIN, 
      --Back_1_40_10_1_2_WIN, Back_1_40_07_1_2_WIN, 
      --Back_1_30_16_1_2_WIN, Back_1_30_13_1_2_WIN, 
      --Back_1_30_10_1_2_WIN, 
      --Back_1_30_07_1_2_WIN, 
      Back_1_30_40_1_2_WIN, 
      Back_1_30_30_1_2_WIN, 
      Back_1_20_30_1_2_WIN, 
      Back_1_20_26_1_2_WIN, 
      Back_1_20_23_1_2_WIN, 
      Back_1_20_20_1_2_WIN, 
      Back_1_20_16_1_2_WIN, 
      Back_1_20_13_1_2_WIN, 
      Back_1_20_10_1_2_WIN, 
      Back_1_20_07_1_2_WIN, 
      Back_1_10_30_1_2_WIN, 
      Back_1_10_26_1_2_WIN, 
      Back_1_10_23_1_2_WIN, 
      Back_1_10_20_1_2_WIN, 
      Back_1_10_16_1_2_WIN, 
      Back_1_10_13_1_2_WIN, 
      Back_1_10_10_1_2_WIN, 
      Back_1_10_07_1_2_WIN, 
      Lay_160_200,
      Lay_1_10_25_4 
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
