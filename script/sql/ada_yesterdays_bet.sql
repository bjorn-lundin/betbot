select b.* from
ABETS B, aevents E, amarkets M
where B.STARTTS::date = (select current_date -1 )
and e.eventid = m.eventid
and b.marketid = m.marketid
and b.status ='SETTLED'
--and b.profit < 0
order by b.betname, B.STARTTS


