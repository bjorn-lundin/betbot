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

DO_SHOW := no


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


DBHOST := localhost
#DBHOST := 192.168.0.13
#DBHOST := nonodev.com
ifeq ($(DBHOST),localhost)
  DBNAME := bnl
  DBPORT := 5432
  DBPWD := bnl
  DBUSER := bnl
endif

ifeq ($(DBHOST),192.168.0.13)
  DBNAME := betting
  DBPORT := 5432
  DBPWD := bnl
  DBUSER := bnl
endif

ifeq ($(DBHOST),nonodev.com)
  HOST := 127.0.0.1
  DBNAME := bnls
  DBPORT := 5433
  #Escape a '$' with a '$'  BettingFotboll1$ is correct pwd
  DBPWD := BettingFotboll1$$
  DBUSER := bnl
endif

#POWERDAYS := 128
#START_DATE := 2013-01-01
#STOP_DATE  := 2013-12-31
#SIZE := 30
SALDO := 0
POWERDAYSLIST := 107 207 307 114 214 314 121 221 321 128 228 328 135 235 335

all : \
      hounds_win_back_gb_35_01.png \
      hounds_win_back_gb_36_01.png \
      hounds_win_back_gb_45_07.png \
      hounds_win_back_gb_60_25.png \
#      horses_win_back_fr_60_05.png \
#      horses_win_back_fr_65_03.png \
#      horses_win_back_gb_60_05.png \
#      horses_win_back_gb_65_03.png \
#      horses_win_back_ie_60_05.png \
#      horses_win_back_ie_65_03.png \
#      horses_win_back_sg_60_05.png \
#      horses_win_back_us_60_05.png \
#      horses_win_back_za_60_05.png \
#      horses_win_back_za_65_03.png \
#      horses_plc_layfav1_fr_107.png \
#      horses_plc_layfav1_gb_107.png \
#      horses_plc_layfav1_ie_107.png \
#      horses_plc_layfav1_sg_107.png \
#      horses_plc_layfav1_us_107.png \
#      horses_plc_layfav1_za_107.png \
#      horses_plc_layfav2_fr_107.png \
#      horses_plc_layfav2_gb_107.png \
#      horses_plc_layfav2_ie_107.png \
#      horses_plc_layfav2_sg_107.png \
#      horses_plc_layfav2_us_107.png \
#      horses_plc_layfav2_za_107.png \
#      horses_plc_layfav3_fr_107.png \
#      horses_plc_layfav3_gb_107.png \
#      horses_plc_layfav3_ie_107.png \
#      horses_plc_layfav3_sg_107.png \
#      horses_plc_layfav3_us_107.png \
#      horses_plc_layfav3_za_107.png \
#      horses_plc_layfav4_fr_107.png \
#      horses_plc_layfav4_gb_107.png \
#      horses_plc_layfav4_ie_107.png \
#      horses_plc_layfav4_sg_107.png \
#      horses_plc_layfav4_us_107.png \
#      horses_plc_layfav4_za_107.png \
#      horses_plc_lay_early_gb_17_22_0_200_5_107.png \
#      horses_plc_lay_early_ie_17_22_0_200_5_107.png \
#      horses_plc_lay_late_gb_17_22_0_200_5_107.png \
#      horses_plc_lay_late_ie_17_22_0_200_5_107.png \
#      horses_win_lay_early_fr_10_90_107.png \
#      horses_win_lay_early_fr_30_60_107.png \
#      horses_win_lay_early_gb_10_60_107.png \
#      horses_win_lay_early_gb_10_90_107.png \
#      horses_win_lay_early_gb_30_60_107.png \
#      horses_win_lay_early_ie_10_90_107.png \
#      horses_win_lay_early_ie_30_60_107.png \
#      horses_win_lay_early_sg_10_90_107.png \
#      horses_win_lay_early_sg_30_60_107.png \
#      horses_win_lay_early_us_10_90_107.png \
#      horses_win_lay_early_us_30_60_107.png \
#      horses_win_lay_early_za_10_90_107.png \
#      horses_win_lay_early_za_30_60_107.png \
#      horses_win_layfav1_fr_107.png \
#      horses_win_layfav1_gb_107.png \
#      horses_win_layfav1_ie_107.png \
#      horses_win_layfav1_sg_107.png \
#      horses_win_layfav1_us_107.png \
#      horses_win_layfav1_za_107.png \
#      horses_win_layfav2_fr_107.png \
#      horses_win_layfav2_gb_107.png \
#      horses_win_layfav2_ie_107.png \
#      horses_win_layfav2_sg_107.png \
#      horses_win_layfav2_us_107.png \
#      horses_win_layfav2_za_107.png \
#      horses_win_layfav3_fr_107.png \
#      horses_win_layfav3_gb_107.png \
#      horses_win_layfav3_ie_107.png \
#      horses_win_layfav3_sg_107.png \
#      horses_win_layfav3_us_107.png \
#      horses_win_layfav3_za_107.png \
#      horses_win_layfav4_fr_107.png \
#      horses_win_layfav4_gb_107.png \
#      horses_win_layfav4_ie_107.png \
#      horses_win_layfav4_sg_107.png \
#      horses_win_layfav4_us_107.png \
#      horses_win_layfav4_za_107.png \
#      horses_win_lay_go_early_fr_10_90_107.png \
#      horses_win_lay_go_early_fr_30_60_107.png \
#      horses_win_lay_go_early_gb_10_90_107.png \
#      horses_win_lay_go_early_gb_30_60_107.png \
#      horses_win_lay_go_early_ie_10_90_107.png \
#      horses_win_lay_go_early_ie_30_60_107.png \
#      horses_win_lay_go_early_sg_10_90_107.png \
#      horses_win_lay_go_early_sg_30_60_107.png \
#      horses_win_lay_go_early_us_10_90_107.png \
#      horses_win_lay_go_early_us_30_60_107.png \
#      horses_win_lay_go_early_za_10_90_107.png \
#      horses_win_lay_go_early_za_30_60_107.png \
#      horses_win_lay_go_late_fr_10_90_107.png \
#      horses_win_lay_go_late_fr_30_60_107.png \
#      horses_win_lay_go_late_gb_10_90_107.png \
#      horses_win_lay_go_late_gb_30_60_107.png \
#      horses_win_lay_go_late_gb_35_50_107.png \
#      horses_win_lay_go_late_ie_10_90_107.png \
#      horses_win_lay_go_late_ie_30_60_107.png \
#      horses_win_lay_go_late_ie_35_50_107.png \
#      horses_win_lay_go_late_sg_10_90_107.png \
#      horses_win_lay_go_late_sg_30_60_107.png \
#      horses_win_lay_go_late_us_10_90_107.png \
#      horses_win_lay_go_late_us_30_60_107.png \
#      horses_win_lay_go_late_za_10_90_107.png \
#      horses_win_lay_go_late_za_30_60_107.png \
#      horses_win_lay_late_fr_10_90_107.png \
#      horses_win_lay_late_fr_30_60_107.png \
#      horses_win_lay_late_gb_10_60_107.png \
#      horses_win_lay_late_gb_10_90_107.png \
#      horses_win_lay_late_gb_30_60_107.png \
#      horses_win_lay_late_gb_35_50_107.png \
#      horses_win_lay_late_ie_10_90_107.png \
#      horses_win_lay_late_ie_35_50_107.png \
#      horses_win_lay_late_sg_10_90_107.png \
#      horses_win_lay_late_sg_30_60_107.png \
#      horses_win_lay_late_us_10_90_107.png \
#      horses_win_lay_late_us_30_60_107.png \
#      horses_win_lay_late_za_10_90_107.png \
#      horses_win_lay_late_za_30_60_107.png \
#      hounds_win_back_gb_35_01_107.png \
#      hounds_win_back_gb_36_01_107.png \
#      hounds_win_back_gb_45_07_107.png \
#      hounds_win_back_gb_60_25_107.png \
#      hounds_win_back_go_gb_35_01_107.png \
#      hounds_win_back_go_gb_36_01_107.png \
#      hounds_win_back_go_gb_45_07_107.png \
#      hounds_win_back_go_gb_60_25_107.png \


