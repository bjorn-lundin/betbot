------------------------------------------------------------------------------
--
-- COPYRIGHT     Consafe Logistics AB
-- FILE NAME     Binary_Semaphores.adb
-- RESPONSIBLE	
-- DESCRIPTION   Body for package Binary Semaphores.
--               This a simple Boolean type this is protected
--
------------------------------------------------------------------------------
--Vers.     Author    Date         Description
------------------------------------------------------------------------------
--9.5-10276 AXO/SNE   09-Oct-2006  Original version
------------------------------------------------------------------------------
package body Binary_Semaphores is

   protected body Semaphore_Type is

      procedure Release is
      begin
         In_Use := False;
      end;

      entry Seize when not In_Use is
      begin
         In_Use := True;
      end;

   end Semaphore_Type;

end Binary_Semaphores;
