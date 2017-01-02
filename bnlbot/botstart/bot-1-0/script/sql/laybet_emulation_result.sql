-- assume 100:- as laybet
select 
  betname,
  startts::date, 
  side,   
  betwon,
  count('a') as cnt,
  sum(
  case betwon
    when false then -100*(price-1.0)
    when true  then 93.5 
  end
  ) as sp
from ABETS 
where 1=1
and side = 'LAY'
and startts > '2017-01-01 00:00:00'
group by betname, startts::date, side, betwon 
order by betname, startts::date, side, betwon

