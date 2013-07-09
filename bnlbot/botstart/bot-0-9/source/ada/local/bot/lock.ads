with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Posix1; use Posix1;

with Ada.Finalization;
package Lock is
  type Lock_Type is tagged private;
  Lock_Error : exception;
  procedure Take(A_Lock : in out Lock_Type; Name : in String);
private
  type Lock_Type is new Ada.Finalization.Controlled with record
    Name : Unbounded_String := Null_Unbounded_String;
    Fd    : Posix1.Int := Posix1.Int'First;
  end record;
  
  overriding procedure Finalize(A_Lock : in out Lock_Type);
end Lock;