-------------------------------------------------------------------------------
--                                                                           --
--                                Helpers                                    --
--                                                                           --
--                                 BODY                                      --
--                                                                           --
--                     Copyright (C) 2011, Thomas Løcke                      --
--                                                                           --
--  Helpers is free software;  you can  redistribute it  and/or modify       --
--  it under terms of the  GNU General Public License as published  by the   --
--  Free Software  Foundation;  either version 2,  or (at your option) any   --
--  later version.  Helpers is distributed in the hope that it will be       --
--  useful, but WITHOUT ANY WARRANTY;  without even the  implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        --
--  General Public License for  more details.  You should have  received a  --
--  copy of the GNU General Public License  distributed with JSON_Test.      --
--  If not, write  to  the  Free Software Foundation,  51  Franklin  Street, --
--  Fifth  Floor, Boston, MA 02110 - 1301, USA.                              --
--                                                                           --
-------------------------------------------------------------------------------

with Ada.Direct_IO;
with Ada.Directories;
with Ada.Text_IO;

package body Helpers is

   ---------------------------
   --  Add_Company_Address  --
   ---------------------------

   procedure Add_Company_Address
     (Obj         : in out JSON_Value;
      Street_Name : in     UTF8_String;
      Street_No   : in     Positive;
      Zip_Code    : in     UTF8_String;
      City_Name   : in     UTF8_String;
      Phone       : in     UTF8_String;
      Comment     : in     UTF8_String)
   is
      Address_JSON : constant JSON_Value  := Create_Object;
      Address_Arr  : JSON_Array;
   begin
      if Has_Field (Obj, "addresses") then
         Address_Arr := Get (Val   => Obj,
                             Field => "addresses");
      end if;
      --  If the Obj JSON object alread have an addresses field, then we've
      --  added at least one address already. We then load the previously
      --  added addresses into the Address_Arr JSON_Array variable, and append
      --  to this later.

      Set_Field (Val        => Address_JSON,
                 Field_Name => "street_name",
                 Field      => Street_Name);
      --  Using the Set_Field procedure we add fields to the Address_JSON. In
      --  this case we add the field "street_name" and we give it the value of
      --  of Street_Name. There are Set_Field procedures for the valid JSON
      --  types. See GNATCOLL.JSON.JSON_Value_Type.

      Set_Field (Val        => Address_JSON,
                 Field_Name => "street_no",
                 Field      => Street_No);

      Set_Field (Val        => Address_JSON,
                 Field_Name => "zip_code",
                 Field      => Zip_Code);

      Set_Field (Val        => Address_JSON,
                 Field_Name => "city",
                 Field      => City_Name);

      Set_Field (Val        => Address_JSON,
                 Field_Name => "phone",
                 Field      => Phone);

      Set_Field (Val        => Address_JSON,
                 Field_Name => "comment",
                 Field      => Comment);

      Append (Arr => Address_Arr,
              Val => Address_JSON);
      --  Here we append the Address_JSON JSON_Value to the Address_Arr
      --  JSON_Array. Note that we could also have used &, but that would've
      --  been less efficient.

      Set_Field (Val        => Obj,
                 Field_Name => "addresses",
                 Field      => Address_Arr);
      --  Finally we add the Address_Arr JSON_Array to the Obj JSON_Value.
   end Add_Company_Address;

   ------------------
   --  Add_Person  --
   ------------------

   procedure Add_Person
     (Obj   : in out JSON_Value;
      Name  : in     UTF8_String;
      Title : in     UTF8_String;
      Email : in     UTF8_String)
   is
      Person_JSON : constant JSON_Value  := Create_Object;
      Person_Arr  : JSON_Array;
   begin
      if Has_Field (Obj, "persons") then
         Person_Arr := Get (Val   => Obj,
                            Field => "persons");
      end if;

      Set_Field (Val        => Person_JSON,
                 Field_Name => "name",
                 Field      => Name);

      Set_Field (Val        => Person_JSON,
                 Field_Name => "title",
                 Field      => Title);

      Set_Field (Val        => Person_JSON,
                 Field_Name => "email",
                 Field      => Email);

      Append (Arr => Person_Arr,
              Val => Person_JSON);

      Set_Field (Val        => Obj,
                 Field_Name => "persons",
                 Field      => Person_Arr);
   end Add_Person;

   ----------------
   --  Iterator  --
   ----------------

   procedure Handler
     (Name  : in UTF8_String;
      Value : in JSON_Value)
   is
      use Ada.Text_IO;
   begin
      case Kind (Val => Value) is
         when JSON_Null_Type =>
            Put_Line (Name & "(null):null");
         when JSON_Boolean_Type =>
            Put_Line (Name & "(boolean):" & Boolean'Image (Get (Value)));
         when JSON_Int_Type =>
            Put_Line (Name & "(integer):" & Integer'Image (Get (Value)));
         when JSON_Float_Type =>
            Put_Line (Name & "(float):" & Float'Image (Get (Value)));
         when JSON_String_Type =>
            Put_Line (Name & "(string):" & Get (Value));
         when JSON_Array_Type =>
            declare
               A_JSON_Array : constant JSON_Array := Get (Val => Value);
               A_JSON_Value : JSON_Value;
               Array_Length : constant Natural := Length (A_JSON_Array);
            begin
               Put (Name & "(array):[");
               for J in 1 .. Array_Length loop
                  A_JSON_Value := Get (Arr   => A_JSON_Array,
                                       Index => J);
                  Put (Get (A_JSON_Value));

                  if J < Array_Length then
                     Put (", ");
                  end if;
               end loop;
               Put ("]");
               New_Line;
            end;
         when JSON_Object_Type =>
            Put_Line (Name & "(object):");
            Map_JSON_Object (Val => Value,
                             CB  => Handler'Access);
      end case;
      --  Decide output depending on the kind of JSON field we're dealing with.
      --  Note that if we get a JSON_Object_Type, then we recursively call
      --  Map_JSON_Object again, which in turn calls this Handler procedure.
   end Handler;

   -----------------
   --  Load_File  --
   -----------------

   function Load_File
     (Filename : in String)
      return String
   is
      use Ada.Directories;

      File_Size    : constant Natural := Natural (Size (Filename));

      subtype Test_JSON_Str is String (1 .. File_Size);
      package File_IO is new Ada.Direct_IO (Test_JSON_Str);

      File           : File_IO.File_Type;
      String_Content : Test_JSON_Str;
   begin
      File_IO.Open (File => File,
                    Mode => File_IO.In_File,
                    Name => Filename);
      File_IO.Read (File => File,
                    Item => String_Content);
      File_IO.Close (File => File);

      return String_Content;
   end Load_File;

   -----------------------------
   --  Set_Core_Company_Data  --
   -----------------------------

   procedure Set_Core_Company_Data
     (Obj     : in out JSON_Value;
      Name    : in     UTF8_String;
      VAT_No  : in     UTF8_String;
      Hours   : in     UTF8_String;
      Product : in     UTF8_String;
      Web     : in     UTF8_String)
   is
   begin
      Set_Field (Val        => Obj,
                 Field_Name => "company_name",
                 Field      => Name);

      Set_Field (Val        => Obj,
                 Field_Name => "vat_no",
                 Field      => VAT_No);

      Set_Field (Val        => Obj,
                 Field_Name => "hours",
                 Field      => Hours);

      Set_Field (Val        => Obj,
                 Field_Name => "product",
                 Field      => Product);

      Set_Field (Val        => Obj,
                 Field_Name => "web",
                 Field      => Web);
   end Set_Core_Company_Data;

end Helpers;
