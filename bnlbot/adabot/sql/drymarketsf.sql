
begin;
create table DRYMARKETSF ( 
  MARKETID integer default 1 not null , -- Primary Key
  BSPMARKET varchar default ' ' not null , 
  MARKETTYPE varchar default ' ' , 
  EVENTHIERARCHY varchar default ' ' not null , -- non unique index 2
  LASTREFRESH timestamp without time zone  not null , 
  TURNINGINPLAY varchar default ' ' not null , 
  MENUPATH varchar default ' ' , 
  BETDELAY integer default 1 not null , 
  EXCHANGEID integer default 1 not null , 
  COUNTRYCODE varchar default ' ' not null , 
  MARKETNAME varchar default ' ' , -- non unique index 3
  MARKETSTATUS integer default 1 , 
  EVENTDATE timestamp without time zone  , -- non unique index 4
  NOOFRUNNERS integer default 1 , 
  TOTALMATCHED integer default 1 , 
  NOOFWINNERS integer default 1 
) without OIDS ;

alter table DRYMARKETSF add constraint DRYMARKETSFP1 primary key (
  marketid
) ;

create index DRYMARKETSFI2 on DRYMARKETSF (
  eventdate
) ;

create index DRYMARKETSFI3 on DRYMARKETSF (
  eventhierarchy
) ;

create index DRYMARKETSFI4 on DRYMARKETSF (
  marketname
) ;

comment on table  DRYMARKETSF is 'collected markets ' ;
comment on column DRYMARKETSF.marketid is 'market id' ;
comment on column DRYMARKETSF.bspmarket is 'bsp_market' ;
comment on column DRYMARKETSF.markettype is 'market_type' ;
comment on column DRYMARKETSF.eventhierarchy is 'event_hierarchy' ;
comment on column DRYMARKETSF.lastrefresh is 'last_refresh' ;
comment on column DRYMARKETSF.turninginplay is 'turning_in_play' ;
comment on column DRYMARKETSF.menupath is 'menu_path' ;
comment on column DRYMARKETSF.betdelay is 'bet_delay' ;
comment on column DRYMARKETSF.exchangeid is 'exchange_id' ;
comment on column DRYMARKETSF.countrycode is 'country_code' ;
comment on column DRYMARKETSF.marketname is 'market_name' ;
comment on column DRYMARKETSF.marketstatus is 'market_status' ;
comment on column DRYMARKETSF.eventdate is 'event_date' ;
comment on column DRYMARKETSF.noofrunners is 'no_of_runners' ;
comment on column DRYMARKETSF.totalmatched is 'total_matched' ;
comment on column DRYMARKETSF.noofwinners is 'no_of_winners' ;

commit;

