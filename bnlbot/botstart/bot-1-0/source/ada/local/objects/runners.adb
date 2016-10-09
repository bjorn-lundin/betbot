
package body Runners is

  function Empty_Data return Runner_Type is
    ED : Runner_Type;
  begin
    return ED;
  end Empty_Data;
  -----------------------------------------
  procedure Read_List(Stm  : in     Sql.Statement_Type;
                      List : in out Lists.List;
                      Max  : in     Integer_4 := Integer_4'Last) is
    R_List :Table_Arunners.Arunners_List_Pack2.List;
    R : Runner_Type;
  begin
    Table_Arunners.Read_List(Stm, R_List, Max);  
    for i of R_List loop
      R := (
          Marketid           => i.Marketid,
          Selectionid        => i.Selectionid,
          Sortprio           => I.Sortprio,  
          Status             => i.Status,
          Handicap           => i.Handicap,
          Runnername         => i.Runnername,
          Runnernamestripped => i.Runnernamestripped,
          Runnernamenum      => i.Runnernamenum,
          Ixxlupd            => i.Ixxlupd,
          Ixxluts            => i.Ixxluts
      );             
      List.Append(R);
    end loop;
  end Read_List;  
  ----------------------------------------

  
end Runners;
