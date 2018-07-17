with Ada.Containers.Hashed_Maps;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Strings.Hash;

with Gnat; use Gnat;
with Gnat.Awk;
with Text_Io; use Text_Io;

with Calendar2; use Calendar2;
with Types; use Types;
with Bot_types; use Bot_types;

procedure Show_Race_Lengths is

  Computer_File : Awk.Session_Type;

  --subtype Marketname_Type is String(1..50);

  type Stats_Type is record
    Marketid   : Marketid_Type := (others => ' ');
    Time       : Interval_Type := (0,0,0,0,0);
  end record ;

  package Race_Length_Pack is new Ada.Containers.Doubly_Linked_Lists(Stats_Type);

  package Stats is new Ada.Containers.Hashed_Maps
        (Marketname_Type,
         Race_Length_Pack.List,
         Ada.Strings.Hash,
         "=",
         Race_Length_Pack."=");

  The_Map : Stats.Map;

  -----------------------------------------------------
  function To_Interval(S2: String) return Calendar2.Interval_Type is
    Tmp : Interval_Type;
    S : String (1.. S2'Length) := S2;
  begin
    -- '02:29.585'

    Tmp.Days := 0;
    Tmp.Hours := 0;
    Tmp.Minutes := Minute_Type'Value (S (1 .. 2));
    Tmp.Seconds :=  Minute_Type'Value (S (4 .. 5));
    Tmp.Milliseconds := Millisecond_Type'Value(S(7..9));
    return Tmp;
  end To_Interval;
  -----------------------------------------------------

begin
  Awk.Set_Current (Computer_File);
  Awk.Open (Separators => "|",
            Filename   => "/home/bnl/bnlbot/botstart/user/bnl/log/race_length.dat");

  while not Awk.End_Of_File loop
    Awk.Get_Line;
    declare
     L :  Race_Length_Pack.List;
     S : Stats_Type;
     Key :  Marketname_Type := Awk.Field(4);
    begin
      if Awk.Field(2) = "datapoint" then
      S.Time  := To_Interval(Awk.Field(2));
      S.Marketid := Awk.Field(3);
      if The_Map.Contains(Key) then
        The_Map(Key).Append(S);
      else
        L.Append(S);
        The_Map.Insert(Key, L);
      end if;
      end if;
    end;
  --  Put_Line(Awk.Field(2) & " -> " & Awk.Field(3) & " -> " &Awk.Field(4)) ;
  end loop;
  Awk.Close (Computer_File);

  for M in The_Map.Iterate loop
   -- Put_Line("Key " & Stats.Key(M)) ;
    declare
      S : Seconds_Type := 0;
      F : Integer_4 := 0;
    begin
      for List_Element of Stats.Element(M) loop
        --Put_Line("   -   " & String_Interval(List_Element.Time, Days => False, Hours => False) & " -> " & List_Element.Marketid) ;
        S := S + To_Seconds(List_Element.Time);
      end loop;
      F := S / Seconds_Type(stats.Element(M).Length);
      S := Seconds_Type(F);
      Put_Line("Key " & Stats.Key(M) & " avg: " & String_Interval(To_Interval(S), Days => False, Hours => False) & " #-> " & Stats.Element(M).Length'Img) ;
    end ;
  end loop;

end Show_Race_Lengths;
