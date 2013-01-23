set style data linespoints
set surface 
set contour base
#set contour surface

set view 60, 60, 1, 1

#set key right
set key off
set dgrid3d
set pm3d
set title "profit f(stoptime,price) for ".typ." ".dat
set ylabel "price"
set xlabel "stoptime (h)"
set zlabel "skr"

#splot 'target/dry_run_hounds_winner_lay_bet_22.dat' using 5:6:7 notitle

splot "target/".typ."_".dat.".dat" using 5:6:7 notitle


