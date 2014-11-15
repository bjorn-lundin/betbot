
with Ada.Strings;           use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;


package Repository_Types is
  type String_Object is tagged private;
  
  procedure Set(Self : in out String_Object; What : String);
  procedure Reset(Self : in out String_Object);
  function Fix_String( Self : String_Object) return String;
  function UBString( Self : String_Object) return Unbounded_String;
  function Lower_Case( Self : String_Object) return String;
  function Upper_Case( Self : String_Object) return String ;
  function Empty_String_Object return String_Object;
  procedure Append(Self : in out String_Object; What : String);
  function Camel_Case(Self : String_Object) return String ;
  procedure Delete_Last_Char(Self : in out String_Object);
  
  function "<"( Left, Right : String_Object) return Boolean;
  function "="( Left, Right : String_Object) return Boolean;
  function ">"( Left, Right : String_Object) return Boolean;
  function Create(What : String) return String_Object;

private 
  type String_Object is tagged record
    Value ,
    Camel_Case_Cache,
    Lower_Case_Cache,
    Upper_Case_Cache: Unbounded_String := Null_Unbounded_String;
  end record;

end Repository_Types;


