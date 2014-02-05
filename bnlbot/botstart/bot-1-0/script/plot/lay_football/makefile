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
  
  
all  : $(PNGS)

png : half_time_score.png correct_score.png

test:
	@echo $(PNG2S)
	@echo $(DAT2S)
    
## equity start ##
#save the intermediate files too
.PRECIOUS : %.dat

# implict rules
# create a dat and then a png file from that dat
# $* is the stem
# $@ is the target file name

#%.dat : $(BOT_TARGET)/bin/equity 
#	$(BOT_TARGET)/bin/equity --host=$(DBHOST) \
#                                 --database=$(DBNAME) \
#                                 --port=$(DBPORT) \
#                                 --pwd=$(DBPWD) \
#                                 --user=$(DBUSER) \
#                                 --powerdays=$(shell echo $* | cut -d'-' -f2) \
#                                 --betname=$(shell echo $(shell echo $* | cut -d'-' -f1) | tr '[:lower:]' '[:upper:]') \
#                                 --saldo=$(SALDO) > $*.dat         

%.png : %.dat lay_football.gpl
	gnuplot -e "db_name='$(DBNAME)'" \
            -e "bet_type='$*'" \
            -e "target_png='$@'" \
            -e "data_file='$*.dat'" lay_football.gpl
	@echo "done gnuplot $* - $@ - $<"        

    

.PHONY : clean
clean :
	rm -rf  *.png 

#.PHONY : clean_all
#clean_all : clean
#	rm -rf *.dat *.green
