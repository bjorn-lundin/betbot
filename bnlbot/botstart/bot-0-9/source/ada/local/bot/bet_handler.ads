with Ada.Finalization; 

with Bot_Messages;

with Table_Aevents;
with Table_Amarkets;
with Table_Aprices;
with Table_Arunners;
with Bot_Config;


package Bet_Handler is
  Bad_Data,
  No_Data : exception;


  procedure Treat_Market(Market_Notification : in Bot_Messages.Market_Notification_Record) ;


  
private

  type Bet_Info_Record is new Ada.Finalization.Controlled with record
    Event       : Table_Aevents.Data_Type;    
    Market      : Table_Amarkets.Data_Type;    
    Runner_List : Table_Arunners.Arunners_List_Pack.List_Type;
    Price_List  : Table_Aprices.Aprices_List_Pack.List_Type;
  end record;
  function Create (Market_Notification : in Bot_Messages.Market_Notification_Record) return Bet_Info_Record;
  overriding procedure Finalize (Bet_Info : in out Bet_Info_Record) ;
  procedure Try_Make_New_Bet (Bet_Info : in out Bet_Info_Record; Bot_Cfg : in out Bot_Config.Bet_Section_Type) ;

  ------------------------------------------------------------------------------------
  type Bet_Type is new Ada.Finalization.Controlled with record
     Bet_Info      : Bet_Info_Record;
     Bot_Cfg       : Bot_Config.Bet_Section_Type;
     This_Bet_Type : Bet_Type_Type; 
  end record;
  
  function Create (Bet_Info : Bet_Info_Record; Bot_Cfg : Bot_Config.Bet_Section_Type) return Bet_Type;
  function Conditions_Fulfilled(Bet : Bet_Type) return Boolean;
  function History_Ok(Bet : Bet_Type) return Boolean;
  function To_String(Bet : Bet_Type) return String;
  function Enabled(Bet : Bet_Type) return Boolean;
  procedure Make_Dry_Bet(Bet : in out Bet_Type) ;
  procedure Make_Real_Bet(Bet : in out Bet_Type) ;
  
  
end Bet_Handler;


