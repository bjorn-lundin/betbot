
begin;
create table AWINNERS ( 
  MARKETID varchar(11) default ' ' not null , -- Primary Key
  SELECTIONID integer default 1 not null , -- Primary Key
  IXXLUPD varchar(15) default ' ' not null , 
  IXXLUTS timestamp(3) without time zone  not null 
) without OIDS ;

alter table AWINNERS add constraint AWINNERSP1 primary key (
  marketid,selectionid
) ;

create index AWINNERSI2 on AWINNERS (
  marketid
) ;

comment on table  AWINNERS is 'winners of market' ;
comment on column AWINNERS.marketid is 'market id' ;
comment on column AWINNERS.selectionid is 'selection_id' ;
comment on column AWINNERS.ixxlupd is 'Latest updater' ;
comment on column AWINNERS.ixxluts is 'Latest update timestamp' ;

commit;

