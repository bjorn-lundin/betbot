select
  count('a'),
  round(avg(profit)::numeric, 2) as avgprofit,
  round(sum(profit)::numeric, 2) as sumprofit,
  round(avg(price)::numeric, 2) as avgprice,
  extract(week from betplaced) as week,
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
  extract(week from betplaced),
  betname
--having sum(profit) > 0
order by
  betname,
  extract(week from betplaced) desc
  ;
