
begin;
create table DRYMARKETS ( 
  MARKETID integer default 1 not null , -- Primary Key
  BSPMARKET varchar(1) default ' ' not null , 
  MARKETTYPE varchar(1) default ' ' , 
  EVENTHIERARCHY varchar(150) default ' ' not null , -- non unique index 2
  LASTREFRESH timestamp(3) without time zone  not null , 
  TURNINGINPLAY varchar(1) default ' ' not null , 
  MENUPATH varchar(200) default ' ' , 
  BETDELAY integer default 1 not null , 
  EXCHANGEID integer default 1 not null , 
  COUNTRYCODE varchar(3) default ' ' not null , 
  MARKETNAME varchar(50) default ' ' , -- non unique index 3
  MARKETSTATUS varchar(15) default ' ' , 
  EVENTDATE timestamp(3) without time zone  , -- non unique index 4
  NOOFRUNNERS integer default 1 , 
  TOTALMATCHED integer default 1 , 
  NOOFWINNERS integer default 1 
) without OIDS ;

alter table DRYMARKETS add constraint DRYMARKETSP1 primary key (
  marketid
) ;

create index DRYMARKETSI2 on DRYMARKETS (
  eventdate
) ;

create index DRYMARKETSI3 on DRYMARKETS (
  eventhierarchy
) ;

create index DRYMARKETSI4 on DRYMARKETS (
  marketname
) ;

comment on table  DRYMARKETS is 'collected markets' ;
comment on column DRYMARKETS.marketid is 'market id' ;
comment on column DRYMARKETS.bspmarket is 'bsp_market' ;
comment on column DRYMARKETS.markettype is 'market_type' ;
comment on column DRYMARKETS.eventhierarchy is 'event_hierarchy' ;
comment on column DRYMARKETS.lastrefresh is 'last_refresh' ;
comment on column DRYMARKETS.turninginplay is 'turning_in_play' ;
comment on column DRYMARKETS.menupath is 'menu_path' ;
comment on column DRYMARKETS.betdelay is 'bet_delay' ;
comment on column DRYMARKETS.exchangeid is 'exchange_id' ;
comment on column DRYMARKETS.countrycode is 'country_code' ;
comment on column DRYMARKETS.marketname is 'market_name' ;
comment on column DRYMARKETS.marketstatus is 'market_status' ;
comment on column DRYMARKETS.eventdate is 'event_date' ;
comment on column DRYMARKETS.noofrunners is 'no_of_runners' ;
comment on column DRYMARKETS.totalmatched is 'total_matched' ;
comment on column DRYMARKETS.noofwinners is 'no_of_winners' ;

commit;

