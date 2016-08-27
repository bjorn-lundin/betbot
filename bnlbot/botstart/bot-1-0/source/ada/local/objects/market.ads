with Ada.Containers.Doubly_Linked_Lists;
with Sql;
with Table_Amarkets;
with Types; use Types;

--with Bot_Types; use Bot_Types;
package Market is
  type Market_Type is new Table_Amarkets.Data_Type with null record;
  function Empty_Data return Market_Type ;

  package List_Pack is new Ada.Containers.Doubly_Linked_Lists(Market_Type);

  procedure Read_List(Stm  : in     Sql.Statement_Type;
                      List : in out List_Pack.List;
                      Max  : in     Integer_4 := Integer_4'Last);


  
end Market;
