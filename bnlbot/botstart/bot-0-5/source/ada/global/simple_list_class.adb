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

package body Simple_List_Class is

   type Cell_Type;

   type Cell_Pointer_Type is access Cell_Type;

   type Cell_Type is
      record
         Element  : Element_Type;
         Next     : Cell_Pointer_Type;
         Previous : Cell_Pointer_Type;
      end record;

   type Attribute_Type is
      record
         Head    : Cell_Pointer_Type;
         Tail    : Cell_Pointer_Type;
         Current : Cell_Pointer_Type;
         Count   : Natural;
      end record;

   procedure Free is new Unchecked_Deallocation (Object => Cell_Type,
                                                 Name   => Cell_Pointer_Type);

   procedure Free is new Unchecked_Deallocation (Object => Attribute_Type,
                                                 Name   => List_Type);

   function Create return List_Type is
   begin
      return new Attribute_Type'(Head    => null,
                                 Tail    => null,
                                 Current => null,
                                 Count   => 0);
   end Create;


   procedure Release (List : in out List_Type) is
   begin
      if (List /= null) then
         Remove_All (List);
         Free (List);
         List := null;
      end if;
   end Release;


   function Is_Legal (List : List_Type) return Boolean is
   begin
      return (List /= null);
   end Is_Legal;


   --v9.5-10139 New procedure
   procedure Put (List : in List_Type; Element : in Element_Type) is
      Cell : Cell_Pointer_Type;
   begin
      if (List = null) then
         raise Illegal_List;
      else

         -- Find sorting place in list for the element
         List.Current := List.Head;
         if List.Current /= null then
            while Relation_Operator (List.Current.Element, Element) loop
               List.Current := List.Current.Next;
               exit when List.Current = null;
            end loop;
         end if;

         if List.Current = null then
            if List.Head = null then
               --Empty list
               Cell := new Cell_Type'(Element  => Element,
                                      Next     => null,
                                      Previous => null);
               List.Head      := Cell;
               List.Tail      := Cell;
               List.Current   := Cell;
            else
               --Add element last in list
               Cell := new Cell_Type'(Element  => Element,
                                      Next     => null,
                                      Previous => List.Tail);
               List.Tail.Next := Cell;
               List.Tail      := Cell;
               List.Current   := Cell;
            end if;
         else
            -- Add element between 2 other element
            Cell := new Cell_Type'(Element  => Element,
                                   Next     => List.Current,
                                   Previous => List.Current.Previous);
            if List.Current = List.Head then
               -- add element first in list
               List.Head := Cell;
            else
               -- between 2 elements
               List.Current.Previous.Next := Cell;
            end if;
            List.Current.Previous      := Cell;
            List.Current               := Cell;
         end if;
         List.Count := List.Count + 1;
      end if;

   end Put;

   procedure Insert_At_Head (List : List_Type; Element : Element_Type) is
      Cell : Cell_Pointer_Type;
   begin
      if (List = null) then
         raise Illegal_List;
      else
         Cell := new Cell_Type'(Element  => Element,
                                Next     => List.Head,
                                Previous => null);
         if (List.Head = null) then
            --
            -- This will be the only element in the list
            --
            List.Tail := Cell;
         else
            List.Head.Previous := Cell;
         end if;
         List.Head  := Cell;
         List.Count := List.Count + 1;
      end if;
   end Insert_At_Head;


   procedure Insert_At_Tail (List : List_Type; Element : Element_Type) is
      Cell : Cell_Pointer_Type;
   begin
      if (List = null) then
         raise Illegal_List;
      else
         Cell := new Cell_Type'(Element  => Element,
                                Next     => null,
                                Previous => List.Tail);
         if (List.Tail = null) then
            --
            -- This will be the only element in the list
            --
            List.Head := Cell;
         else
            List.Tail.Next := Cell;
         end if;
         List.Tail := Cell;
         List.Count := List.Count + 1;
      end if;
   end Insert_At_Tail;


   procedure Get_First (List        : List_Type;
                        Element     : out Element_Type;
                        End_Of_List : out Boolean) is
   begin
      if (List = null) then
         raise Illegal_List;
      elsif (List.Count = 0) then
         End_Of_List := True;
      else
         Element      := List.Head.Element;
         List.Current := List.Head;
         End_Of_List  := False;
      end if;
   end Get_First;


   procedure Get_Next (List        : List_Type;
                       Element     : out Element_Type;
                       End_Of_List : out Boolean) is
   begin
      if (List = null) then
         raise Illegal_List;
      elsif (List.Current = null) then
         End_Of_List := True;
      elsif (List.Current.Next = null) then
         End_Of_List := True;
      else
         List.Current := List.Current.Next;
         Element      := List.Current.Element;
         End_Of_List  := False;
      end if;
   end Get_Next;


   --v9.5-10139 New procedure
   procedure Get (List             : in List_Type;
                  Element          : in out Element_Type;
                  End_Of_List      : out Boolean;
                  Continue_In_List : in Boolean := False) is
   begin
      if (List = null) then
         raise Illegal_List;
      else

         if not Continue_In_List or else
           List.Current = null then         -- v9.7-13984
            List.Current := List.Head;
         else
            List.Current := List.Current.Next;
         end if;

         -- Try to find element
         if List.Current /= null then
            while not Is_Equal (List.Current.Element, Element) loop
               List.Current := List.Current.Next;
               exit when List.Current = null;
            end loop;
         end if;

         if List.Current = null then
            -- Element not found!
            End_Of_List := True;
         else
            -- Return found element!
            Element      := List.Current.Element;
            End_Of_List := False;
         end if;
      end if;
   end Get;

   procedure Remove_From_Head (List        : List_Type;
                               Element     : out Element_Type;
                               End_Of_List : out Boolean) is
      Cell : Cell_Pointer_Type;
   begin
      if (List = null) then
         raise Illegal_List;
      elsif (List.Head = null) then
         End_Of_List := True;
      else
         Cell := List.Head;
         if (List.Head = List.Tail) then
            --
            -- No more elements left in the list.
            --
            List.Head := null;
            List.Tail := null;
         else
            List.Head.Next.Previous := null;
            List.Head := List.Head.Next;
         end if;
         Element := Cell.Element;
         Free (Cell);
         List.Count := List.Count - 1;
         End_Of_List := False;
      end if;
   end Remove_From_Head;


   procedure Remove_From_Head (List : List_Type; Element : out Element_Type) is
      End_Of_List : Boolean;
   begin
      Remove_From_Head (List, Element, End_Of_List);
      if (End_Of_List) then
         raise Illegal_List;
      end if;
   end Remove_From_Head;


   procedure Remove_From_Tail (List        : List_Type;
                               Element     : out Element_Type;
                               End_Of_List : out Boolean) is
      Cell : Cell_Pointer_Type;
   begin
      if (List = null) then
         raise Illegal_List;
      elsif (List.Tail = null) then
         End_Of_List := True;
      else
         Cell := List.Tail;
         if (List.Head = List.Tail) then
            --
            -- No more elements left in the list.
            --
            List.Head := null;
            List.Tail := null;
         else
            List.Tail.Previous.Next := null;
            List.Tail := List.Tail.Previous;
         end if;
         Element := Cell.Element;
         Free (Cell);
         List.Count := List.Count - 1;
         End_Of_List := False;
      end if;
   end Remove_From_Tail;


   procedure Remove_From_Tail (List : List_Type; Element : out Element_Type) is
      End_Of_List : Boolean;
   begin
      Remove_From_Tail (List, Element, End_Of_List);
      if (End_Of_List) then
         raise Illegal_List;
      end if;
   end Remove_From_Tail;


   procedure Remove_All (List : List_Type) is
      Cell : Cell_Pointer_Type;
   begin
      if (List = null) then
         raise Illegal_List;
      else
         while (List.Head /= null) loop
            Cell      := List.Head;
            List.Head := List.Head.Next;
            Free (Cell);
         end loop;
         List.Head  := null;
         List.Tail  := null;
         List.Count := 0;
      end if;
   end Remove_All;


   --v9.5-10139 New procedure
   procedure Update (List : List_Type; Element : in Element_Type) is
   begin
      List.Current.Element := Element;
   end Update;

   --v9.5-10139 New procedure
   procedure Delete (List : List_Type) is
      Cell : Cell_Pointer_Type;
   begin
      if (List = null) then
         raise Illegal_List;
      elsif (List.Head = null) then
         null;
      else
         Cell := List.Current;
         if List.Head = List.Current and
           List.Tail = List.Current then
            -- Element to be deleted is the only element in the list
            List.Head := null;
            List.Tail := null;
         elsif List.Head = List.Current then
            -- Element to be deleted is first in list
            List.Head.Next.Previous := null;
            List.Head := List.Head.Next;
         elsif List.Tail = List.Current then
            -- Element to be deleted is last in list
            List.Tail.Previous.Next := null;
            List.Tail := List.Tail.Previous;
         else
            -- Element to be deleted is in the middle of the list
            List.Current.Next.Previous := List.Current.Previous;
            List.Current.Previous.Next := List.Current.Next;
         end if;
         List.Current := List.Current.Previous;
         Free (Cell);
         List.Count := List.Count - 1;
      end if;
   end Delete;

   function Is_Empty (List : List_Type) return Boolean is
   begin
      if (List = null) then
         raise Illegal_List;
      else
         return List.Count = 0;
      end if;
   end Is_Empty;


   function Get_Count (List : List_Type) return Natural is
   begin
      if (List = null) then
         raise Illegal_List;
      else
         return List.Count;
      end if;
   end Get_Count;

end Simple_List_Class;
