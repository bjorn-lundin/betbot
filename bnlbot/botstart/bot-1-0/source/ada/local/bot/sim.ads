
with Types; use Types;
with Bot_Types; use Bot_Types;
with Table_Amarkets;
with Table_Aprices;
with Table_Abets;

package Sim is

  procedure Get_Market_Prices(Market_Id  : in     Market_Id_Type; 
                              Market     : in out Table_Amarkets.Data_Type;
                              Price_List : in out Table_Aprices.Aprices_List_Pack2.List;
                              In_Play    :    out Boolean);

                              
  procedure Place_Bet (Bet_Name         : in     Bet_Name_Type;
                       Market_Id        : in     Market_Id_Type; 
                       Side             : in     Bet_Side_Type;
                       Runner_Name      : in     Runner_Name_Type;
                       Selection_Id     : in     Integer_4;
                       Size             : in     Bet_Size_Type;
                       Price            : in     Bet_Price_Type;
                       Bet_Persistence  : in     Bet_Persistence_Type;
                       Bet              :    out Table_Abets.Data_Type);
                            

end Sim ;
