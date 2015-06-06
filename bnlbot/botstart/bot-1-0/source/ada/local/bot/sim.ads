
with Types; use Types;
with Bot_Types; use Bot_Types;
with Table_Amarkets;
with Table_Aprices;
with Table_Abets;
with Table_Apricesfinish;

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


  procedure Filter_List(Price_List, Avg_Price_List : in out Table_Aprices.Aprices_List_Pack2.List);


  subtype Num_Runners_Type is Integer range 1..36;
  type Fifo_Type is tagged record
    Selectionid    : Integer_4 := 0;
    One_Runner_Sample_List : Table_Aprices.Aprices_List_Pack2.List;
    Avg_Lay_Price  : Float_8 := 0.0;
    Avg_Back_Price : Float_8 := 0.0;
    In_Use         : Boolean := False;
    Index          : Num_Runners_Type := Num_Runners_Type'first;
  end record;
  procedure Clear(F : in out Fifo_Type);

  Fifo : array (Num_Runners_Type'range) of Fifo_Type;



  procedure Read_Marketid(Marketid : in     Market_Id_Type;
                          List      :    out Table_Apricesfinish.Apricesfinish_List_Pack2.List) ;

  procedure Create_Runner_Data(Price_List : in Table_Aprices.Aprices_List_Pack2.List;
                               Is_Average : in Boolean) ;


end Sim ;
