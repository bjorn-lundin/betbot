


with Races;
with Sattmate_Types ; use Sattmate_Types;

package Hitrates is

  function Needed_Backbet_Hitrate(Price : Races.Price_Type) return Float_8;
  function Needed_Laybet_Hitrate(Price : Races.Price_Type) return Float_8;

end Hitrates ;
