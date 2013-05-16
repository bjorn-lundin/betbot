
with Races;

with Sattmate_Types ; use Sattmate_Types;

package Hitrates is

  type Commission_Type is new Float_8 range 0.0 .. 5.0;

  Betfair_Commission : constant Commission_Type := 0.05;
  No_Commission      : constant Commission_Type := 0.00;

  function Needed_Backbet_Hitrate(Price : Races.Price_Type; Commission : Commission_Type) return Float_8;
  function Needed_Laybet_Hitrate(Price : Races.Price_Type; Commission : Commission_Type) return Float_8;

end Hitrates ;
