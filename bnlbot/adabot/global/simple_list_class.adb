--------------------------------------------------------------------------------
--
--	COPYRIGHT	SattControl AB, Malm|
--
--	FILE NAME	SIMPLE_LIST_CLASS.ADB
--
--	RESPONSIBLE	Henrik Dannberg
--
--	DESCRIPTION	Original version.
--
--------------------------------------------------------------------------------
--Version   Author     Date         Description
--------------------------------------------------------------------------------
--6.0       HKD        18-AUG-1994  Original version
--9.5-10139 SNE        10-May-2006  Added the following new procedures GET, PUT, 
--                                  UPDATE and DELETE.
--9.7-13984 SNE/AlexO. 24-Apr-2008  Generic Get could cause a CONSTRAINT_ERROR to be raised if:
--                                  0. A list with several records existed
--                                  1. A generic get finds the first item in the list
--                                  2. Delete is made on that record.
--                                  3. A generic get with continue_in_list => true
--------------------------------------------------------------------------------

with UNCHECKED_DEALLOCATION;

package body SIMPLE_LIST_CLASS is

  type CELL_TYPE;

  type CELL_POINTER_TYPE is access CELL_TYPE;

  type CELL_TYPE is 
    record
      ELEMENT : ELEMENT_TYPE;
      NEXT    : CELL_POINTER_TYPE;
      PREVIOUS: CELL_POINTER_TYPE;
    end record;

  type ATTRIBUTE_TYPE is
    record
      HEAD    : CELL_POINTER_TYPE;
      TAIL    : CELL_POINTER_TYPE;
      CURRENT : CELL_POINTER_TYPE;
      COUNT   : NATURAL;            
    end record;
  
  procedure FREE is new UNCHECKED_DEALLOCATION (OBJECT => CELL_TYPE,
                                                NAME   => CELL_POINTER_TYPE);

  procedure FREE is new UNCHECKED_DEALLOCATION (OBJECT => ATTRIBUTE_TYPE,
                                                NAME   => LIST_TYPE);

  function CREATE return LIST_TYPE is
  begin
    return new ATTRIBUTE_TYPE'(HEAD    => null,
                               TAIL    => null,
                               CURRENT => null,
                               COUNT   => 0);
  end CREATE;


  procedure RELEASE (LIST: in out LIST_TYPE) is
  begin
    if (LIST /= null) then
      REMOVE_ALL(LIST);
      FREE(LIST);
      LIST := null;
    end if;
  end RELEASE;


  function IS_LEGAL (LIST: LIST_TYPE) return BOOLEAN is
  begin
    return (LIST /= null);
  end IS_LEGAL;


  --v9.5-10139 New procedure
  procedure PUT (LIST : in LIST_TYPE; ELEMENT : in ELEMENT_TYPE) is
    CELL: CELL_POINTER_TYPE;
  begin
    if (LIST = null) then
      raise ILLEGAL_LIST;
    else

      -- Find sorting place in list for the element 
      LIST.CURRENT := LIST.HEAD;
      if LIST.CURRENT /= null then
        while RELATION_OPERATOR(LIST.CURRENT.ELEMENT, ELEMENT) loop
          LIST.CURRENT := LIST.CURRENT.NEXT;
          exit when LIST.CURRENT = null;
        end loop;
      end if;

      if LIST.CURRENT = null then
        if LIST.HEAD = null then
          --Empty list
          CELL := new CELL_TYPE'(ELEMENT  => ELEMENT,
                                 NEXT     => null,
                                 PREVIOUS => null);
          LIST.HEAD      := CELL;
          LIST.TAIL      := CELL;
          LIST.CURRENT   := CELL;
        else
          --Add element last in list
          CELL := new CELL_TYPE'(ELEMENT  => ELEMENT,
                                 NEXT     => null,
                                 PREVIOUS => LIST.TAIL);
          LIST.TAIL.NEXT := CELL;
          LIST.TAIL      := CELL;
          LIST.CURRENT   := CELL;
        end if;
      else
        -- Add element between 2 other element
        CELL := new CELL_TYPE'(ELEMENT  => ELEMENT,
                               NEXT     => LIST.CURRENT,
                               PREVIOUS => LIST.CURRENT.PREVIOUS);
        if LIST.CURRENT = LIST.HEAD then
          -- add element first in list
          LIST.HEAD := CELL;
        else
          -- between 2 elements
          LIST.CURRENT.PREVIOUS.NEXT := CELL;
        end if;
        LIST.CURRENT.PREVIOUS      := CELL;
        LIST.CURRENT               := CELL;
      end if;
      LIST.COUNT := LIST.COUNT + 1;
    end if;

  end PUT;

  procedure INSERT_AT_HEAD (LIST: LIST_TYPE; ELEMENT: ELEMENT_TYPE) is
    CELL: CELL_POINTER_TYPE;
  begin
    if (LIST = null) then
      raise ILLEGAL_LIST;
    else
      CELL := new CELL_TYPE'(ELEMENT  => ELEMENT,
                             NEXT     => LIST.HEAD,
                             PREVIOUS => null);
      if (LIST.HEAD = null) then
        --
        -- This will be the only element in the list
        --
        LIST.TAIL := CELL;
      else
        LIST.HEAD.PREVIOUS := CELL;
      end if;
      LIST.HEAD  := CELL;
      LIST.COUNT := LIST.COUNT + 1;
    end if;
  end INSERT_AT_HEAD;


  procedure INSERT_AT_TAIL (LIST: LIST_TYPE; ELEMENT: ELEMENT_TYPE) is
    CELL: CELL_POINTER_TYPE;
  begin
    if (LIST = null) then
      raise ILLEGAL_LIST;
    else
      CELL := new CELL_TYPE'(ELEMENT  => ELEMENT,
                             NEXT     => null,
                             PREVIOUS => LIST.TAIL);
      if (LIST.TAIL = null) then
        --
        -- This will be the only element in the list
        --
        LIST.HEAD := CELL;
      else
        LIST.TAIL.NEXT := CELL;
      end if;
      LIST.TAIL := CELL;
      LIST.COUNT := LIST.COUNT + 1;
    end if;
  end INSERT_AT_TAIL;


  procedure GET_FIRST (LIST       : LIST_TYPE; 
                       ELEMENT    : out ELEMENT_TYPE;
                       END_OF_LIST: out BOOLEAN) is
  begin
    if (LIST = null) then
      raise ILLEGAL_LIST;
    elsif (LIST.COUNT = 0) then
      END_OF_LIST := TRUE;
    else
      ELEMENT      := LIST.HEAD.ELEMENT;
      LIST.CURRENT := LIST.HEAD;
      END_OF_LIST  := FALSE;
    end if;
  end GET_FIRST;


  procedure GET_NEXT (LIST       : LIST_TYPE; 
                      ELEMENT    : out ELEMENT_TYPE;
                      END_OF_LIST: out BOOLEAN) is
  begin
    if (LIST = null) then
      raise ILLEGAL_LIST;
    elsif (LIST.CURRENT = null) then
      END_OF_LIST := TRUE;
    elsif (LIST.CURRENT.NEXT = null) then
      END_OF_LIST := TRUE;
    else
      LIST.CURRENT := LIST.CURRENT.NEXT;
      ELEMENT      := LIST.CURRENT.ELEMENT;
      END_OF_LIST  := FALSE;
    end if;
  end GET_NEXT;


  --v9.5-10139 New procedure
  procedure GET (LIST             : in LIST_TYPE;
                 ELEMENT          : in out ELEMENT_TYPE;
                 END_OF_LIST      : out BOOLEAN;
                 CONTINUE_IN_LIST : in BOOLEAN := FALSE) is
  begin
    if (LIST = null) then
      raise ILLEGAL_LIST;
    else

      if not CONTINUE_IN_LIST or else
        LIST.CURRENT = null then         -- v9.7-13984
        LIST.CURRENT := LIST.HEAD;
      else
        LIST.CURRENT := LIST.CURRENT.NEXT;
      end if;

      -- Try to find element
      if LIST.CURRENT /= null then
        while not IS_EQUAL(LIST.CURRENT.ELEMENT, ELEMENT) loop
          LIST.CURRENT := LIST.CURRENT.NEXT;
          exit when LIST.CURRENT = null;
        end loop;
      end if;

      if LIST.CURRENT = null then
          -- Element not found!
          END_OF_LIST := True;
      else
        -- Return found element!
        ELEMENT      := LIST.CURRENT.ELEMENT;
        END_OF_LIST := False;
      end if;
    end if;
  end GET;

  procedure REMOVE_FROM_HEAD (LIST       : LIST_TYPE; 
                              ELEMENT    : out ELEMENT_TYPE;
                              END_OF_LIST: out BOOLEAN) is
    CELL: CELL_POINTER_TYPE;
  begin
    if (LIST = null) then
      raise ILLEGAL_LIST;
    elsif (LIST.HEAD = null) then
      END_OF_LIST := TRUE;
    else      
      CELL := LIST.HEAD;
      if (LIST.HEAD = LIST.TAIL) then
        --
        -- No more elements left in the list.
        --
        LIST.HEAD := null;
        LIST.TAIL := null;
      else
        LIST.HEAD.NEXT.PREVIOUS := null;
        LIST.HEAD := LIST.HEAD.NEXT;
      end if;
      ELEMENT := CELL.ELEMENT;
      FREE(CELL);
      LIST.COUNT := LIST.COUNT - 1;      
      END_OF_LIST := FALSE;
    end if;
  end REMOVE_FROM_HEAD;


  procedure REMOVE_FROM_HEAD (LIST: LIST_TYPE; ELEMENT: out ELEMENT_TYPE) is
    END_OF_LIST: BOOLEAN;
  begin
    REMOVE_FROM_HEAD (LIST, ELEMENT, END_OF_LIST);
    if (END_OF_LIST) then
      raise ILLEGAL_LIST;
    end if;
  end REMOVE_FROM_HEAD;


  procedure REMOVE_FROM_TAIL (LIST       : LIST_TYPE; 
                              ELEMENT    : out ELEMENT_TYPE;
                              END_OF_LIST: out BOOLEAN) is
    CELL: CELL_POINTER_TYPE;
  begin
    if (LIST = null) then
      raise ILLEGAL_LIST;
    elsif (LIST.TAIL = null) then
      END_OF_LIST := TRUE;
    else      
      CELL := LIST.TAIL;
      if (LIST.HEAD = LIST.TAIL) then
        --
        -- No more elements left in the list.
        --
        LIST.HEAD := null;
        LIST.TAIL := null;
      else
        LIST.TAIL.PREVIOUS.NEXT := null;
        LIST.TAIL := LIST.TAIL.PREVIOUS;
      end if;
      ELEMENT := CELL.ELEMENT;
      FREE(CELL);
      LIST.COUNT := LIST.COUNT - 1;      
      END_OF_LIST := FALSE;
    end if;
  end REMOVE_FROM_TAIL;


  procedure REMOVE_FROM_TAIL (LIST: LIST_TYPE; ELEMENT: out ELEMENT_TYPE) is
    END_OF_LIST: BOOLEAN;
  begin
    REMOVE_FROM_TAIL (LIST, ELEMENT, END_OF_LIST);
    if (END_OF_LIST) then
      raise ILLEGAL_LIST;
    end if;
  end REMOVE_FROM_TAIL;


  procedure REMOVE_ALL (LIST: LIST_TYPE) is
    CELL: CELL_POINTER_TYPE;
  begin
    if (LIST = null) then
      raise ILLEGAL_LIST;
    else
      while (LIST.HEAD /= null) loop
        CELL      := LIST.HEAD;
        LIST.HEAD := LIST.HEAD.NEXT;
        FREE(CELL);
      end loop;
      LIST.HEAD  := null;
      LIST.TAIL  := null;
      LIST.COUNT := 0;
    end if;
  end REMOVE_ALL;


  --v9.5-10139 New procedure
  procedure UPDATE (LIST: LIST_TYPE; ELEMENT : in ELEMENT_TYPE) is
  begin
    LIST.CURRENT.ELEMENT := ELEMENT;
  end UPDATE;

  --v9.5-10139 New procedure
  procedure DELETE (LIST: LIST_TYPE) is
    CELL: CELL_POINTER_TYPE;
  begin
    if (LIST = null) then
      raise ILLEGAL_LIST;
    elsif (LIST.HEAD = null) then
      null;
    else      
      CELL := LIST.CURRENT;
      if LIST.HEAD = LIST.CURRENT and
         LIST.TAIL = LIST.CURRENT then
        -- Element to be deleted is the only element in the list
        LIST.HEAD := null;
        LIST.TAIL := null;
      elsif LIST.HEAD = LIST.CURRENT then
        -- Element to be deleted is first in list
        LIST.HEAD.NEXT.PREVIOUS := null;
        LIST.HEAD := LIST.HEAD.NEXT;
      elsif LIST.TAIL = LIST.CURRENT then
        -- Element to be deleted is last in list
        LIST.TAIL.PREVIOUS.NEXT := null;
        LIST.TAIL := LIST.TAIL.PREVIOUS;
      else
        -- Element to be deleted is in the middle of the list
        LIST.CURRENT.NEXT.PREVIOUS := LIST.CURRENT.PREVIOUS;
        LIST.CURRENT.PREVIOUS.NEXT := LIST.CURRENT.NEXT;
      end if;
      LIST.CURRENT := LIST.CURRENT.PREVIOUS;
      FREE(CELL);
      LIST.COUNT := LIST.COUNT - 1;      
    end if;
  end DELETE;

  function IS_EMPTY (LIST: LIST_TYPE) return BOOLEAN is
  begin
    if (LIST = null) then
      raise ILLEGAL_LIST;
    else
      return LIST.COUNT = 0;
    end if;
  end IS_EMPTY;


  function GET_COUNT (LIST: LIST_TYPE) return NATURAL is
  begin
    if (LIST = null) then
      raise ILLEGAL_LIST;
    else
      return LIST.COUNT;
    end if;
  end GET_COUNT;

end SIMPLE_LIST_CLASS;
