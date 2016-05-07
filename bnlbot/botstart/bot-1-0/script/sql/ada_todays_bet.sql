select R.STATUS, B.* 
--select sum(b.profit)
from ABETS B, ARUNNERS R
where B.STARTTS::date = (select current_date)
and  B.MARKETID = R.MARKETID
and B.SELECTIONID = R.SELECTIONID
--and b.status = 'SETTLED'
--and B.SIDE = 'BACK'
--and betname like '%PLC'
--and betname not in ('BACK_1_50_30_1_4_PLC','BACK_1_10_07_1_2_PLC')
order by  betplaced ,betname, pricematched ,B.STARTTS

