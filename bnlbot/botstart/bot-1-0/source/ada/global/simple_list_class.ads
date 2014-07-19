------------------------------------------------------------------------------
--                                                                          --
--                        Simple_List_Class                                 --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--  Copyright (c) Björn Lundin 2014                                         --
--  All rights reserved.                                                    --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions      --
--  are met:                                                                --
--  1. Redistributions of source code must retain the above copyright       --
--     notice, this list of conditions and the following disclaimer.        --
--  2. Redistributions in binary form must reproduce the above copyright    --
--     notice, this list of conditions and the following disclaimer in      --
--     the documentation and/or other materials provided with the           --
--     distribution.                                                        --
--  3. Neither the name of Björn Lundin nor the names of its contributors   --
--     may be used to endorse or promote products derived from this         --
--     software without specific prior written permission.                  --
--                                                                          --
--  THIS SOFTWARE IS PROVIDED BY BJÖRN LUNDIN AND CONTRIBUTORS ``AS         --
--  IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT          --
--  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       --
--  FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL BJÖRN       --
--  LUNDIN OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,              --
--  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES                --
--  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR      --
--  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)      --
--  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN               --
--  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR            --
--  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,          --
--  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                      --
--                                                                          --
------------------------------------------------------------------------------
with Ada.Finalization;

generic
  type Element_Type is private;

package Simple_List_Class is


    type List_Type is tagged private; 

  --
  -- Allocate a new empty list object
  --
  function Create return List_Type;

  --
  -- Deallocate entire list object. All elements will also be deallocated 
  -- (if any). CREATE must be called again if the list shall be used again.
  --
  procedure Release (List: in out List_Type);


  -- Check if list is legal. A list is illegal if it is declared but not
  -- created. It is also illegal after it has been released.
  --
  function Is_Legal (List: List_Type) return Boolean;

  --
  -- Insert element as first in list.
  --
  procedure Insert_At_Head (List: in List_Type; Element: Element_Type);

  --
  -- Insert element as last in list.
  --
  procedure Insert_At_Tail (List: in List_Type; Element: Element_Type);

  --
  -- Read first element (from head). END_OF_LIST is TRUE if no
  -- element has been found (list is empty). 
  --
  procedure Get_First (List       : in List_Type; 
                       Element    : out Element_Type;
                       End_Of_List: out Boolean);

  -- Read next element (from head to tail). END_OF_LIST is TRUE if no more 
  -- elements are found. 
  --
  procedure Get_Next (List       : in List_Type; 
                      Element    : out Element_Type;
                      End_Of_List: out Boolean);

  --
  -- Read and remove first element in list. Internal storage will be 
  -- deallocated. END_OF_LIST will be TRUE if the list is empty.
  --
  procedure Remove_From_Head (List       : in List_Type; 
                              Element    : out Element_Type;
                              End_Of_List: out Boolean);

  --
  -- Read and remove first element in list. Internal storage will be 
  -- deallocated. Exception ILLEGAL_LIST will be raised if the list is empty.
  --
  procedure Remove_From_Head (List: in  List_Type; Element: out Element_Type);

  --
  -- Read and remove last element in list. Internal storage will be 
  -- deallocated. END_OF_LIST will be TRUE if the list is empty.
  --
  procedure Remove_From_Tail (List       : in List_Type; 
                              Element    : out Element_Type;
                              End_Of_List: out Boolean);

  --
  -- Read and remove last element in list. Internal storage will be 
  -- deallocated. Exception ILLEGAL_LIST will be raised if the list is empty.
  --
  procedure Remove_From_Tail (List: in List_Type; Element: out Element_Type);

  --
  -- Remove all elements from the list. Internal storage will be deallocated.
  --
  procedure Remove_All (List: in List_Type);

  --v9.5-10139
  -- Updates the element which is pointed at by the package.
  -- UPDATE does not affect the pointers in the list.
  --
  procedure Update (List: in List_Type; Element : in Element_Type);

  --v9.5-10139
  -- Deletes the item which is pointed at by the package.
  -- After DELETE the package points to the record before the deleted record.
  --
  procedure Delete (List:in List_Type);
  
  --
  -- Check if list is empty.
  --
  function Is_Empty (List: List_Type) return Boolean;

  --
  -- Get number of elements in the list.
  --
  function Get_Count (List: List_Type) return Natural;


  Illegal_List: exception;	-- An attempt was made to access an 
				-- uninitialized list.

private

  type Attribute_Type;
 
  type Attribute_Type_Access is access Attribute_Type; 
  
  type Cell_Type;

  type Cell_Pointer_Type is access Cell_Type;

  type Cell_Type is 
    record
      Element : Element_Type;
      Next    : Cell_Pointer_Type;
      Previous: Cell_Pointer_Type;
    end record;

  type Attribute_Type is
    record
      Head    : Cell_Pointer_Type;
      Tail    : Cell_Pointer_Type;
      Current : Cell_Pointer_Type;
      Count   : Natural;
    end record;
  
  type List_Type is new Ada.Finalization.Controlled with record
      Header : Attribute_Type_Access;
      Is_Initialized : Boolean := False;
      
  end record;
  overriding procedure Finalize (List : in out List_Type);
  
end Simple_List_Class;
