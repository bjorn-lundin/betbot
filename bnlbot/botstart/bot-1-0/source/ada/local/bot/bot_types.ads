
with Sattmate_Types; use Sattmate_Types;
with Unchecked_Conversion;
--with Ada.Strings.Unbounded ; use Ada.Strings.Unbounded ; 

with Table_Amarkets;
with Table_Arunners;
with Table_Abets;
with Table_Aevents;

package Bot_Types is

--   subtype Bot_Name_Type is Unbounded_String;
--   subtype Bot_Log_File_Name_Type is Unbounded_String;
   type Bet_Market_Type is (Place, 
                            Winner, 
                            Match_Odds, 
                            Correct_Score, 
                            Half_Time_Score, 
                            Hat_Tricked_Scored, 
                            Penalty_Taken,
                            Sending_Off);
   type Bet_Side_Type is (Back, Lay);
   type Bet_Type_Type is (Greenup, Back, Lay); 
   
   type Animal_Type is (Horse, Hound, Human);
   type Max_Daily_Profit_Type is new Float_8;
   type Max_Daily_Loss_Type is new Float_8;
   type Max_Lay_Price_Type is new Float_8;
   type Min_Lay_Price_Type is new Float_8;
   type Back_Price_Type is new Float_8;
   type Delta_Price_Type is new Float_8;
   type Bet_Size_Type is new Float_8;
   type Bet_Price_Type is new Float_8;
   type Min_Num_Runners_Type is new Byte;
   type Max_Num_Runners_Type is new Byte;   
   type Num_Winners_Type is new Byte;
   type Favorite_By_Type is new Float_8;
   type Profit_Type is new Float_8;
   type Max_Exposure_Type is new Float_8;
   
   type Bet_Persistence_Type is (Lapse, Persist, Market_On_Close);
   
   type Bot_Mode_Type is (Real, Simulation);
   for Bot_Mode_Type'Size use Integer_4'Size;
   for Bot_Mode_Type use ( Real => 2, Simulation => 3);
   function Bot_Mode is new Unchecked_Conversion(Bot_Mode_Type, Integer_4);
   function Bot_Mode is new Unchecked_Conversion(Integer_4, Bot_Mode_Type);
     
   type Bet_Status_Type is (Executable, Execution_Complete, Voided, Cancelled, Lapsed, Settled);
   subtype Cleared_Bet_Status_Type is Bet_Status_Type range  Voided .. Settled ;
   
   type JSON_Data_Type is (I4,Flt,Ts,Str);
      
   type Green_Up_Mode_Type is (None, Lay_First_Then_Back, Back_First_Then_Lay);
   
   subtype Market_Id_Type       is String(Table_Amarkets.Empty_Data.Marketid'range);
   subtype Event_Name_Type      is String(Table_AEvents.Empty_Data.Eventname'range);
   subtype Runner_Name_Type     is String(Table_Arunners.Empty_Data.Runnername'range);
   subtype Status_Type          is String(Table_Arunners.Empty_Data.Status'range);
   subtype Bet_Name_Type        is String(Table_Abets.Empty_Data.Betname'range);
   subtype Bet_Side_String_Type is String(Table_Abets.Empty_Data.Side'range);
  
   function "-" (Left : Back_Price_Type ; Right : Delta_Price_Type) return Back_Price_Type;
   function "+" (Left : Back_Price_Type ; Right : Delta_Price_Type) return Back_Price_Type;
   function "+" (Left : Back_Price_Type ; Right : Favorite_By_Type) return Back_Price_Type;
   function "+" (Left : Float_8 ; Right : Favorite_By_Type) return Back_Price_Type ;
   function "+" (Left : Float_8 ; Right : Favorite_By_Type) return Float_8;
   function "<=" (Left : Back_Price_Type ; Right : Float_8) return Boolean;
   function "<=" (Left : Float_8 ; Right : Back_Price_Type) return Boolean ;
   function "<" (Left : Min_Lay_Price_Type ; Right : Float_8) return Boolean;
   function "<=" (Left : Min_Lay_Price_Type ; Right : Float_8) return Boolean;
   function "<=" (Left : Float_8 ; Right : Max_Lay_Price_Type) return Boolean ;
   
   function "*" (Left : Bet_Size_Type ; Right : Back_Price_Type) return Float_8;
   
   function ">=" (Left : Profit_Type ; Right : Max_Daily_Profit_Type) return Boolean ;
   function ">=" (Left : Profit_Type ; Right : Max_Daily_Loss_Type) return Boolean ;
   function "<" (Left : Profit_Type ; Right : Max_Daily_Loss_Type) return Boolean ;

   function "<" (Left : Integer ; Right : Min_Num_Runners_Type) return Boolean ;
   function ">" (Left : Integer ; Right : Max_Num_Runners_Type) return Boolean ;

   function "=" (Left : Integer_4 ; Right : Num_Winners_Type) return Boolean ;

   function "-" (Left : Bet_Price_Type ; Right : Delta_Price_Type) return Bet_Price_Type;
   function "+" (Left : Bet_Price_Type ; Right : Delta_Price_Type) return Bet_Price_Type;
   function "*" (Left : Bet_Size_Type ; Right : Bet_Price_Type) return Bet_Size_Type;
   function "/" (Left : Bet_Size_Type ; Right : Bet_Price_Type) return Bet_Size_Type;

   function ">" (Left : Float_8 ; Right : Max_Exposure_Type) return Boolean ; 
end Bot_Types;
