with Table_Arunners;
with Ada.Containers.Doubly_Linked_Lists;
with Sql;
with Types; use Types;
--with Bot_Types; use Bot_Types;

package Runners is
  type Runner_Type is new Table_Arunners.Data_Type with null record;
  function Empty_Data return Runner_Type ;


  package Lists is new Ada.Containers.Doubly_Linked_Lists(Runner_Type);

  procedure Read_List(Stm  : in     Sql.Statement_Type;
                      List : in out Lists.List;
                      Max  : in     Integer_4 := Integer_4'Last) ;




end Runners;
