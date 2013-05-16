



package body Hitrates is
  use type Races.Price_Type;


  --------------------------------------------------
  function Needed_Backbet_Hitrate(Price : Races.Price_Type; Commission : Commission_Type) return Float_8 is
  begin
    return Float_8(1.0/((1.0 - Races.Price_Type(Commission)) * Price));
  end Needed_Backbet_Hitrate;
  --------------------------------------------------




  function Needed_Laybet_Hitrate(Price : Races.Price_Type; Commission : Commission_Type) return Float_8 is
  begin
    return Float_8((Price - 1.0)/((1.0 - Races.Price_Type(Commission)) * Price));
  end Needed_Laybet_Hitrate;
  --------------------------------------------------

end Hitrates ;
