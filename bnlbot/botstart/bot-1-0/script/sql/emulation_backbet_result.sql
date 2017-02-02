-- assume 100:- as backbet
--group on marketid and day
with backbets as (
  select 
    betname,
    marketid,
    startts::date, 
    count('a') as cnt,
    sum(
    case betwon -- comission i slutet
      when false then -100
      when true  then  100*(price-1.0) 
      else 0
    end
    ) as SUM_PROFIT
  from ABETS 
  where true
  and betwon is not null
--  and status in ('SETTLED')
  and insterrcode in ('INVALID_BET_SIZE')
  and side = 'BACK'
  and startts > '2017-01-01 00:00:00'
  group by betname, marketid, startts::date
)
select 
  betname,
  startts::date,
  round(sum(
      case SUM_PROFIT > 0
        when TRUE  then SUM_PROFIT * (1.0 - (0.065))
        when FALSE then SUM_PROFIT
      end
   ),2) as profit_incl_commision, 
  round(sum(SUM_PROFIT),2) as profit_excl_commision, 
  sum(cnt) as cnt
from backbets
group by betname, startts::date 
order by startts::date desc,betname

