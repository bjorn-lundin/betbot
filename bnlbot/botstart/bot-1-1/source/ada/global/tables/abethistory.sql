
begin;
create table ABETHISTORY ( 
  BETID bigint default 1 not null , -- Primary Key
  POWERDAYS integer default 1 not null , -- Primary Key
  STARTTS timestamp(3) without time zone  , -- non unique index 3
  HISTORYSUM float default 0.0 not null , 
  IXXLUPD varchar(15) default ' ' not null , 
  IXXLUTS timestamp(3) without time zone  not null 
) without OIDS ;

alter table ABETHISTORY add constraint ABETHISTORYP1 primary key (
  betid,powerdays
) ;

create index ABETHISTORYI2 on ABETHISTORY (
  startts
) ;

comment on table  ABETHISTORY is 'Bets' ;
comment on column ABETHISTORY.betid is 'bet id' ;
comment on column ABETHISTORY.powerdays is 'power of denominator' ;
comment on column ABETHISTORY.startts is 'start ts according to market' ;
comment on column ABETHISTORY.historysum is 'sum' ;
comment on column ABETHISTORY.ixxlupd is 'Latest updater' ;
comment on column ABETHISTORY.ixxluts is 'Latest update timestamp' ;

commit;

