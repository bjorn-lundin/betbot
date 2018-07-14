select R.STATUS,B.* 
--select 
--  --betwon,
--  sum(b.profit) sum_profit, 
--  sum(b.sizematched) sum_matched,
--  round(avg(b.pricematched),3) avg_price,
--  count('a'),
--  betname,
--  round( (100 * sum(b.profit) ) / sum(b.sizematched),2) risk
from ABETS B
     , ARUNNERS R
where true
and B.STARTTS::date = (select current_date) 
and B.MARKETID = R.MARKETID
and B.SELECTIONID = R.SELECTIONID
and b.status = 'SETTLED'
and b.pricematched >= 1.01
--and betname like '%HIGH%'
--and side = 'BACK'
--group by betname --, betwon
--order by betname -- , betwon
order by  B.startts, B.betplaced

