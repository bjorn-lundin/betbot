with Ada.Containers.Doubly_Linked_Lists;
with Sql;
with Table_Amarkets;
with Types; use Types;

--with Bot_Types; use Bot_Types;
package Markets is
  type Market_Type is new Table_Amarkets.Data_Type with null record;
  function Empty_Data return Market_Type ;

  procedure Corresponding_Place_Market(Self         : in out Market_Type;
                                       Place_Market :    out Market_Type;
                                       Found        :    out Boolean);

  package Lists is new Ada.Containers.Doubly_Linked_Lists(Market_Type);

  procedure Read_Eventid(  Data  : in out Market_Type'Class;
                           List  : in out Lists.List;
                           Order : in     Boolean := False;
                           Max   : in     Integer_4 := Integer_4'Last);


  procedure Read_List(Stm  : in     Sql.Statement_Type;
                      List : in out Lists.List;
                      Max  : in     Integer_4 := Integer_4'Last);


  procedure Check_Market_Status ;
  procedure Check_Unsettled_Markets(Inserted_Winner : in out Boolean) ;






end Markets;
