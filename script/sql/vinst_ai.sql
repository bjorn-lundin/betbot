with w as
(select
  count('a') as cw,
  round(sum(p.backprice),2) as sw,
  round(sum(p.backprice) - count('a'),2) as ow,
  betname as bnw,
  betwon as bww
from abets b, aprices p
where 1=1
and b.betplaced::date >= '2024-11-11'
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
 round(sum(p.backprice),2) as sl,
 round(sum(p.backprice) - count('a'),2) as ol,
betname as bnl,
betwon as bwl
from abets b, aprices p
where 1=1
and b.betplaced::date >= '2024-11-11'
and b.betname like 'HORSE_BACK_AI_%'
and b.marketid = p.marketid
and b.selectionid = p.selectionid
and not b.betwon
group by b.betname, b.betwon
order by b.betname, b.betwon)
select
  substring(coalesce(bnw, bnl),19) as betname,
  round(10*(( ow * 0.95) - coalesce(cl,0)),2) as netprofit,
  round(10 * ow * 0.95,2) as grossprofit,
  round(coalesce(cl,0) * 10,2) as grossloss ,
  round((coalesce(sw,1) / coalesce(cw,1)),2) as avg_w_odds ,
  round((coalesce(sl,1) / coalesce(cl,1)),2) as avg_l_odds ,
  round( 100.0* (1.0*coalesce(cw,0) / (1.0*coalesce(cw,0) + 1.0*coalesce(cl,0) )),2) as winrate ,
  round(100.0*(10*(( ow * 0.95) - coalesce(cl,0)) / (10*1.0*coalesce(cw,0) + 10*1.0*coalesce(cl,0) )),2) as riskrate,
  cw, sw, ow, cl, sl, ol 
from w
full outer join l on w.bnw = l.bnl
order by 2 desc
;
