
begin;
create table DRYRUNNERS ( 
  MARKETID integer default 1 not null , -- Primary Key
  SELECTIONID integer default 1 not null , -- Primary Key
  INDEX integer default 1 , 
  BACKPRICE float default 0.0 not null , 
  LAYPRICE float default 0.0 not null , 
  RUNNERNAME varchar(50) default ' ' not null , 
  RUNNERNAMESTRIPPED varchar(50) default ' ' , -- non unique index 3
  STARTNUM varchar(2) default ' ' 
) without OIDS ;

alter table DRYRUNNERS add constraint DRYRUNNERSP1 primary key (
  marketid,selectionid
) ;

create index DRYRUNNERSI2 on DRYRUNNERS (
  runnernamestripped
) ;

comment on table  DRYRUNNERS is 'collected runners ' ;
comment on column DRYRUNNERS.marketid is 'market id' ;
comment on column DRYRUNNERS.selectionid is 'selection_id' ;
comment on column DRYRUNNERS.index is 'index' ;
comment on column DRYRUNNERS.backprice is 'back_price' ;
comment on column DRYRUNNERS.layprice is 'lay_price' ;
comment on column DRYRUNNERS.runnername is 'runner_name' ;
comment on column DRYRUNNERS.runnernamestripped is 'runner_name without startnum' ;
comment on column DRYRUNNERS.startnum is 'startnum from runnername' ;

commit;

