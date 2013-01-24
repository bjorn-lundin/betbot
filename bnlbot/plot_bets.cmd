
set terminal png medium size 640,480 background '#ffffffff'
set output "target/".typ.".png"

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


set xyplane at 0
#show xyplane

#splot 'target/dry_run_hounds_winner_lay_bet.dat' using 3:4:5 notitle


if (is_lay == 0 ) splot "target/".typ.".dat" using 3:5:6 notitle
if (is_lay == 1 ) splot "target/".typ.".dat" using 3:4:6 notitle


