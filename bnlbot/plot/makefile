#makefile for splitting full bet.dat file, rename the parts and plot the files


all: target profit.dat split plot

target :
	mkdir target


profit.dat : profit_tester.py
	python2.6 profit_tester.py  -n 1 -x 25| tee profit.dat

.PHONY : split
split : target profit.dat
	./split.bash profit.dat


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
