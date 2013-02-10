#!/bin/bash

#make some simulations, first day, by day

animal_names="Vinnare Plats"
animals="horse hound"
#bet_types="lay back"
bet_types="back"
football_names="0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 lagen straff udda utvisning"
val="1 2"

#date_list="2013-02-06 2013-02-07 2013-02-08 2013-02-09"
date_list="2013-02-09"

#names_football="Utvisning udda 0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 lagen straff"

for d in $date_list ; do
    start_date=$(date -d "$d -7 days" +"%Y-%m-%d")
    for bet_name in $football_names ; do
        for valet in $val ; do
                python simulator3.py \
                    --bet_type=back \
                    --bet_name=$bet_name \
                    --saldo=10000 \
                    --start_date=$start_date \
                    --stop_date=$d \
                    --size=30 \
                    --animal=human \
                    --index=$valet \
                    --summary --plot &
        done
    done
done

for d in $date_list ; do
    start_date=$(date -d "$d -7 days" +"%Y-%m-%d")
    for bet_name in $animal_names ; do
        for bet_type in $bet_types ; do
            for animal in $animals ; do
                python simulator3.py \
                    --bet_type=back \
                    --bet_name=$bet_name \
                    --saldo=10000 \
                    --start_date=$start_date \
                    --stop_date=$d \
                    --size=30 \
                    --animal=$animal \
                    --summary --plot &
            done
        done
    done
done


