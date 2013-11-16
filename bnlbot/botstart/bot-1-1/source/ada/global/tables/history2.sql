
begin;
create table history2 ( 
  PK integer default 1 not null , -- Primary Key
  SPORTSID integer default 1 not null , -- non unique index 2
  EVENTID integer default 1 not null , -- non unique index 3
  SETTLEDDATE timestamp(3) without time zone  not null , 
  COUNTRY varchar(3) default ' ' , -- non unique index 4
  FULLDESCRIPTION varchar(200) default ' ' not null , 
  COURSE varchar(50) default ' ' , 
  SCHEDULEDOFF timestamp(3) without time zone  not null , 
  EVENT varchar(50) default ' ' not null , -- non unique index 5
  SELECTIONID integer default 1 not null , -- non unique index 6
  SELECTION varchar(50) default ' ' not null , 
  ODDS float default 0.0 not null , 
  NUMBERBETS integer default 1 not null , 
  VOLUMEMATCHED float default 0.0 not null , 
  LATESTTAKEN timestamp(3) without time zone  not null , -- non unique index 7
  FIRSTTAKEN timestamp(3) without time zone  not null , 
  WINFLAG boolean default False not null , 
  INPLAY varchar(2) default ' ' not null 
) without OIDS ;

alter table history2 add constraint history2P1 primary key (
  pk
) ;

create index history2I2 on history2 (
  sportsid
) ;

create index history2I3 on history2 (
  eventid
) ;

create index history2I4 on history2 (
  country
) ;

create index history2I5 on history2 (
  event
) ;

create index history2I6 on history2 (
  latesttaken
) ;

create index history2I7 on history2 (
  eventid,selectionid,latesttaken
) ;

comment on table  history2 is 'Historic bfdata ' ;
comment on column history2.pk is 'serial pk' ;
comment on column history2.sportsid is 'hound/horse/football...' ;
comment on column history2.eventid is 'market_id' ;
comment on column history2.settleddate is '' ;
comment on column history2.country is '' ;
comment on column history2.fulldescription is '' ;
comment on column history2.course is '' ;
comment on column history2.scheduledoff is '' ;
comment on column history2.event is 'market_name' ;
comment on column history2.selectionid is '' ;
comment on column history2.selection is 'runner_name' ;
comment on column history2.odds is '' ;
comment on column history2.numberbets is '' ;
comment on column history2.volumematched is '' ;
comment on column history2.latesttaken is '' ;
comment on column history2.firsttaken is '' ;
comment on column history2.winflag is '' ;
comment on column history2.inplay is '' ;

commit;

