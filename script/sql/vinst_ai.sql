rollback;
with w as
(select
  count('a') as cw,
  round(sum(p.backprice -1.0),2) as ow,
  round(avg(p.backprice),2) as aw,
  betname as bnw,
  betwon as bww
from abets b, aprices p
where 1=1
  and b.betplaced::date >= '2024-11-20'
  and b.betname like 'HORSE_BACK_AI_%'
  and b.marketid = p.marketid
  and b.selectionid = p.selectionid
  and b.betwon
group by b.betname, b.betwon
order by b.betname, b.betwon)
,
l as
(select
  count('a') as cl,
  round(sum(p.backprice - 1.0),2) as ol,
  round(avg(p.backprice),2) as al, 
  betname as bnl,
  betwon as bwl
from abets b, aprices p
where 1=1
  and b.betplaced::date >= '2024-11-20'
  and b.betname like 'HORSE_BACK_AI_%'
  and b.marketid = p.marketid
  and b.selectionid = p.selectionid
  and not b.betwon
group by b.betname, b.betwon
order by b.betname, b.betwon)
select
  substring(coalesce(bnw, bnl),19) as betname,
  round(10*(( ow * 0.95) - coalesce(cl,0)),0) as netprofit,
  (cw + cl) as cnt,
  round( 100.0* (1.0*coalesce(cw,0) / (1.0*coalesce(cw,0) + 1.0*coalesce(cl,0) )),1) as winrate ,
  round(100.0*(10*(( ow * 0.95) - coalesce(cl,0)) / (10*1.0*coalesce(cw,0) + 10*1.0*coalesce(cl,0) )),1) as riskrate,
  cw, 
  cl,
  aw,
  al,
  round(10 * ow * 0.95,0) as grossprofit,
  round(coalesce(cl,0) * 10,0) as grossloss
from w
full outer join l on w.bnw = l.bnl
order by 2 desc
;
