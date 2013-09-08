select
  count('a'),
  round(avg(b.profit)::numeric, 2) as avgprofit,
  round(sum(b.profit)::numeric, 2) as sumprofit,
  round(avg(b.price)::numeric, 2) as avgprice,
  min(b.startts)::date as mindate,
  max(b.startts)::date as maxdate,
  max(b.startts)::date - min(b.startts)::date  + 1 as days, 
  round(count('a')/(max(b.startts)::date - min(b.startts)::date  + 1)::numeric,2) as betsperday, 
  round((sum(profit)/(max(b.startts)::date - min(b.startts)::date  + 1))::numeric, 2) as profitperday,
  e.countrycode,
  b.powerdays,
  b.betmode,
  b.betname ,
  case 
    when b.betname like '%LAY%' then round((sum(b.profit)/(avg(b.size) * ((avg(b.price) -1))))::numeric, 2)
    else round((sum(b.profit) / avg(b.size) )::numeric, 2)
  end as profit_riskratio  
--  round(sum(m.totalmatched)::numeric, 2) as totalmatched
from
  abets b, amarkets m, aevents e
where
  b.startts::date > (select current_date - interval '420 days')
  and b.status = 'EXECUTION_COMPLETE'
  and b.betwon is not null
  and b.betname not like '%GO'
  and b.betname like '%HOUN%'
  and betmode= 3  
  and b.marketid = m.marketid
  and m.eventid = e.eventid
group by
  e.countrycode,
  b.betname,
  b.powerdays,
  b.betmode
having sum(b.profit) > -100000.0
order by
--  profit_riskratio desc,
  sumprofit desc,
  b.betname
  ;

