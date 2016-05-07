--ALL_RUNNERS är bara från i år , ABETS är totalt ...
select 
  B.BETNAME,
  R.STATUS, 
  B.STATUS, 
  count('a'), 
  round(min(pricematched)::numeric,2) as min_price, 
  round(avg(pricematched)::numeric,2) as avg_price, 
  round(max(pricematched)::numeric,2) as max_price,
  min(startts)::date as minimal_date,
  max(startts)::date as maximal_date,
  round((case R.STATUS 
     when 'WINNER' then  count('a') * avg(sizematched) * (avg(pricematched)-1) * 0.935
     when 'LOSER'  then -count('a') * avg(sizematched) 
     else 0.0
  end)::numeric,2) as sum_profit
 -- round(sum(profit)::numeric,2) as sum_profit
  
from ABETS B, ALL_RUNNERS R
where 
    B.BETNAME like 'BACK%'
and B.MARKETID = R.MARKETID
and B.SELECTIONID = R.SELECTIONID
and R.STATUS in ('LOSER','WINNER')
and B.STATUS in ('SETTLED')--,'EXECUTABLE')
group by B.BETNAME , R.STATUS
, B.STATUS
--having max(BETPLACED)::date >= '2015-02-13'
order by B.BETNAME , R.STATUS , B.STATUS