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
#HOST := 192.168.0.13
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
  DBPWD := bnl
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

.PHONY : hitratio saldo_local saldo_nono saldo_nono_sim


hitratio: $(TARGET_PNG) $(TARGET_LAY_PNG) $(TARGET_BACK_PNG)

saldo_local : dry_run_horses_winner_lay_bet_all.png \
              dry_run_hounds_place_lay_bet.png \
              dry_run_hounds_winner_back_bet_36_01.png \
              dry_run_horses_winner_back_bet_54_04.png
saldo_nono : dry_run_horses_winner_back_bet_30_09.png \
             dry_run_horses_winner_back_bet_29_10.png \
             dry_run_horses_winner_back_bet_28_10.png \
             dry_run_horses_winner_back_bet_27_10.png \
             dry_run_horses_winner_back_bet_27_03.png \
             dry_run_horses_winner_back_bet_26_10.png \
             dry_run_horses_winner_back_bet_25_10.png \
             dry_run_horses_winner_back_bet_24_10.png \
             dry_run_horses_winner_back_bet_23_10.png \
             dry_run_hounds_winner_lay_bet_11_17.png \
             dry_run_hounds_winner_lay_bet_12_13.png \
             dry_run_hounds_winner_lay_bet_1_7.png \
             dry_run_hounds_winner_lay_bet_2_5.png


saldo_nono_sim : sim_dry_run_horses_winner_back_bet_30_09.dat \
             sim_dry_run_horses_winner_back_bet_29_10.dat \
             sim_dry_run_horses_winner_back_bet_28_10.dat \
             sim_dry_run_horses_winner_back_bet_27_10.dat \
             sim_dry_run_horses_winner_back_bet_27_03.dat \
             sim_dry_run_horses_winner_back_bet_26_10.dat \
             sim_dry_run_horses_winner_back_bet_25_10.dat \
             sim_dry_run_horses_winner_back_bet_24_10.dat \
             sim_dry_run_horses_winner_back_bet_23_10.dat \
             sim_dry_run_hounds_winner_lay_bet_11_17.dat \
             sim_dry_run_hounds_winner_lay_bet_12_13.dat \
             sim_dry_run_hounds_winner_lay_bet_1_7.dat \
             sim_dry_run_hounds_winner_lay_bet_2_5.dat

.PHONY : sim_equity_all \
         sim_equity_loop_back_horse \
         sim_equity_loop_back_hound \
         sim_equity_loop_lay_horse \
         sim_equity_loop_lay_hound \
         sim_equity_loop_lay_favorite_horse \
         sim_equity_loop_lay_favorite_hound

sim_equity_all : sim_equity_loop_back_horse \
                 sim_equity_loop_back_hound \
                 sim_equity_loop_lay_horse \
                 sim_equity_loop_lay_hound \
                 sim_equity_loop_lay_favorite_horse \
                 sim_equity_loop_lay_favorite_hound

sim_equity_loop_back_horse : back_bet_horse_winner_loop.dat \
                             back_bet_horse_place_loop.dat

sim_equity_loop_back_hound : back_bet_hound_winner_loop.dat \
                             back_bet_hound_place_loop.dat

sim_equity_loop_lay_horse : lay_bet_horse_winner_loop.dat \
                            lay_bet_horse_place_loop.dat

sim_equity_loop_lay_hound : lay_bet_hound_winner_loop.dat \
                            lay_bet_hound_place_loop.dat

sim_equity_loop_lay_favorite_horse : lay_favorite_bet_horse_winner_loop.dat \
                                     lay_favorite_bet_horse_place_loop.dat

sim_equity_loop_lay_favorite_hound : lay_favorite_bet_hound_winner_loop.dat \
                                     lay_favorite_bet_hound_place_loop.dat




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
                -e "sim_input_file='sim_$*.dat'" \
                -e "input_file='$*.dat'" equity.gpl
ifneq ($(UNAME),MINGW32_NT-6.1)
	$(SHOW_PNG) $*.png
