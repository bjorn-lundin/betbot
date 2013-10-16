###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################

UNAME := $(shell uname)


DBHOST := sebjlun-deb64
#DBHOST := 192.168.0.13
#DBHOST := nonodev.com
ifeq ($(DBHOST),localhost)
  DBNAME := bnl
  DBPORT := 5432
  DBPWD  := bnl
  DBUSER := bnl
endif

ifeq ($(DBHOST),192.168.0.13)
  DBNAME := betting
  DBPORT := 5432
  DBPWD  := bnl
  DBUSER := bnl
endif


ifeq ($(DBHOST),nonodev.com)
# Go via ssh tunnel
  HOST := 127.0.0.1
  DBNAME := bnls
  DBPORT := 5433
  #Escape a '$' with a '$'  BettingFotboll1$ is correct pwd
  DBPWD  := BettingFotboll1$$
  DBUSER := bnl
endif

ifeq ($(DBHOST),sebjlun-deb64)
  DBNAME := bnl
  DBPORT := 5432
  DBPWD  := bnl
  DBUSER := bnl
endif



#POWERDAYS := 128
START_DATE := 2012-01-01
STOP_DATE  := 2013-12-31
#SIZE := 30
SALDO := 0
POWERDAYSLIST := 107 207 307 114 214 314 121 221 321 128 228 328 135 235 335


#BET_NAMES := horses_plc_lay4_ie \
#             horses_win_lay5_ie \
#             horses_plc_lay4_gb \
#             horses_win_lay4_gb \
#             horses_win_lay4_ie \
#             horses_win_fav2_gb \
#             horses_win_fav5_ie \
#             horses_win_fav4_ie \
             
#BET_NAMES := \
#     hounds_plc_lay6_gb \
#     hounds_win_fav3_gb \
#     hounds_win_fav5_gb \
#     hounds_win_fav4_gb \
#     hounds_plc_fav3_gb \
#     hounds_plc_fav5_gb \
#     hounds_plc_lay3_gb \
     
BET_NAMES := \
  horses_win_lay1_gb_6 \
  horses_win_lay3_gb_12 \
  horses_win_lay4_gb_12 \
  horses_win_lay6_gb_15 \
  horses_win_fav2_gb_8 \
  horses_win_fav5_gb_11 \
  hounds_plc_lay6_gb_8
     

BET_NAMES_WITH_POWER := $(foreach i,$(POWERDAYSLIST), $(foreach j,$(BET_NAMES), $(j)-$(i)))

PNGS := $(foreach i,$(BET_NAMES_WITH_POWER), $(i).png)
DATS := $(foreach i,$(BET_NAMES_WITH_POWER), $(i).dat)


PNG2S := $(foreach i,$(BET_NAMES_WITH_POWER), $(i).xyz)
DAT2S := $(foreach i,$(BET_NAMES_WITH_POWER), $(i).dat2)


all  : $(PNGS)

dat : $(DATS)
png : $(PNGS)
dat2 : $(DAT2S)
png2 : $(PNG2S)
xyz : $(PNG2S)

test:
	@echo $(BET_NAMES_WITH_POWER)
	@echo $(PNG2S)
	@echo $(DAT2S)

    
    
#min/max/delta/hours_before
green : \
  green_30_40_4_1_GB.green \
  green_10_20_5_1_GB.green \
  green_15_25_5_1_GB.green \
  green_30_40_5_1_GB.green \
  green_10_20_1_2_GB.green \
  green_15_25_1_2_GB.green \
  green_30_40_1_2_GB.green \
  green_10_20_2_2_GB.green \
  green_15_25_2_2_GB.green \
  green_30_40_2_2_GB.green \
  green_10_20_3_2_GB.green \
  green_15_25_3_2_GB.green \
  green_30_40_3_2_GB.green \
  green_10_20_4_2_GB.green \
  green_15_25_4_2_GB.green \
  green_30_40_4_2_GB.green \
  green_10_20_5_2_GB.green \
  green_15_25_5_2_GB.green \
  green_30_40_5_2_GB.green \
  green_10_20_1_3_GB.green \
  green_15_25_1_3_GB.green \
  green_30_40_1_3_GB.green \
  green_10_20_2_3_GB.green \
  green_15_25_2_3_GB.green \
  green_30_40_2_3_GB.green \
  green_10_20_3_3_GB.green \
  green_15_25_3_3_GB.green \
  green_30_40_3_3_GB.green \
  green_10_20_4_3_GB.green \
  green_15_25_4_3_GB.green \
  green_30_40_4_3_GB.green \
  green_10_20_5_3_GB.green \
  green_15_25_5_3_GB.green \
  green_30_40_5_3_GB.green \
  green_10_20_1_4_GB.green \
  green_15_25_1_4_GB.green \
  green_30_40_1_4_GB.green \
  green_10_20_2_4_GB.green \
  green_15_25_2_4_GB.green \
  green_30_40_2_4_GB.green \
  green_10_20_3_4_GB.green \
  green_15_25_3_4_GB.green \
  green_30_40_3_4_GB.green \
  green_10_20_4_4_GB.green \
  green_15_25_4_4_GB.green \
  green_30_40_4_4_GB.green \
  green_10_20_5_4_GB.green \
  green_15_25_5_4_GB.green \
  green_30_40_5_4_GB.green \
