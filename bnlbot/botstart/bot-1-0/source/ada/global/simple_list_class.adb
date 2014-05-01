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

with Unchecked_Deallocation;
--with Text_Io;
package body Simple_List_Class is

--  type Cell_Type;
--
--  type Cell_Pointer_Type is access Cell_Type;
--
--  type Cell_Type is 
--    record
--      Element : Element_Type;
--      Next    : Cell_Pointer_Type;
--      Previous: Cell_Pointer_Type;
--    end record;
--
--  type Attribute_Type is
--    record
--      Head    : Cell_Pointer_Type;
--      Tail    : Cell_Pointer_Type;
--      Current : Cell_Pointer_Type;
--      Count   : Natural;
--    end record;
  
  procedure Free is new Unchecked_Deallocation (Object => Cell_Type,
                                                Name   => Cell_Pointer_Type);

  procedure Free is new Unchecked_Deallocation (Object => Attribute_Type,
                                                Name   => Attribute_Type_Access);

  function Create return List_Type is
    Tmp :  List_Type;
  begin
    Tmp.Is_Initialized := True;
    Tmp.Header := new Attribute_Type'(Head    => null,
                                      Tail    => null,
                                      Current => null,
                                      Count   => 0);
    return Tmp;
  end Create;


  procedure Release (List: in out List_Type) is
  begin
    if List.Is_Legal then
      Remove_All(List);
      Free(List.Header);
      List.Header := null;
      List.Is_Initialized := False;
    end if;
  end Release;

  procedure Release_Automatically (List: in out List_Type) is
  begin
    if List.Is_Legal then
      Remove_All(List);
      -- Free(List.Header); -- will crash process badly
      List.Header := null;
      List.Is_Initialized := False;
    end if;
  end Release_Automatically;

  
  function Is_Legal (List: List_Type) return Boolean is
  begin
    return List.Is_Initialized;
  end Is_Legal;


  --v9.5-10139 New procedure
  procedure Put (List : in List_Type; Element : in Element_Type) is
