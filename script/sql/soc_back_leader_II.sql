select e.eventname, e.countrycode, m.*
from aevents e, amarkets m
where m.eventid=e.eventid
and m.markettype='MATCH_ODDS'
and m.status ='OPEN'
and m.betdelay > 0
order by opents