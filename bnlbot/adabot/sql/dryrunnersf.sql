
create table DRYRUNNERSF ( 
  MARKETID integer  default 1 not null , -- Primary Key
  SELECTIONID integer  default 1 not null , -- Primary Key
  INDEX integer  default 1 , 
  BACKPRICE float  default 0.0 not null , 
  LAYPRICE float  default 0.0 not null , 
  RUNNERNAME varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' not null 
)
go

alter table DRYRUNNERSF add constraint DRYRUNNERSFP1 primary key (
  marketid,selectionid
)
go

