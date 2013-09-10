select
  count('a'),
  round(avg(profit)::numeric, 2) as avgprofit,
  round(sum(profit)::numeric, 2) as sumprofit,
  round(avg(price)::numeric, 2) as avgprice,
  min(betplaced)::date as mindate,
  max(betplaced)::date as maxdate,
  max(betplaced)::date - min(betplaced)::date  + 1 as days, 
  round(count('a')/(max(betplaced)::date - min(betplaced)::date  + 1)::numeric,2) as betsperday, 
  round((sum(profit)/(max(betplaced)::date - min(betplaced)::date  + 1))::numeric, 2) as profitperday,
  betname
from
  abets
where
  betplaced::date > (select CURRENT_DATE - interval '42 days')
  and STATUS = 'EXECUTION_COMPLETE'
  and betwon is not null
  and betname like '%HO%'
  and betmode =2
group by
  betname
having sum(profit) > 0
order by
  sum(profit) desc,
  betname
  ;

