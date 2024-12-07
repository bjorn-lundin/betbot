select 
  e.eventid, 
  e.eventname, 
  e.countrycode, 
  mcs.startts,
  mcs.marketid,
  mcs.markettype,
  pcs.backprice,
  mmo3.marketid,
  mmo3.markettype,
  rmo1.runnername,
  pmo1.backprice,
  pmo1.layprice,
  rmo3.runnername,
  pmo3.backprice,
  pmo3.layprice,
  rmo2.runnername,
  pmo2.backprice,
  pmo2.layprice
from aprices pcs, 
     amarkets mcs, 
     amarkets mmo3, 
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
-- enough money on game
and mmo3.totalmatched > 700000
and mmo3.status = 'OPEN'
and mmo3.betdelay > 0  --in play
-- probability for goals
and pcs.marketid = mcs.marketid
and e.eventid = mcs.eventid
and mcs.markettype = 'CORRECT_SCORE'
and pcs.selectionid = 1 
and pcs.backprice >= 15 -- 0-0
and pcs.backprice < 1000 -- 0-0
-- the_draw
and e.eventid = mmo3.eventid
and pmo3.marketid = mmo3.marketid
and rmo3.marketid = pmo3.marketid
and rmo3.selectionid = pmo3.selectionid
and mmo3.markettype = 'MATCH_ODDS'
and pmo3.selectionid = rmo3.selectionid
and rmo3.runnernamenum = '3'   -- the_draw 
and pmo3.layprice <= 7   -- the_draw 
-- away team
and e.eventid = mmo2.eventid
and pmo2.marketid = mmo2.marketid
and rmo2.marketid = pmo2.marketid
and rmo2.selectionid = pmo2.selectionid
and mmo2.markettype = 'MATCH_ODDS'
and pmo2.selectionid = rmo2.selectionid
and rmo2.runnernamenum = '2'   --away
and pmo2.backprice >= 8  -- away underdogs
-- home team
and e.eventid = mmo1.eventid
and pmo1.marketid = mmo1.marketid
and rmo1.marketid = pmo1.marketid
and rmo1.selectionid = pmo1.selectionid
and mmo1.markettype = 'MATCH_ODDS'
and pmo1.selectionid = rmo1.selectionid
and rmo1.runnernamenum = '1'   --home
and pmo1.backprice <= 1.7   -- home favs
---- no previous bets on CORRECT_SCORE nor on MATCH_ODDS
and not exists (select 'x' from abets where abets.marketid = mcs.marketid)
and not exists (select 'x' from abets where abets.marketid = mmo1.marketid)
order by mcs.startts, e.eventname;

