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

generic

  type ELEMENT_TYPE is private;

package SIMPLE_LIST_CLASS is


  type LIST_TYPE is private;

  -- 
  -- Allocate a new empty list object
  --
  function CREATE return LIST_TYPE;

  --
  -- Deallocate entire list object. All elements will also be deallocated 
  -- (if any). CREATE must be called again if the list shall be used again.
  --
  procedure RELEASE (LIST: in out LIST_TYPE);


  -- Check if list is legal. A list is illegal if it is declared but not
  -- created. It is also illegal after it has been released.
  --
  function IS_LEGAL (LIST: LIST_TYPE) return BOOLEAN;

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
    with function RELATION_OPERATOR (LEFT, RIGHT : in ELEMENT_TYPE) return BOOLEAN;
  procedure PUT (LIST : in LIST_TYPE; ELEMENT : in ELEMENT_TYPE);

  --
  -- Insert element as first in list.
  --
  procedure INSERT_AT_HEAD (LIST: LIST_TYPE; ELEMENT: ELEMENT_TYPE);

  --
  -- Insert element as last in list.
  --
  procedure INSERT_AT_TAIL (LIST: LIST_TYPE; ELEMENT: ELEMENT_TYPE);

  --
  -- Read first element (from head). END_OF_LIST is TRUE if no
  -- element has been found (list is empty). 
  --
  procedure GET_FIRST (LIST       : LIST_TYPE; 
                       ELEMENT    : out ELEMENT_TYPE;
                       END_OF_LIST: out BOOLEAN);

  -- Read next element (from head to tail). END_OF_LIST is TRUE if no more 
  -- elements are found. 
  --
  procedure GET_NEXT (LIST       : LIST_TYPE; 
                      ELEMENT    : out ELEMENT_TYPE;
                      END_OF_LIST: out BOOLEAN);

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
    with function IS_EQUAL (LEFT, RIGHT : in ELEMENT_TYPE) return BOOLEAN;
  procedure GET 
            (LIST             : in LIST_TYPE;
             ELEMENT          : in out ELEMENT_TYPE;
             END_OF_LIST      : out BOOLEAN;
             CONTINUE_IN_LIST : in BOOLEAN := FALSE);

  --
  -- Read and remove first element in list. Internal storage will be 
  -- deallocated. END_OF_LIST will be TRUE if the list is empty.
  --
  procedure REMOVE_FROM_HEAD (LIST       : LIST_TYPE; 
                              ELEMENT    : out ELEMENT_TYPE;
                              END_OF_LIST: out BOOLEAN);

  --
  -- Read and remove first element in list. Internal storage will be 
  -- deallocated. Exception ILLEGAL_LIST will be raised if the list is empty.
  --
  procedure REMOVE_FROM_HEAD (LIST: LIST_TYPE; ELEMENT: out ELEMENT_TYPE);

  --
  -- Read and remove last element in list. Internal storage will be 
  -- deallocated. END_OF_LIST will be TRUE if the list is empty.
  --
  procedure REMOVE_FROM_TAIL (LIST       : LIST_TYPE; 
                              ELEMENT    : out ELEMENT_TYPE;
                              END_OF_LIST: out BOOLEAN);

  --
  -- Read and remove last element in list. Internal storage will be 
  -- deallocated. Exception ILLEGAL_LIST will be raised if the list is empty.
  --
  procedure REMOVE_FROM_TAIL (LIST: LIST_TYPE; ELEMENT: out ELEMENT_TYPE);

  --
  -- Remove all elements from the list. Internal storage will be deallocated.
  --
  procedure REMOVE_ALL (LIST: LIST_TYPE);

  --v9.5-10139
  -- Updates the element which is pointed at by the package.
  -- UPDATE does not affect the pointers in the list.
  --
  procedure UPDATE (LIST: LIST_TYPE; ELEMENT : in ELEMENT_TYPE);

  --v9.5-10139
  -- Deletes the item which is pointed at by the package.
  -- After DELETE the package points to the record before the deleted record.
  --
  procedure DELETE (LIST: LIST_TYPE);
  
  --
  -- Check if list is empty.
  --
  function IS_EMPTY (LIST: LIST_TYPE) return BOOLEAN;

  --
  -- Get number of elements in the list.
  --
  function GET_COUNT (LIST: LIST_TYPE) return NATURAL;


  ILLEGAL_LIST: exception;	-- An attempt was made to access an 
				-- uninitialized list.

private

  type ATTRIBUTE_TYPE;

  type LIST_TYPE is access ATTRIBUTE_TYPE;

end SIMPLE_LIST_CLASS;
