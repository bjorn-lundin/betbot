select R.STATUS,B.* 
--select sum(b.profit), count('a'), betname
from ABETS B, ARUNNERS R
where 1=1
and B.STARTTS::date = (select current_date)
and B.MARKETID = R.MARKETID
and B.SELECTIONID = R.SELECTIONID
and b.status = 'SETTLED'
--and side = 'BACK'
--group by betname 
order by betplaced ,betname, pricematched ,B.STARTTS

