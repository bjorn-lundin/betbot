select R.STATUS, B.* 
--select sum(b.profit)
from ABETS B, ARUNNERS R
where B.STARTTS::date = (select current_date)
and  B.MARKETID = R.MARKETID
and B.SELECTIONID = R.SELECTIONID
and b.status != 'SETTLED'
order by  betplaced ,betname, pricematched ,B.STARTTS

