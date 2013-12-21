with Ada.Finalization; 
with Sattmate_Types; use Sattmate_Types;
with Bot_Types ; use Bot_Types;

with Bot_Messages;
with Table_Aevents;
with Table_Amarkets;
with Table_Aprices;
with Table_Arunners;
with Bot_Config;

package Bet_Handler is
  Bad_Data,
  No_Data : exception;


  procedure Treat_Market(Market_Notification : in     Bot_Messages.Market_Notification_Record) ;

  procedure Check_Bets;
  procedure Test_Bet; 
  procedure Check_If_Bet_Accepted;
  procedure Check_Market_Status ;
  procedure Check_Unsettled_Markets(Inserted_Winner : in out Boolean) ;
  
private

  type Runners_Record_Type is record
    Runner : Table_Arunners.Data_Type;
    Price  : Table_Aprices.Data_Type;
  end record;
  type Runners_Array_Type is array(1 .. 50) of Runners_Record_Type;
  
  type Bet_Info_Record is new Ada.Finalization.Controlled with record
    Event        : Table_Aevents.Data_Type;    
    Market       : Table_Amarkets.Data_Type;    
    Runner_Array : Runners_Array_Type;
    Last_Runner  : Integer := 0;
    Used_Index   : Integer := 0;    
    Selection_Id : Integer_4 := 0;
  end record;
  function Create (Market_Notification : in Bot_Messages.Market_Notification_Record) return Bet_Info_Record;
  overriding procedure Finalize (Bet_Info : in out Bet_Info_Record) ;
  procedure Try_Make_New_Bet (Bet_Info : in out Bet_Info_Record; 
                              Bot_Cfg  : in out Bot_Config.Bet_Section_Type) ;

  ------------------------------------------------------------------------------------

  
  type Bet_Type is new Ada.Finalization.Controlled with record
     Bet_Info      : Bet_Info_Record;
     Bot_Cfg       : Bot_Config.Bet_Section_Type;
  end record;
  
  function Create (Bet_Info : Bet_Info_Record'Class; Bot_Cfg : Bot_Config.Bet_Section_Type) return Bet_Type;
  procedure Check_Conditions_Fulfilled(Bet : in out Bet_Type; Result : in out Boolean) ;

  procedure Do_Try(Bet       : in out Bet_Type) ;
                 
--  function To_String(Bet : Bet_Type) return String;
  function Enabled(Bet : Bet_Type) return Boolean;

  
  
  procedure Make_Bet(Bet           : in out Bet_Type;
                     Betmode       : in     Bet_Mode_Type; 
                     A_Bet_Type    : in     Bet_Type_Type;
                     Price         : in     Bet_Price_Type;
                     Size          : in     Bet_Size_Type;
                     Price_Matched :    out Bet_Price_Type;
                     Size_Matched  :    out Bet_Size_Type ) ;

                     
  function Exists          (Bet : Bet_Type) return Boolean;
  function Profit_Today    (Bet : Bet_Type) return Profit_Type;
  function Num_Losses_Today(Bet : Bet_Type) return Integer_4;
  function Num_In_The_Air  (Bet : Bet_Type) return Integer_4;
  
  
  ---------------------------------------------------------------------------------
  type Pip_Type is tagged record
     Wanted_Price  : Float_8 := 0.0;
     Pip_Price     : Float_8 := 0.0;
     Lower_Index   : Integer := 0;
     Upper_Index   : Integer := 0;
     This_Index    : Integer := 0;
  end record;
  procedure Init(Pip : in out Pip_Type; Price : Float_8) ;
  function Next_Price(Pip : Pip_Type) return Float_8;
  function Previous_Price(Pip : Pip_Type) return Float_8;
  
end Bet_Handler;


