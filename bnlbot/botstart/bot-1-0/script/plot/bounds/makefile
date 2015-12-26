###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################

UNAME := $(shell uname)



all  : png

dat : $(DATS)



test:
	@echo "---------------------"
	@echo $(BET_NAMES)
	@echo "---------------------"
	@echo $(PNGS)
	@echo "---------------------"
	@echo $(DATS)
	@echo "---------------------"

PHONY : png
png: heatmap_win.png heatmap_plc.png 

heatmap_win.png : heatmap_win.dat heatmap_bounds.gpl
	gnuplot -e "type='Win'" \
	        -e "desc='cnt*(hitrate-needed hitrate)'" \
	        -e "target_png='heatmap_win.png'" \
            -e "source_dat='heatmap_win.dat'" heatmap_bounds.gpl
heatmap_win.dat : $(BOT_TARGET)/bin/stat_maker
	$(BOT_TARGET)/bin/stat_maker --market_type=win > heatmap_win.dat
            
heatmap_plc.png : heatmap_plc.dat heatmap_bounds.gpl
	gnuplot -e "type='Place'" \
	        -e "desc='cnt*(hitrate-needed hitrate)'" \
	        -e "target_png='heatmap_plc.png'" \
            -e "source_dat='heatmap_plc.dat'" heatmap_bounds.gpl

heatmap_plc.dat : $(BOT_TARGET)/bin/stat_maker
	$(BOT_TARGET)/bin/stat_maker --market_type=plc > heatmap_plc.dat
                        
            
            
            
## equity start ##
#save the intermediate files too
#.PRECIOUS : %.dat

# implict rules
# create a dat and then a png file from that dat
# $* is the stem
# $@ is the target file name

   
#%.dat:
#	psql --host=$(DBHOST)\
#    --username=$(DBUSER) \
#    --tuples-only \
#    --command="select STARTTS,sum(PROFIT) from ABETS where BETNAME ='$*' group by STARTTS order by STARTTS" \
#    --output=tmp.dat $(DBNAME)
#	cat tmp.dat | awk -F '|' '{i=i+$$2; print $$1,FS,i}' |  head -n-1 >  $*.dat
#	@echo "done gnuplot $* - $@ - $<"        



#%.dat : $(BOT_TARGET)/bin/equity 
#	$(BOT_TARGET)/bin/equity --host=$(DBHOST) \
#                                 --database=$(DBNAME) \
#                                 --port=$(DBPORT) \
#                                 --pwd=$(DBPWD) \
#                                 --user=$(DBUSER) \
#                                 --powerdays=$(shell echo $* | cut -d'-' -f2) \
#                                 --betname=$(shell echo $(shell echo $* | cut -d'-' -f1) | tr '[:lower:]' '[:upper:]') \
#                                 --saldo=$(SALDO) > $*.dat         
    

.PHONY : clean
clean :
	rm -rf  *.png 

.PHONY : clean_all
clean_all : clean
	rm -rf *.dat
