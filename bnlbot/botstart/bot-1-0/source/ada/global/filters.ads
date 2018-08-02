
with Types; use Types;

package Filters is
  type Array_Type is array(1..10) of Fixed_Type;

--  type Filter_Type is tagged private ;
  type Filter_Type is tagged record
    Selectionid : Integer_4  := 0;
    Values      : Array_Type := (others => 0.0);
    Weights     : Array_Type := (others => 1.0); --(1.0,0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1);
    Mean        : Fixed_Type := 0.0;
  end record;

  procedure Add(Self : in out Filter_Type; Value : Fixed_Type);
  procedure Recalculate(Self : in out Filter_Type);

--private


end Filters;
