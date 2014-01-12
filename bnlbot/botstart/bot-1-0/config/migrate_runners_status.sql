
begin;
create table ARUNNERS_TMP as select * from ARUNNERS;
drop table ARUNNERS;
commit;


begin;
create table ARUNNERS (
  MARKETID varchar(11) default ' ' not null , -- Primary Key
  SELECTIONID integer default 1 not null , -- Primary Key
  SORTPRIO integer default 1 not null ,
  STATUS varchar(50) default ' ' not null , -- non unique index 3
  HANDICAP float default 0.0 not null ,
  RUNNERNAME varchar(50) default ' ' not null ,
  RUNNERNAMESTRIPPED varchar(50) default ' ' , -- non unique index 4
  RUNNERNAMENUM varchar(2) default ' ' ,
  IXXLUPD varchar(15) default ' ' not null ,
  IXXLUTS timestamp(3) without time zone  not null
) without OIDS ;

alter table ARUNNERS add constraint ARUNNERSP1 primary key (
  marketid,selectionid
) ;

create index ARUNNERSI2 on ARUNNERS (
  runnernamestripped
) ;

create index ARUNNERSI3 on ARUNNERS (
  status
) ;

comment on table  ARUNNERS is 'collected runners ' ;
comment on column ARUNNERS.marketid is 'market id' ;
comment on column ARUNNERS.selectionid is 'selection_id' ;
comment on column ARUNNERS.sortprio is 'sortprio' ;
comment on column ARUNNERS.status is 'status' ;
comment on column ARUNNERS.handicap is 'handicap' ;
comment on column ARUNNERS.runnername is 'runner_name' ;
comment on column ARUNNERS.runnernamestripped is 'runner_name without startnum' ;
comment on column ARUNNERS.runnernamenum is 'startnum in runner name' ;
comment on column ARUNNERS.ixxlupd is 'Latest updater' ;
comment on column ARUNNERS.ixxluts is 'Latest update timestamp' ;

commit;

begin;
insert into ARUNNERS select MARKETID,SELECTIONID,SORTPRIO,'NOT_SET_YET',HANDICAP,RUNNERNAME,RUNNERNAMESTRIPPED,RUNNERNAMENUM,IXXLUPD,IXXLUTS from ARUNNERS_TMP;
commit;

--fix markets

begin;

update AMARKETS set STATUS ='CLOSED'  
where STATUS <> 'CLOSED'
and exists (select 'a' from AWINNERS where AWINNERS.MARKETID = AMARKETS.MARKETID)
;

update ARUNNERS set STATUS ='WINNER'
where STATUS <> 'WINNER'
and 
exists 
(
  select 'a' from AWINNERS 
  where AWINNERS.MARKETID = ARUNNERS.MARKETID
  and AWINNERS.SELECTIONID = ARUNNERS.SELECTIONID
  )
;


update ARUNNERS set STATUS ='REMOVED' 
where STATUS <> 'REMOVED'
and exists 
(
  select 'a' from ANONRUNNERS 
  where ANONRUNNERS.MARKETID = ARUNNERS.MARKETID
  and ANONRUNNERS.NAME = ARUNNERS.RUNNERNAMESTRIPPED
  )
;


update ARUNNERS set STATUS ='LOSER' where 
STATUS in ('NOT_SET_YET','NOT SET YET' ) ;
commit;


