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


#HOST := localhost
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



START_DATE := 2013-01-01
STOP_DATE  := 2013-12-31
SIZE := 30
SALDO := 10000
BET_TYPE := winner


all : hounds_win_back_gb_36_01.png \
      horses_win_lay_go_early_us_10_90.png \
      horses_win_lay_early_gb_30_60.png \
      horses_win_lay_late_fr_30_60.png \
      horses_win_lay_late_us_10_90.png



## equity start ##


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



sb_hounds_win_back_gb_36_01.dat : $(BOT_TARGET)/bin/equity
	$(BOT_TARGET)/bin/equity --database=bnl \
                             --bet_name=SB_HOUNDS_WIN_BACK_GB_36_01 \
                             --host=localhost \
                             --port=5432 \
                             --start_date=2013-01-01 \
                             --stop_date=2013-12-31 \
                             --db_pwd=bnl \
                             --saldo=10000 > sb_hounds_win_back_gb_36_01.dat

dr_hounds_win_back_gb_36_01.dat : $(BOT_TARGET)/bin/equity
	$(BOT_TARGET)/bin/equity --database=bnl \
                             --bet_name=DR_HOUNDS_WIN_BACK_GB_36_01 \
                             --host=localhost \
                             --port=5432 \
                             --start_date=2013-01-01 \
                             --stop_date=2013-12-31 \
                             --db_pwd=bnl \
                             --saldo=10000 > dr_hounds_win_back_gb_36_01.dat
  

hounds_win_back_gb_36_01.png : dr_hounds_win_back_gb_36_01.dat sb_hounds_win_back_gb_36_01.dat
	gnuplot -e "start_date='2006-01-01'" \
            -e "stop_date='2013-12-31'" \
            -e "db_name='bnl'" \
            -e "bet_type='hounds_win_back_gb_36_01 dr/sb'" \
            -e "target_png='hounds_win_back_gb_36_01.png'" \
            -e "dr_file='dr_hounds_win_back_gb_36_01.dat'" \
            -e "sb_file='sb_hounds_win_back_gb_36_01.dat'" equity.gpl
ifneq ($(DISPLAY),)
	$(SHOW_PNG) hounds_win_back_gb_36_01.png
endif

##############################################################################


sb_horses_win_lay_go_early_us_10_90.dat : $(BOT_TARGET)/bin/equity
	$(BOT_TARGET)/bin/equity --database=bnl \
                             --bet_name=SB_HORSES_WIN_LAY_GO_EARLY_US_10_90 \
                             --host=localhost \
                             --port=5432 \
                             --start_date=2013-01-01 \
                             --stop_date=2013-12-31 \
                             --db_pwd=bnl \
                             --saldo=10000 > sb_horses_win_lay_go_early_us_10_90.dat

dr_horses_win_lay_go_early_us_10_90.dat : $(BOT_TARGET)/bin/equity
	$(BOT_TARGET)/bin/equity --database=bnl \
                             --bet_name=DR_HORSES_WIN_LAY_GO_EARLY_US_10_90 \
                             --host=localhost \
                             --port=5432 \
                             --start_date=2013-01-01 \
                             --stop_date=2013-12-31 \
                             --db_pwd=bnl \
                             --saldo=10000 > dr_horses_win_lay_go_early_us_10_90.dat
  

horses_win_lay_go_early_us_10_90.png : dr_horses_win_lay_go_early_us_10_90.dat sb_horses_win_lay_go_early_us_10_90.dat
	gnuplot -e "start_date='2006-01-01'" \
            -e "stop_date='2013-12-31'" \
            -e "db_name='bnl'" \
            -e "bet_type='horses_win_lay_go_early_us_10_90 dr/sb'" \
            -e "target_png='horses_win_lay_go_early_us_10_90.png'" \
            -e "dr_file='dr_horses_win_lay_go_early_us_10_90.dat'" \
            -e "sb_file='sb_horses_win_lay_go_early_us_10_90.dat'" equity.gpl
ifneq ($(DISPLAY),)
	$(SHOW_PNG) horses_win_lay_go_early_us_10_90.png
endif  
##############################################################################

sb_horses_win_lay_early_gb_30_60.dat : $(BOT_TARGET)/bin/equity
	$(BOT_TARGET)/bin/equity --database=bnl \
                             --bet_name=SB_HORSES_WIN_LAY_EARLY_GB_30_60 \
                             --host=localhost \
                             --port=5432 \
                             --start_date=2013-01-01 \
                             --stop_date=2013-12-31 \
                             --db_pwd=bnl \
                             --saldo=10000 > sb_horses_win_lay_early_gb_30_60.dat

