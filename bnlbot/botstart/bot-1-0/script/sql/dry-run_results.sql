select
  side,
  round((case SIDE 
     when 'BACK' then 
       case betwon  
         when true  then (avg(price)-1) * 100 *0.935 * count('a')
         when false then -100 * count('a')
         else 0.0
        end
     when 'LAY'  then 
       case betwon  
         when true  then 100 *0.935 * count('a')
         when false then -(avg(price)-1) * 100 * count('a')
         else 0.0
        end
     else 0.0
  end)::numeric,2) as profit,
  count('a'), 
  betname,
  betwon,
  round(avg(price),2) as avg_price
from ABETS B
where 1=1
and B.STARTTS::date = (select current_date)
group by betname, betwon, side
order by betname, betwon
