
begin;
create table ANONRUNNERS ( 
  MARKETID varchar(11) default ' ' not null , -- Primary Key
  SELECTIONID integer default 1 not null , -- Primary Key
  IXXLUPD varchar(15) default ' ' not null , 
  IXXLUTS timestamp(3) without time zone  not null 
) without OIDS ;

alter table ANONRUNNERS add constraint ANONRUNNERSP1 primary key (
  marketid,selectionid
) ;

create index ANONRUNNERSI2 on ANONRUNNERS (
  marketid
) ;

comment on table  ANONRUNNERS is 'non runners of market' ;
comment on column ANONRUNNERS.marketid is 'market id' ;
comment on column ANONRUNNERS.selectionid is 'selection_id' ;
comment on column ANONRUNNERS.ixxlupd is 'Latest updater' ;
comment on column ANONRUNNERS.ixxluts is 'Latest update timestamp' ;

commit;

