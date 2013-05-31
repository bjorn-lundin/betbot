###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################

DAT  := balance.dat
TMP  := balance.tmp
DAT2 := back_bet_price_distribution.dat
TMP2 := back_bet_price_distribution.tmp


UNAME := $(shell uname)


DBNAME := $(BOT_DATABASE_NAME)



ifeq ($(UNAME),Linux)
  PSQL := psql --username=$(BOT_DATABASE_USERNAME)
  SHOW_PNG := display
endif

ifeq ($(UNAME),Darwin)
  PSQL := /opt/local/bin/psql92
  SHOW_PNG := open
endif

#win-7
ifeq ($(UNAME),MINGW32_NT-6.1)
  PSQL := psql --username=bnl
  SHOW_PNG :=
endif


#  HOST := localhost
#  HOST := 192.168.0.13
HOST := nonodev.com
ifeq ($(HOST),localhost)
  HOST := localhost
  DBNAME := betting
  DBPORT := 5432
  DBPWD := bnl
endif

ifeq ($(HOST),192.168.0.13)
  DBNAME := betting
  DBPORT := 5432
  DBPWD :=
endif

ifeq ($(HOST),nonodev.com)
  HOST := 127.0.0.1
  DBNAME := bnls
  DBPORT := 5433
  #Escape a '$' with a '$'  BettingFotboll1$ is correct pwd
  DBPWD := BettingFotboll1$$
endif



GRAPH_TYPE := one_hundred_and_four_weeks
START_DATE := 2013-01-01
STOP_DATE  := 2013-12-31
SIZE := 30
SALDO := 10000
BET_TYPE := winner



TARGET_DAT_HORSE_BACK_WINNER := horse_back_winner.dat
TARGET_DAT_HOUND_BACK_WINNER := hound_back_winner.dat
TARGET_DAT_HORSE_LAY_WINNER := horse_lay_winner.dat
TARGET_DAT_HOUND_LAY_WINNER := hound_lay_winner.dat
TARGET_PNG := hitratio.png
TARGET_BACK_PNG := hitratio_back.png
TARGET_LAY_PNG := hitratio_lay.png

## equity start ##
DRY_RUN_HORSES_WINNER_LAY_BET_ALL=dry_run_horses_winner_lay_bet_all
DRY_RUN_HOUNDS_WINNER_BACK_BET_36_01=dry_run_hounds_winner_back_bet_36_01
DRY_RUN_HOUNDS_PLACE_LAY_BET=dry_run_hounds_place_lay_bet
DRY_RUN_HORSES_WINNER_BACK_BET_54_04=dry_run_horses_winner_back_bet_54_04

DRY_RUN_HORSES_WINNER_BACK_BET_30_09=dry_run_horses_winner_back_bet_30_09
DRY_RUN_HORSES_WINNER_BACK_BET_29_10=dry_run_horses_winner_back_bet_29_10

#horses_back:
#	$(BOT_TARGET)/bin/simulator6 --bet_name=winner --saldo=10000 \
#                            --stop_date=$(STOP_DATE) --graph_type=$(GRAPH_TYPE) --size=30 \
#                            --animal=horse --quiet --bet_type=back --price=3 \
#                            --delta=1.0 --db_name=bfhistory > $(TARGET_DAT_HORSE_BACK)
#	gnuplot -e "graph_type='$(GRAPH_TYPE)'"



#all: $(TARGET_PNG) $(TARGET_LAY_PNG) $(TARGET_BACK_PNG)
.PHONY : saldo_local
saldo_local : $(DRY_RUN_HORSES_WINNER_LAY_BET_ALL).png \
              $(DRY_RUN_HOUNDS_PLACE_LAY_BET).png \
              $(DRY_RUN_HOUNDS_WINNER_BACK_BET_36_01).png \
              $(DRY_RUN_HORSES_WINNER_BACK_BET_54_04).png