--  procedure Put (List : in List_Type; Element : in Element_Type) is
    Cell: Cell_Pointer_Type;
  begin
    if not List.Is_Legal then
      raise Illegal_List;
    else

      -- Find sorting place in list for the element 
      List.Header.Current := List.Header.Head;
      if List.Header.Current /= null then
        while Relation_Operator(List.Header.Current.Element, Element) loop
          List.Header.Current := List.Header.Current.Next;
          exit when List.Header.Current = null;
        end loop;
      end if;

      if List.Header.Current = null then
        if not List.Is_Legal then
          --Empty list
          Cell := new Cell_Type'(Element  => Element,
                                 Next     => null,
                                 Previous => null);
          List.Header.Head      := Cell;
          List.Header.Tail      := Cell;
          List.Header.Current   := Cell;
        else
          --Add element last in list
          Cell := new Cell_Type'(Element  => Element,
                                 Next     => null,
                                 Previous => List.Header.Tail);
          List.Header.Tail.Next := Cell;
          List.Header.Tail      := Cell;
          List.Header.Current   := Cell;
        end if;
      else
        -- Add element between 2 other element
        Cell := new Cell_Type'(Element  => Element,
                               Next     => List.Header.Current,
                               Previous => List.Header.Current.Previous);
        if List.Header.Current = List.Header.Head then
          -- add element first in list
          List.Header.Head := Cell;
        else
          -- between 2 elements
          List.Header.Current.Previous.Next := Cell;
        end if;
        List.Header.Current.Previous      := Cell;
        List.Header.Current               := Cell;
      end if;
      List.Header.Count := List.Header.Count + 1;
    end if;
  end Put;

  procedure Insert_At_Head (List:in List_Type; Element: Element_Type) is
    Cell: Cell_Pointer_Type;
  begin
    if not List.Is_Legal then
      raise Illegal_List;
    else
      Cell := new Cell_Type'(Element  => Element,
                             Next     => List.Header.Head,
                             Previous => null);
      if List.Header.Head = null then
        --
        -- This will be the only element in the list
        --
        List.Header.Tail := Cell;
      else
        List.Header.Head.Previous := Cell;
      end if;
      List.Header.Head  := Cell;
      List.Header.Count := List.Header.Count + 1;
    end if;
  end Insert_At_Head;


  procedure Insert_At_Tail (List:in List_Type; Element: Element_Type) is
    Cell: Cell_Pointer_Type;
  begin
    if not List.Is_Legal then
      raise Illegal_List;
    else
      Cell := new Cell_Type'(Element  => Element,
                             Next     => null,
                             Previous => List.Header.Tail);
      if List.Header.Tail = null then
        --
        -- This will be the only element in the list
        --
        List.Header.Head := Cell;
      else
        List.Header.Tail.Next := Cell;
      end if;
      List.Header.Tail := Cell;
      List.Header.Count := List.Header.Count + 1;
    end if;
  end Insert_At_Tail;


  procedure Get_First (List       : in List_Type; 
                       Element    : out Element_Type;
                       End_Of_List: out Boolean) is
  begin
    if not List.Is_Legal then
      raise Illegal_List;
    elsif List.Header.Count = 0 then
      End_Of_List := True;
    else
      Element      := List.Header.Head.Element;
      List.Header.Current := List.Header.Head;
      End_Of_List  := False;
    end if;
  end Get_First;


  procedure Get_Next (List       : in List_Type; 
                      Element    : out Element_Type;
                      End_Of_List: out Boolean) is
  begin
    if not List.Is_Legal then
      raise Illegal_List;
    elsif List.Header.Current = null then
      End_Of_List := True;
    elsif List.Header.Current.Next = null then
      End_Of_List := True;
    else
      List.Header.Current := List.Header.Current.Next;
      Element      := List.Header.Current.Element;
      End_Of_List  := False;
    end if;
  end Get_Next;


  --v9.5-10139 New procedure
  procedure Get (List             : in List_Type;
                 Element          : in out Element_Type;
                 End_Of_List      : out Boolean;
                 Continue_In_List : in Boolean := False) is
  begin
    if not List.Is_Legal then
      raise Illegal_List;
    else

      if not Continue_In_List or else
        List.Header.Current = null then         -- v9.7-13984
        List.Header.Current := List.Header.Head;
      else
        List.Header.Current := List.Header.Current.Next;
      end if;

      -- Try to find element
      if List.Header.Current /= null then
        while not Is_Equal(List.Header.Current.Element, Element) loop
          List.Header.Current := List.Header.Current.Next;
          exit when List.Header.Current = null;
        end loop;
      end if;

      if List.Header.Current = null then
          -- Element not found!
          End_Of_List := True;
      else
        -- Return found element!
        Element      := List.Header.Current.Element;
        End_Of_List := False;
      end if;
    end if;
  end Get;

  procedure Remove_From_Head (List       : in List_Type; 
                              Element    : out Element_Type;
                              End_Of_List: out Boolean) is
    Cell: Cell_Pointer_Type;
  begin
    if not List.Is_Legal then
      raise Illegal_List;
    elsif not List.Is_Legal then
      End_Of_List := True;
    else      
      Cell := List.Header.Head;
      if List.Header.Head = List.Header.Tail then
        --
        -- No more elements left in the list.
        --
        List.Header.Head := null;
        List.Header.Tail := null;
      else
        List.Header.Head.Next.Previous := null;
        List.Header.Head := List.Header.Head.Next;
      end if;
      Element := Cell.Element;
      Free(Cell);
      List.Header.Count := List.Header.Count - 1;      
      End_Of_List := False;
    end if;
  end Remove_From_Head;


  procedure Remove_From_Head (List: in List_Type; Element: out Element_Type) is
    End_Of_List: Boolean;
  begin
    Remove_From_Head (List, Element, End_Of_List);
    if End_Of_List then
      raise Illegal_List;
    end if;
  end Remove_From_Head;


  procedure Remove_From_Tail (List       : in List_Type; 
                              Element    : out Element_Type;
                              End_Of_List: out Boolean) is
    Cell: Cell_Pointer_Type;
  begin
    if not List.Is_Legal then
      raise Illegal_List;
    elsif List.Header.Tail = null then
      End_Of_List := True;
    else      
      Cell := List.Header.Tail;
      if List.Header.Head = List.Header.Tail then
        --
        -- No more elements left in the list.
        --
        List.Header.Head := null;
        List.Header.Tail := null;
      else
        List.Header.Tail.Previous.Next := null;
        List.Header.Tail := List.Header.Tail.Previous;
      end if;
      Element := Cell.Element;
      Free(Cell);
      List.Header.Count := List.Header.Count - 1;      
      End_Of_List := False;
    end if;
  end Remove_From_Tail;


  procedure Remove_From_Tail (List: in List_Type; Element: out Element_Type) is
    End_Of_List: Boolean;
  begin
    Remove_From_Tail (List, Element, End_Of_List);
    if End_Of_List then
      raise Illegal_List;
    end if;
  end Remove_From_Tail;


  procedure Remove_All (List: in List_Type) is
    Cell: Cell_Pointer_Type;
  begin
    if not List.Is_Legal then
      raise Illegal_List;
    else
      while List.Header.Head /= null loop
        Cell             := List.Header.Head;
        List.Header.Head := List.Header.Head.Next;
        Free(Cell);
      end loop;
      List.Header.Head  := null;
      List.Header.Tail  := null;
      List.Header.Count := 0;
    end if;
  end Remove_All;


  --v9.5-10139 New procedure
  procedure Update (List: in List_Type; Element : in Element_Type) is
  begin
    List.Header.Current.Element := Element;
  end Update;

  --v9.5-10139 New procedure
  procedure Delete (List: in List_Type) is
    Cell: Cell_Pointer_Type;
  begin
    if not List.Is_Legal then
      raise Illegal_List;
    elsif not List.Is_Legal then
      null;
    else      
      Cell := List.Header.Current;
      if List.Header.Head = List.Header.Current and
         List.Header.Tail = List.Header.Current then
        -- Element to be deleted is the only element in the list
        List.Header.Head := null;
        List.Header.Tail := null;
      elsif List.Header.Head = List.Header.Current then
        -- Element to be deleted is first in list
        List.Header.Head.Next.Previous := null;
        List.Header.Head := List.Header.Head.Next;
      elsif List.Header.Tail = List.Header.Current then
        -- Element to be deleted is last in list
        List.Header.Tail.Previous.Next := null;
        List.Header.Tail := List.Header.Tail.Previous;
      else
        -- Element to be deleted is in the middle of the list
        List.Header.Current.Next.Previous := List.Header.Current.Previous;
        List.Header.Current.Previous.Next := List.Header.Current.Next;
      end if;
      List.Header.Current := List.Header.Current.Previous;
      Free(Cell);
      List.Header.Count := List.Header.Count - 1;      
    end if;
  end Delete;

  function Is_Empty (List: List_Type) return Boolean is
  begin
    if not List.Is_Legal then
      raise Illegal_List;
    else
      return List.Header.Count = 0;
    end if;
  end Is_Empty;


  function Get_Count (List: List_Type) return Natural is
  begin
    if not List.Is_Legal then
      raise Illegal_List;
    else
      return List.Header.Count;
    end if;
  end Get_Count;

  overriding procedure Finalize (List : in out List_Type) is
  begin
     Release_Automatically(List);
  end Finalize;
  
  
end Simple_List_Class;
