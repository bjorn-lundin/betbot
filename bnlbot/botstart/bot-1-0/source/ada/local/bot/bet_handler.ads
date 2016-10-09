


package Bet_Handler is
  Bad_Data,
  No_Data : exception;


  procedure Check_Bets;
  procedure Check_If_Bet_Accepted;
  procedure Check_Market_Status ;
  procedure Check_Unsettled_Markets(Inserted_Winner : in out Boolean) ;
  
    
end Bet_Handler;
