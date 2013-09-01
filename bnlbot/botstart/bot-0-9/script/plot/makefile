###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################

UNAME := $(shell uname)

DBHOST := localhost
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

#POWERDAYS := 128
#START_DATE := 2013-01-01
#STOP_DATE  := 2013-12-31
#SIZE := 30
SALDO := 0
POWERDAYSLIST := 107 207 307 114 214 314 121 221 321 128 228 328 135 235 335


BET_NAMES := horses_plc_lay4_ie \
             horses_win_lay5_ie \
             horses_plc_lay4_gb \
             horses_win_lay4_gb \
             horses_win_lay4_ie \
             horses_win_fav2_gb \
             horses_win_fav5_ie \
             horses_win_fav4_ie \

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
    
    
.PHONY : clean
clean :
	rm -rf  *.png

.PHONY : clean_all
clean_all : clean
	rm -rf *.dat
