with Table_Arunners;
with Ada.Containers.Doubly_Linked_Lists;

--with Types; use Types;
--with Bot_Types; use Bot_Types;

package Runners is
  type Runner_Type is new Table_Arunners.Data_Type with null record;
  function Empty_Data return Runner_Type ;

  package List_Pack is new Ada.Containers.Doubly_Linked_Lists(Runner_Type);
  
end Runners;
