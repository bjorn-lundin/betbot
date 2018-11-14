select
  betname,
  round(avg(sizematched),2) size,
  --extract(year from betplaced) yr,
  --extract(week from betplaced) wk,
 count('a'), 
  sum(profit) profit,
  round(sum(
    case when betwon then profit*0.935
       else profit
    end),2) profit2, 
  round((100.0 * sum(profit)/sum(sizematched)),2) rate,
  round((100.0 * 
    sum(
      case when betwon then profit*0.935
         else profit
      end)/
      sum(sizematched)),2) rate2
from abets
where true  
and status = 'MATCHED'
and betname like 'WIN%'
--and betplaced > '2018-09-01'
group by betname --,yr, wk
order by profit2 desc
-- betname --, yr, wk
