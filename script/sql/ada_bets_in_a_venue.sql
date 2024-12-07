

select 
  substring(eventname from E'^\\w+') venue,
  extract(dow from B.STARTTS::date) weekday,
  round(Sum(profit)::numeric,2) profit,
  count('a') cnt
from ABETS B, ALL_EVENTS E, ALL_MARKETS M
where B.STATUS='SETTLED'
and B.STARTTS::date >= '2014-01-01'
and B.BETNAME like '%BACK%FINISH%'
and B.BETNAME not like 'MR%'
and B.MARKETID = M.MARKETID
and M.EVENTID = E.EVENTID
--and extract(dow from B.STARTTS::date) not in (1,2,6)
--and substring(eventname from E'^\\w+') not in ('Navan','Sthl','Weth','Extr','Sand','Wolv','Leic','Clon','Ling','Donc','Carl','Strat','Muss','Ayr','Hayd')
group by
  substring(eventname from E'^\\w+') ,
  extract(dow from B.STARTTS::date) 
--and substring(eventname from E'^\\w+') = 'Navan'

order by 
  Sum(profit)
