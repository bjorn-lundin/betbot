
begin;
create table history ( 
  PK integer default 1 not null , -- Primary Key
  SPORTSID integer default 1 not null , -- non unique index 2
  EVENTID integer default 1 not null , -- non unique index 3
  SETTLEDDATE timestamp(3) without time zone  not null , 
  COUNTRY varchar(3) default ' ' , -- non unique index 4
  FULLDESCRIPTION varchar(200) default ' ' not null , -- non unique index 5
  COURSE varchar(50) default ' ' , 
  SCHEDULEDOFF timestamp(3) without time zone  not null , -- non unique index 6
  EVENT varchar(50) default ' ' not null , -- non unique index 7
  SELECTIONID integer default 1 not null , -- non unique index 8
  SELECTION varchar(50) default ' ' not null , 
  ODDS float default 0.0 not null , 
  NUMBERBETS integer default 1 not null , 
  VOLUMEMATCHED float default 0.0 not null , 
  LATESTTAKEN timestamp(3) without time zone  not null , -- non unique index 9
  FIRSTTAKEN timestamp(3) without time zone  not null , -- non unique index 10
  WINFLAG boolean default False not null , 
  INPLAY varchar(2) default ' ' not null 
) without OIDS ;

alter table history add constraint historyP1 primary key (
  pk
) ;

create index historyI2 on history (
  sportsid
) ;

create index historyI3 on history (
  eventid
) ;

create index historyI4 on history (
  event
) ;

create index historyI5 on history (
  country
) ;

create index historyI6 on history (
  latesttaken
) ;

create index historyI7 on history (
  eventid,selectionid,latesttaken
) ;

create index historyI8 on history (
  eventid,selectionid
) ;

create index historyI9 on history (
  fulldescription
) ;

create index historyI10 on history (
  firsttaken
) ;

create index historyI11 on history (
  eventid,selectionid,firsttaken
) ;

create index historyI12 on history (
  scheduledoff
) ;

create index historyI13 on history (
  scheduledoff,selectionid,firsttaken
) ;

comment on table  history is 'Historic bfdata ' ;
comment on column history.pk is 'serial pk' ;
comment on column history.sportsid is 'hound/horse/football...' ;
comment on column history.eventid is 'market_id' ;
comment on column history.settleddate is '' ;
comment on column history.country is '' ;
comment on column history.fulldescription is '' ;
comment on column history.course is '' ;
comment on column history.scheduledoff is '' ;
comment on column history.event is 'market_name' ;
comment on column history.selectionid is '' ;
comment on column history.selection is 'runner_name' ;
comment on column history.odds is '' ;
comment on column history.numberbets is '' ;
comment on column history.volumematched is '' ;
comment on column history.latesttaken is '' ;
comment on column history.firsttaken is '' ;
comment on column history.winflag is '' ;
comment on column history.inplay is '' ;

commit;