.PHONY : powerdays
powerdays :
	@echo "hej"
	$(foreach i,$(POWERDAYSLIST), $(shell export POWERDAYS=$(i) && make ))
	@echo "hej då"

## equity start ##


## test implict rules
## if a .bet file is present, create a corresponding dat and then a png file from that dat
## $* is the stem
#%.png :
#	$(BOT_TARGET)/bin/equity --host=$(HOST) \
#                                 --database=$(DBNAME) \
#                                 --port=$(DBPORT) \
#                                 --pwd=$(DBPWD) \
#                                 --user=$(DBUSER) \
#                                 --bet_type=$(shell echo $* | tr '[:lower:]' '[:upper:]') \
#                                 --saldo=$(SALDO) \
#                                 --start_date=2013-01-01 \
#                                 --stop_date=2013-12-31 > $*.dat
#
#	gnuplot -e "start_date='$(STOP_DATE)'" \
#                -e "stop_date='$(STOP_DATE)'" \
#                -e "db_name='$(DBNAME)'" \
#                -e "bet_type='$*'" \
#                -e "target_png='$@'" \
#                -e "sim_input_file='sim_$*.dat'" \
#                -e "input_file='$*.dat'" equity.gpl
#ifneq ($(UNAME),MINGW32_NT-6.1)
#	$(SHOW_PNG) $*.png
#endif

