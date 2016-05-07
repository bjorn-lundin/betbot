﻿

select 
  betname,
  count('a') num_bets, 
  round(sum(PROFIT)::numeric,2) sum_profit, 
  extract(ISODOW From STARTTS)::int weekday
from ABETS
where STATUS='SETTLED'
and STARTTS::date >= '2015-01-01'
and BETNAME like 'BACK%'
group by betname,extract(ISODOW From STARTTS)
--having sum(PROFIT) < 0
--and count('a') > 30
order by 
  betname,
  extract(ISODOW From STARTTS), 
  sum(PROFIT)
