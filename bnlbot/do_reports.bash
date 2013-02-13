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
bet_types="back"
football_names_1="straff"
football_names_2="3.5 4.5"

#date_list="2013-02-11"

date_list="2013-01-31 \
 2013-02-01 2013-02-02 2013-02-03 2013-02-04 2013-02-05 \
 2013-02-06 2013-02-07 2013-02-08 2013-02-09 2013-02-10 2013-02-11"
graph_type=daily
#graph_type=weekly

date_list="2013-02-06 2013-02-07 2013-02-08 2013-02-09 2013-02-10 2013-02-11"
date_list="2013-02-11"



#for d in $date_list ; do
#    if [ "$graph_type" == 'daily' ] ; then
#      start_date=$d
#    elif [ "$graph_type" == 'weekly' ] ; then
#      start_date=$(date -d "$d -7 days" +"%Y-%m-%d")
#    else
#      echo "bad graph_type - $graph_type" >&2
#      exit 1
#    fi
#    for bet_name in $animal_names ; do
#        for bet_type in $bet_types ; do
#            for animal in $animals ; do
#                python simulator3.py \
#                    --bet_type=lay \
#                    --bet_name=$bet_name \
#                    --saldo=10000 \
#                    --start_date=$start_date \
#                    --stop_date=$d \
#                    --graph_type=$graph_type \
#                    --size=30 \
#                    --animal=$animal \
#                    --summary --plot   &
#            done
#        done
#    done
#done




for d in $date_list ; do
    if [ "$graph_type" == 'daily' ] ; then
      start_date=$d
    elif [ "$graph_type" == 'weekly' ] ; then
      start_date=$(date -d "$d -7 days" +"%Y-%m-%d")
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
                    --index=2 \
                    --summary --plot &
    done
done

for d in $date_list ; do
    if [ "$graph_type" == 'daily' ] ; then
      start_date=$d
    elif [ "$graph_type" == 'weekly' ] ; then
      start_date=$(date -d "$d -7 days" +"%Y-%m-%d")
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
                    --index=1 \
                    --summary --plot &
    done
done


for d in $date_list ; do
    if [ "$graph_type" == 'daily' ] ; then
      start_date=$d
    elif [ "$graph_type" == 'weekly' ] ; then
      start_date=$(date -d "$d -7 days" +"%Y-%m-%d")
    else
      echo "bad graph_type - $graph_type" >&2
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
                    --graph_type=$graph_type \
                    --size=30 \
                    --animal=$animal \
                    --summary --plot &
            done
        done
    done
done


