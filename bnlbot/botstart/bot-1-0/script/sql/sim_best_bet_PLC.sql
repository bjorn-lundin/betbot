select
  betname,
  max(startts) max_startts,
  round(avg(sizematched),2) avg_size,
  round(avg(
      case when betwon 
         then pricematched
      end),2) avg_pricematched2,
  round(avg(pricematched),2) avg_pricematched,
  --extract(year from betplaced) yr,
  --extract(week from betplaced) wk,
  count('a'), 
  sum(profit) profit,
  round(sum(
    case when betwon 
       then profit*0.935
       else profit
    end),2) profit2, 
  round((100.0 * sum(profit)/sum(sizematched)),2) rate,
  round((100.0 * 
    sum(
      case when betwon 
         then profit*0.935
         else profit
      end)/
      sum(sizematched)),2) rate2
from abets
where true  
and status = 'MATCHED'
--and betname like '%1.28%00.00%'
group by betname --,yr, wk
order by -- betname,
profit2 desc
-- betname,max(startts),  --, yr, wk
