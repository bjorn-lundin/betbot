
begin;
create table ABALANCES ( 
  BALDATE timestamp(3) without time zone  not null , -- Primary Key
  BALANCE float default 0.0 not null , 
  EXPOSURE float default 0.0 not null , 
  IXXLUPD varchar(15) default ' ' not null , 
  IXXLUTS timestamp(3) without time zone  not null 
) without OIDS ;

alter table ABALANCES add constraint ABALANCESP1 primary key (
  baldate
) ;

comment on table  ABALANCES is 'Saldo' ;
comment on column ABALANCES.baldate is 'ts of balance' ;
comment on column ABALANCES.balance is 'balance' ;
comment on column ABALANCES.exposure is 'exposure' ;
comment on column ABALANCES.ixxlupd is 'Latest updater' ;
comment on column ABALANCES.ixxluts is 'Latest update timestamp' ;

commit;

