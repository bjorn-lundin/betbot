
create table DRY_RESULTS ( 
  MARKET_ID integer  default 1 not null , -- Primary Key
  SELECTION_ID integer  default 1 not null  -- Primary Key
)
go

alter table DRY_RESULTS add constraint DRY_RESULTSP1 primary key (
  market_id,selection_id
)
go

