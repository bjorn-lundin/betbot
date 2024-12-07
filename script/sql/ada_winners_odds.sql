
select p.*,  r.runnername 
from aprices p, 
     arunners r, 
     amarkets m, 
     aevents e
where p.marketid = r.marketid
and p.selectionid = r.selectionid
and p.marketid = m.marketid
and e.eventid = m.eventid
and e.eventtypeid=7
and e.countrycode in ('GB', 'IE')
and m.markettype='WIN'
and r.status = 'WINNER'
order by p.backprice desc
limit 1000