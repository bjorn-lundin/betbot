--------------------------------------------------------------------------------
--
--	COPYRIGHT	SattControl AB, Malm|
--
--	FILE NAME	SIMPLE_LIST_CLASS_SPEC.ADA
--
--	RESPONSIBLE	Henrik Dannberg
--
--  DESCRIPTION  Generic package SIMPLE_LIST_CLASS_2
--               create lists with the following characteristics:
--               
--                  o  Elements can be inserted either first or last
--                     in the list.
--                  o  Elements can be read from first to last.
--                  o  Elements can be removed either from the start of
--                     the list or from the end of the list.
--               
--               No garbage collection is used. Instead, all internal
--               memory associated with an element is deallocated when
--               the element is removed from the list.
--
--------------------------------------------------------------------------------
--Version   Author     Date         Description
--------------------------------------------------------------------------------
--6.0       HKD        18-AUG-1994  Original version
--9.5-10139 SNE        10-May-2006  Added the following new procedures GET, PUT, 
--                                  UPDATE and DELETE.
--------------------------------------------------------------------------------
-- #4516 BNL 25-Apr-2014 Made the list tagged.  Object.verb syntax
-----------------------------------------------------------------
with Ada.Finalization;

generic
  type Element_Type is private;

package Simple_List_Class is


--#4516  type LIST_TYPE is private;
    type List_Type is tagged private; --#4516

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

  --v9.5-10139
  -- If you want to have the list sorted you can use this procedure to put
  -- the elements into the list. You can either have the list sorted in ascending 
  -- or descending order. If you instantiate the function RELATION_OPERATOR 
  -- with a "less than" operator you will get an ascending list and with a 
  -- "greater than" operator a descending list. If some elements are equal, the 
  -- element which was put into the list first will be closest to the end of the 
  -- list. 
  -- After the procedure the list handler points at the new element.
  --
  generic
    with function Relation_Operator (Left, Right : in Element_Type) return Boolean;    
    procedure Put (List : in  List_Type; Element : in Element_Type);

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

  -- v9.5-10139
  -- If you want to make a search in the list, you have to put a key value into 
  -- the ELEMENT_TYPE record before you call the procedure GET. If the record is
  -- present in the list the record is returned, otherwise nothing is returned.
  -- If the record is present the variable END_OF_LIST returns FALSE, otherwise
  -- it returns TRUE. 
  -- It is the function IS_EQUAL which decides whether a record in the list 
  -- contains the key value or not. The parameter LEFT is the parameter used by
  -- the element in the list and the parameter RIGHT by the your key value.
  -- If the parameter CONTINUE_IN_LIST is FALSE then the search in the list will
  -- start at the first record in the list LIST.
  -- If the parameter CONTINUE_IN_LIST is TRUE then the search in the list will
  -- start at the next record in the current list, i.e. the parameter LIST has
  -- no meaning in this call.
  -- If the element is not found, the list handler's pointer is undefined.
  --
  generic
    with function Is_Equal (Left, Right : in Element_Type) return Boolean;
  procedure Get 
            (List             : in List_Type;
             Element          : in out Element_Type;
             End_Of_List      : out Boolean;
             Continue_In_List : in Boolean := False);

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
