select
  count('a'),
  round(sum(b.profit)::numeric,2) sum_profit,
  round(avg(b.price)::numeric,2) avg_price,
  b.betname,
  b.betwon
from
  abets b
where
      b.STATUS = 'EXECUTION_COMPLETE'
  and b.betplaced::date >= (select CURRENT_DATE - interval '42 days')
  and b.betname like '%HO%'
  and betwon is not null
  and betmode =2
group by
  b.betname,
  b.betwon
order by
  b.betname,
  b.betwon;
