
select p.*,  r.runnername 
from aprices p, 
     arunners r, 
     amarkets m, 
     aevents e, 
     awinners w
where p.marketid = r.marketid
and p.marketid = w.marketid
and p.selectionid = r.selectionid
and w.selectionid = p.selectionid
and p.marketid = m.marketid
and e.eventid = m.eventid
and e.eventtypeid=7
and e.countrycode = 'GB'
and m.markettype='WIN'
order by p.backprice desc
limit 1000