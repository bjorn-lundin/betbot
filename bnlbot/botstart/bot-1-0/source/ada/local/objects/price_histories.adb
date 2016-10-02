package body Price_Histories is

  function Empty_Data return Price_History_Type is
    ED : Price_History_Type;
  begin
    return ED;
  end Empty_Data;

  ----------------------------------------

  procedure Read_List(Stm  : in     Sql.Statement_Type;
                      List : in out List_Pack.List;
                      Max  : in     Integer_4 := Integer_4'Last) is
    PH_List :Table_Apriceshistory.Apriceshistory_List_Pack2.List;
    PH : Price_History_Type;
  begin
    Table_Apriceshistory.Read_List(Stm, PH_List, Max);  
    for i of PH_List loop
      PH := (
          Marketid     => i.Marketid,
          Selectionid  => i.Selectionid,
          Pricets      => i.Pricets,
          Status       => i.Status,
          Totalmatched => i.Totalmatched,
          Backprice    => i.Backprice,
          Layprice     => i.Layprice,
          Ixxlupd      => i.Ixxlupd,
          Ixxluts      => i.Ixxluts
      );        
      List.Append(PH);
    end loop;
  end Read_List;  
  ----------------------------------------
end Price_Histories;
