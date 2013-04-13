###############################################################################
#                                                                             #
#                                JSON_Test                                    #
#                                                                             #
#                                Make File                                    #
#                                                                             #
#                      Copyright (C) 2011, Thomas Løcke                       #
#                                                                             #
# JSON_Test is free software; you can redistribute it and/or modify it under  #
# terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 2, or (at your option) any later version.        #
# JSON_Test is distributed in the hope that it will be useful, but WITHOUT    #
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or       #
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for    #
# more details. You should have received a copy of the GNU General Public     #
# License distributed with JSON_Test. If not, write to the Free Software      #
# Foundation, 51 Franklin Street, Fifth Floor, Boston, MA 02110 - 1301, USA.  #
#                                                                             #
###############################################################################

DAT := plot/balance.dat
TMP := plot/balance.tmp
DAT2 := plot/back_bet_price_distribution.dat
TMP2 := plot/back_bet_price_distribution.tmp

UNAME := $(shell uname)

ifeq ($(UNAME),Linux)
  PSQL := psql
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

.PHONY : json_test adabot back_bet_price_distribution

all: json_test adabot

json_test :
	gnatmake -P json_test

adabot :
	gnatmake -P adabot

balance_plot:
	$(PSQL) -h $(HOST) --command="select cast(eventdate as date), saldo from balance order by eventdate" betting > $(DAT)
	cat $(DAT) | grep -v event > $(TMP)
	cat $(TMP) | grep -v rows > $(DAT)
	cat $(DAT) | grep -v "\-\-" > $(TMP)
	cat $(TMP) > $(DAT)
	rm $(TMP)
ifneq ($(UNAME),MINGW32_NT-6.1)
	cd plot && gnuplot balance.gpl
	cd plot && $(SHOW_PNG) balance.png
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
	exe/back_bet_analyzer > $(DAT2)
	cd plot && gnuplot back_bet_price_distribution.gpl
	cd plot && $(SHOW_PNG) back_bet_price_distribution.png



clean:
	gnatclean -P json_test
	gnatclean -P adabot
	gnatclean -P global
	rm plot/*.dat plot/*.png


