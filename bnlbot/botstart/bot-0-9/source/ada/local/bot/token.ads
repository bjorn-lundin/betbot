with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;


package Token is
  Not_Valid_Token,
  Login_Failed  : exception;

  type Token_Type is private;
  procedure Login(A_Token : in out Token_Type) ;
  function  Id (A_Token : Token_Type) return String;
private
  type Token_Type is record
    Token_Is_Set : Boolean          := False;
    The_Token    : Unbounded_String := Null_Unbounded_String;
  end record;
end Token;