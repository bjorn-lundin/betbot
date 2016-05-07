select
  Side,
  extract(year from startts ) as year ,
  extract(month from startts ) as month ,
  round(sum(sizematched),0)::numeric as matched,
  round(sum(profit) * 0.935,0)::numeric  as profit,
  round(sum(profit)*100*0.935/sum(sizematched),2) as profit_matched
from abets
where startts::date >= '2010-01-01'
and status = 'SETTLED'
--and side ='BACK'
group by side,extract(year from startts ) , extract(month from startts)
order by side,extract(year from startts ) desc , extract(month from startts) desc

    