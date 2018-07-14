DBHOST:=192.168.1.20
DBUSER:=bnl
DBNAME:=bnl

.PHONY : all 


#$(shell echo $* | cut -d'-' -f2)
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

all  : \
       place_back_heatmap_f_1.01_2d.png place_back_heatmap_f_1.01_3d.png \
       place_back_heatmap_t_1.01_2d.png place_back_heatmap_t_1.01_3d.png \
       place_back_heatmap_f_1.02_2d.png place_back_heatmap_f_1.02_3d.png \
       place_back_heatmap_t_1.02_2d.png place_back_heatmap_t_1.02_3d.png \
       place_back_heatmap_f_1.03_2d.png place_back_heatmap_f_1.03_3d.png \
       place_back_heatmap_t_1.03_2d.png place_back_heatmap_t_1.03_3d.png \
       place_back_heatmap_f_1.04_2d.png place_back_heatmap_f_1.04_3d.png \
       place_back_heatmap_t_1.04_2d.png place_back_heatmap_t_1.04_3d.png \
       place_back_heatmap_f_1.05_2d.png place_back_heatmap_f_1.05_3d.png \
       place_back_heatmap_t_1.05_2d.png place_back_heatmap_t_1.05_3d.png \
       place_back_heatmap_f_1.06_2d.png place_back_heatmap_f_1.06_3d.png \
       place_back_heatmap_t_1.06_2d.png place_back_heatmap_t_1.06_3d.png \
        

# start 1.01
#Match direct start

place_back_heatmap_t_1.01_2d.png : heatmap_2d.gpl place_back_plot_data_t_1.01.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct, min price matched=1.01'" \
                -e "target_png='place_back_heatmap_t_1.01_2d.png'" \
                -e "source_dat='place_back_plot_data_t_1.01.dat'" heatmap_2d.gpl

place_back_heatmap_t_1.02_2d.png : heatmap_2d.gpl place_back_plot_data_t_1.02.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct, min price matched=1.02'" \
                -e "target_png='place_back_heatmap_t_1.02_2d.png'" \
                -e "source_dat='place_back_plot_data_t_1.02.dat'" heatmap_2d.gpl

place_back_heatmap_t_1.03_2d.png : heatmap_2d.gpl place_back_plot_data_t_1.03.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct, min price matched=1.03'" \
                -e "target_png='place_back_heatmap_t_1.03_2d.png'" \
                -e "source_dat='place_back_plot_data_t_1.03.dat'" heatmap_2d.gpl

place_back_heatmap_t_1.04_2d.png : heatmap_2d.gpl place_back_plot_data_t_1.04.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct, min price matched=1.04'" \
                -e "target_png='place_back_heatmap_t_1.04_2d.png'" \
                -e "source_dat='place_back_plot_data_t_1.04.dat'" heatmap_2d.gpl


place_back_heatmap_t_1.05_2d.png : heatmap_2d.gpl place_back_plot_data_t_1.05.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct, min price matched=1.05'" \
                -e "target_png='place_back_heatmap_t_1.05_2d.png'" \
                -e "source_dat='place_back_plot_data_t_1.05.dat'" heatmap_2d.gpl

place_back_heatmap_t_1.06_2d.png : heatmap_2d.gpl place_back_plot_data_t_1.06.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct, min price matched=1.06'" \
                -e "target_png='place_back_heatmap_t_1.06_2d.png'" \
                -e "source_dat='place_back_plot_data_t_1.06.dat'" heatmap_2d.gpl



place_back_heatmap_t_1.01_3d.png : heatmap_3d.gpl place_back_plot_data_t_1.01.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct, min price matched=1.01'" \
                -e "target_png='place_back_heatmap_t_1.01_3d.png'" \
                -e "source_dat='place_back_plot_data_t_1.01.dat'" heatmap_3d.gpl

