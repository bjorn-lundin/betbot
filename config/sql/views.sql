create or replace view PROFIT_PER_MARKET_AND_BETNAME as 
select 
  BETNAME,
  MARKETID,
  sum(PROFIT) SUM_PROFIT , 
  max(STARTTS) as STARTTS
from ABETS
where BETWON is not NULL  
  and STATUS = 'SETTLED'  
  and EXESTATUS = 'SUCCESS' 
group by 
  BETNAME,
  MARKETID
;  
  
  