#!/bin/bash


#to be able to ctrl-c
trap "exit" SIGINT SIGTERM

hound_place_lay_price_list="1 2 3 4 5 6 7 8 9 10"
lay_price_list="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20"
back_price_list="1.0 1.20 1.40 1.60 1.80 \
                 2.0 2.20 2.40 2.60 2.80 \
                 3.0 3.20 3.40 3.60 3.80 \
                 4.0 4.20 4.40 4.60 4.80 \
                 5.0 5.20 5.40 5.60 5.80 " 
                   
#hound_date_list="2013-01-18 2013-01-19 2013-01-20 2013-01-21 2013-01-22 2013-01-23 \
#           2013-01-24 2013-01-25 2013-01-26 2013-01-27 2013-01-28" 

#horse_date_list="2013-01-25 2013-01-26 2013-01-27 2013-01-28" 
#human_date_list="2013-01-25 2013-01-26 2013-01-27 2013-01-28" 

hound_date_list="2013-01-30 2013-01-31" 
horse_date_list="2013-01-30 2013-01-31" 
human_date_list="2013-01-30 2013-01-31" 

use_argument_dates=0

while getopts “a:b:n:s:t:u” OPTION
do
     case $OPTION in
         s) start_date=$OPTARG  ;;
         t) stop_date=$OPTARG  ;;
         u) use_argument_dates=1  ;;
         a) animal=$OPTARG  ;;
         b) bet_type=$OPTARG  ;;
         n) bet_name=$OPTARG  ;;
     esac
done

echo "bet_name - $bet_name"
echo "bet_type - $bet_type"
echo "start_date - $start_date"
echo "stop_date - $stop_date"
echo "animal - $animal"
echo "use_argument_dates - $use_argument_dates"
                   

#delay_list = "0 1 2 3 4 5 6"

#  bet_type=$(echo $BET_TYPE | tr '[A-Z]' '[a-z]')

price_list=""
if [ $bet_type == "lay" ] ; then
  price_list=$lay_price_list
elif [ $bet_type == "back" ] ; then
  price_list=$back_price_list
else
  echo "bad bet_type '$bet_type'"
  exit
fi


case "$animal" in
    hound )
           date_list=$hound_date_list
           if [ $bet_type == "lay" ] ; then
               price_list=$lay_price_list
               
               if [ $bet_name == "Plats" ] ; then
                   price_list=$hound_place_lay_price_list
               fi                
               
               
           elif [ $bet_type == "back" ] ; then
               price_list=$back_price_list
           else
               echo "bad bet_type '$bet_type'"
               exit 1
           fi    
           ;;
    horse )
           date_list=$horse_date_list
           if [ $bet_type == "lay" ] ; then
               price_list=$lay_price_list
           elif [ $bet_type == "back" ] ; then
               price_list=$back_price_list
           else
               echo "bad bet_type '$bet_type'"
               exit 1
           fi    
           ;;
    human )
           date_list=$human_date_list
           if [ $bet_type == "lay" ] ; then
               price_list=$lay_price_list
           elif [ $bet_type == "back" ] ; then
               price_list=$back_price_list
           else
               echo "bad bet_type '$bet_type'"
               exit 1
           fi    
           ;;
esac


echo "3 $date_list"
#exit

[ ! -d sims ] && mkdir sims

for the_date in $date_list ; do

#    start_date=$the_date
#    stop_date=$the_date

    if [ $use_argument_dates -eq 0 ] ; then
      start_date=$the_date
      stop_date=$the_date
    fi

    datadir=sims
    filname=simulation-$animal\-$bet_name\-$bet_type\-$start_date\-$stop_date\.dat
    fil=$datadir/$filname
    rm -rf $fil
    rm -rf $fil.dat
    for min_price in $price_list; do
        for max_price in $price_list; do
            echo "Treating $the_date $min_price - $max_price to $fil"
            
            python simulator.py \
                --bet_type=$bet_type \
                --bet_name=$bet_name \
                --start_date=$start_date \
                --stop_date=$stop_date \
                --saldo=10000 \
                --size=30 \
                --animal=$animal \
                --min_price=$min_price \
                --max_price=$max_price \
                --summary >> $fil
        done
    done
    gnuplot -e "animal='$animal'" \
            -e "bet_name='$bet_name'" \
            -e "bet_type='$bet_type'" \
            -e "start_date='$start_date'" \
            -e "stop_date='$stop_date'" \
            -e "datafil='$filname'" \
            -e "datadir='$datadir'" plot_simulation.gpl
    rm -f /Users/bnl/Dropbox/betfair/png/sim/$fil.png
    cp $fil.png /Users/bnl/Dropbox/betfair/png/sim/

    if [ $use_argument_dates ] ; then
      break 
    fi
    
done
