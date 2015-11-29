
with Ada.Strings;           use Ada.Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

package Types is

   type Byte is range 0 .. 255;
   for  Byte'Size use 8;

   type Integer_2 is range -32_768 .. 32_767;
   for  Integer_2'Size use 16;

   type Word is range 0 .. 2**16-1;
   for Word'size use 16;
   
   type Integer_4 is range -2_147_483_648 .. 2_147_483_647;
   for  Integer_4'Size use 32;

   type Integer_8 is range -9_223_372_036_854_775_808 .. 9_223_372_036_854_775_807;
   for  Integer_8'Size use 64;

   type Float_8 is new Long_Float; 
   
   package F8 is new Ada.Text_IO.Float_IO (Float_8);
   
   
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
   
   
   
end Types;
