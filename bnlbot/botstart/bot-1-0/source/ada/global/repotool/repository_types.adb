with Ada.Characters.Handling;
with Ada.Strings.Fixed;     use Ada.Strings.Fixed;




package body Repository_Types is

  function Do_Camel_Case(LC_String : String) return String is
  -- will Not remove underscores, and make Capital letter of next, all
  -- others small : eg COMLI_MASTER_SLAVE -> comliMasterSlave
  -- letter after digits are capitalized: eg SIEMENS_3964R -> siemens3964R
    Tmp             : String   := LC_String;
    Capitalize_Next : Boolean  := True;
    use Ada.Characters.Handling;
  begin
    for i in Tmp'range loop
      case Tmp(i) is 
        when '_'    => 
          Capitalize_Next := True;
        when others => 
          if Is_Digit(Tmp(i)) then
            Capitalize_Next := True;
          elsif Capitalize_Next then
            Tmp(i) := To_Upper(Tmp(i));
            Capitalize_Next := False;
          end if;
      end case;
    end loop;
    return Tmp;
  end Do_Camel_Case;
  -----------------------------------------------------------
  
  function Create(What : String) return String_Object is
    Tmp : String_Object;
  begin
    Tmp.Set(What);
    return Tmp;
  end Create;
  
  procedure Set(Self : in out String_Object; What : String) is
  begin
    Self.Value := To_Unbounded_String(What);
    Self.Lower_Case_Cache := To_Unbounded_String(Ada.Characters.Handling.To_Lower(What));
    Self.Upper_Case_Cache := To_Unbounded_String(Ada.Characters.Handling.To_Upper(What));
    Self.Camel_Case_Cache := To_Unbounded_String(Do_Camel_Case(Ada.Characters.Handling.To_Lower(What)));
  end Set;
  -----------------------------------------------------------
  procedure Reset(Self : in out String_Object) is
  begin
    Self.Value := Null_Unbounded_String;
  end Reset;
  -----------------------------------------------------------
  function Fix_String(Self : String_Object) return String is
  begin -- return the right trimmed string
    return Trim(To_String(Self.Value), Right);    
  end Fix_String;
  -----------------------------------------------------------
  function UBString(Self : String_Object) return Unbounded_String is
  begin 
    return Self.Value;
  end UBString;
  -----------------------------------------------------------
  function Lower_Case( Self : String_Object) return String is
  begin 
    return Trim(To_String(Self.Lower_Case_Cache), Right); 
  end Lower_Case;
  -----------------------------------------------------------
  function Upper_Case( Self : String_Object) return String is
  begin 
    return Trim(To_String(Self.Upper_Case_Cache), Right); 
  end Upper_Case;
  -----------------------------------------------------------
  function Camel_Case(Self : String_Object) return String is
  begin
    return Trim(To_String(Self.Camel_Case_Cache), Right);     
  end Camel_Case;
  -----------------------------------------------------------
  procedure Append(Self : in out String_Object; What : String) is
  begin
    Append(Self.Value, To_Unbounded_String(What));
    Self.Set(To_String(Self.Value)); -- needs to update cache. DO NOT USE Fix_String, it trims ... 
  end Append;                                          
  -----------------------------------------------------------
  function Empty_String_Object return String_Object is
    Another : String_Object;
  begin
    return Another;
  end Empty_String_Object;
  -----------------------------------------------------------
  function "<"( Left, Right : String_Object) return Boolean is
  begin -- Sort new records in list with ascending string
      return Left.Fix_String < Right.Fix_String;
  end "<";
  -----------------------------------------------------------
  function ">"( Left, Right : String_Object) return Boolean is
  begin -- Sort new records in list with ascending string
      return Left.Fix_String > Right.Fix_String;
  end ">";
  -----------------------------------------------------------
  function "="( Left, Right : String_Object) return Boolean is
  begin -- Sort new records in list with ascending string
      return Left.Fix_String = Right.Fix_String;
  end "=";
  -----------------------------------------------------------
  procedure Delete_Last_Char(Self : in out String_Object) is
    Len : Natural := Length(Self.Value);
  begin
    Delete(Source  => Self.Value,
           From    => Len,
           Through => Len);
    Self.Set(To_String(Self.Value)); -- needs to update cache. DO NOT USE Fix_String, it trims ... 
  end Delete_Last_Char;

 
end Repository_Types;


