
create table DRY_MARKETS ( 
  MARKET_ID integer  default 1 not null , -- Primary Key
  BSP_MARKET varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' not null , 
  MARKET_TYPE varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' , 
  EVENT_HIERARCHY varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' not null , -- non unique index 2
  LAST_REFRESH datetime2(3)   not null , 
  TURNING_IN_PLAY varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' not null , 
  MENU_PATH varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' , 
  BET_DELAY integer  default 1 not null , 
  EXCHANGE_ID integer  default 1 not null , 
  COUNTRY_CODE varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' not null , 
  MARKET_NAME varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' , -- non unique index 3
  MARKET_STATUS integer  default 1 , 
  EVENT_DATE datetime2(3)   , -- non unique index 4
  NO_OF_RUNNERS integer  default 1 , 
  TOTAL_MATCHED integer  default 1 , 
  NO_OF_WINNERS integer  default 1 
)
go

alter table DRY_MARKETS add constraint DRY_MARKETSP1 primary key (
  market_id
)
go

create index DRY_MARKETSI2 on DRY_MARKETS (
  event_date
)
go

create index DRY_MARKETSI3 on DRY_MARKETS (
  event_hierarchy
)
go

create index DRY_MARKETSI4 on DRY_MARKETS (
  market_name
)
go