place_back_heatmap_t_1.02_3d.png : heatmap_3d.gpl place_back_plot_data_t_1.02.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct, min price matched=1.02'" \
                -e "target_png='place_back_heatmap_t_1.02_3d.png'" \
                -e "source_dat='place_back_plot_data_t_1.02.dat'" heatmap_3d.gpl

place_back_heatmap_t_1.03_3d.png : heatmap_3d.gpl place_back_plot_data_t_1.03.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct, min price matched=1.03'" \
                -e "target_png='place_back_heatmap_t_1.03_3d.png'" \
                -e "source_dat='place_back_plot_data_t_1.03.dat'" heatmap_3d.gpl

place_back_heatmap_t_1.04_3d.png : heatmap_3d.gpl place_back_plot_data_t_1.04.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct, min price matched=1.04'" \
                -e "target_png='place_back_heatmap_t_1.04_3d.png'" \
                -e "source_dat='place_back_plot_data_t_1.04.dat'" heatmap_3d.gpl

place_back_heatmap_t_1.05_3d.png : heatmap_3d.gpl place_back_plot_data_t_1.05.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct, min price matched=1.05'" \
                -e "target_png='place_back_heatmap_t_1.05_3d.png'" \
                -e "source_dat='place_back_plot_data_t_1.05.dat'" heatmap_3d.gpl

place_back_heatmap_t_1.06_3d.png : heatmap_3d.gpl place_back_plot_data_t_1.06.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct, min price matched=1.06'" \
                -e "target_png='place_back_heatmap_t_1.06_3d.png'" \
                -e "source_dat='place_back_plot_data_t_1.06.dat'" heatmap_3d.gpl



place_back_plot_data_t_1.01.dat : place_back_heatmap_t_1.01.dat filter_data.tcl
	cat place_back_heatmap_t_1.01.dat | ./filter_data.tcl > place_back_plot_data_t_1.01.dat

place_back_plot_data_t_1.02.dat : place_back_heatmap_t_1.02.dat filter_data.tcl
	cat place_back_heatmap_t_1.02.dat | ./filter_data.tcl > place_back_plot_data_t_1.02.dat

place_back_plot_data_t_1.03.dat : place_back_heatmap_t_1.03.dat filter_data.tcl
	cat place_back_heatmap_t_1.03.dat | ./filter_data.tcl > place_back_plot_data_t_1.03.dat

place_back_plot_data_t_1.04.dat : place_back_heatmap_t_1.04.dat filter_data.tcl
	cat place_back_heatmap_t_1.04.dat | ./filter_data.tcl > place_back_plot_data_t_1.04.dat

place_back_plot_data_t_1.05.dat : place_back_heatmap_t_1.05.dat filter_data.tcl
	cat place_back_heatmap_t_1.05.dat | ./filter_data.tcl > place_back_plot_data_t_1.05.dat

place_back_plot_data_t_1.06.dat : place_back_heatmap_t_1.06.dat filter_data.tcl
	cat place_back_heatmap_t_1.06.dat | ./filter_data.tcl > place_back_plot_data_t_1.06.dat

place_back_heatmap_t_1.01.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'MATCHED' and BETNAME like 'PLC_BACK_%_T_1.01' and pricematched >= 1.01 group by betname order by betname" \
    --output=place_back_heatmap_t_1.01.dat $(DBNAME)

place_back_heatmap_t_1.02.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'MATCHED' and BETNAME like 'PLC_BACK_%_T_1.01' and pricematched >= 1.02 group by betname order by betname" \
    --output=place_back_heatmap_t_1.02.dat $(DBNAME)

place_back_heatmap_t_1.03.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'MATCHED' and BETNAME like 'PLC_BACK_%_T_1.01' and pricematched >= 1.03 group by betname order by betname" \
    --output=place_back_heatmap_t_1.03.dat $(DBNAME)

place_back_heatmap_t_1.04.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'MATCHED' and BETNAME like 'PLC_BACK_%_T_1.01' and pricematched >= 1.04 group by betname order by betname" \
    --output=place_back_heatmap_t_1.04.dat $(DBNAME)

