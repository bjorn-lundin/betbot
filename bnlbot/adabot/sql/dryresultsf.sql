
begin;
create table DRYRESULTSF ( 
  MARKETID integer default 1 not null , -- Primary Key
  SELECTIONID integer default 1 not null  -- Primary Key
) without OIDS ;

alter table DRYRESULTSF add constraint DRYRESULTSFP1 primary key (
  marketid,selectionid
) ;

comment on table  DRYRESULTSF is 'collected results ' ;
comment on column DRYRESULTSF.marketid is 'market id' ;
comment on column DRYRESULTSF.selectionid is 'selection_id' ;

commit;

