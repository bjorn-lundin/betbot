###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################

BET_NAMES_DRY := \
DIFF_R1_R4_005.00_001.70_PLC_2 \
DIFF_R1_R4_001.00_001.70_PLC_2 \
DIFF_R1_R4_003.00_001.70_PLC_2 \
DIFF_R1_R4_001.00_001.75_PLC_1 \
DIFF_R1_R4_003.00_001.75_PLC_1 \
DIFF_R1_R4_001.00_001.70_PLC_1 \
DIFF_R1_R4_003.00_001.70_PLC_1 \
DIFF_R1_R4_005.00_001.75_PLC_1 \
DIFF_R1_R4_001.00_001.75_PLC_2 \
DIFF_R1_R4_005.00_001.75_PLC_2 \
DIFF_R1_R4_003.00_001.75_PLC_2 \
DIFF_R1_R4_001.00_001.65_PLC_2 \
DIFF_R1_R4_003.00_001.65_PLC_2 \
DIFF_R1_R4_005.00_001.70_PLC_1 \
DIFF_R1_R2_003.00_001.45_WIN_1 \
DIFF_R1_R4_001.00_001.65_PLC_1 \
DIFF_R1_R4_005.00_001.80_PLC_2 \
DIFF_R1_R4_003.00_001.65_PLC_1 \
DIFF_R1_R4_003.00_001.80_PLC_2 \
DIFF_R1_R2_003.00_001.50_WIN_1 \
DIFF_R1_R4_001.00_001.60_PLC_1 \
DIFF_R1_R4_003.00_001.60_PLC_1 \
DIFF_R1_R2_001.00_001.45_WIN_1 \
DIFF_R1_R4_001.00_001.80_PLC_2 \
DIFF_R1_R2_001.00_001.35_WIN_1 \
DIFF_R1_R4_005.00_001.65_PLC_2 \
DIFF_R1_R4_001.00_001.60_PLC_2 \
DIFF_R1_R4_005.00_001.90_PLC_2 \
DIFF_R1_R4_003.00_001.60_PLC_2 \
DIFF_R1_R4_003.00_001.90_PLC_2 \
DIFF_R1_R4_001.00_001.80_PLC_1 \
DIFF_R1_R4_001.00_001.90_PLC_2 \
DIFF_R1_R4_005.00_001.60_PLC_2 \
DIFF_R1_R4_001.00_001.85_PLC_1 \
DIFF_R1_R4_003.00_001.80_PLC_1 \
DIFF_R1_R4_005.00_001.65_PLC_1 \
DIFF_R1_R4_005.00_001.60_PLC_1 \
DIFF_R1_R2_005.00_002.00_WIN_1 \
DIFF_R1_R4_003.00_001.85_PLC_1 \
DIFF_R1_R2_003.00_001.75_WIN_1 \
DIFF_R1_R4_005.00_001.85_PLC_2 \
DIFF_R1_R2_005.00_001.95_WIN_1 \
DIFF_R1_R4_003.00_001.85_PLC_2 \
DIFF_R1_R4_001.00_002.05_PLC_1 \
DIFF_R1_R4_001.00_002.00_PLC_1 \
DIFF_R1_R4_001.00_001.50_PLC_1 \
DIFF_R1_R4_005.00_001.95_PLC_2 \
DIFF_R1_R4_001.00_001.85_PLC_2 \
DIFF_R1_R4_001.00_001.90_PLC_1 \
DIFF_R1_R4_003.00_001.50_PLC_1 \
DIFF_R1_R4_003.00_001.95_PLC_2 \
DIFF_R1_R4_005.00_001.80_PLC_1 \
DIFF_R1_R4_001.00_001.55_PLC_1

BET_NAMES := $(BET_NAMES_DRY)



DATS := $(foreach i,$(BET_NAMES), $(i).dat)
PNGS := $(foreach i,$(BET_NAMES), $(i).png)


# do a wordcount of how many items in array, strip whitespace on mac
NUMBETS := $(shell echo $(BET_NAMES) | wc -w | tr -d '[:space:]')

all  :  pngs png_top

jmb : pngjmb

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
	@echo $(NUMBETS)
	@echo "---------------------"

PHONY : png_top
png_top: $(DATS)
	gnuplot -e "db_name='$(DBNAME)'" \
            -e "numbets='$(NUMBETS)'" \
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
	$(BOT_TARGET)/bin/graph_data --betname=$* --equity > $*.dat
#	$(BOT_TARGET)/bin/graph_data_ael --betname=$* --equity --side=LAY > $*.dat


%.png: $(DATS)
	gnuplot -e "db_name='$(DBNAME)'" \
            -e "numbets ='$(NUMBETS)'" \
            -e "target_png='$*.png'" \
            -e "files='$*'" equity_many.gpl


.PHONY : clean
clean :
	rm -rf  *.png *.dat
