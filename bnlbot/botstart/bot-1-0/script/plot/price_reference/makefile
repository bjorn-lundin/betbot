DBHOST:=192.168.1.20
DBUSER:=bnl
DBNAME:=bnl

.PHONY : all 

all  : heatmap.png heatmap_3d.png back_heatmap.png back_heatmap_3d.png lay_heatmap.png lay_heatmap_3d.png

heatmap.png : heatmap.gpl plot_data.dat
	gnuplot -e "type='Win'" \
	        -e "title='Horses GB/IE - for laysize=100 skr and backsize= 700-800 skr and greenup for no loss'" \
	        -e "target_png='heatmap.png'" \
            -e "source_dat='plot_data.dat'" heatmap.gpl

heatmap_3d.png : heatmap_3d.gpl plot_data.dat
	gnuplot -e "type='Win'" \
	        -e "title='Horses GB/IE - for laysize=100 skr and backsize= 700-800 skr and greenup for no loss'" \
	        -e "target_png='heatmap_3d.png'" \
            -e "source_dat='plot_data.dat'" heatmap_3d.gpl

back_heatmap.png : heatmap.gpl back_plot_data.dat
	gnuplot -e "type='Win'" \
	        -e "title='Horses GB/IE - for backsize= 700-800 skr back but NO lay bet first'" \
	        -e "target_png='back_heatmap.png'" \
            -e "source_dat='back_plot_data.dat'" heatmap.gpl

back_heatmap_3d.png : heatmap_3d.gpl back_plot_data.dat
	gnuplot -e "type='Win'" \
	        -e "title='Horses GB/IE - for backsize= 700-800 skr back but NO lay bet first'" \
	        -e "target_png='back_heatmap_3d.png'" \
            -e "source_dat='back_plot_data.dat'" heatmap_3d.gpl

lay_heatmap.png : heatmap.gpl lay_plot_data.dat
	gnuplot -e "type='Win'" \
	        -e "title='Horses GB/IE - for laysize=100 skr lay and not back bet as safety'" \
	        -e "target_png='lay_heatmap.png'" \
            -e "source_dat='lay_plot_data.dat'" heatmap.gpl

lay_heatmap_3d.png : heatmap_3d.gpl lay_plot_data.dat
	gnuplot -e "type='Win'" \
	        -e "title='Horses GB/IE - for laysize=100 skr lay and not back bet as safety'" \
	        -e "target_png='lay_heatmap_3d.png'" \
            -e "source_dat='lay_plot_data.dat'" heatmap_3d.gpl

plot_data.dat : heatmap.dat filter_data.tcl
	cat heatmap.dat | ./filter_data.tcl > plot_data.dat

back_plot_data.dat : back_heatmap.dat filter_data.tcl
	cat back_heatmap.dat | ./filter_data.tcl > back_plot_data.dat

lay_plot_data.dat : lay_heatmap.dat filter_data.tcl
	cat lay_heatmap.dat | ./filter_data.tcl > lay_plot_data.dat

excel.dat : plot_data.dat filter_data_for_excel.bash
	cat plot_data.dat | ./filter_data_for_excel.bash > excel.dat

heatmap.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'M' and side in ('BACK','LAY') and BETNAME like 'GREENUP_LAY_FIXED_LOSS_TICS%' group by betname order by betname" \
    --output=heatmap.dat $(DBNAME)

back_heatmap.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'M' and side in ('BACK') and BETNAME like 'GREENUP_LAY_FIXED_LOSS_TICS%' group by betname order by betname" \
    --output=back_heatmap.dat $(DBNAME)

lay_heatmap.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select betname, sum(profit) from abets where status = 'M' and side in ('LAY') and BETNAME like 'GREENUP_LAY_FIXED_LOSS_TICS%' group by betname order by betname" \
    --output=lay_heatmap.dat $(DBNAME)

.PHONY : clean
clean :
	rm -rf  *.dat

.PHONY : very_clean
very_clean :
	rm -rf  *.dat *.png