endif

best_plot :
	gnuplot -e "start_date='2011-01-01'" \
                -e "stop_date='2013-12-31'" \
                -e "db_name='bfhistory'" \
                -e "bet_type='lay horse place/17/22/5/200/0 - winner/15/21/0/200/5'" \
                -e "target_png='best_plot.png'" \
                -e "sim_input_file='equity_lay_bet_horse_place_17_22_0_200_5.dat'" \
                -e "input_file='equity_lay_bet_horse_winner_15_21_5_200_0.dat'" equity.gpl
ifneq ($(UNAME),MINGW32_NT-6.1)
	$(SHOW_PNG) best_plot.png
endif




######## equity stop ##########

equity_lay_bet_horse_winner_15_21_5_200_0.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=bfhistory \
                                   --animal=horse \
                                   --bet_type=lay \
                                   --bet_name=winner \
                                   --max_profit_factor=3 \
                                   --max_daily_loss=-200 \
                                   --start_date=2006-01-01 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=16 \
                                   --delta=21 \
                                   --saldo=10000 \
                                   --favorite_by=5 \
                                   --quiet > equity_lay_bet_horse_winner_15_21_5_200_0.dat
	gnuplot -e "start_date='2006-01-01'" \
                -e "stop_date='2013-12-31'" \
                -e "db_name='bfhistory'" \
                -e "bet_type='lay horse place/17/22/5/200/0 - winner/15/21/0/200/5'" \
                -e "target_png='best_plot.png'" \
                -e "sim_input_file='equity_lay_bet_horse_place_17_22_0_200_5.dat'" \
                -e "input_file='equity_lay_bet_horse_winner_15_21_5_200_0.dat'" equity.gpl
ifneq ($(UNAME),MINGW32_NT-6.1)
	$(SHOW_PNG) best_plot.png
endif


equity_lay_bet_horse_winner_18_21_5_200_4.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=bfhistory \
                                   --animal=horse \
                                   --bet_type=lay \
                                   --bet_name=winner \
                                   --max_profit_factor=4 \
                                   --max_daily_loss=-200 \
                                   --start_date=2006-01-01 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=18 \
                                   --delta=21 \
                                   --saldo=10000 \
                                   --favorite_by=5 \
                                   --quiet > equity_lay_bet_horse_winner_18_21_5_200_4.dat
	gnuplot -e "start_date='2006-01-01'" \
                -e "stop_date='2013-12-31'" \
                -e "db_name='bfhistory'" \
                -e "bet_type='lay horse winner/15/21/5/200/4 - winner/18/21/5/200/4'" \
                -e "target_png='best_plot.png'" \
                -e "sim_input_file='equity_lay_bet_horse_winner_15_21_5_200_4.dat'" \
                -e "input_file='equity_lay_bet_horse_winner_18_21_5_200_4.dat'" equity.gpl
ifneq ($(UNAME),MINGW32_NT-6.1)
	$(SHOW_PNG) best_plot.png
endif


sim_dry_run_horses_winner_back_bet_23_10.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=betting \
                                   --animal=horse \
                                   --bet_type=back \
                                   --bet_name=winner \
                                   --max_profit_factor=300 \
                                   --max_daily_loss=-250 \
                                   --start_date=2013-05-11 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=2.3 \
                                   --delta=1 \
                                   --saldo=10000 \
                                   --favorite_by=0 \
                                   --quiet > sim_dry_run_horses_winner_back_bet_23_10.dat

sim_dry_run_horses_winner_back_bet_24_10.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=betting \
                                   --animal=horse \
                                   --bet_type=back \
                                   --bet_name=winner \
                                   --max_profit_factor=300 \
                                   --max_daily_loss=-250 \
                                   --start_date=2013-05-11 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=2.4 \
                                   --delta=1 \
                                   --saldo=10000 \
                                   --favorite_by=0 \
                                   --quiet > sim_dry_run_horses_winner_back_bet_24_10.dat

