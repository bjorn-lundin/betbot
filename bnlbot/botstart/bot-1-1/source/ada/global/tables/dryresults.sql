
begin;
create table DRYRESULTS ( 
  MARKETID integer default 1 not null , -- Primary Key
  SELECTIONID integer default 1 not null  -- Primary Key
) without OIDS ;

alter table DRYRESULTS add constraint DRYRESULTSP1 primary key (
  marketid,selectionid
) ;

comment on table  DRYRESULTS is 'collected results ' ;
comment on column DRYRESULTS.marketid is 'market id' ;
comment on column DRYRESULTS.selectionid is 'selection_id' ;

commit;

