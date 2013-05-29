create or replace view betinfo as
select
  markets.market_id,
  markets.market_type,
  markets.menu_path,
  markets.market_name,
  markets.market_status,
  markets.event_date,
  markets.bet_delay,
  markets.last_refresh,
  bets.bet_id,
  bets.selection_id,
  bets.price,
  bets.code,
  bets.success,
  bets.size,
  bets.runner_name,
  bets.profit,
  bets.bet_placed,
  bets.full_market_name,
  bets.bet_type,
  bets.bet_won
from markets, bets
where markets.market_id = bets.market_id;




create or replace view bet_with_commission as
select * from
(
(
select
  markets.market_id,
  markets.market_type,
  markets.menu_path,
  markets.market_name,
  markets.market_status,
  markets.event_date,
  markets.bet_delay,
  bets.bet_id,
  bets.selection_id,
  bets.price,
  bets.code,
  bets.success,
  bets.size,
  bets.runner_name,
  0.95 * bets.profit as profit,
  bets.bet_placed,
  bets.full_market_name,
  bets.bet_type,
  bets.bet_won
from markets, bets
where markets.market_id = bets.market_id
and bets.profit >= 0.0
)
union (
select
  markets.market_id,
  markets.market_type,
  markets.menu_path,
  markets.market_name,
  markets.market_status,
  markets.event_date,
  markets.bet_delay,
  bets.bet_id,
  bets.selection_id,
  bets.price,
  bets.code,
  bets.success,
  bets.size,
  bets.runner_name,
  bets.profit,
  bets.bet_placed,
  bets.full_market_name,
  bets.bet_type,
  bets.bet_won
from markets, bets
where markets.market_id = bets.market_id
and bets.profit < 0.0
)
) tmp


drop view hitratio_21;


create or replace view  hitratio_21 as
(
select
  count('a') as cntwon,
  0 as cntlost,
  avg(profit) as avgprofitwon,
  0.0 as avgprofitlost,
  sum(profit) as sumprofit,
  avg(price) as avgpricewon,
  0.0 as avgpricelost,
  bet_type as bt
from
  bet_with_commission
where
event_date::date > (select CURRENT_DATE - interval '21 days')
and CODE = 'S'
and bet_type like '%HO%'
and bet_won
group by
  bt
)
union
(
select
  0 as cntwon,
  count('a') as cntlost,
  0.0 as avgprofitwon,
  avg(profit) as avgprofitlost,
  sum(profit) as sumprofit,
  0.0 as avgpricewon,
  avg(price) as avgpricelost,
  bet_type as bt
from
  bet_with_commission
where
event_date::date > (select CURRENT_DATE - interval '21 days')
and CODE = 'S'
and bet_type like '%HO%'
and not bet_won
group by
  bt
)
;


drop view hitratio_42;
create or replace view  hitratio_42 as
(
select
  count('a') as cntwon,
  0 as cntlost,
  avg(profit) as avgprofitwon,
  0.0 as avgprofitlost,
  sum(profit) as sumprofit,
  avg(price) as avgpricewon,
  0.0 as avgpricelost,
  bet_type as bt
from
  bet_with_commission
where
event_date::date > (select CURRENT_DATE - interval '42 days')
and CODE = 'S'
and bet_type like '%HO%'
and bet_won
group by
  bt
)
union
(
select
  0 as cntwon,
  count('a') as cntlost,
  0.0 as avgprofitwon,
  avg(profit) as avgprofitlost,
  sum(profit) as sumprofit,
  0.0 as avgpricewon,
  avg(price) as avgpricelost,
  bet_type as bt
from
  bet_with_commission
where
event_date::date > (select CURRENT_DATE - interval '42 days')
and CODE = 'S'
and bet_type like '%HO%'
and not bet_won
group by
  bt
)
;
