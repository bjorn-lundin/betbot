#makefile for splitting full bet.dat file, rename the parts and plot the files


TODAY=$(shell date -j -v-0d "+%Y_%m_%d")
ONE_WEEK_AGO=$(shell date -j -v-6d "+%Y_%m_%d")

all: target profit.dat split plot

target :
	mkdir target

.PHONY : reports
reports : weekly daily


.PHONY : weekly
weekly:  weekly_types
	@echo "weekly"

.PHONY : daily
daily :  daily_types
	@echo "daily"


.PHONY : params
params :
	echo $(TODAY)


profit.dat : profit_tester.py
	python profit_tester.py  -n 1 -x 25| tee profit.dat

.PHONY : split
split : target profit.dat
	./split.bash profit.dat


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
weekly_dats : weekly_types
	./make_dats.bash $(ONE_WEEK_AGO) $(TODAY) weekly_types


gplot : 
	./do_plot.bash


## pattern rule, make a .png file from a .dat file
#%.png: %.dat 
#	java BitmapExperiment $< > $@  


# draw the plot
.PHONY : plot
plot: 
	./do_plot.bash target
#	gnuplot -e "typ='dry_run_hounds_winner_lay_bet'" -e "dat=22" plot_bets.cmd

.PHONY : clean
clean:
	rm -f *.dat
	rm -f *.png
	rm -f weekly_types daily_types