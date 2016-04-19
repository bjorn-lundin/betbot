MF := marker_file

.PHONY : all png update_only

all  : png

# lost data for jan + feb 2016:-(
#     heatmap_plc_month_01.png_month_plc heatmap_win_month_01.png_month_win \
#     heatmap_plc_month_02.png_month_plc heatmap_win_month_02.png_month_win \
#     heatmap_plc_week_01.png_week_plc   heatmap_win_week_01.png_week_win \
#     heatmap_plc_week_02.png_week_plc   heatmap_win_week_02.png_week_win \
#     heatmap_plc_week_03.png_week_plc   heatmap_win_week_03.png_week_win \
#     heatmap_plc_week_04.png_week_plc   heatmap_win_week_04.png_week_win \
#     heatmap_plc_week_05.png_week_plc   heatmap_win_week_05.png_week_win \
#     heatmap_plc_week_06.png_week_plc   heatmap_win_week_06.png_week_win \
#     heatmap_plc_week_07.png_week_plc   heatmap_win_week_07.png_week_win \
#     heatmap_plc_week_08.png_week_plc   heatmap_win_week_08.png_week_win \
#     heatmap_plc_week_09.png_week_plc   heatmap_win_week_09.png_week_win \


png: heatmap_win_all.png                heatmap_plc_all.png         \
     heatmap_plc_month_03.png_month_plc heatmap_win_month_03.png_month_win \
     heatmap_plc_month_04.png_month_plc heatmap_win_month_04.png_month_win \
     heatmap_plc_week_10.png_week_plc   heatmap_win_week_10.png_week_win \
     heatmap_plc_week_11.png_week_plc   heatmap_win_week_11.png_week_win \
     heatmap_plc_week_12.png_week_plc   heatmap_win_week_12.png_week_win \
     heatmap_plc_week_13.png_week_plc   heatmap_win_week_13.png_week_win \
     heatmap_plc_week_14.png_week_plc   heatmap_win_week_14.png_week_win \
     heatmap_plc_week_15.png_week_plc   heatmap_win_week_15.png_week_win \
     heatmap_plc_week_16.png_week_plc   heatmap_win_week_16.png_week_win \

heatmap_win_all.png : heatmap_win_all.dat heatmap_bounds.gpl
	gnuplot -e "type='Win'" \
	        -e "range_low=-100" \
	        -e "range_high=10000" \
	        -e "desc='profit skr'" \
	        -e "target_png='heatmap_win_all.png'" \
            -e "source_dat='heatmap_win_all.dat'" heatmap_bounds.gpl
	rm heatmap_win_all.dat

heatmap_win_all.dat : $(BOT_TARGET)/bin/stat_maker $(MF)
	$(BOT_TARGET)/bin/stat_maker --market_type=win  > heatmap_win_all.dat

heatmap_plc_all.png : heatmap_plc_all.dat heatmap_bounds.gpl
	gnuplot -e "type='Place'" \
	        -e "range_low=-100" \
	        -e "range_high=10000" \
	        -e "desc='profit skr'" \
	        -e "target_png='heatmap_plc_all.png'" \
            -e "source_dat='heatmap_plc_all.dat'" heatmap_bounds.gpl
	rm heatmap_plc_all.dat

heatmap_plc_all.dat : $(BOT_TARGET)/bin/stat_maker $(MF)
	$(BOT_TARGET)/bin/stat_maker --market_type=plc > heatmap_plc_all.dat



#weeknum is in $(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1)

%.png_week_plc : %.dat_week_plc
	gnuplot -e "type='Place'" \
	        -e "range_low=-100" \
	        -e "range_high=4000" \
	        -e "desc='week $(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1) plc'" \
	        -e "target_png='$*.png'" \
            -e "source_dat='$*.dat'" heatmap_bounds.gpl


%.dat_week_plc : $(BOT_TARGET)/bin/stat_maker $(MF)
	$(BOT_TARGET)/bin/stat_maker \
	  --market_type=plc\
	  --week=$(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1) \
	  --month=0 \
      --lower_limit=-1 > $*.dat


%.png_week_win : %.dat_week_win
	gnuplot -e "type='win'" \
	        -e "range_low=-100" \
	        -e "range_high=4000" \
	        -e "desc='week $(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1) win'" \
	        -e "target_png='$*.png'" \
            -e "source_dat='$*.dat'" heatmap_bounds.gpl

%.dat_week_win : $(BOT_TARGET)/bin/stat_maker $(MF)
	$(BOT_TARGET)/bin/stat_maker \
	  --market_type=win\
	  --week=$(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1) \
	  --month=0 \
      --lower_limit=-1 > $*.dat


#month is in $(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1)

%.png_month_plc : %.dat_month_plc
	gnuplot -e "type='Place'" \
	        -e "range_low=-100" \
	        -e "range_high=8000" \
	        -e "desc='month $(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1) plc'" \
	        -e "target_png='$*.png'" \
            -e "source_dat='$*.dat'" heatmap_bounds.gpl


%.dat_month_plc : $(BOT_TARGET)/bin/stat_maker $(MF)
	$(BOT_TARGET)/bin/stat_maker \
	  --market_type=plc \
	  --week=0 \
	  --month=$(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1) \
	 --lower_limit=-1 > $*.dat


%.png_month_win : %.dat_month_win
	gnuplot -e "type='win'" \
	        -e "range_low=-100" \
	        -e "range_high=8000" \
	        -e "desc='month $(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1) win'" \
	        -e "target_png='$*.png'" \
            -e "source_dat='$*.dat'" heatmap_bounds.gpl

%.dat_month_win : $(BOT_TARGET)/bin/stat_maker $(MF)
	$(BOT_TARGET)/bin/stat_maker \
	  --market_type=win\
	  --week=0 \
	  --month=$(shell echo $(shell echo $* | cut -d'_' -f4) | cut -d'.' -f1) \
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
