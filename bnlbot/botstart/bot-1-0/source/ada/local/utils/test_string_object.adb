
with Text_Io; use Text_io;
with Types; use Types;

procedure Test_String_Object is

  Tmp : String_Object;
begin

  Tmp.Set("1234_!#_!%&/()=?#_56_ABCDEF_ghij_klMN_OPQ");

  Tmp.Put_Line(Fix);
  Tmp.Put_Line(Upper);
  Tmp.Put_Line(Lower);
  Tmp.Put_Line(Camel);
  
  Put_Line("Delete_Last_Char");
  Tmp.Delete_Last_Char;
  
  
  Tmp.Put_Line(Fix);
  Tmp.Put_Line(Upper);
  Tmp.Put_Line(Lower);
  Tmp.Put_Line(Camel);
  
  
  
end Test_String_Object;
