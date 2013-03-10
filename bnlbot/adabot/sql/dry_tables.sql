begin;
create table DRY_MARKETS (
  MARKET_ID integer default 1 not null , -- Primary Key
  BSP_MARKET varchar default ' ' not null ,
  MARKET_TYPE varchar default ' ' ,
  EVENT_HIERARCHY varchar default ' ' not null , -- non unique index 2
  LAST_REFRESH timestamp without time zone  not null ,
  TURNING_IN_PLAY varchar default ' ' not null ,
  MENU_PATH varchar default ' ' ,
  BET_DELAY integer default 1 not null ,
  EXCHANGE_ID integer default 1 not null ,
  COUNTRY_CODE varchar default ' ' not null ,
  MARKET_NAME varchar default ' ' , -- non unique index 3
  MARKET_STATUS integer default 1 ,
  EVENT_DATE timestamp without time zone  , -- non unique index 4
  NO_OF_RUNNERS integer default 1 ,
  TOTAL_MATCHED integer default 1 ,
  NO_OF_WINNERS integer default 1
) without OIDS ;

alter table DRY_MARKETS add constraint DRY_MARKETSP1 primary key (
  market_id
) ;

create index DRY_MARKETSI2 on DRY_MARKETS (
  event_date
) ;

create index DRY_MARKETSI3 on DRY_MARKETS (
  event_hierarchy
) ;

create index DRY_MARKETSI4 on DRY_MARKETS (
  market_name
) ;

comment on table  DRY_MARKETS is 'collected markets ' ;
comment on column DRY_MARKETS.market_id is 'market id' ;
comment on column DRY_MARKETS.bsp_market is 'bsp_market' ;
comment on column DRY_MARKETS.market_type is 'market_type' ;
comment on column DRY_MARKETS.event_hierarchy is 'event_hierarchy' ;
comment on column DRY_MARKETS.last_refresh is 'last_refresh' ;
comment on column DRY_MARKETS.turning_in_play is 'turning_in_play' ;
comment on column DRY_MARKETS.menu_path is 'menu_path' ;
comment on column DRY_MARKETS.bet_delay is 'bet_delay' ;
comment on column DRY_MARKETS.exchange_id is 'exchange_id' ;
comment on column DRY_MARKETS.country_code is 'country_code' ;
comment on column DRY_MARKETS.market_name is 'market_name' ;
comment on column DRY_MARKETS.market_status is 'market_status' ;
comment on column DRY_MARKETS.event_date is 'event_date' ;
comment on column DRY_MARKETS.no_of_runners is 'no_of_runners' ;
comment on column DRY_MARKETS.total_matched is 'total_matched' ;
comment on column DRY_MARKETS.no_of_winners is 'no_of_winners' ;

commit;

--------------


begin;
create table DRY_RUNNERS (
  MARKET_ID integer default 1 not null , -- Primary Key
  SELECTION_ID integer default 1 not null , -- Primary Key
  INDEX integer default 1 ,
  BACK_PRICE float default 0.0 not null ,
  LAY_PRICE float default 0.0 not null ,
  RUNNER_NAME varchar default ' ' not null
) without OIDS ;

alter table DRY_RUNNERS add constraint DRY_RUNNERSP1 primary key (
  market_id,selection_id
) ;

comment on table  DRY_RUNNERS is 'collected runners ' ;
comment on column DRY_RUNNERS.market_id is 'market id' ;
comment on column DRY_RUNNERS.selection_id is 'selection_id' ;
comment on column DRY_RUNNERS.index is 'index' ;
comment on column DRY_RUNNERS.back_price is 'back_price' ;
comment on column DRY_RUNNERS.lay_price is 'lay_price' ;
comment on column DRY_RUNNERS.runner_name is 'runner_name' ;

commit;


----------------------
begin;
create table DRY_RESULTS (
  MARKET_ID integer default 1 not null , -- Primary Key
  SELECTION_ID integer default 1 not null  -- Primary Key
) without OIDS ;

alter table DRY_RESULTS add constraint DRY_RESULTSP1 primary key (
  market_id,selection_id
) ;

comment on table  DRY_RESULTS is 'collected results ' ;
comment on column DRY_RESULTS.market_id is 'market id' ;
comment on column DRY_RESULTS.selection_id is 'selection_id' ;

commit;


