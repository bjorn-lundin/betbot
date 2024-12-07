select
  count('a'),
  round(avg(profit)::numeric, 2) as avgprofit,
  round(sum(profit)::numeric, 2) as sumprofit,
  round(avg(price)::numeric, 2) as avgprice,
  startts::date as marketts,
  betname
from
  abets
where 
  startts::date > (select CURRENT_DATE - interval '42 days')
  and STATUS = 'EXECUTION_COMPLETE'
  and betwon is not null
 and betname like '%HO%'
group by
  startts::date,
  betname
order by
  startts::date desc,
  betname
  ;
