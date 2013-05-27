-------------------------------------------------------------------------------
--                                                                           --
--                                Helpers                                    --
--                                                                           --
--                                 SPEC                                      --
--                                                                           --
--                     Copyright (C) 2011, Thomas Løcke                      --
--                                                                           --
--  Helpers is free software;  you can  redistribute it  and/or modify       --
--  it under terms of the  GNU General Public License as published  by the   --
--  Free Software  Foundation;  either version 2,  or (at your option) any   --
--  later version.  Helpers is distributed in the hope that it will be       --
--  useful, but WITHOUT ANY WARRANTY;  without even the  implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        --
--  General Public License for  more details.  You should have  received  a  --
--  copy of the GNU General Public License  distributed with JSON_Test.      --
--  If not, write  to  the  Free Software Foundation,  51  Franklin  Street, --
--  Fifth  Floor, Boston, MA 02110 - 1301, USA.                              --
--                                                                           --
-------------------------------------------------------------------------------

with GNATCOLL.JSON;

package Helpers is

   use GNATCOLL.JSON;

   procedure Set_Core_Company_Data
     (Obj     : in out JSON_Value;
      Name    : in     UTF8_String;
      VAT_No  : in     UTF8_String;
      Hours   : in     UTF8_String;
      Product : in     UTF8_String;
      Web     : in     UTF8_String);
   --  There can only be one set of these data in the final JSON, so whenever
   --  this procedure is called, the previous set is overwritten with the
   --  latest set.

   procedure Add_Company_Address
     (Obj         : in out JSON_Value;
      Street_Name : in     UTF8_String;
      Street_No   : in     Positive;
      Zip_Code    : in     UTF8_String;
      City_Name   : in     UTF8_String;
      Phone       : in     UTF8_String;
      Comment     : in     UTF8_String);
   --  A company can have several addresses, so these are added as JSON arrays.

   procedure Add_Person
     (Obj   : in out JSON_Value;
      Name  : in     UTF8_String;
      Title : in     UTF8_String;
      Email : in     UTF8_String);
   --  A company can have several employees, so these are added as JSON arrays.

   procedure Handler
     (Name  : in UTF8_String;
      Value : in JSON_Value);
   --  Output the contents of the Value JSON object.

   function Load_File
     (Filename : in String)
      return String;
   --  Load the test.json JSON object from Filename and return it as a string.

end Helpers;
