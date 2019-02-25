
select
  betname,
  round(avg(sizematched),2) size,
  extract(year from betplaced) yr,
  extract(week from betplaced) wk,
 count('a'), 
  sum(profit) profit,
  round(sum(
    case when betwon then profit*0.935
       else profit
    end),2) profit2,
 
  round((100.0 * sum(profit)/sum(sizematched)),2) rate
from abets
where true  
and betname like '%PLC%'
and status = 'SETTLED'
and betplaced > '2018-11-01'
group by betname, yr, wk
order by yr, wk, betname, profit2 desc
--order by betname, yr, wk, profit2 desc
