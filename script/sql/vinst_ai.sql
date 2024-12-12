with w as
(select
  count('a') as cw,
  round(sum(p.backprice),2) as sw,
  round(sum(p.backprice) - count('a'),2) as ow,
  betname as bnw,
  betwon as bww
from abets b, aprices p
where 1=1
and b.betplaced::date >= '2024-12-11'
and b.betname like 'HORSE_BACK_AI_%1P00%'
and b.marketid = p.marketid
and b.selectionid = p.selectionid
and b.betwon
group by b.betname, b.betwon
order by b.betname, b.betwon)
,
l as
(select
 count('a') as cl,
 round(sum(p.backprice),2) as sl,
 round(sum(p.backprice) - count('a'),2) as ol,
betname as bnl,
betwon as bwl
from abets b, aprices p
where 1=1
and b.betplaced::date >= '2024-12-11'
and b.betname like 'HORSE_BACK_AI_%1P00%'
and b.marketid = p.marketid
and b.selectionid = p.selectionid
and not b.betwon
group by b.betname, b.betwon
order by b.betname, b.betwon)
select
  round(10*(( ow * 0.95) - coalesce(cl,0)),2) as profit,
  round(10 * ow * 0.95,2) as nettoprofit,
  round(coalesce(cl,0) * 10,2) as loss ,
  *
from w
full outer join l on w.bnw = l.bnl
;