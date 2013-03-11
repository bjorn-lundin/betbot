
create table DRYMARKETSF ( 
  MARKETID integer  default 1 not null , -- Primary Key
  BSPMARKET varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' not null , 
  MARKETTYPE varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' , 
  EVENTHIERARCHY varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' not null , -- non unique index 2
  LASTREFRESH datetime2(3)   not null , 
  TURNINGINPLAY varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' not null , 
  MENUPATH varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' , 
  BETDELAY integer  default 1 not null , 
  EXCHANGEID integer  default 1 not null , 
  COUNTRYCODE varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' not null , 
  MARKETNAME varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' , -- non unique index 3
  MARKETSTATUS integer  default 1 , 
  EVENTDATE datetime2(3)   , -- non unique index 4
  NOOFRUNNERS integer  default 1 , 
  TOTALMATCHED integer  default 1 , 
  NOOFWINNERS integer  default 1 
)
go

alter table DRYMARKETSF add constraint DRYMARKETSFP1 primary key (
  marketid
)
go

create index DRYMARKETSFI2 on DRYMARKETSF (
  eventdate
)
go

create index DRYMARKETSFI3 on DRYMARKETSF (
  eventhierarchy
)
go

create index DRYMARKETSFI4 on DRYMARKETSF (
  marketname
)
go

