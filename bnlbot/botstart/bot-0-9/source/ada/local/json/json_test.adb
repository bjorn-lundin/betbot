-------------------------------------------------------------------------------
--                                                                           --
--                                JSON_Test                                  --
--                                                                           --
--                     Copyright (C) 2011, Thomas Løcke                      --
--                                                                           --
--  JSON_Test is free software;  you can  redistribute it  and/or modify     --
--  it under terms of the  GNU General Public License as published  by the   --
--  Free Software  Foundation;  either version 2,  or (at your option) any   --
--  later version.  JSON_Test is distributed in the hope that it will be     --
--  useful, but WITHOUT ANY WARRANTY;  without even the  implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        --
--  General Public License for  more details.  You should have  received  a  --
--  copy of the GNU General Public License  distributed with JSON_Test.      --
--  If not, write  to  the  Free Software Foundation,  51  Franklin  Street, --
--  Fifth  Floor, Boston, MA 02110 - 1301, USA.                              --
--                                                                           --
-------------------------------------------------------------------------------

with Ada.Text_IO;
with GNATCOLL.JSON;
with Helpers;

with Sattmate_Exception;

procedure JSON_Test is
   use Ada.Text_IO;
   use GNATCOLL.JSON;
   use Helpers;

   Company_JSON : JSON_Value := Create_Object;
   --  Initialize an empty JSON_Value object. We will add values to this
   --  object using the GNATCOLL.JSON.Set_Field procedures.

   Test_JSON    : JSON_Value;
   --  Uninitialized JSON_Value. We'll use this to hold the JSON object read
   --  from the exe/test.json file.
begin
   --  Build the company JSON. See the Helpers package.
   Set_Core_Company_Data (Obj     => Company_JSON,
                          Name    => "AdaHeads K/S",
                          VAT_No  => "134679-zoink",
                          Hours   => "24/7",
                          Product => "Software development.",
                          Web     => "adaheads.com");

   Add_Company_Address (Obj         => Company_JSON,
                        Street_Name => "Mosekrogen",
                        Street_No   => 3,
                        Zip_Code    => "3520",
                        City_Name   => "Farum",
                        Phone       => "+45 11223344",
                        Comment     => "Headquarters");

   Add_Company_Address (Obj         => Company_JSON,
                        Street_Name => "Granvej",
                        Street_No   => 6,
                        Zip_Code    => "3660",
                        City_Name   => "Stenlose",
                        Phone       => "+45 22334455",
                        Comment     => "Branch office, Thomas Locke");

   Add_Person (Obj   => Company_JSON,
               Name  => "Jacob Sparre Andersen",
               Title => "Codemonkey",
               Email => "jacspaand@somewhere.tld");

   Add_Person (Obj   => Company_JSON,
               Name  => "Kim Rostgaard Christensen",
               Title => "Codemonkey",
               Email => "kimroschr@somewhere.tld");

   Add_Person (Obj   => Company_JSON,
               Name  => "Thomas Locke",
               Title => "Codemonkey",
               Email => "tholoc@somewhere.tld");

   Add_Person (Obj   => Company_JSON,
               Name  => "Ulrik Horlyk Hjort",
               Title => "Codemonkey",
               Email => "ulrhorhjo@somewhere.tld");

   --  Output the company JSON. Note that we've set the Compact parameter of
   --  Write to False for slightly improved readability. The default is True.
   New_Line;
   Put_Line ("--> Company_JSON Start <--");
   Put_Line (Write (Company_JSON, False));
   Put_Line ("--> Company_JSON End <--");
   New_Line;

   --  Load the test.json JSON object into the Test_JSON object.
   Test_JSON := Read (Strm     => Load_File ("test.json"),
                      Filename => "");

   --  Iterate the Test_JSON object. The Handler procedure is responsible for
   --  outputting the contents.
   Put_Line ("--> Test_JSON Start <--");
   Map_JSON_Object (Val   => Test_JSON,
                    CB    => Handler'Access);
   Put_Line ("--> Test_JSON End <--");
   New_Line;

exception
   when E : others =>
      Sattmate_Exception.Tracebackinfo(E);
end JSON_Test;
