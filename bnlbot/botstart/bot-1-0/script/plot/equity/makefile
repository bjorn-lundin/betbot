###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################



BET_NAMES_DRY := \
 BACK_5_4_4_8.00_14.00 \
 BACK_6_4_4_8.00_14.00 \
 LAY_3_1_4_10.00_16.00 \
 BACK_5_4_4_9.00_15.00 \
 BACK_3_4_4_8.00_14.00 \
 BACK_4_4_4_8.00_14.00 \
 BACK_4_4_4_9.00_15.00 \

BET_NAMES_REAL := \
  HORSES_PLC_BACK_FINISH_1.15_7.0_1


BET_NAMES := $(BET_NAMES_DRY)

DATS := $(foreach i,$(BET_NAMES), $(i).dat)
PNGS := $(foreach i,$(BET_NAMES), $(i).png)


# do a wordcount of how many items in array
NUMBETS := $(shell echo $(BET_NAMES) | wc -w )


all  :  pngs png_top

dat : $(DATS)

pngs : $(PNGS)


test:
	@echo "---------------------"
	@echo $(BET_NAMES)
	@echo "---------------------"
	@echo $(PNGS)
	@echo "---------------------"
	@echo $(DATS)
	@echo "---------------------"

PHONY : png_top
png_top: $(DATS)
	gnuplot -e "db_name='$(DBNAME)'" \
            -e "numbets ='$(NUMBETS)'" \
            -e "target_png='equity_top_$(NUMBETS).png'" \
            -e "files='$(BET_NAMES)'" equity_many.gpl
## equity start ##
#save the intermediate files too
#.PRECIOUS : %.dat

# implict rules
# create a dat and then a png file from that dat
# $* is the stem
# $@ is the target file name


#%.dat:
#	psql ael \
#    --tuples-only \
#    --command="select STARTTS,sum(PROFIT) from ABETS where BETNAME ='$*' group by STARTTS order by STARTTS" \
#    --output=tmp.dat $(DBNAME)
#	cat tmp.dat | awk -F '|' '{i=i+$$2; print $$1,FS,i}' |  head -n-1 >  $*.dat
#	@echo "done gnuplot $* - $@ - $<"
#

#%.dat : $(BOT_TARGET)/bin/equity
#	$(BOT_TARGET)/bin/equity --host=$(DBHOST) \
#                                 --database=$(DBNAME) \
#                                 --port=$(DBPORT) \
#                                 --pwd=$(DBPWD) \
#                                 --user=$(DBUSER) \
#                                 --powerdays=$(shell echo $* | cut -d'-' -f2) \
#                                 --betname=$(shell echo $(shell echo $* | cut -d'-' -f1) | tr '[:lower:]' '[:upper:]') \
#                                 --saldo=$(SALDO) > $*.dat

%.dat:
	$(BOT_TARGET)/bin/graph_data_ael --betname=$* --equity > $*.dat

%.png: $(DATS)
	gnuplot -e "db_name='$(DBNAME)'" \
            -e "numbets ='$(NUMBETS)'" \
            -e "target_png='$*.png'" \
            -e "files='$*'" equity_many.gpl

.PHONY : clean
clean :
	rm -rf  *.png

.PHONY : clean_all
clean_all : clean
	rm -rf *.dat *.green
