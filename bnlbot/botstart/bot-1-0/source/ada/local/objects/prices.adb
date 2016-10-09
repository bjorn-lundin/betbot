

package body Prices is
  function Empty_Data return Price_Type is
    ED : Price_Type;
  begin
    return ED;
  end Empty_Data;
  ---------------------------------
 procedure Read_List(Stm  : in     Sql.Statement_Type;
                      List : in out Lists.List;
                      Max  : in     Integer_4 := Integer_4'Last) is
    AP_List :Table_Aprices.Aprices_List_Pack2.List;
    P : Price_Type;
  begin
    Table_Aprices.Read_List(Stm,AP_List,Max);
    for i of AP_List loop
      P := (
        Marketid         => i.Marketid,
        Selectionid      => i.Selectionid,
        Pricets          => i.Pricets,
        Totalmatched     => i.Totalmatched,
        Backprice        => i.Backprice,
        Status           => i.Status,
        Layprice         => i.Layprice,
        Ixxlupd          => i.Ixxlupd,
        Ixxluts          => i.Ixxluts
      );
      List.Append(P);
    end loop;
  end Read_List;
  ----------------------------------------

  procedure Read_I1_Marketid(
                           Data  : in     Table_Aprices.Data_Type'class;
                           List  : in out Lists.List;
                           Order : in     Boolean := False;
                           Max   : in     Integer_4 := Integer_4'Last) is

    AP_List :Table_Aprices.Aprices_List_Pack2.List;
    P : Price_Type;
  begin
    Table_Aprices.Read_I1_Marketid(Data, AP_List, Order, Max);
    for i of AP_List loop
      P := (
        Marketid         => i.Marketid,
        Selectionid      => i.Selectionid,
        Pricets          => i.Pricets,
        Totalmatched     => i.Totalmatched,
        Backprice        => i.Backprice,
        Status           => i.Status,
        Layprice         => i.Layprice,
        Ixxlupd          => i.Ixxlupd,
        Ixxluts          => i.Ixxluts
      );
      List.Append(P);
    end loop;
  end Read_I1_Marketid;


end Prices;
