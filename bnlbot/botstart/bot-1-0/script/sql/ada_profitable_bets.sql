select
  count('a'),
  round(avg(profit)::numeric, 2) as avgprofit,
  round(sum(profit)::numeric, 2) as sumprofit,
  round(sum(
    case when betwon 
       then profit*0.935
       else profit
    end),2) profit2, 
  round(avg(pricematched)::numeric, 3) as avgpricem,
--  round(avg(sizematched)::numeric,0) as avgsizem,
  round((case SIDE 
     when 'BACK' then avg(sizematched)
     when 'LAY'  then avg(sizematched) * (avg(pricematched)-1)
     else 0.0
  end)::numeric,0) as avgsizem,

 -- round((sum(profit)*100/sum(sizematched))::numeric,2) as interest_rate_pct,
  round((case SIDE 
     when 'BACK' then --sum(profit)*100/sum(sizematched) 
      round((100.0 * 
      sum(
          case when betwon 
            then profit*0.935
            else profit
          end)/sum(sizematched)),2) 
     when 'LAY'  then --sum(profit)*100/(count('a') * avg(sizematched) * (avg(pricematched)-1))
      round((100.0 * 
      sum(
          case when betwon 
            then profit*0.935
            else profit
          end)/sum(sizematched)),2) 
     else 0.0
  end)::numeric,2) as rate_pct,
  round(sum(sizematched),0) as sumsm,
  min(betplaced)::date as mindate,
  max(betplaced)::date as maxdate,
  max(betplaced)::date - min(betplaced)::date  + 1 as days, 
  round(count('a')/(max(betplaced)::date - min(betplaced)::date  + 1)::numeric,2) as betsperday, 
  round((sum(profit)/(max(betplaced)::date - min(betplaced)::date  + 1))::numeric, 2) as profitperday,
  side,
  betname
from
  abets
where true
  and STATUS in ('SETTLED')
  and betwon is not null
  and betname not like 'DR%'
  and betname not like 'MR%'
group by
  betname,side
having true
and sum(profit) > 300
--and max(betplaced) > '2018-01-01 00:00:00' 
and count('a') >= 300
order by
  sum(profit) desc,
  betname
  ;