.PHONY : saldo_nono
saldo_nono : dry_run_horses_winner_back_bet_30_09.png \
             dry_run_horses_winner_back_bet_29_10.png \
             dry_run_horses_winner_back_bet_28_10.png \
             dry_run_horses_winner_back_bet_27_10.png \
             dry_run_horses_winner_back_bet_27_03.png \
             dry_run_horses_winner_back_bet_26_10.png \
             dry_run_horses_winner_back_bet_25_10.png \
             dry_run_horses_winner_back_bet_29_10.png \
             dry_run_horses_winner_back_bet_24_10.png \
             dry_run_horses_winner_back_bet_23_10.png \
             dry_run_hounds_winner_lay_bet_11_17.png \
             dry_run_hounds_winner_lay_bet_12_13.png \
             dry_run_hounds_winner_lay_bet_1_7.png \
             dry_run_hounds_winner_lay_bet_2_5.png


$(TARGET_PNG) : hitratio.gpl \
              $(TARGET_DAT_HORSE_BACK_WINNER) \
              $(TARGET_DAT_HOUND_BACK_WINNER) \
              $(TARGET_DAT_HORSE_LAY_WINNER) \
              $(TARGET_DAT_HOUND_LAY_WINNER)
	gnuplot -e "graph_type='$(GRAPH_TYPE)'" \
                -e "stop_date='$(STOP_DATE)'" \
                -e "db_name='$(DB_NAME)'" \
                -e "target_png='$(TARGET_PNG)'" \
                -e "horse_lay_winner='$(TARGET_DAT_HORSE_LAY_WINNER)'" \
                -e "hound_lay_winner='$(TARGET_DAT_HOUND_LAY_WINNER)'" \
                -e "horse_back_winner='$(TARGET_DAT_HORSE_BACK_WINNER)'" \
                -e "hound_back_winner='$(TARGET_DAT_HOUND_BACK_WINNER)'" hitratio.gpl
	display $(TARGET_PNG)

$(TARGET_LAY_PNG) : hitratio_lay.gpl \
              $(TARGET_DAT_HORSE_LAY_WINNER) \
              $(TARGET_DAT_HOUND_LAY_WINNER)
	gnuplot -e "graph_type='$(GRAPH_TYPE)'" \
                -e "stop_date='$(STOP_DATE)'" \
                -e "db_name='$(DB_NAME)'" \
                -e "target_png='$(TARGET_LAY_PNG)'" \
                -e "horse_lay_winner='$(TARGET_DAT_HORSE_LAY_WINNER)'" \
                -e "hound_lay_winner='$(TARGET_DAT_HOUND_LAY_WINNER)'" hitratio_lay.gpl
	display $(TARGET_LAY_PNG)


$(TARGET_BACK_PNG) : hitratio_back.gpl \
              $(TARGET_DAT_HORSE_BACK_WINNER) \
              $(TARGET_DAT_HOUND_BACK_WINNER)
	gnuplot -e "graph_type='$(GRAPH_TYPE)'" \
                -e "stop_date='$(STOP_DATE)'" \
                -e "db_name='$(DB_NAME)'" \
                -e "target_png='$(TARGET_BACK_PNG)'" \
                -e "horse_back_winner='$(TARGET_DAT_HORSE_BACK_WINNER)'" \
                -e "hound_back_winner='$(TARGET_DAT_HOUND_BACK_WINNER)'" hitratio_back.gpl
	display $(TARGET_BACK_PNG)

$(TARGET_DAT_HORSE_BACK_WINNER) : $(BOT_TARGET)/bin/simulator6
	$(BOT_TARGET)/bin/simulator6 --animal=horse \
                                     --bet_name=winner \
                                     --graph_type=$(GRAPH_TYPE) \
                                     --size=$(SIZE) \
                                     --saldo=$(SALDO) \
                                     --price=1 \
                                     --delta=1 \
                                     --favorite_by=0 \
                                     --stop_date=$(STOP_DATE) \
                                     --db_name=$(DB_NAME) \
                                     --bet_type=back \
                                     --quiet > $(TARGET_DAT_HORSE_BACK_WINNER)


