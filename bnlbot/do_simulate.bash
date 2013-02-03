#!/bin/bash

names="Vinnare Plats"
animals="horse hound"
names_football="Utvisning?"

start_date="2013-01-30"
stop_date="2013-02-03"



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
exit

for bet_name in $names_football ; do
        python simulator.py \
          --min_price=1.00 \
          --max_price=10.0 \
          --bet_type=back \
          --bet_name=$bet_name \
          --saldo=10000 \
          --start_date=$start_date \
          --stop_date=$stop_date \
          --size=30 \
          --animal=human \
          --summary --plot 
done
exit

for bet_name in $names ; do
    for animal in $animals ; do
        python simulator.py \
          --min_price=1.15 \
          --max_price=6.0 \
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
          --max_price=15 \
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



