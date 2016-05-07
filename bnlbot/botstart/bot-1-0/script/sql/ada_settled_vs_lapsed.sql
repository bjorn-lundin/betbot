select sum(settled) s, sum(SETTLED_LAPSED) sl from 
(
  select count('a') settled, 0 SETTLED_LAPSED
  from ABETS 
  where BETNAME='BACK_1_10_07_1_2_PLC'
  and STATUS in ('SETTLED') 
  and  betplaced::date > (select CURRENT_DATE - interval '7 days')
) tmp1
union 
(
  select 0 settled, count('a') SETTLED_LAPSED
  from ABETS 
  where BETNAME='BACK_1_10_07_1_2_PLC'
  and STATUS in ('SETTLED', 'LAPSED') 
  and  betplaced::date > (select CURRENT_DATE - interval '7 days')
)

 