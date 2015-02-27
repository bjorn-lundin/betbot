with Bot_Types     ; use Bot_Types;
with Types; use Types;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Calendar2;

package Config is
  type Allowed_Days_Array is array(Calendar2.Week_Day_Type'range) of Boolean;

  type Config_Type is tagged record
    Size                       : Bet_Size_Type    := 30.0;
    Max_Loss_Per_Day           : Float_8          := -500.0;
    Fav_Max_Price              : Back_Price_Type  := 1.10;
    Second_Fav_Min_Price       : Back_Price_Type  := 7.0; 
    Max_Turns_Not_Started_Race : Integer_4        := 17;  --17*30s -> 8.5 min
    Enabled                    : Boolean          := False;
    Allowed_Countries          : Unbounded_String := Null_Unbounded_String;
    Allowed_Days               : Allowed_Days_Array     := (others => False);
    Allow_Lay_During_Race      : Boolean          := False;
  end record;  
  
  function Create(Filename : String) return Config_Type;
  function Country_Is_Ok (Cfg : Config_Type; Country_Code : String) return Boolean;
  function To_String(Cfg : Config_Type) return String ;

end Config;
