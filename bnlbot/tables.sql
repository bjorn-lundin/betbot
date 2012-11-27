----[52, {
--'bsp_market': 'Y', 
--'market_type': 'O', 
--'event_hierarchy': '/4339/5385914/26919446/107364850', 
--'last_refresh': '1352229158491', 
--'market_id': '107364850', 
--'turning_in_play': 'N', 
--'menu_path': '\\Greyhounds\\BAGS kort\\Newc 6 nov', 
--'bet_delay': '0', 
--'exchange_id': '1', 
--'country_code': 'GBR', 
--'market_name': 'A7 480m', 
--'market_status': 'ACTIVE', 
--'event_date': datetime.datetime(2012, 11, 6, 19, 16), 
--'no_of_runners': 6, 
--'total_matched': 0.0, 
--'no_of_winners': 1}],


create table markets (
  market_id  integer,
  bsp_market  varchar,
  market_type  varchar,
  event_hierarchy  varchar,
  last_refresh  timestamp,
  turning_in_play  varchar,
  menu_path  varchar,
  bet_delay  integer,
  exchange_id  integer,
  country_code  varchar,
  market_name  varchar,
  market_status  varchar,
  event_date  timestamp,
  no_of_runners  integer, 
  total_matched  integer, 
  no_of_winners  integer,
  home_team varchar, 
  away_team varchar,  
  ts timestamp,  
  xml_soccer_id integer  
   primary key(market_id)
  );
  
--alter table MARKETS add column HOME_TEAM     varchar;  
--alter table MARKETS add column AWAY_TEAM     varchar;
--alter table MARKETS add column TS            timestamp;  
--alter table MARKETS add column XML_SOCCER_ID integer;  


--'marketId': market_id,
--'selectionId': my_runner['selection_id'],
--'betType': 'B', # we bet on winner, not loose
--'price': '%.2f' % bet_price, # set string to 2 decimal places
--'size': '%.2f' % bet_size,
--'betCategoryType': 'E',
--'betPersistenceType': 'NONE',
--'bspLiability': '0',
--'asianLineId': '0'
--
--'bet_id': '23313887165', 'price': '0.0', 'code': 'OK', 'success': 'true', 'size': '0.0
create table bets (
  bet_id bigint,
  market_id integer,
  selection_id integer,
  price float,
  code varchar,
  success boolean,
  size float,
  bet_type varchar,
  primary key (bet_id)
  );
  
--alter table BETS add column bet_type varchar;  


create or replace view betinfo as
select 
  markets.market_id,
  markets.market_type,
  markets.menu_path,
  markets.market_name,
  markets.market_status,
  markets.event_date,   
  markets.bet_delay,  
  bets.bet_id,
  bets.selection_id, 
  bets.price, 
  bets.code, 
  bets.success, 
  bets.size
from markets, bets
where markets.market_id = bets.market_id;
  
create table teams (
  team_id integer,
  team_name varchar,
  Country varchar,
  Stadium varchar,
  Home_Page_URL varchar,
  WIKI_Link varchar,
  primary key (team_id)  
);  

create table games (
  xml_soccer_id integer,
  kickoff timestamp,
  home_team_id integer,
  away_team_id integer,
  time_in_game  varchar,
  home_goals integer,
  away_goals integer,
  primary key (xml_soccer_id)
);

create table team_aliases (
  team_id integer,
  team_alias varchar,
  primary key(team_id,team_alias)
);

create table test_timestamp (
  id integer,
  t timestamp,
  primary key(id)
);

create sequence games_stats_serial;

create table games_stats (
  id    integer  default nextval('games_stats_serial'),
  eventtime timestamp without time zone default Localtimestamp not null,
  xml_soccer_id integer,
  kickoff timestamp,
  home_team_id integer,
  away_team_id integer,
  time_in_game  varchar,
  home_goals integer,
  away_goals integer,
  primary key(id)
);



select count('a') from
markets, team_aliases home_aliases, team_aliases away_aliases, games
where markets.home_team = home_aliases.team_alias
and   markets.away_team = away_aliases.team_alias
and games.home_team_id = home_aliases.team_id
and games.away_team_id = away_aliases.team_id
and markets.market_id = 107390486
;

create or replace view market_in_xml_feed as
select 
  markets.market_id,
  markets.market_name,
  home_aliases.team_id home_team_id,
  away_aliases.team_id away_team_id, 
  home_aliases.team_alias home_team_alias,
  away_aliases.team_alias away_team_alias
from  
  markets, 
  team_aliases home_aliases, 
  team_aliases away_aliases, 
  games
where markets.home_team = home_aliases.team_alias
and   markets.away_team = away_aliases.team_alias
and   games.home_team_id = home_aliases.team_id
and   games.away_team_id = away_aliases.team_id
;

create sequence unidentified_teams_serial;

create table unidentified_teams (
  id    integer default nextval('unidentified_teams_serial'),
  team_name varchar not null,
  country_code varchar,
  eventtime timestamp without time zone default Localtimestamp not null,
  primary key(id)
);
CREATE UNIQUE INDEX unidentified_teams_name ON unidentified_teams (team_name);



create sequence score_statistics_serial;

create table score_statistics (
  id    integer default nextval('score_statistics_serial'),
  league varchar not null,
  season varchar not null,
  event_date timestamp,
  home_team varchar not null,
  away_team varchar not null,
  home_goals int not null,
  away_goals int not null,
  primary key(id)
);



