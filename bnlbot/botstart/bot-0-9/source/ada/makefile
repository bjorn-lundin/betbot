###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################
DAT := $(BOT_SCRIPT)/plot/balance.dat
TMP := $(BOT_SCRIPT)/plot/balance.tmp
DAT2 := $(BOT_SCRIPT)/plot/back_bet_price_distribution.dat
TMP2 := $(BOT_SCRIPT)/plot/back_bet_price_distribution.tmp

UNAME := $(shell uname)

TP := tclsh $(BOT_SCRIPT)/tcl/make_table_package.tcl
ST := $(BOT_SOURCE)/ada/global/tables

DBNAME := $(BOT_DATABASE_NAME)


ifeq ($(UNAME),Linux)
  PSQL := psql --username=$(BOT_DATABASE_USERNAME)
  HOST := localhost
  SHOW_PNG := display
endif

ifeq ($(UNAME),Darwin)
  PSQL := /opt/local/bin/psql92
  HOST := 192.168.0.13
  SHOW_PNG := open
endif

#win-7
ifeq ($(UNAME),MINGW32_NT-6.1)
  PSQL := psql --username=bnl
  HOST := 192.168.0.13
  SHOW_PNG :=
endif


OBJECT_DIR_JSON := $(BOT_TARGET)/objects/json
OBJECT_DIR_BOT  := $(BOT_TARGET)/objects/bot
EXE_DIR_BOT     := $(BOT_TARGET)/bin

.PHONY : json_test adabot back_bet_price_distribution tables adatools

all:  adabot adatools


tables : $(ST)/table_history.ads $(ST)/table_history2.ads \
         $(ST)/table_drymarkets.ads $(ST)/table_dryresults.ads \
         $(ST)/table_dryrunners.ads $(ST)/table_animals.ads \
         $(ST)/table_drymarketsf.ads $(ST)/table_dryresultsf.ads \
         $(ST)/table_dryrunnersf.ads \
         $(ST)/table_bets.ads \
         #$(ST)/table_markets.ads \


$(EXE_DIR_BOT) :
	mkdir -p $(EXE_DIR_BOT)

$(OBJECT_DIR_BOT) :
	mkdir -p $(OBJECT_DIR_BOT)

$(OBJECT_DIR_JSON) :
	mkdir -p $(OBJECT_DIR_JSON)

json_test : $(OBJECT_DIR_JSON) $(EXE_DIR_BOT)
	gnatmake -P json_test

adabot : $(OBJECT_DIR_BOT) $(EXE_DIR_BOT)
	gnatmake -P adabot

adatools : $(OBJECT_DIR_BOT) $(EXE_DIR_BOT)
	gnatmake -P adatools

balance_plot:
	$(PSQL) -h $(HOST) --command="select cast(eventdate as date), saldo as \"saldo\", exposure as \"i spel\" from balance order by eventdate" $(DBNAME) > $(DAT)
#	cat $(DAT) | grep -v event > $(TMP)
	cat $(DAT) > $(TMP)
	cat $(TMP) | grep -v rows > $(DAT)
	cat $(DAT) | grep -v "\-\-" > $(TMP)
	cat $(TMP) > $(DAT)
	rm $(TMP)
ifneq ($(UNAME),MINGW32_NT-6.1)
	cd $(BOT_SCRIPT)/plot && gnuplot balance.gpl
	cd $(BOT_SCRIPT)/plot && $(SHOW_PNG) balance.png
endif

ifeq ($(UNAME),MINGW32_NT-6.1)
	@echo Gnuplot not installed in windows
endif


back_bet_price_distribution:
#	$(PSQL) -h $(HOST) --command="select count(DRY_RUNNERS.*), DRY_RUNNERS.BACK_PRICE from DRY_MARKETS , DRY_RESULTS, DRY_RUNNERS where ( lower(MARKET_NAME) ~ '^[0-9][a-z]' or lower(MARKET_NAME) ~ '^[a-z][0-9]' or lower(MARKET_NAME) like 'hp%' or lower(MARKET_NAME) like 'hc%' or   lower(MARKET_NAME) like 'or%' or    lower(MARKET_NAME) like 'iv%' ) and BSP_MARKET = 'Y' and lower(MARKET_NAME) not like '%% v %%' and lower(MARKET_NAME) not like '%%forecast%%' and lower(MARKET_NAME) not like '%%tbp%%' and lower(MARKET_NAME) not like '%%challenge%%' and lower(MARKET_NAME) not like '%%fc%%' and lower(MENU_PATH) not like '%%daily win%%' and lower(MARKET_NAME) not like '%%reverse%%' and lower(MARKET_NAME) not like '%%plats%%' and lower(MARKET_NAME) not like '%%place%%' and lower(MARKET_NAME) not like '%%without%%' and EVENT_HIERARCHY like '/4339/%' and DRY_MARKETS.MARKET_ID = DRY_RESULTS.MARKET_ID and DRY_MARKETS.MARKET_ID = DRY_RUNNERS.MARKET_ID and DRY_RESULTS.SELECTION_ID = DRY_RUNNERS.SELECTION_ID group by DRY_RUNNERS.BACK_PRICE order by DRY_RUNNERS.BACK_PRICE " betting > $(DAT2)
#	cat $(DAT2) | grep -v event > $(TMP2)
#	cat $(TMP2) | grep -v rows > $(DAT2)
#	cat $(DAT2) | grep -v "\-\-" > $(TMP2)
#	cat $(TMP2) > $(DAT2)
#	rm $(TMP2)
	$(BOT_TARGET)/bin/back_bet_analyzer > $(DAT2)
	cd $(BOT_SCRIPT)/plot && gnuplot back_bet_price_distribution.gpl
	cd $(BOT_SCRIPT)/plot && $(SHOW_PNG) back_bet_price_distribution.png


