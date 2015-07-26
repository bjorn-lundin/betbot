
with Types; use Types;
with Bot_Types; use Bot_Types;
with Table_Amarkets;
with Table_Aprices;
with Table_Abets;
with Table_Apriceshistory;
with Calendar2;
with Ada.Containers.Hashed_Maps;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Strings;
with Ada.Strings.Hash;
--with Ada.Strings.Fixed; use Ada.Strings.Fixed;

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
                       Bet_Placed       : in     Calendar2.Time_Type := Calendar2.Time_Type_First;
                       Bet              :    out Table_Abets.Data_Type);

  type Algorithm_Type is (None, Avg);
  procedure Filter_List(Price_List, Avg_Price_List : in out Table_Aprices.Aprices_List_Pack2.List; Alg : Algorithm_Type := None);


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



  procedure Read_Marketid(Marketid : in      Market_Id_Type;
                          List      :    out Table_Apriceshistory.Apriceshistory_List_Pack2.List) ;

  procedure Create_Runner_Data(Price_List : in Table_Aprices.Aprices_List_Pack2.List;
                               Alg        : in Algorithm_Type;
                               Is_Winner  : in Boolean;
                               Is_Place   : in Boolean ) ;

  procedure Create_Bet_Data(Bet : in Table_Abets.Data_Type ) ;
                               
  function Get_Win_Market(Place_Market_Id : Market_Id_Type) return Table_Amarkets.Data_Type ;

  -- for lay_during_race2 start
  

  package Market_Id_With_Data_Pack is new Ada.Containers.Doubly_Linked_Lists(Market_Id_Type);
  procedure Read_All_Markets(List : out Market_Id_With_Data_Pack.List) ;
                                      
  package Timestamp_Pack is new Ada.Containers.Doubly_Linked_Lists(Calendar2.Time_Type, Calendar2."=");
                                      
  package Marketid_Pricets_Maps is new Ada.Containers.Hashed_Maps
        (Market_Id_Type,
         Timestamp_Pack.List,
         Ada.Strings.Hash,
         "=",
         Timestamp_Pack."=");

  procedure Fill_Marketid_Pricets_Map(Market_Id_With_Data_List   : in     Market_Id_With_Data_Pack.List;
                                      Marketid_Pricets_Map       :    out Marketid_Pricets_Maps.Map);


  
  package Marketid_Winner_Maps is new Ada.Containers.Hashed_Maps
        (Market_Id_Type,
         Integer_4,
         Ada.Strings.Hash,
         "=",
         "=");

  procedure Fill_Winners_Map(Market_Id_With_Data_List         : in     Market_Id_With_Data_Pack.List;
                             Winners_Map                      :    out Marketid_Winner_Maps.Map );

         
  -- for lay_during_race2 stop


  -- for timestamp slices start
  
  --'2015-04-12 16:41:25.500'
  subtype Timestamp_String_Key_Type is String(1..23);
  
  package Timestamp_To_Apriceshistory_Maps is new Ada.Containers.Hashed_Maps (
         Timestamp_String_Key_Type,
         Table_Apriceshistory.Apriceshistory_List_Pack2.List,
         Ada.Strings.Hash,
         "=",
         Table_Apriceshistory.Apriceshistory_List_Pack2."=");
         
  package Marketid_Timestamp_To_Apriceshistory_Maps is new Ada.Containers.Hashed_Maps
        (Market_Id_Type,
         Timestamp_To_Apriceshistory_Maps.Map,
         Ada.Strings.Hash,
         "=",
         Timestamp_To_Apriceshistory_Maps."=");

         
  procedure Fill_Marketid_Runners_Pricets_Map(Market_Id_With_Data_List        : in     Market_Id_With_Data_Pack.List;
                                              Marketid_Pricets_Map            : in     Marketid_Pricets_Maps.Map;
                                              Marketid_Timestamp_To_Apriceshistory_Map :    out Marketid_Timestamp_To_Apriceshistory_Maps.Map) ;
  
  -- for timestamp slices stop
  
  
  

  
end Sim ;
