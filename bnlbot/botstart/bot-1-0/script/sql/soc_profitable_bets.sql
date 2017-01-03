select
  count('a'),
  round(avg(profit)::numeric, 2) as avgprofit,
  round(sum(profit)::numeric, 2) as sumprofit,
  round(avg(pricematched)::numeric, 3) as avgpricem,
  round(avg(sizematched)::numeric,0) as avgsizem,
  round((sum(profit)*100/sum(sizematched))::numeric,2) as interest_rate_pct,
  min(betplaced)::date as mindate,
  max(betplaced)::date as maxdate,
  max(betplaced)::date - min(betplaced)::date  + 1 as days, 
  round(count('a')/(max(betplaced)::date - min(betplaced)::date  + 1)::numeric,2) as betsperday, 
  round((sum(profit)/(max(betplaced)::date - min(betplaced)::date  + 1))::numeric, 2) as profitperday,
  betname
from
  abets
where STATUS in ('MATCHED','SETTLED')
  and betwon is not null
group by
  betname
having sum(profit) > -0
and max(betplaced) > '2016-01-01 00:00:00' 
and count('a') >= 10
order by
  sum(profit) desc,
  betname
  ;

