DBHOST:=192.168.1.20
DBUSER:=bnl
DBNAME:=bnl

.PHONY : all 

all  : price_refer_sum.png
   

price_refer_sum.png : heatmap_gh.gpl plot_data.dat
	gnuplot -e "type='Win'" \
	        -e "target_png='price_refer_sum.png'" \
            -e "source_dat='plot_data.dat'" heatmap.gpl
	gnuplot -e "type='Win'" \
	        -e "target_png='price_refer_sum_3d.png'" \
            -e "source_dat='plot_data.dat'" heatmap_3d.gpl
	#rm heatmap_win_all.dat

plot_data.dat : price_refer_sum.dat filter_data.bash
	cat price_refer_sum.dat | ./filter_data.bash > plot_data.dat


price_refer_sum.dat :
	psql --host=$(DBHOST)\
    --username=$(DBUSER) \
    --tuples-only \
    --command="select reference, sum(profit) from abets group by reference order by reference" \
    --output=price_refer_sum.dat $(DBNAME)



.PHONY : clean
clean :
	rm -rf  *.dat


.PHONY : very_clean
very_clean :
	rm -rf  *.dat *.png
