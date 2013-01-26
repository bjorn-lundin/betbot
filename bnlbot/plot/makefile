#makefile for splitting full bet.dat file, rename the parts and plot the files

TODAY=$(shell date -j -v-0d "+%Y_%m_%d")
ONE_WEEK_AGO=$(shell date -j -v-6d "+%Y_%m_%d")
WEEKLY_DIR=$(TODAY)\_$(ONE_WEEK_AGO)
DAILY_DIR=$(TODAY)

.PHONY : all
all: daily weekly

weekly_dir :
	mkdir $(WEEKLY_DIR)
	
daily_dir :
	mkdir $(DAILY_DIR)


.PHONY : weekly
weekly:  weekly_dats
	rm -f *.png
	./do_plot.bash
	for i in *.png; do mv $i $(WEEKLY_DIR)/; done


.PHONY : daily
daily :  daily_dats
	rm -f *.png
	./do_plot.bash
	for i in *.png; do mv $i $(DAILY_DIR)/; done


.PHONY : weekly_types
weekly_types :
	python profit_tester.py --min_price=1 \
	                        --max_price=25 \
	                        --start_date=$(ONE_WEEK_AGO) \
	                        --stop_date=$(TODAY) \
	                        --print_types \
	                        --quit_one > weekly_types


.PHONY : daily_types
daily_types :
	python profit_tester.py --min_price=1 \
	                        --max_price=25 \
	                        --start_date=$(ONE_WEEK_AGO) \
	                        --stop_date=$(TODAY) \
	                        --print_types \
	                        --quit_one > daily_types


.PHONY : weekly_dats 
weekly_dats : weekly_types weekly_dir
	./make_dats.bash $(ONE_WEEK_AGO) $(TODAY) weekly_types

.PHONY : daily_dats 
daily_dats : weekly_types daily_dir
	./make_dats.bash $(ONE_WEEK_AGO) $(TODAY) weekly_types


gplot : 
	./do_plot.bash






## pattern rule, make a .png file from a .dat file
#%.png: %.dat 
#	java BitmapExperiment $< > $@  



.PHONY : clean
clean:
	rm -f *.dat
	rm -f *.png
	rm -f weekly_types daily_types