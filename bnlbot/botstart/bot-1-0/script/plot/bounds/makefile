MF := marker_file

.PHONY : all png update_only

all  : png

png: heatmap_plc_week_01.png_plc heatmap_win_week_01.png_win \
     heatmap_plc_week_02.png_plc heatmap_win_week_02.png_win \
     heatmap_plc_week_03.png_plc heatmap_win_week_03.png_win \
     heatmap_plc_week_04.png_plc heatmap_win_week_04.png_win \
     heatmap_plc_week_05.png_plc heatmap_win_week_05.png_win \
     heatmap_plc_week_06.png_plc heatmap_win_week_06.png_win \
     heatmap_plc_week_07.png_plc heatmap_win_week_07.png_win 
     
#png: heatmap_win_all.png heatmap_plc_all.png heatmap_win_50.png heatmap_plc_50.png \
#     heatmap_win_week_01.png heatmap_plc_week_01.png \
#     heatmap_win_week_02.png heatmap_plc_week_02.png \
#     heatmap_win_week_03.png heatmap_plc_week_03.png

#heatmap_win_all.png : heatmap_win_all.dat heatmap_bounds.gpl
#	gnuplot -e "type='Win'" \
#	        -e "desc='profit skr'" \
#	        -e "target_png='heatmap_win_all.png'" \
#            -e "source_dat='heatmap_win_all.dat'" heatmap_bounds.gpl
#
#heatmap_win_all.dat : $(BOT_TARGET)/bin/stat_maker $(MF)
#	$(BOT_TARGET)/bin/stat_maker --market_type=win  > heatmap_win_all.dat
#
#heatmap_plc_all.png : heatmap_plc_all.dat heatmap_bounds.gpl
#	gnuplot -e "type='Place'" \
#	        -e "desc='profit skr'" \
#	        -e "target_png='heatmap_plc_all.png'" \
#            -e "source_dat='heatmap_plc_all.dat'" heatmap_bounds.gpl
#
#heatmap_plc_all.dat : $(BOT_TARGET)/bin/stat_maker $(MF)
#	$(BOT_TARGET)/bin/stat_maker --market_type=plc > heatmap_plc_all.dat
#


#weeknum is $(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1)

%.png_plc : %.dat_plc
	gnuplot -e "type='Place'" \
	        -e "desc='week $(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1) plc'" \
	        -e "target_png='$*.png'" \
            -e "source_dat='$*.dat'" heatmap_bounds.gpl


%.dat_plc : $(BOT_TARGET)/bin/stat_maker $(MF)
	$(BOT_TARGET)/bin/stat_maker \
	  --market_type=plc\
	  --week=$(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1) \
	 --lower_limit=-1 > $*.dat


%.png_win : %.dat_win
	gnuplot -e "type='win'" \
	        -e "desc='week $(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1) win'" \
	        -e "target_png='$*.png'" \
            -e "source_dat='$*.dat'" heatmap_bounds.gpl

%.dat_win : $(BOT_TARGET)/bin/stat_maker $(MF)
	$(BOT_TARGET)/bin/stat_maker \
	  --market_type=win\
	  --week=$(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1) \
	 --lower_limit=-1 > $*.dat




    
update_only :
	$(BOT_TARGET)/bin/stat_maker --update_only
	touch $(MF)
    



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
	rm -rf  *.png *.dat