$(ST)/table_history.ads : $(BOT_CONFIG)/repository/tables/table_history.xml
	$(TP) -t history > $(ST)/table_history.ada
	cd $(ST) && gnatchop -w -gnat05 table_history.ada
	cd $(ST) && rm table_history.ada
	$(TP) -p history > $(ST)/history.sql

$(ST)/table_history2.ads : $(BOT_CONFIG)/repository/tables/table_history2.xml
	$(TP) -t history2 > $(ST)/table_history2.ada
	cd $(ST) && gnatchop -w -gnat05 table_history2.ada
	cd $(ST) && rm table_history2.ada
	$(TP) -p history2 > $(ST)/history2.sql

$(ST)/table_drymarkets.ads : $(BOT_CONFIG)/repository/tables/table_drymarkets.xml
	$(TP) -t drymarkets > $(ST)/table_drymarkets.ada
	cd $(ST) && gnatchop -w -gnat05 table_drymarkets.ada
	cd $(ST) && rm table_drymarkets.ada
	$(TP) -p drymarkets > $(ST)/drymarkets.sql

$(ST)/table_dryresults.ads : $(BOT_CONFIG)/repository/tables/table_dryresults.xml
	$(TP) -t dryresults > $(ST)/table_dryresults.ada
	cd $(ST) && gnatchop -w -gnat05 table_dryresults.ada
	cd $(ST) && rm table_dryresults.ada
	$(TP) -p dryresults > $(ST)/dryresults.sql

$(ST)/table_dryrunners.ads : $(BOT_CONFIG)/repository/tables/table_dryrunners.xml
	$(TP) -t dryrunners > $(ST)/table_dryrunners.ada
	cd $(ST) && gnatchop -w -gnat05 table_dryrunners.ada
	cd $(ST) && rm table_dryrunners.ada
	$(TP) -p dryrunners > $(ST)/dryrunners.sql

$(ST)/table_drymarketsf.ads : $(BOT_CONFIG)/repository/tables/table_drymarketsf.xml
	$(TP) -t drymarketsf > $(ST)/table_drymarketsf.ada
	cd $(ST) && gnatchop -w -gnat05 table_drymarketsf.ada
	cd $(ST) && rm table_drymarketsf.ada
	$(TP) -p drymarketsf > $(ST)/drymarketsf.sql

$(ST)/table_dryresultsf.ads : $(BOT_CONFIG)/repository/tables/table_dryresultsf.xml
	$(TP) -t dryresultsf > $(ST)/table_dryresultsf.ada
	cd $(ST) && gnatchop -w -gnat05 table_dryresultsf.ada
	cd $(ST) && rm table_dryresultsf.ada
	$(TP) -p dryresultsf > $(ST)/dryresultsf.sql

$(ST)/table_dryrunnersf.ads : $(BOT_CONFIG)/repository/tables/table_dryrunnersf.xml
	$(TP) -t dryrunnersf > $(ST)/table_dryrunnersf.ada
	cd $(ST) && gnatchop -w -gnat05 table_dryrunnersf.ada
	cd $(ST) && rm table_dryrunnersf.ada
	$(TP) -p dryrunnersf > $(ST)/dryrunnersf.sql

$(ST)/table_animals.ads : $(BOT_CONFIG)/repository/tables/table_animals.xml
	$(TP) -t animals > $(ST)/table_animals.ada
	cd $(ST) && gnatchop -w -gnat05 table_animals.ada
	cd $(ST) && rm table_animals.ada
	$(TP) -p animals > $(ST)/animals.sql

$(ST)/table_markets.ads : $(BOT_CONFIG)/repository/tables/table_markets.xml
	$(TP) -t markets > $(ST)/table_markets.ada
	cd $(ST) && gnatchop -w -gnat05 table_markets.ada
	cd $(ST) && rm table_markets.ada
	$(TP) -p markets > $(ST)/markets.sql

$(ST)/table_bets.ads : $(BOT_CONFIG)/repository/tables/table_bets.xml
	$(TP) -t bets > $(ST)/table_bets.ada
	cd $(ST) && gnatchop -w -gnat05 table_bets.ada
	cd $(ST) && rm table_bets.ada
	$(TP) -p bets > $(ST)/bets.sql

clean:
	gnatclean -P json_test
	gnatclean -P adabot
	gnatclean -P global
	gnatclean -P adatools
	rm $(ST)/table*.ad[abs]