place_back_heatmap_t_1.05.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'MATCHED' and BETNAME like 'PLC_BACK_%_T_1.01' and pricematched >= 1.05 group by betname order by betname" \
    --output=place_back_heatmap_t_1.05.dat $(DBNAME)

place_back_heatmap_t_1.06.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'MATCHED' and BETNAME like 'PLC_BACK_%_T_1.01' and pricematched >= 1.06 group by betname order by betname" \
    --output=place_back_heatmap_t_1.06.dat $(DBNAME)


#Match direct stop
#Not Match direct start

place_back_heatmap_f_1.01_2d.png : heatmap_2d.gpl place_back_plot_data_f_1.01.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct=no, min price matched=1.01'" \
                -e "target_png='place_back_heatmap_f_1.01_2d.png'" \
                -e "source_dat='place_back_plot_data_f_1.01.dat'" heatmap_2d.gpl

place_back_heatmap_f_1.02_2d.png : heatmap_2d.gpl place_back_plot_data_f_1.02.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct=no, min price matched=1.02'" \
                -e "target_png='place_back_heatmap_f_1.02_2d.png'" \
                -e "source_dat='place_back_plot_data_f_1.02.dat'" heatmap_2d.gpl

place_back_heatmap_f_1.03_2d.png : heatmap_2d.gpl place_back_plot_data_f_1.03.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct=no, min price matched=1.03'" \
                -e "target_png='place_back_heatmap_f_1.03_2d.png'" \
                -e "source_dat='place_back_plot_data_f_1.03.dat'" heatmap_2d.gpl

place_back_heatmap_f_1.04_2d.png : heatmap_2d.gpl place_back_plot_data_f_1.04.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct=no, min price matched=1.04'" \
                -e "target_png='place_back_heatmap_f_1.04_2d.png'" \
                -e "source_dat='place_back_plot_data_f_1.04.dat'" heatmap_2d.gpl


place_back_heatmap_f_1.05_2d.png : heatmap_2d.gpl place_back_plot_data_f_1.05.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct=no, min price matched=1.05'" \
                -e "target_png='place_back_heatmap_f_1.05_2d.png'" \
                -e "source_dat='place_back_plot_data_f_1.05.dat'" heatmap_2d.gpl

place_back_heatmap_f_1.06_2d.png : heatmap_2d.gpl place_back_plot_data_f_1.06.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct=no, min price matched=1.06'" \
                -e "target_png='place_back_heatmap_f_1.06_2d.png'" \
                -e "source_dat='place_back_plot_data_f_1.06.dat'" heatmap_2d.gpl


place_back_heatmap_f_1.01_3d.png : heatmap_3d.gpl place_back_plot_data_f_1.01.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct=no, min price matched=1.01'" \
                -e "target_png='place_back_heatmap_f_1.01_3d.png'" \
                -e "source_dat='place_back_plot_data_f_1.01.dat'" heatmap_3d.gpl

place_back_heatmap_f_1.02_3d.png : heatmap_3d.gpl place_back_plot_data_f_1.02.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct=no, min price matched=1.02'" \
                -e "target_png='place_back_heatmap_f_1.02_3d.png'" \
                -e "source_dat='place_back_plot_data_f_1.02.dat'" heatmap_3d.gpl

place_back_heatmap_f_1.03_3d.png : heatmap_3d.gpl place_back_plot_data_f_1.03.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct=no, min price matched=1.03'" \
                -e "target_png='place_back_heatmap_f_1.03_3d.png'" \
                -e "source_dat='place_back_plot_data_f_1.03.dat'" heatmap_3d.gpl

place_back_heatmap_f_1.04_3d.png : heatmap_3d.gpl place_back_plot_data_f_1.04.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct=no, min price matched=1.04'" \
                -e "target_png='place_back_heatmap_f_1.04_3d.png'" \
                -e "source_dat='place_back_plot_data_f_1.04.dat'" heatmap_3d.gpl

