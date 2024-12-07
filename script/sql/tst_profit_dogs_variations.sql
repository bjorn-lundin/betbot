select 
min(betplaced),
max(betplaced),
sum(profit), 
reference 
from abets 
where betname like '2%' 
and status = 'M'
group by reference 
having sum(profit) > -100000 
order by 3 desc 
--limit 200;
