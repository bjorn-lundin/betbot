select 
  sum(cnt),
  sum(sum_profit) vinst,
  round(avg(pm),3)::numeric avg_odds,
  max(mx) mx,
  min(mn) mn,
  fi,
  si
from (
--         1         2
--12345678901234567890123456789
--BACK_1_51_1_55_01_04_1_2_PLC
select 
  count('a') cnt,
  betwon,
  max(betplaced) as mx,
  min(betplaced) as mn,
   round((case betwon
     when true then  sum(profit)* 0.935
     when false then sum(profit) 
     else 0.0
  end)::numeric,2) as sum_profit, 
  avg(pricematched) pm,
  SUBSTRING(betname from 6 for 9) fi,
  SUBSTRING(betname from 16 for 5) si
from abets
where 1=1
and betname like '%PLC%'
and status = 'SUCCESS'
group by si,fi,betwon
order by si,fi,betwon
) tmp
group by si,fi
order by -- si,fi
vinst desc 
--si,fi
