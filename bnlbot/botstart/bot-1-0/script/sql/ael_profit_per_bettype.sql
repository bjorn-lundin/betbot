select
  betname,
  count('a'),
  sum(profit)
from abets
group by betname
order by sum(profit) desc, betname 
 