place_back_heatmap_f_1.05_3d.png : heatmap_3d.gpl place_back_plot_data_f_1.05.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct=no, min price matched=1.05'" \
                -e "target_png='place_back_heatmap_f_1.05_3d.png'" \
                -e "source_dat='place_back_plot_data_f_1.05.dat'" heatmap_3d.gpl

place_back_heatmap_f_1.06_3d.png : heatmap_3d.gpl place_back_plot_data_f_1.06.dat
	gnuplot -e "type='Place'" \
                -e "title='Horses GB/IE - for PLACE-market, WIN-odds backsize=30 skr match direct=no, min price matched=1.06'" \
                -e "target_png='place_back_heatmap_f_1.06_3d.png'" \
                -e "source_dat='place_back_plot_data_f_1.06.dat'" heatmap_3d.gpl

place_back_plot_data_f_1.01.dat : place_back_heatmap_f_1.01.dat filter_data.tcl
	cat place_back_heatmap_f_1.01.dat | ./filter_data.tcl > place_back_plot_data_f_1.01.dat

place_back_plot_data_f_1.02.dat : place_back_heatmap_f_1.02.dat filter_data.tcl
	cat place_back_heatmap_f_1.02.dat | ./filter_data.tcl > place_back_plot_data_f_1.02.dat

place_back_plot_data_f_1.03.dat : place_back_heatmap_f_1.03.dat filter_data.tcl
	cat place_back_heatmap_f_1.03.dat | ./filter_data.tcl > place_back_plot_data_f_1.03.dat

place_back_plot_data_f_1.04.dat : place_back_heatmap_f_1.04.dat filter_data.tcl
	cat place_back_heatmap_f_1.04.dat | ./filter_data.tcl > place_back_plot_data_f_1.04.dat

place_back_plot_data_f_1.05.dat : place_back_heatmap_f_1.05.dat filter_data.tcl
	cat place_back_heatmap_f_1.05.dat | ./filter_data.tcl > place_back_plot_data_f_1.05.dat

place_back_plot_data_f_1.06.dat : place_back_heatmap_f_1.06.dat filter_data.tcl
	cat place_back_heatmap_f_1.06.dat | ./filter_data.tcl > place_back_plot_data_f_1.06.dat

place_back_heatmap_f_1.01.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'MATCHED' and BETNAME like 'PLC_BACK_%_F_1.01' and pricematched >= 1.01 group by betname order by betname" \
    --output=place_back_heatmap_f_1.01.dat $(DBNAME)

place_back_heatmap_f_1.02.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'MATCHED' and BETNAME like 'PLC_BACK_%_F_1.01' and pricematched >= 1.02 group by betname order by betname" \
    --output=place_back_heatmap_f_1.02.dat $(DBNAME)

place_back_heatmap_f_1.03.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'MATCHED' and BETNAME like 'PLC_BACK_%_F_1.01' and pricematched >= 1.03 group by betname order by betname" \
    --output=place_back_heatmap_f_1.03.dat $(DBNAME)

place_back_heatmap_f_1.04.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'MATCHED' and BETNAME like 'PLC_BACK_%_F_1.01' and pricematched >= 1.04 group by betname order by betname" \
    --output=place_back_heatmap_f_1.04.dat $(DBNAME)

place_back_heatmap_f_1.05.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'MATCHED' and BETNAME like 'PLC_BACK_%_F_1.01' and pricematched >= 1.05 group by betname order by betname" \
    --output=place_back_heatmap_f_1.05.dat $(DBNAME)

place_back_heatmap_f_1.06.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'MATCHED' and BETNAME like 'PLC_BACK_%_F_1.01' and pricematched >= 1.06 group by betname order by betname" \
    --output=place_back_heatmap_f_1.06.dat $(DBNAME)

#Not Match direct stop




.PHONY : clean
clean :
	rm -rf  *.dat *.png

