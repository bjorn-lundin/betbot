

package body Filters is

  procedure Add(Self : in out Filter_Type; Value : Fixed_Type) is
  begin
    for I in reverse Self.Values'First +1 .. Self.Values'Last loop
      Self.Values(I) := Self.Values(I-1);
    end loop;
    Self.Values(Self.Values'First) := Value;
  end Add;

  procedure Calculate(Self : in out Filter_Type) is
  begin
    Self.Mean := 0.0;
    for I in Self.Values'Range loop
      Self.Mean := Self.Mean + Self.Values(I) * Self.Weights(I);
    end loop;
    Self.Mean := Self.Mean / Fixed_Type(Self.Values'Length);
  end Calculate;


end Filters;
