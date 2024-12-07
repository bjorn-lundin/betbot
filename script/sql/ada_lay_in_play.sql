select 
  B.BETNAME,
  R.STATUS,
 -- B.STATUS,
  count('a'), 
  round(min(price)::numeric,2) as min_price, 
  round(avg(price)::numeric,2) as avg_price, 
  round(max(price)::numeric,2) as max_price,
  min(startts)::date as minimal_date,
  max(startts)::date as maximal_date,
  round((case R.STATUS 
     when 'WINNER' then -count('a') * 30 *  avg(price)-1
     when 'LOSER'  then count('a') * 30 * 0.935
     else 0.0
  end)::numeric,2) as sum_profit
from ABETS B, ALL_RUNNERS R
where B.BETNAME in ('HORSES_WIN_LAY_FINISH_160_200_1',
                    'HORSES_WIN_LAY_FINISH_1.10_25.0_4')                
and B.MARKETID = R.MARKETID
and B.SELECTIONID = R.SELECTIONID
and R.STATUS in ('LOSER','WINNER')
and B.STATUS in ('SETTLED','EXECUTABLE','EXECUTION_COMPLETE')
group by
  B.BETNAME,
  R.STATUS
 -- B.STATUS
order by
  B.BETNAME,
  R.STATUS
 -- B.STATUS