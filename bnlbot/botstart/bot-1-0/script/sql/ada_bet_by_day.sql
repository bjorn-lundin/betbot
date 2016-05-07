select
  count('a'),
  round(avg(profit)::numeric, 2) as avgprofit,
  round(sum(profit)::numeric, 2) as sumprofit,
  round(avg(price)::numeric, 2) as avgprice,
  betplaced::date,
  betname
from
  abets
where
--  betplaced::date > (select CURRENT_DATE - interval '42 days')
  --and STATUS = 'EXECUTION_COMPLETE'
  --and 
  betwon is not null
 
group by
  betplaced::date,
  betname
order by
  betplaced::date desc,
  betname
  ;
