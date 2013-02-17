#!/bin/bash

#make some simulations, first day, by day

animal_names="Vinnare Plats"
animals="horse hound"
#names_football="Utvisning udda 0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 lagen straff"
#football_names="0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 lagen straff udda utvisning"
#val="1 2"
#bet_types="lay back"


#animal_names="Plats"
#animals="hound"
football_names_1="straff"
football_names_2="3.5 4.5"

date_list=" \
                                  2013-01-31 2013-02-01 2013-02-02 2013-02-03 \
 2013-02-04 2013-02-05 2013-02-06 2013-02-07 2013-02-08 2013-02-09 2013-02-10 \
 2013-02-11 2013-02-12 2013-02-13 2012-02-14"


date_list=" \
                                  2013-01-31 2013-02-01 2013-02-02 2013-02-03 \
 2013-02-04 2013-02-05 2013-02-06 2013-02-07 2013-02-08 2013-02-09 2013-02-10 \
 2013-02-11 2013-02-12 2013-02-13 2012-02-14 2013-02-15"


date_list="2013-01-31 2013-02-01 2013-02-02 2013-02-03 \
 2013-02-04 2013-02-05 2013-02-06 2013-02-07"


date_list="2013-02-13 2012-02-14 2013-02-15"
date_list="2013-02-16"
graph_type=daily
graph_type=weekly
graph_type=biweekly

variants="favorite_lay_bet normal_lay_bet"

#backbet s football choise = 2 - no/odd/over

for d in $date_list ; do
    if [ "$graph_type" == 'daily' ] ; then
      start_date=$d
    elif [ "$graph_type" == 'weekly' ] ; then
      start_date=$(date -d "$d -6 days" +"%Y-%m-%d")
    elif [ "$graph_type" == 'biweekly' ] ; then
      start_date=$(date -d "$d -13 days" +"%Y-%m-%d")
    else
      echo "bad graph_type - $graph_type" >&2
      exit 1
    fi

    for bet_name in $football_names_2 ; do
                python simulator3.py \
                    --bet_type=back \
                    --bet_name=$bet_name \
                    --saldo=10000 \
                    --start_date=$start_date \
                    --stop_date=$d \
                    --graph_type=$graph_type \
                    --size=30 \
                    --animal=human \
                    --variant=normal \
                    --index=2 \
                    --summary --plot &
    done
done

#backbet s football choise = 1 - yes/even/under

for d in $date_list ; do
    if [ "$graph_type" == 'daily' ] ; then
      start_date=$d
    elif [ "$graph_type" == 'weekly' ] ; then
      start_date=$(date -d "$d -6 days" +"%Y-%m-%d")
    elif [ "$graph_type" == 'biweekly' ] ; then
      start_date=$(date -d "$d -13 days" +"%Y-%m-%d")
    else
      echo "bad graph_type - $graph_type" >&2
      exit 1
    fi
    for bet_name in $football_names_1 ; do
                python simulator3.py \
                    --bet_type=back \
                    --bet_name=$bet_name \
                    --saldo=10000 \
                    --start_date=$start_date \
                    --stop_date=$d \
                    --graph_type=$graph_type \
                    --size=30 \
                    --animal=human \
                    --variant=normal \
                    --index=1 \
                    --summary --plot &
    done
done


#back bet on horses/hound winner/place

for d in $date_list ; do
    if [ "$graph_type" == 'daily' ] ; then
      start_date=$d
    elif [ "$graph_type" == 'weekly' ] ; then
      start_date=$(date -d "$d -6 days" +"%Y-%m-%d")
    elif [ "$graph_type" == 'biweekly' ] ; then
      start_date=$(date -d "$d -13 days" +"%Y-%m-%d")
    else
      echo "bad graph_type - $graph_type" >&2
      exit 1
    fi
    for bet_name in $animal_names ; do

            for animal in $animals ; do
                    python simulator3.py \
                        --bet_type=back \
                        --bet_name=$bet_name \
                        --saldo=10000 \
                        --start_date=$start_date \
                        --stop_date=$d \
                        --graph_type=$graph_type \
                        --size=30 \
                        --variant=normal \
                        --animal=$animal \
                        --summary --plot &
                done

    done
done

#back bet on horses/hound winner/place
for d in $date_list ; do
    if [ "$graph_type" == 'daily' ] ; then
      start_date=$d
    elif [ "$graph_type" == 'weekly' ] ; then
      start_date=$(date -d "$d -6 days" +"%Y-%m-%d")
    elif [ "$graph_type" == 'biweekly' ] ; then
      start_date=$(date -d "$d -13 days" +"%Y-%m-%d")
    else
      echo "bad graph_type - $graph_type" >&2
      exit 1
    fi
    for bet_name in $animal_names ; do
            for animal in $animals ; do
                for variant in $variants ; do
                    python simulator3.py \
                        --bet_type=lay \
                        --bet_name=$bet_name \
                        --saldo=10000 \
                        --start_date=$start_date \
                        --stop_date=$d \
                        --graph_type=$graph_type \
                        --size=30 \
                        --variant=$variant \
                        --animal=$animal \
                        --summary --plot &
                done
            done
    done
done