$(TARGET_DAT_HORSE_LAY_WINNER) : $(BOT_TARGET)/bin/simulator6
	$(BOT_TARGET)/bin/simulator6 --animal=horse \
                                     --bet_name=winner \
                                     --graph_type=$(GRAPH_TYPE) \
                                     --size=$(SIZE) \
                                     --saldo=$(SALDO) \
                                     --price=1 \
                                     --delta=1 \
                                     --favorite_by=0 \
                                     --stop_date=$(STOP_DATE) \
                                     --db_name=$(DB_NAME) \
                                     --bet_type=lay \
                                     --quiet > $(TARGET_DAT_HORSE_LAY_WINNER)


$(TARGET_DAT_HOUND_BACK_WINNER) : $(BOT_TARGET)/bin/simulator6
	$(BOT_TARGET)/bin/simulator6 --animal=hound \
                                     --bet_name=winner \
                                     --graph_type=$(GRAPH_TYPE) \
                                     --size=$(SIZE) \
                                     --saldo=$(SALDO) \
                                     --price=1 \
                                     --delta=1 \
                                     --favorite_by=0 \
                                     --stop_date=$(STOP_DATE) \
                                     --db_name=$(DB_NAME) \
                                     --bet_type=back \
                                     --quiet > $(TARGET_DAT_HOUND_BACK_WINNER)


$(TARGET_DAT_HOUND_LAY_WINNER) : $(BOT_TARGET)/bin/simulator6
	$(BOT_TARGET)/bin/simulator6 --animal=hound \
                                     --bet_name=winner \
                                     --graph_type=$(GRAPH_TYPE) \
                                     --size=$(SIZE) \
                                     --saldo=$(SALDO) \
                                     --price=1 \
                                     --delta=1 \
                                     --favorite_by=0 \
                                     --stop_date=$(STOP_DATE) \
                                     --db_name=$(DB_NAME) \
                                     --bet_type=lay \
                                     --quiet > $(TARGET_DAT_HOUND_LAY_WINNER)


######## equity start ##########


##
#$(DRY_RUN_HORSES_WINNER_BACK_BET_54_04).png : $(BOT_TARGET)/bin/equity $(DRY_RUN_HORSES_WINNER_BACK_BET_54_04).dat equity.gpl
#	gnuplot -e "start_date='$(STOP_DATE)'" \
#                -e "stop_date='$(STOP_DATE)'" \
#                -e "db_name='$(DB_NAME)'" \
#                -e "bet_type='DRY_RUN_HORSES_WINNER_BACK_BET_54_04'" \
#                -e "target_png='$(DRY_RUN_HORSES_WINNER_BACK_BET_54_04).png'" \
#                -e "input_file='$(DRY_RUN_HORSES_WINNER_BACK_BET_54_04).dat'" equity.gpl
#ifneq ($(UNAME),MINGW32_NT-6.1)
#	$(SHOW_PNG) $(DRY_RUN_HORSES_WINNER_BACK_BET_54_04).png
#endif
#
#
#$(DRY_RUN_HORSES_WINNER_BACK_BET_54_04).dat : $(BOT_TARGET)/bin/equity
#	$(BOT_TARGET)/bin/equity --host=$(HOST) \
#                                 --database=$(DBNAME) \
#                                 --bet_type=DRY_RUN_HORSES_WINNER_BACK_BET_54_04 \
#                                 --saldo=$(SALDO) \
#                                 --start_date=2013-01-01 \
#                                 --stop_date=2013-12-31 > $(DRY_RUN_HORSES_WINNER_BACK_BET_54_04).dat




# test implict rules
# if a .bet file is present, create a corresponding dat and then a png file from that dat
# $* is the stem
%.png :
	$(BOT_TARGET)/bin/equity --host=$(HOST) \
                                 --database=$(DBNAME) \
                                 --port=$(DBPORT) \
                                 --db_pwd=$(DBPWD) \
                                 --bet_type=$(shell echo $* | tr '[:lower:]' '[:upper:]') \
                                 --saldo=$(SALDO) \
                                 --start_date=2013-01-01 \
                                 --stop_date=2013-12-31 > $*.dat
	gnuplot -e "start_date='$(STOP_DATE)'" \
                -e "stop_date='$(STOP_DATE)'" \
                -e "db_name='$(DBNAME)'" \
                -e "bet_type='$*'" \
                -e "target_png='$@'" \
                -e "input_file='$*.dat'" equity.gpl
