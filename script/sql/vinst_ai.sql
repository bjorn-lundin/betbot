--rollback;
with w as
(select
  count('a') as cw,
  sum(p.backprice -1.0) as ow,
  avg(p.backprice) as aw,
  avg(p.backprice- 1.0) as aw2,
  sum(b.size) as ssw,
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
  sum(p.backprice - 1.0) as ol,
  avg(p.backprice) as al, 
  avg(p.backprice- 1.0) as al2,
  sum(b.size) as ssl,
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
  substring(coalesce(bnw, bnl),1) as betname,
  round(( ssw * aw2 * 0.95) - coalesce(ssl,0),0) as netprofit,
  coalesce((cw + cl),0) as cnt,
  round( 100.0* (1.0*coalesce(cw,0) / (1.0*coalesce(cw,0) + 1.0*coalesce(cl,0) )),1) as winrate ,
  round(100.0*( (( ssw * aw2 * 0.95) - coalesce(ssl,0)) / (coalesce(ssw,0) + coalesce(ssl,0) )),1) as riskrate,
  coalesce(cw,0) as cw,
  coalesce(cl,0) as cl,
  round(coalesce(aw,1.0),2) as aw --,
  --round(coalesce(al,1.0),2) as al,
  --round(coalesce(aw,1.0),2) as aw2,
  --round(coalesce(al,1.0),2) as al2,
  --coalesce(ow,1.0) as ow,
  --coalesce(ol,1.0) as ol,
  --coalesce(ssw,1.0) as ssw,
  --coalesce(ssl,1.0) as ssl,
  --round(ssw * aw2 * 0.95,0) as grossprofit,
  --round(coalesce(ssl,0) ,0) as grossloss
from w
full outer join l on w.bnw = l.bnl
order by 2 desc
;
