select count('a'), sum(profit), extract(month from betplaced), side, betwon
from Abets
where side = 'LAY'
group by extract(month from betplaced), side, betwon
order by extract(month from betplaced), side, betwon

