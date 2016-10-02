with Table_Abets;
with Types; use Types;
with Bot_Types; use Bot_Types;
with Calendar2;
with Ada.Containers.Doubly_Linked_Lists;
with Runners;
with Markets;
with Sql;
package Bets is
  function Profit_Today(Bet_Name : Betname_Type) return Float_8 ;
  function Exists(Bet_Name : Betname_Type; Market_Id : Marketid_Type) return Boolean;

  Commission : constant Float_8 := 6.5/100.0;

  type Bet_Type is new Table_Abets.Data_Type with null record;
  
  function Create(Name : Betname_Type;
                  Side : Bet_Side_Type;
                  Size : Bet_Size_Type;
                  Price : Price_Type;
                  Placed : Calendar2.Time_Type;
                  The_Runner : Runners.Runner_Type;
                  The_Market : Markets.Market_Type) return Bet_Type;

  procedure Check_Matched(Self : in out Bet_Type);
  procedure Check_Outcome(Self : in out Bet_Type);
  procedure Clear(Self : in out Bet_Type);

  procedure Match_Directly(Self : in out Bet_Type; Value : Boolean );
  function  Match_Directly(Self : in out Bet_Type) return Boolean;
  
  
  function Empty_Data return Bet_Type;
  package List_Pack is new Ada.Containers.Doubly_Linked_Lists(Bet_Type);

  function Is_Existing_I7(Betname : in String) return Boolean renames Table_Abets.Is_Existing_I7;
  procedure Read_List(Stm  : in     Sql.Statement_Type;
                      List : in out List_Pack.List;
                      Max  : in     Integer_4 := Integer_4'Last) ;
  

end Bets;
