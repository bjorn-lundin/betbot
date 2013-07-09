

package Logging is
   procedure Set_Quiet (Q: Boolean) ;

   procedure Log (What : in String) ;
   procedure Print (What : in String) ;

   procedure Change_Indent(How_Much : Integer) ;
   function Indent return String ;
   
   procedure Open(Name : String);
   procedure Close;
      
end Logging;
