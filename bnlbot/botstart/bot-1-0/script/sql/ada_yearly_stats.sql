select 
  extract(year from startts)::int as year,
  betwon,
  sum(sizematched) sum_sizematched,
  sum(profit)*0.935 sum_profit,
  avg(profit)*0.935 avg_profit,
  avg(sizematched) avg_sizematched,
  avg(pricematched) avg_pricematched,
  count('a') cnt --,
--  extract(week from startts)
from ABETS
where 1=1
and betname ='BACK_1_10_07_1_2_PLC'
and status = 'SETTLED'
--and extract(year from startts) = 2015
group by extract(year from startts), betwon
order by extract(year from startts), betwon
--group by  extract(week from startts)
--order by  extract(week from startts)