ifneq ($(UNAME),MINGW32_NT-6.1)
	$(SHOW_PNG) $*.png
endif





######## equity stop ##########

.PHONY : balance
balance:
	$(PSQL) -h $(HOST) --command="select cast(eventdate as date), saldo as \"saldo\", exposure as \"i spel\" from balance order by eventdate" $(DBNAME) > $(DAT)
#	cat $(DAT) | grep -v event > $(TMP)
	cat $(DAT) > $(TMP)
	cat $(TMP) | grep -v rows > $(DAT)
	cat $(DAT) | grep -v "\-\-" > $(TMP)
	cat $(TMP) > $(DAT)
	rm $(TMP)
ifneq ($(UNAME),MINGW32_NT-6.1)
	gnuplot balance.gpl
	$(SHOW_PNG) balance.png
endif

ifeq ($(UNAME),MINGW32_NT-6.1)
	@echo Gnuplot not installed in windows
endif

back_bet_price_distribution:
	$(BOT_TARGET)/bin/back_bet_analyzer > $(DAT2)
	gnuplot back_bet_price_distribution.gpl
	$(SHOW_PNG) back_bet_price_distribution.png

.PHONY : excel_42 excel_21
excel_42:
ifneq ($(UNAME),MINGW32_NT-6.1)
	$(PSQL) -h $(HOST) --command="select sum(cntwon) as cwon,sum(cntlost) as clost, round(sum(avgprofitwon + avgprofitlost)::numeric,2) as aerrorprofit, round(sum(sumprofit)::numeric,2) as sprofit, round(avg(avgpricelost+avgpricewon)::numeric,2) as aprice, round(100*sum(cntwon)/(sum(cntwon)+sum(cntlost)),2) as hitratio, bt from hitratio_42 group by bt having sum(sumprofit) > 0 order by aprice" $(DBNAME) > excel_42.dat
#	$(PSQL) -h $(HOST) --command="select sum(cntwon) as cwon,sum(cntlost) as clost, round(sum(avgprofitwon + avgprofitlost)::numeric,2) as aerrorprofit, round(sum(sumprofit)::numeric,2) as sprofit, round(avg(avgpricelost+avgpricewon)::numeric,2) as aprice, round(100*sum(cntwon)/(sum(cntwon)+sum(cntlost)),2) as hitratio, bt from hitratio_42 group by bt order by aprice" $(DBNAME) > excel_42.dat
	cat excel_42.dat | grep -v "\-\-" > $(TMP)
	cat $(TMP) | grep -v rows > excel_42.dat
	gnuplot -e "target_png='excel_42.png'" \
                -e "days='42'" \
                -e "inputfile='excel_42.dat'" excel.gpl
	$(SHOW_PNG) excel_42.png
endif

excel_21:
ifneq ($(UNAME),MINGW32_NT-6.1)
	$(PSQL) -h $(HOST) --command="select sum(cntwon) as cwon,sum(cntlost) as clost, round(sum(avgprofitwon + avgprofitlost)::numeric,2) as aerrorprofit, round(sum(sumprofit)::numeric,2) as sprofit, round(avg(avgpricelost+avgpricewon)::numeric,2) as aprice, round(100*sum(cntwon)/(sum(cntwon)+sum(cntlost)),2) as hitratio, bt from hitratio_21 group by bt having sum(sumprofit) > -10000 order by aprice" $(DBNAME) > excel_21.dat
	cat excel_21.dat | grep -v "\-\-" > $(TMP)
	cat $(TMP) | grep -v rows > excel_21.dat
	gnuplot -e "target_png='excel_21.png'" \
                -e "days='21'" \
                -e "inputfile='excel_21.dat'" excel.gpl
	$(SHOW_PNG) excel_21.png
endif


.PHONY : clean
clean :
	rm *.png *.dat