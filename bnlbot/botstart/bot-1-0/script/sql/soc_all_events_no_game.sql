select *
from AEVENTS E, amarkets m, arunners r
where e.eventid = m.eventid 
and m.marketid = r.marketid
and r.selectionid > 30 
and r.runnername not in ('Any Other Home Win','Any Other Draw','Any Other Away Win','The Draw')
and m.markettype ='MATCH_ODDS'
order by e.eventid, countrycode, startts