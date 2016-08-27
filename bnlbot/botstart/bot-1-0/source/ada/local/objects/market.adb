package body Market is

  function Empty_Data return Market_Type is
    ED : Market_Type;
  begin
    return ED;
  end Empty_Data;

  ----------------------------------------
  
  procedure Read_List(Stm  : in     Sql.Statement_Type;
                      List : in out List_Pack.List;
                      Max  : in     Integer_4 := Integer_4'Last) is
    AM_List :Table_Amarkets.Amarkets_List_Pack2.List;
    M : Market_Type;
  begin
    Table_Amarkets.Read_List(Stm,AM_List,Max);  
    for i of AM_List loop
      M := (
        Marketid         => i.Marketid,
        Marketname       => i.Marketname,
        Startts          => i.Startts,
        Eventid          => i.Eventid,
        Markettype       => i.Markettype,
        Status           => i.Status,
        Betdelay         => i.Betdelay,
        Numwinners       => i.Numwinners,
        Numrunners       => i.Numrunners,
        Numactiverunners => i.Numactiverunners,
        Totalmatched     => i.Totalmatched,
        Totalavailable   => i.Totalavailable,
        Ixxlupd          => i.Ixxlupd,
        Ixxluts          => i.Ixxluts           
      );
      List.Append(M);
    end loop;
  end Read_List;  
  ----------------------------------------
    
end Market;
