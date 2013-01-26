#makefile for splitting full bet.dat file, rename the parts and plot the files


TODAY=$(shell date -j -v-0d "+%Y-%m-%d")
ONE_WEEK_AGO=$(shell date -j -v-6d "+%Y-%m-%d")

all: target profit.dat split plot

target :
	mkdir target


.PHONY : params
params :
	echo $(TODAY)


profit.dat : profit_tester.py
	python profit_tester.py  -n 1 -x 25| tee profit.dat

.PHONY : split
split : target profit.dat
	./split.bash profit.dat

.PHONY :dates
dates :
	python profit_tester.py --min_price=1 \
	                        --max_price=25 \
	                        --start_date=$(ONE_WEEK_AGO) \
	                        --stop_date=$(TODAY) \
	                        --print_dates \
	                        --quit_one > dates

.PHONY :types
types :
	python profit_tester.py --min_price=1 \
	                        --max_price=25 \
	                        --start_date=$(ONE_WEEK_AGO) \
	                        --stop_date=$(TODAY) \
	                        --print_types \
	                        --quit_one > types


gplot : 
	gnuplot \
        -e "typ='dry_run_hounds_winner_lay_bet'" \
        -e "start_date='2013-01-25'" \
        -e "stop_date='2013-01-26'" \
        -e "is_lay=1" \
        plot_bets.gpl


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
	rm -rf target
	rm -f profit.dat