sim_dry_run_horses_winner_back_bet_25_10.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=betting \
                                   --animal=horse \
                                   --bet_type=back \
                                   --bet_name=winner \
                                   --max_profit_factor=300 \
                                   --max_daily_loss=-250 \
                                   --start_date=2013-05-11 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=2.5 \
                                   --delta=1 \
                                   --saldo=10000 \
                                   --favorite_by=0 \
                                   --quiet > sim_dry_run_horses_winner_back_bet_25_10.dat

sim_dry_run_horses_winner_back_bet_26_10.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=betting \
                                   --animal=horse \
                                   --bet_type=back \
                                   --bet_name=winner \
                                   --max_profit_factor=300 \
                                   --max_daily_loss=-250 \
                                   --start_date=2013-05-11 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=2.6 \
                                   --delta=1 \
                                   --saldo=10000 \
                                   --favorite_by=0 \
                                   --quiet > sim_dry_run_horses_winner_back_bet_26_10.dat

sim_dry_run_horses_winner_back_bet_27_10.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=betting \
                                   --animal=horse \
                                   --bet_type=back \
                                   --bet_name=winner \
                                   --max_profit_factor=300 \
                                   --max_daily_loss=-250 \
                                   --start_date=2013-05-11 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=2.7 \
                                   --delta=1 \
                                   --saldo=10000 \
                                   --favorite_by=0 \
                                   --quiet > sim_dry_run_horses_winner_back_bet_27_10.dat

sim_dry_run_horses_winner_back_bet_28_10.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=betting \
                                   --animal=horse \
                                   --bet_type=back \
                                   --bet_name=winner \
                                   --max_profit_factor=300 \
                                   --max_daily_loss=-250 \
                                   --start_date=2013-05-11 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=2.8 \
                                   --delta=1 \
                                   --saldo=10000 \
                                   --favorite_by=0 \
                                   --quiet > sim_dry_run_horses_winner_back_bet_28_10.dat

sim_dry_run_horses_winner_back_bet_29_10.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=betting \
                                   --animal=horse \
                                   --bet_type=back \
                                   --bet_name=winner \
                                   --max_profit_factor=300 \
                                   --max_daily_loss=-250 \
                                   --start_date=2013-05-11 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=2.9 \
                                   --delta=1 \
                                   --saldo=10000 \
                                   --favorite_by=0 \
                                   --quiet > sim_dry_run_horses_winner_back_bet_29_10.dat

sim_dry_run_horses_winner_back_bet_30_09.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=betting \
                                   --animal=horse \
                                   --bet_type=back \
                                   --bet_name=winner \
                                   --max_profit_factor=300 \
                                   --max_daily_loss=-250 \
                                   --start_date=2013-05-11 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=3 \
                                   --delta=0.9 \
                                   --saldo=10000 \
                                   --favorite_by=0 \
                                   --quiet > sim_dry_run_horses_winner_back_bet_30_09.dat

sim_dry_run_horses_winner_back_bet_27_03.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=betting \
                                   --animal=horse \
                                   --bet_type=back \
                                   --bet_name=winner \
                                   --max_profit_factor=300 \
                                   --max_daily_loss=-250 \
                                   --start_date=2013-05-11 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=2.7 \
                                   --delta=0.3 \
                                   --saldo=10000 \
                                   --favorite_by=0 \
                                   --quiet > sim_dry_run_horses_winner_back_bet_27_03.dat

sim_dry_run_hounds_winner_lay_bet_11_17.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=betting \
                                   --animal=hound \
                                   --bet_type=lay \
                                   --bet_name=winner \
                                   --max_profit_factor=5 \
                                   --max_daily_loss=-250 \
                                   --start_date=2013-05-11 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=11 \
                                   --delta=17 \
                                   --saldo=10000 \
                                   --favorite_by=0 \
                                   --quiet > sim_dry_run_hounds_winner_lay_bet_11_17.dat

