#!/bin/bash

names="Vinnare Plats"
animals="horse hound"
#names_football="Utvisning udda 0.5 1.5 2.5 3.5 4.5 lagen straff"
names_football="1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 lagen straff"
val="1 2"
start_date="2013-01-30"
stop_date="2013-02-05"


what=$1
case "$what" in

    football )

        for bet_name in $names_football ; do
            for valet in $val ; do
                python simulator3.py \
                  --price=1.0 \
                  --delta_price=0.2 \
                  --bet_type=back \
                  --bet_name=$bet_name \
                  --saldo=10000 \
                  --start_date=$start_date \
                  --stop_date=$stop_date \
                  --size=30 \
                  --animal=human \
                  --index=$valet \
                  --summary --plot 
            done
        done
        ;;
    animals )
   

        for bet_name in $names ; do
            for animal in $animals ; do
                python simulator3.py \
                  --price=1.0 \
                  --delta_price=0.2 \
                  --bet_type=back \
                  --bet_name=$bet_name \
                  --saldo=10000 \
                  --start_date=$start_date \
                  --stop_date=$stop_date \
                  --size=30 \
                  --animal=$animal \
                  --summary --plot 
            done
        done
      
      
        for bet_name in $names ; do
            for animal in $animals ; do
                python simulator.py \
                  --min_price=5 \
                  --max_price=50 \
                  --bet_type=lay \
                  --bet_name=$bet_name \
                  --saldo=10000 \
                  --start_date=$start_date \
                  --stop_date=$stop_date \
                  --size=30 \
                  --animal=$animal \
                  --summary --plot 
            done
        done
        ;;
      
    *)
       echo "$0 [football|animals]"
     ;;
     
esac
