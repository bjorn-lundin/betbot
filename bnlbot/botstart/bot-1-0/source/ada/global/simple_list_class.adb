------------------------------------------------------------------------------
--                                                                          --
--                        Simple_List_Class                                 --
--                                                                          --
--                                 Body                                     --
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

with Unchecked_Deallocation;
package body Simple_List_Class is

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

  procedure Update (List: in List_Type; Element : in Element_Type) is
  begin
    List.Header.Current.Element := Element;
  end Update;

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
