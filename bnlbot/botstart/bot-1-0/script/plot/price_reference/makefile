DBHOST:=192.168.1.20
DBUSER:=bnl
DBNAME:=bnl

.PHONY : all 

all  : heatmap.png heatmap_3d.png

heatmap.png : heatmap.gpl plot_data.dat
	gnuplot -e "type='Win'" \
	        -e "target_png='heatmap.png'" \
            -e "source_dat='plot_data.dat'" heatmap.gpl

heatmap_3d.png : heatmap_3d.gpl plot_data.dat
	gnuplot -e "type='Win'" \
	        -e "target_png='heatmap_3d.png'" \
            -e "source_dat='plot_data.dat'" heatmap_3d.gpl

plot_data.dat : heatmap.dat filter_data.bash
	cat heatmap.dat | ./filter_data.bash > plot_data.dat

excel.dat : plot_data.dat filter_data_for_excel.bash
	cat plot_data.dat | ./filter_data_for_excel.bash > excel.dat

heatmap.dat :
	psql --host=$(DBHOST) \
    --username=$(DBUSER) \
    --tuples-only \
    --command="select reference, sum(profit) from abets where status = 'M' group by reference order by reference" \
    --output=heatmap.dat $(DBNAME)

.PHONY : clean
clean :
	rm -rf  *.dat

.PHONY : very_clean
very_clean :
	rm -rf  *.dat *.png
