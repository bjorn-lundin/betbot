select 
  extract(year from startts)::int as year,
 -- betwon,
  sum(sizematched) sum_sizematched,
  round(sum(profit)*0.935,0)::numeric sum_profit,
  round(avg(profit)*0.935,2)::numeric avg_profit,
  round(avg(sizematched),2)::numeric avg_sizematched,
  round(avg(pricematched),3)::numeric avg_pricematched,
  count('a') cnt --,
--  extract(week from startts)
from ABETS
where 1=1
--and betname ='BACK_1_10_07_1_2_PLC_1_01'
and status = 'SETTLED'
--and extract(year from startts) = 2015
group by extract(year from startts)--, betwon
order by extract(year from startts)--, betwon
--group by  extract(week from startts)
--order by  extract(week from startts)