#  green_10_20_1_1_GB.green \
#  green_15_25_1_1_GB.green \
#  green_30_40_1_1_GB.green \
#  green_10_20_2_1_GB.green \
#  green_15_25_2_1_GB.green \
#  green_30_40_2_1_GB.green \
#  green_10_20_3_1_GB.green \
#  green_15_25_3_1_GB.green \
#  green_30_40_3_1_GB.green \
#  green_10_20_4_1_GB.green \
#  green_15_25_4_1_GB.green \

    
## equity start ##
#save the intermediate files too
.PRECIOUS : %.dat
.PRECIOUS : %.dat2

# implict rules
# create a dat and then a png file from that dat
# $* is the stem
# $@ is the target file name

%.dat : $(BOT_TARGET)/bin/equity 
	$(BOT_TARGET)/bin/equity --host=$(DBHOST) \
                                 --database=$(DBNAME) \
                                 --port=$(DBPORT) \
                                 --pwd=$(DBPWD) \
                                 --user=$(DBUSER) \
                                 --powerdays=$(shell echo $* | cut -d'-' -f2) \
                                 --betname=$(shell echo $(shell echo $* | cut -d'-' -f1) | tr '[:lower:]' '[:upper:]') \
                                 --saldo=$(SALDO) > $*.dat         

%.png : %.dat equity.gpl
	gnuplot -e "db_name='$(DBNAME)'" \
            -e "bet_type='$*'" \
            -e "target_png='$@'" \
            -e "powerdays='$(shell echo $* | cut -d'-' -f2)'" \
            -e "data_file='$*.dat'" equity.gpl
	@echo "done gnuplot $* - $@ - $<"        
    

%.dat2 : $(BOT_TARGET)/bin/profit_per_weekday 
	$(BOT_TARGET)/bin/profit_per_weekday --host=$(DBHOST) \
                                 --database=$(DBNAME) \
                                 --port=$(DBPORT) \
                                 --pwd=$(DBPWD) \
                                 --user=$(DBUSER) \
                                 --powerdays=$(shell echo $* | cut -d'-' -f2) \
                                 --betname=$(shell echo $(shell echo $* | cut -d'-' -f1) | tr '[:lower:]' '[:upper:]') > $*.dat2         

%.xyz : %.dat2 profit_per_weekday.gpl
	gnuplot -e "db_name='$(DBNAME)'" \
            -e "bet_type='$*'" \
            -e "target_png='$@'" \
            -e "powerdays='$(shell echo $* | cut -d'-' -f2)'" \
            -e "data_file='$*.dat2'" profit_per_weekday.gpl
	@echo "done gnuplot $* - $@ - $<"        
    

#min/max/delta/hours_before
#  green_10_20_2_2_GB.green \


%.green : $(BOT_TARGET)/bin/greening_up_2 
	$(BOT_TARGET)/bin/greening_up_2  \
                                    --max_odds=$(shell echo $* | cut -d'_' -f3) \
                                    --min_odds=$(shell echo $* | cut -d'_' -f2) \
                                    --delta_odds=$(shell echo $* | cut -d'_' -f4) \
                                    --hours_before_start=$(shell echo $* | cut -d'_' -f5) \
                                    --start_date=$(START_DATE) \
                                    --stop_date=$(STOP_DATE) > $*.green


	gnuplot -e "db_name='bnl'" \
            -e "bet_type='greening up'" \
            -e "target_png='green_10_20_1_1_GB.png'" \
            -e "data_file='green_10_20_1_1_GB.plt'" equity_greening_up.gpl
#                                    
# $BOT_TARGET/bin/greening_up_3 > $BOT_SCRIPT/plot/greenup/green_10_20_1_1_GB.plt
                                    
#	$(BOT_TARGET)/bin/greening_up_2 --host=$(DBHOST) \
#                                    --database=$(DBNAME) \
#                                    --port=$(DBPORT) \
#                                    --pwd=$(DBPWD) \
#                                    --user=$(DBUSER) \
#                                    --max_odds=$(shell echo $* | cut -d'_' -f3) \
#                                    --min_odds=$(shell echo $* | cut -d'_' -f2) \
#                                    --delta_odds=$(shell echo $* | cut -d'_' -f4) \
#                                    --hours_before_start=$(shell echo $* | cut -d'_' -f5) \
#                                    --start_date=$(START_DATE) \
#                                    --stop_date=$(STOP_DATE) > $*.green         



.PHONY : clean
clean :
	rm -rf  *.png 

.PHONY : clean_all
clean_all : clean
	rm -rf *.dat *.green
