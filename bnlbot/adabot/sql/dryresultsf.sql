
create table DRYRESULTSF ( 
  MARKETID integer  default 1 not null , -- Primary Key
  SELECTIONID integer  default 1 not null  -- Primary Key
)
go

alter table DRYRESULTSF add constraint DRYRESULTSFP1 primary key (
  marketid,selectionid
)
go

