
create table DRY_RUNNERS ( 
  MARKET_ID integer  default 1 not null , -- Primary Key
  SELECTION_ID integer  default 1 not null , -- Primary Key
  INDEX integer  default 1 , 
  BACK_PRICE float  default 0.0 not null , 
  LAY_PRICE float  default 0.0 not null , 
  RUNNER_NAME varchar(0) COLLATE SQL_Latin1_General_CP1_CS_AS default ' ' not null 
)
go

alter table DRY_RUNNERS add constraint DRY_RUNNERSP1 primary key (
  market_id,selection_id
)
go

