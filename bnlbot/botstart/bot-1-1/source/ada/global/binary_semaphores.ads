------------------------------------------------------------------------------
--
-- COPYRIGHT     Consafe Logistics AB
-- FILE NAME     Binary_Semaphores.ads
-- RESPONSIBLE	
-- DESCRIPTION   Specification for package Binary Semaphores.
--               This a simple Boolean type this is protected
--
------------------------------------------------------------------------------
--Vers.     Author    Date         Description
------------------------------------------------------------------------------
--9.5-10276 AXO/SNE   09-Oct-2006  Original version
------------------------------------------------------------------------------
package Binary_Semaphores is

   pragma Pure;


   protected type Semaphore_Type is

      -- Release the semaphore
      procedure Release;

      -- Seize the semaphore
      entry Seize;

   private

      In_Use : Boolean := False;

   end Semaphore_Type;

end Binary_Semaphores;
