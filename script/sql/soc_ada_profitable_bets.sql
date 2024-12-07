select 
  sum(count),
  round(avg(avgprofit)::numeric, 2) as avgprofit,
  sum(sumprofit)as sumprofit,
  round(avg(avgpricem)::numeric, 2) as avgpricem,
  round(avg(avgsizem)::numeric, 2) as avgsizem,
  round(avg(interest_rate_pct)::numeric, 2) as interest_rate_pct,
  min(mindate),
  max(maxdate),
  max(days) as days,
  max(betsperday) as betsperday ,
  sum(profitperday) profitperday,
  betname from (
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
having max(betplaced) > '2016-01-01 00:00:00' 
and count('a') >= 0
order by
  sum(profit) desc,
  betname
) tmp

group by betname
order by sumprofit desc
--having sum(profit) > -0
