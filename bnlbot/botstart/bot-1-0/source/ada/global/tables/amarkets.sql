
begin;
create table AMARKETS ( 
  MARKETID varchar(11) default ' ' not null , -- Primary Key
  MARKETNAME varchar(50) default ' ' not null , 
  STARTTS timestamp(3) without time zone  not null , 
  EVENTID varchar(11) default ' ' not null , -- non unique index 2
  MARKETTYPE varchar(6) default ' ' not null , -- non unique index 3
  STATUS varchar(50) default ' ' not null , -- non unique index 4
  BETDELAY integer default 1 not null , 
  NUMWINNERS integer default 1 not null , -- non unique index 5
  NUMRUNNERS integer default 1 not null , 
  NUMACTIVERUNNERS integer default 1 not null , 
  TOTALMATCHED float default 0.0 not null , 
  TOTALAVAILABLE float default 0.0 not null , 
  IXXLUPD varchar(15) default ' ' not null , 
  IXXLUTS timestamp(3) without time zone  not null 
) without OIDS ;

alter table AMARKETS add constraint AMARKETSP1 primary key (
  marketid
) ;

create index AMARKETSI2 on AMARKETS (
  eventid
) ;

create index AMARKETSI3 on AMARKETS (
  markettype
) ;

create index AMARKETSI4 on AMARKETS (
  status
) ;

create index AMARKETSI5 on AMARKETS (
  numwinners
) ;

comment on table  AMARKETS is 'collected runners ' ;
comment on column AMARKETS.marketid is 'market id' ;
comment on column AMARKETS.marketname is 'market name' ;
comment on column AMARKETS.startts is 'timestamp start' ;
comment on column AMARKETS.eventid is 'event id' ;
comment on column AMARKETS.markettype is 'WINNER/PLACE' ;
comment on column AMARKETS.status is 'status' ;
comment on column AMARKETS.betdelay is 'betdelay' ;
comment on column AMARKETS.numwinners is 'num winners' ;
comment on column AMARKETS.numrunners is 'num runners' ;
comment on column AMARKETS.numactiverunners is 'num active runners' ;
comment on column AMARKETS.totalmatched is 'tot matched' ;
comment on column AMARKETS.totalavailable is 'tot available' ;
comment on column AMARKETS.ixxlupd is 'Latest updater' ;
comment on column AMARKETS.ixxluts is 'Latest update timestamp' ;

commit;

