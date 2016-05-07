

select 
  --B.betname,
  count('a') num_bets, 
  min(B.STARTTS)::date min_startts, 
  max(B.STARTTS)::date max_startts, 
  round(sum(B.PROFIT)::numeric,2) sum_profit,
  --B.Startts::date as date,
  substring(eventname from E'^\\w+') venue,
  extract(ISODOW From B.STARTTS) weekday 
from ABETS B, ALL_EVENTS E, ALL_MARKETS M
where B.STATUS='SETTLED'
and B.STARTTS::date >= '2014-01-01'
and B.BETNAME = 'HORSES_PLC_BACK_FINISH_1.10_7.0_1'
and B.BETNAME not like 'MR%'
and B.MARKETID = M.MARKETID
and M.EVENTID = E.EVENTID
and  extract(ISODOW From B.STARTTS) = 6
group by venue,
--B.Startts::date
weekday
--having sum(B.PROFIT) < 0
--and count('a') > 30
order by 
 sum_profit,
 venue --,
 --B.Startts::date
-- weekday,
