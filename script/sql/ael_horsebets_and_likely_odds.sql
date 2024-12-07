select 
 -- avg(h.backprice),
 -- avg(b.pricematched) 
  b.betid,
  b.betname,
  b.marketid,
  b.selectionid,
  b.betwon,
  b.betplaced,
  h.pricets,
  b.price,
  b.pricematched,
  h.backprice,
  h.layprice
from abets b, apriceshistory h
where b.marketid = h.marketid
and b.betwon
and b.selectionid = h.selectionid
and h.pricets between b.betplaced +'1 sec' and b.betplaced+'1.1 sec'
and b.betname = 'BACK_1_11_1_15_08_10_1_2_WIN'
and h.backprice >= 1.10
order by b.betplaced,h.pricets
--limit 100  

