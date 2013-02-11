#!/bin/bash

#make some simulations, first day, by day

#animal_names="Vinnare Plats"
#animals="horse hound"

animal_names="Vinnare"
animals="hound"
#bet_types="lay back"
bet_types="back"
#football_names="0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 lagen straff udda utvisning"
football_names_1="straff"
football_names_2="3.5 4.5"
#val="1 2"

date_list="2013-01-31 \
 2013-02-01 2013-02-02 2013-02-03 2013-02-04 2013-02-05 \
 2013-02-06 2013-02-07 2013-02-08 2013-02-09 2013-02-10"
date_list=" 2013-02-05 2013-02-10"
#date_list="2013-02-07"

#names_football="Utvisning udda 0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 lagen straff"

report_type=daily
#report_type=weekly

for d in $date_list ; do
    if [ "$report_type" == 'daily' ] ; then
      start_date=$d
    elif [ "$report_type" == 'weekly' ] ; then
      start_date=$(date -d "$d -7 days" +"%Y-%m-%d")
    else
      echo "bad report_type - $report_type" >&2
      exit 1
    fi

    for bet_name in $football_names_2 ; do
                python simulator3.py \
                    --bet_type=back \
                    --bet_name=$bet_name \
                    --saldo=10000 \
                    --start_date=$start_date \
                    --stop_date=$d \
                    --size=30 \
                    --animal=human \
                    --index=2 \
                    --summary --plot &
    done
done

for d in $date_list ; do
    if [ "$report_type" == 'daily' ] ; then
      start_date=$d
    elif [ "$report_type" == 'weekly' ] ; then
      start_date=$(date -d "$d -7 days" +"%Y-%m-%d")
    else
      echo "bad report_type - $report_type" >&2
      exit 1
    fi
    for bet_name in $football_names_1 ; do
                python simulator3.py \
                    --bet_type=back \
                    --bet_name=$bet_name \
                    --saldo=10000 \
                    --start_date=$start_date \
                    --stop_date=$d \
                    --size=30 \
                    --animal=human \
                    --index=1 \
                    --summary --plot &
    done
done


for d in $date_list ; do
    if [ "$report_type" == 'daily' ] ; then
      start_date=$d
    elif [ "$report_type" == 'weekly' ] ; then
      start_date=$(date -d "$d -7 days" +"%Y-%m-%d")
    else
      echo "bad report_type - $report_type" >&2
      exit 1
    fi
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


