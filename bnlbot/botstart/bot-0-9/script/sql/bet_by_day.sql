select  
  count('a'),  
  round(avg(profit)::numeric,2) as avgprofit,  
  round(sum(profit)::numeric,2) as sumprofit,  
  round(avg(price)::numeric,2) as avgprice,  
  bet_placed::date,  
  bet_type
from  
  bet_with_commission
where
  event_date > (select current_date - interval '42 days')
  and CODE = 'S'
  and bet_type like '%HO%'
group by
  bet_placed::date,  
  bet_type
order by  
  bet_placed::date desc,  
  bet_type;

