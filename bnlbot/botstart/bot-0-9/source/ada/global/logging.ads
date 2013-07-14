with Ada.Finalization;

package Logging is
   procedure Set_Quiet (Q: Boolean) ;

   procedure Log (What : in String) ;
   procedure Log (Who, What : in String) ;
   procedure Print (What : in String) ;

   procedure Change_Indent(How_Much : Integer) ;
   function Indent return String ;
   
   procedure Open(Name : String);
   procedure Close;

private
   type Dummy_Type is new Ada.Finalization.Controlled with null record;
   overriding procedure Finalize(D : in out Dummy_Type);
   
end Logging;
