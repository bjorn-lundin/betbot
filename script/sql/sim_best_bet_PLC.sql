select
  betname bname,
--  substring(betname,1,33) bname,
  min(startts) min_startts,
  max(startts) max_startts,
  round(avg(sizematched),2) avg_size,
  round(avg(
      case when betwon 
         then pricematched
      end),2) avg_pricematched2,
  round(avg(pricematched),2) avg_pricematched,
--  extract(year from betplaced) yr,
 -- extract(month from betplaced) wk,
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
and status = 'SETTLED'
and extract(year from betplaced) >= 2018
and betname like 'HORSE_BACK_1_%_1_2_PLC_1_01%'
group by bname --, yr --, wk
--having max(startts) > '2018-10-11'
order by bname --, yr --, wk
