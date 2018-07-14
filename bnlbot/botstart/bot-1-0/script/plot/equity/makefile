###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################


#PLCGREENUP_LAY_FIXED_LOSS_TICS_001_10.50 \
#PLCGREENUP_LAY_FIXED_LOSS_TICS_001_11.00 \
#PLCGREENUP_LAY_FIXED_LOSS_TICS_001_11.50 \
#PLCGREENUP_LAY_FIXED_LOSS_TICS_001_04.70 \
#PLCGREENUP_LAY_FIXED_LOSS_TICS_001_04.30 \

BET_NAMES_DRY := \
PLC_BACK_1.10_07.00_F_1.01 \
PLC_BACK_1.50_02.00_F_1.01 \
PLC_BACK_1.50_01.00_F_1.01 \
PLC_BACK_1.54_01.00_F_1.01 \
PLC_BACK_1.54_02.00_F_1.01 \
PLC_BACK_1.52_01.00_F_1.01 \
PLC_BACK_1.52_02.00_F_1.01 \
PLC_BACK_1.50_02.00_T_1.01 \
PLC_BACK_1.50_01.00_T_1.01 \
PLC_BACK_1.54_01.00_T_1.01 \
PLC_BACK_1.54_02.00_T_1.01




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
	$(BOT_TARGET)/bin/graph_data_ael --betname=$* --equity --min_price_matched=1.06 > $*.dat


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
