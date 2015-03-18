select 
  E.EVENTNAME,
  -- M.*,
  -- R.*,
  RP.*
from
  AEVENTS E,
  AMARKETS M,
  APRICESFINISH RP,
  ARUNNERS R
where
  E.EVENTID = M.EVENTID              -- joins
  and M.MARKETID = R.MARKETID        -- joins
  and M.MARKETID = RP.MARKETID       -- joins
  and R.SELECTIONID = RP.SELECTIONID -- joins
  and R.STATUS in ('WINNER','LOSER') -- eg not 'REMOVED' or something else
  and E.EVENTTYPEID = 7              -- horses
  and M.MARKETTYPE = 'WIN'           -- normal win market
order by RP.PRICETS, RP.MARKETID, RP.SELECTIONID
LIMIT 100 ;        