dr_horses_win_lay_early_gb_30_60.dat : $(BOT_TARGET)/bin/equity
	$(BOT_TARGET)/bin/equity --database=bnl \
                             --bet_name=DR_HORSES_WIN_LAY_EARLY_GB_30_60 \
                             --host=localhost \
                             --port=5432 \
                             --start_date=2013-01-01 \
                             --stop_date=2013-12-31 \
                             --db_pwd=bnl \
                             --saldo=10000 > dr_horses_win_lay_early_gb_30_60.dat
  

horses_win_lay_early_gb_30_60.png : dr_horses_win_lay_early_gb_30_60.dat sb_horses_win_lay_early_gb_30_60.dat
	gnuplot -e "start_date='2006-01-01'" \
            -e "stop_date='2013-12-31'" \
            -e "db_name='bnl'" \
            -e "bet_type='horses_win_lay_early_gb_30_60 dr/sb'" \
            -e "target_png='horses_win_lay_early_gb_30_60.png'" \
            -e "dr_file='dr_horses_win_lay_early_gb_30_60.dat'" \
            -e "sb_file='sb_horses_win_lay_early_gb_30_60.dat'" equity.gpl
ifneq ($(DISPLAY),)
	$(SHOW_PNG) horses_win_lay_early_gb_30_60.png
endif  

##############################################################################

sb_horses_win_lay_late_fr_30_60.dat : $(BOT_TARGET)/bin/equity
	$(BOT_TARGET)/bin/equity --database=bnl \
                             --bet_name=SB_HORSES_WIN_LAY_LATE_FR_30_60 \
                             --host=localhost \
                             --port=5432 \
                             --start_date=2013-01-01 \
                             --stop_date=2013-12-31 \
                             --db_pwd=bnl \
                             --saldo=10000 > sb_horses_win_lay_late_fr_30_60.dat

dr_horses_win_lay_late_fr_30_60.dat : $(BOT_TARGET)/bin/equity
	$(BOT_TARGET)/bin/equity --database=bnl \
                             --bet_name=DR_HORSES_WIN_LAY_LATE_FR_30_60 \
                             --host=localhost \
                             --port=5432 \
                             --start_date=2013-01-01 \
                             --stop_date=2013-12-31 \
                             --db_pwd=bnl \
                             --saldo=10000 > dr_horses_win_lay_late_fr_30_60.dat
  

horses_win_lay_late_fr_30_60.png : dr_horses_win_lay_late_fr_30_60.dat sb_horses_win_lay_late_fr_30_60.dat
	gnuplot -e "start_date='2006-01-01'" \
            -e "stop_date='2013-12-31'" \
            -e "db_name='bnl'" \
            -e "bet_type='horses_win_lay_late_fr_30_60 dr/sb'" \
            -e "target_png='horses_win_lay_late_fr_30_60.png'" \
            -e "dr_file='dr_horses_win_lay_late_fr_30_60.dat'" \
            -e "sb_file='sb_horses_win_lay_late_fr_30_60.dat'" equity.gpl
ifneq ($(DISPLAY),)
	$(SHOW_PNG) horses_win_lay_late_fr_30_60.png
endif  

##############################################################################

sb_horses_win_lay_late_us_10_90.dat : $(BOT_TARGET)/bin/equity
	$(BOT_TARGET)/bin/equity --database=bnl \
                             --bet_name=SB_HORSES_WIN_LAY_LATE_US_10_90 \
                             --host=localhost \
                             --port=5432 \
                             --start_date=2013-01-01 \
                             --stop_date=2013-12-31 \
                             --db_pwd=bnl \
                             --saldo=10000 > sb_horses_win_lay_late_us_10_90.dat

dr_horses_win_lay_late_us_10_90.dat : $(BOT_TARGET)/bin/equity
	$(BOT_TARGET)/bin/equity --database=bnl \
                             --bet_name=DR_HORSES_WIN_LAY_LATE_US_10_90 \
                             --host=localhost \
                             --port=5432 \
                             --start_date=2013-01-01 \
                             --stop_date=2013-12-31 \
                             --db_pwd=bnl \
                             --saldo=10000 > dr_horses_win_lay_late_us_10_90.dat
  

horses_win_lay_late_us_10_90.png : dr_horses_win_lay_late_us_10_90.dat sb_horses_win_lay_late_us_10_90.dat
	gnuplot -e "start_date='2006-01-01'" \
            -e "stop_date='2013-12-31'" \
            -e "db_name='bnl'" \
            -e "bet_type='horses_win_lay_late_us_10_90 dr/sb'" \
            -e "target_png='horses_win_lay_late_us_10_90.png'" \
            -e "dr_file='dr_horses_win_lay_late_us_10_90.dat'" \
            -e "sb_file='sb_horses_win_lay_late_us_10_90.dat'" equity.gpl
ifneq ($(DISPLAY),)
	$(SHOW_PNG) horses_win_lay_late_us_10_90.png
endif  



.PHONY : clean
clean :
	rm -f *.png rm -f *.dat
