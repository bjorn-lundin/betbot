
with Types; use Types;

package Filters is

  type Filter_Type is tagged private ;
  procedure Add(Self : in out Filter_Type; Value : Fixed_Type);
  procedure Calculate(Self : in out Filter_Type);

private
  type Array_Type is array(1..10) of Fixed_Type;
  type Filter_Type is tagged record
    Values : Array_Type := (others => 0.0);
    Weights : Array_Type := (1.0,0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1);
    Mean   : Fixed_Type;
  end record;

end Filters;