sim_dry_run_hounds_winner_lay_bet_12_13.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=betting \
                                   --animal=hound \
                                   --bet_type=lay \
                                   --bet_name=winner \
                                   --max_profit_factor=300 \
                                   --max_daily_loss=-250 \
                                   --start_date=2013-05-11 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=12 \
                                   --delta=13 \
                                   --saldo=10000 \
                                   --favorite_by=0 \
                                   --quiet > sim_dry_run_hounds_winner_lay_bet_12_13.dat

sim_dry_run_hounds_winner_lay_bet_1_7.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=betting \
                                   --animal=hound \
                                   --bet_type=lay \
                                   --bet_name=winner \
                                   --max_profit_factor=0 \
                                   --max_daily_loss=-750 \
                                   --start_date=2013-05-11 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=1 \
                                   --delta=7 \
                                   --saldo=10000 \
                                   --favorite_by=0 \
                                   --quiet > sim_dry_run_hounds_winner_lay_bet_1_7.dat

sim_dry_run_hounds_winner_lay_bet_2_5.dat : $(BOT_TARGET)/bin/sim_equity
	$(BOT_TARGET)/bin/sim_equity --db_name=betting \
                                   --animal=hound \
                                   --bet_type=lay \
                                   --bet_name=winner \
                                   --max_profit_factor=0 \
                                   --max_daily_loss=-750 \
                                   --start_date=2013-05-11 \
                                   --stop_date=2013-12-31 \
                                   --size=30 \
                                   --price=2 \
                                   --delta=5 \
                                   --saldo=10000 \
                                   --favorite_by=0 \
                                   --quiet > sim_dry_run_hounds_winner_lay_bet_2_5.dat


########
#sim equity with history data
back_bet_horse_winner_loop.dat : $(BOT_TARGET)/bin/sim_equity_total
	$(BOT_TARGET)/bin/sim_equity_total \
                                 --db_name=bfhistory \
                                 --animal=horse \
                                 --bet_type=back \
                                 --bet_name=winner  \
                                 --start_date=2006-01-01 \
                                 --stop_date=2013-12-31 \
                                 --size=30 \
                                 --saldo=10000 \
                                 --quiet > back_bet_horse_winner_loop.dat

 back_bet_horse_place_loop.dat : $(BOT_TARGET)/bin/sim_equity_total
	$(BOT_TARGET)/bin/sim_equity_total \
                                 --db_name=bfhistory \
                                 --animal=horse \
                                 --bet_type=back \
                                 --bet_name=place    \
                                 --start_date=2006-01-01 \
                                 --stop_date=2013-12-31 \
                                 --size=30  \
                                 --saldo=10000 \
                                 --quiet >  back_bet_horse_place_loop.dat
back_bet_hound_winner_loop.dat : $(BOT_TARGET)/bin/sim_equity_total
	$(BOT_TARGET)/bin/sim_equity_total \
                                 --db_name=bfhistory \
                                 --animal=hound \
                                 --bet_type=back \
                                 --bet_name=winner \
                                 --start_date=2006-01-01 \
                                 --stop_date=2013-12-31 \
                                 --size=30  \
                                 --saldo=10000 \
                                 --quiet > back_bet_hound_winner_loop.dat
 back_bet_hound_place_loop.dat : $(BOT_TARGET)/bin/sim_equity_total
	$(BOT_TARGET)/bin/sim_equity_total \
                                 --db_name=bfhistory \
                                 --animal=hound \
                                 --bet_type=back \
                                 --bet_name=place   \
                                 --start_date=2006-01-01 \
                                 --stop_date=2013-12-31 \
                                 --size=30  \
                                 --saldo=10000 \
                                 --quiet > back_bet_hound_place_loop.dat
