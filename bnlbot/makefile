#makefile for splitting full bet.dat file, rename the parts and plot the files


all: target split plot

target :
	mkdir target

.PHONY : split
split : target
	./split.bash profit.dat


# draw the plot
plot: 
	./do_plot.bash target
#	gnuplot -e "typ='dry_run_hounds_winner_lay_bet'" -e "dat=22" plot_bets.cmd

.PHONY : clean
clean:
	rm -rf target
