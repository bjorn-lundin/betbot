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
  b.betname --,
--  round(sum(m.totalmatched)::numeric, 2) as totalmatched
from
  abets b, amarkets m, aevents e
where
  b.startts::date > (select current_date - interval '42 days')
  and b.status = 'EXECUTION_COMPLETE'
  and b.betwon is not null
  and b.betname like '%HO%'
  and b.marketid = m.marketid
  and m.eventid = e.eventid
group by
  e.countrycode,
  b.betname
having sum(b.profit) > -0.0
order by
--  count desc ,
  sum(b.profit) desc,
  b.betname
  ;

