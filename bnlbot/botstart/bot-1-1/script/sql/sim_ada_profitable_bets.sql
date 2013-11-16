select
  count('a'),
  round(avg(profit)::numeric, 2) as avgprofit,
  round(sum(profit)::numeric, 2) as sumprofit,
  round(avg(price)::numeric, 2) as avgprice,
  min(startts)::date as mindate,
  max(startts)::date as maxdate,
  max(startts)::date - min(startts)::date  + 1 as days, 
  round(count('a')/(max(startts)::date - min(startts)::date  + 1)::numeric,2) as betsperday, 
  round((sum(profit)/(max(startts)::date - min(startts)::date  + 1))::numeric, 2) as profitperday,
  betname
from
  abets
where
  startts::date > (select CURRENT_DATE - interval '42 days')
  and STATUS = 'EXECUTION_COMPLETE'
  and betwon is not null
  and betname like '%HO%'
group by
  betname
having sum(profit) > 0
order by
  sum(profit) desc,
  betname
  ;