#save the intermediate files too
.PRECIOUS : %.dat
.PRECIOUS : $(POWERDAYS)/%.dat

# test implict rules
#  create a dat and then a png file from that dat
# $* is the stem
# $@ is the target file name

$(POWERDAYS) :
	@echo "mkdir $(POWERDAYS)"
	mkdir $(POWERDAYS)
    
$(POWERDAYS)/%.dat : $(BOT_TARGET)/bin/equity $(POWERDAYS)
	$(BOT_TARGET)/bin/equity --host=$(DBHOST) \
                                 --database=$(DBNAME) \
                                 --port=$(DBPORT) \
                                 --pwd=$(DBPWD) \
                                 --user=$(DBUSER) \
                                 --powerdays=$(POWERDAYS) \
                                 --betname=$(shell echo $* | tr '[:lower:]' '[:upper:]') \
                                 --saldo=$(SALDO) > $(POWERDAYS)/$*.dat
#%.plt : %.dat
#	cat $*.dat | sort| uniq > $*.plt

%.png : $(POWERDAYS)/%.dat equity.gpl
	gnuplot -e "db_name='$(DBNAME)'" \
            -e "bet_type='$*'" \
            -e "target_png='$(POWERDAYS)/$@'" \
            -e "powerdays='$(POWERDAYS)'" \
            -e "data_file='$(POWERDAYS)/$*.dat'" equity.gpl
ifeq ($(DO_SHOW),yes)
ifneq ($(UNAME),MINGW32_NT-6.1)
	$(SHOW_PNG) $*.png
endif
endif


#hounds_win_back_gb_35_01.dat : $(BOT_TARGET)/bin/equity
#	$(BOT_TARGET)/bin/equity --database=$(DBNAME) \
#                             --sb_betname=SB_HOUNDS_WIN_BACK_GB_35_01 \
#                             --dr_betname=DR_HOUNDS_WIN_BACK_GB_35_01 \
#                             --host=$(DBHOST) \
#                             --port=$(DBPORT) \
#                             --user=$(DBUSER) \
#                             --pwd=$(DBPWD) \
#                             --saldo=$(SALDO) > hounds_win_back_gb_35_01.dat
#  
#
#hounds_win_back_gb_35_01.png : hounds_win_back_gb_35_01.dat equity.gpl
#	gnuplot -e "db_name='$(DBNAME)'" \
#            -e "bet_type='hounds_win_back_gb_35_01 dr/sb'" \
#            -e "target_png='hounds_win_back_gb_35_01.png'" \
#            -e "data_file='hounds_win_back_gb_35_01.dat'" equity.gpl
#            
#ifeq ($(DO_SHOW),yes)
#ifneq ($(DISPLAY),)
#	$(SHOW_PNG) hounds_win_back_gb_35_01.png
#endif
#endif  
#
###############################################################################
#
#


.PHONY : clean
clean :
	rm -rf $(POWERDAYSLIST)
