
begin;
create table DRYRUNNERSF ( 
  MARKETID integer default 1 not null , -- Primary Key
  SELECTIONID integer default 1 not null , -- Primary Key
  INDEX integer default 1 , 
  BACKPRICE float default 0.0 not null , 
  LAYPRICE float default 0.0 not null , 
  RUNNERNAME varchar default ' ' not null 
) without OIDS ;

alter table DRYRUNNERSF add constraint DRYRUNNERSFP1 primary key (
  marketid,selectionid
) ;

comment on table  DRYRUNNERSF is 'collected runners ' ;
comment on column DRYRUNNERSF.marketid is 'market id' ;
comment on column DRYRUNNERSF.selectionid is 'selection_id' ;
comment on column DRYRUNNERSF.index is 'index' ;
comment on column DRYRUNNERSF.backprice is 'back_price' ;
comment on column DRYRUNNERSF.layprice is 'lay_price' ;
comment on column DRYRUNNERSF.runnername is 'runner_name' ;

commit;