lay_bet_horse_winner_loop.dat : $(BOT_TARGET)/bin/sim_equity_total
	$(BOT_TARGET)/bin/sim_equity_total \
                                 --db_name=bfhistory \
                                 --animal=horse \
                                 --bet_type=lay \
                                 --bet_name=winner \
                                 --start_date=2010-05-11 \
                                 --stop_date=2013-12-31 \
                                 --size=30  \
                                 --saldo=10000 \
                                 --quiet > lay_bet_horse_winner_loop.dat
lay_bet_horse_place_loop.dat : $(BOT_TARGET)/bin/sim_equity_total
	$(BOT_TARGET)/bin/sim_equity_total \
                                 --db_name=bfhistory \
                                 --animal=horse \
                                 --bet_type=lay \
                                 --bet_name=place    \
                                 --start_date=2006-01-01 \
                                 --stop_date=2013-12-31 \
                                 --size=30  \
                                 --saldo=10000 \
                                 --quiet > lay_bet_horse_place_loop.dat
lay_bet_hound_winner_loop.dat : $(BOT_TARGET)/bin/sim_equity_total
	$(BOT_TARGET)/bin/sim_equity_total \
                                 --db_name=bfhistory \
                                 --animal=hound \
                                 --bet_type=lay \
                                 --bet_name=winner \
                                 --start_date=2006-01-01 \
                                 --stop_date=2013-12-31 \
                                 --size=30  \
                                 --saldo=10000 \
                                 --quiet > lay_bet_hound_winner_loop.dat
lay_bet_hound_place_loop.dat : $(BOT_TARGET)/bin/sim_equity_total
	$(BOT_TARGET)/bin/sim_equity_total \
                                 --db_name=bfhistory \
                                 --animal=hound \
                                 --bet_type=lay \
                                 --bet_name=place   \
                                 --start_date=2006-01-01 \
                                 --stop_date=2013-12-31 \
                                 --size=30  \
                                 --saldo=10000 \
                                 --quiet > lay_bet_hound_place_loop.dat
lay_favorite_bet_horse_winner_loop.dat : $(BOT_TARGET)/bin/sim_equity_total
	$(BOT_TARGET)/bin/sim_equity_total \
                                 --db_name=bfhistory \
                                 --animal=horse \
                                 --bet_type=lay_favorite \
                                 --bet_name=winner  \
                                 --start_date=2006-01-01 \
                                 --stop_date=2013-12-31 \
                                 --size=30  \
                                 --saldo=10000 \
                                 --quiet > lay_favorite_bet_horse_winner_loop.dat
lay_favorite_bet_horse_place_loop.dat : $(BOT_TARGET)/bin/sim_equity_total
	$(BOT_TARGET)/bin/sim_equity_total \
                                 --db_name=bfhistory \
                                 --animal=horse \
                                 --bet_type=lay_favorite \
                                 --bet_name=place    \
                                 --start_date=2006-01-01 \
                                 --stop_date=2013-12-31 \
                                 --size=30  \
                                 --saldo=10000 \
                                 --quiet > lay_favorite_bet_horse_place_loop.dat
lay_favorite_bet_hound_winner_loop.dat : $(BOT_TARGET)/bin/sim_equity_total
	$(BOT_TARGET)/bin/sim_equity_total \
                                 --db_name=bfhistory \
                                 --animal=hound \
                                 --bet_type=lay_favorite \
                                 --bet_name=winner \
                                 --start_date=2006-01-01 \
                                 --stop_date=2013-12-31 \
                                 --size=30  \
                                 --saldo=10000 \
                                 --quiet > lay_favorite_bet_hound_winner_loop.dat
lay_favorite_bet_hound_place_loop.dat : $(BOT_TARGET)/bin/sim_equity_total
	$(BOT_TARGET)/bin/sim_equity_total \
                                 --db_name=bfhistory \
                                 --animal=hound \
                                 --bet_type=lay_favorite \
                                 --bet_name=place   \
                                 --start_date=2006-01-01 \
                                 --stop_date=2013-12-31 \
                                 --size=30  \
                                 --saldo=10000 \
                                 --quiet > lay_favorite_bet_hound_place_loop.dat



##########

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
	rm *.png