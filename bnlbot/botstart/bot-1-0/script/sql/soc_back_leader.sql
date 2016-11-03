select 
  e.eventid, 
  e.eventname, 
  e.countrycode, 
  mmo3.marketid,
  mmo3.markettype,
  mmo3.totalmatched,
  rmo1.runnername,
  pmo1.backprice,
  pmo1.layprice,
  rmo3.runnername,
  pmo3.backprice,
  pmo3.layprice,
  rmo2.runnername,
  pmo2.backprice,
  pmo2.layprice
from amarkets mmo3, 
     arunners rmo3, 
     aprices pmo3, 
     amarkets mmo2, 
     arunners rmo2, 
     aprices pmo2, 
     amarkets mmo1, 
     arunners rmo1, 
     aprices pmo1, 
     aevents e
where 1=1
--enough money on game
--and mmo3.totalmatched > 700000
and mmo3.status = 'OPEN'
and mmo3.betdelay > 0 --in play
-- the_draw
and e.eventid = mmo3.eventid
and pmo3.marketid = mmo3.marketid
and rmo3.marketid = pmo3.marketid
and rmo3.selectionid = pmo3.selectionid
and mmo3.markettype = 'MATCH_ODDS'
and pmo3.selectionid = rmo3.selectionid
and rmo3.runnernamenum = '3'   -- the_draw 
and pmo3.backprice >= 10   -- the_draw 
-- away team
and e.eventid = mmo2.eventid
and pmo2.marketid = mmo2.marketid
and rmo2.marketid = pmo2.marketid
and rmo2.selectionid = pmo2.selectionid
and mmo2.markettype = 'MATCH_ODDS'
and pmo2.selectionid = rmo2.selectionid
and rmo2.runnernamenum = '2'   --away
and pmo2.backprice >= 6  -- away underdogs
-- home team
and e.eventid = mmo1.eventid
and pmo1.marketid = mmo1.marketid
and rmo1.marketid = pmo1.marketid
and rmo1.selectionid = pmo1.selectionid
and mmo1.markettype = 'MATCH_ODDS'
and pmo1.selectionid = rmo1.selectionid
and rmo1.runnernamenum = '1'   --home
and pmo1.backprice <= 1.25   -- home favs
and abs(pmo1.layprice - pmo1.backprice) <= 0.05 -- say 1.10/1.12
---- no previous bets on MATCH_ODDS
and not exists (select 'x' from abets where abets.marketid = mmo1.marketid)
order by mmo1.startts, e.eventname;

