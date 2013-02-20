#!/bin/bash

#make some simulations, first day, by day

function the_start_date {
    the_stop_date=$1
    the_graph_type=$2

    if [ "$the_graph_type" == 'daily' ] ; then
      start_date=$the_stop_date
    elif [ "$the_graph_type" == 'weekly' ] ; then
      start_date=$(date -d "$the_stop_date -6 days" +"%Y-%m-%d")
      if [ $start_date \< "2013-01-30" ] ; then
#          echo "$start_date $the_graph_type " >&2
          start_date="2013-01-01"
      fi
    elif [ "$the_graph_type" == 'biweekly' ] ; then
      start_date=$(date -d "$the_stop_date -13 days" +"%Y-%m-%d")
      if [ $start_date \< "2013-01-30" ] ; then
#          echo "$start_date $the_graph_type " >&2
          start_date="2013-01-01"
      fi
    else
      echo "bad graph_type - $the_graph_type" >&2
      start_date="2013-01-01"
    fi
    echo $start_date
}

function the_date_list {
    the_start_date=$1
    the_stop_date=$2
    the_date_list=""

    the_next_date=$the_start_date
    while [ "$the_next_date" != "$the_stop_date" ]; do
#        echo "$the_next_date - $the_stop_date"
        the_next_date=$(date +%Y-%m-%d -d "$the_next_date +1 day")
        the_date_list=" $the_date_list $the_next_date"
    done
    the_date_list="$the_start_date $the_date_list"

    echo $the_date_list
}


while getopts "g:" opt; do
  case $opt in
    g)
      graph_type=$OPTARG
      ;;

    *)
      echo "$0 -g [daily|weekly|biweekly]" >&2
      exit 1
      ;;
  esac
done


if [ "$graph_type" == "daily" ] ; then
  echo $graph_type
#OK
elif [ "$graph_type" == "weekly" ] ; then
#OK
  echo $graph_type
elif [ "$graph_type" == "biweekly" ] ; then
  #OK
  echo $graph_type
else
  echo "bad graph_type - $graph_type" >&2
  echo "must be 'daily' or 'weekly' or 'biweekly'" >&2
  exit 1
fi


#today=$(date +%Y-%m-%d)
#we have no data for today...
yesterday=$(date +%Y-%m-%d -d "-1 day")

echo "yesterday = $yesterday"
start_date=$(the_start_date $yesterday $graph_type)
echo "start_date = $start_date"


#date_list=$(the_date_list $start_date $yesterday)
date_list=$yesterday
date_list="2013-01-30 2013-01-31 2013-02-01 2013-02-02 2013-02-03 2013-02-04 2013-02-05 \
2013-02-06 2013-02-07 2013-02-08 2013-02-09 2013-02-10 2013-02-11 2013-02-12 \
2013-02-13"
#2013-02-14 2013-02-15 2013-02-16"

date_list="2013-02-18 2013-02-19"

echo "date_list = $date_list"


animal_names="Vinnare Plats"
animals="horse hound"
#names_football="Utvisning udda 0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 lagen straff"
#football_names="0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 lagen straff udda utvisning"
#val="1 2"
#bet_types="lay back"

#animal_names="Plats"
#animals="hound"
#football_names_1="straff"
#football_names_2="3.5 4.5"


#graph_type=daily
#graph_type=weekly
#graph_type=biweekly

variants="normal"

#back bet on horses/hound winner/place

for d in $date_list ; do
    start_date=$(the_start_date $d $graph_type)
    if [  $start_date == "2013-01-01" ] ; then
      echo "graph_type - $graph_type"
      echo "start_date is first date -> continue with next"
      continue
    fi

    echo "$d - $start_date"
    for bet_name in $animal_names ; do
        for variant in $variants ; do
            for animal in $animals ; do
                    python simulator3.py \
                        --bet_type=back \
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

#back bet on horses/hound winner/place
for d in $date_list ; do
    start_date=$(the_start_date $d $graph_type)
    if [  $start_date == "2013-01-01" ] ; then
      echo "graph_type - $graph_type"
      echo "start_date is first date -> continue with next"
      continue
    fi

    echo "$d - $start_date"
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


#backbet s football choise = 2 - no/odd/over

#for d in $date_list ; do
#
#    start_date=$(the_start_date $d $graph_type)
#
#    for bet_name in $football_names_2 ; do
#                python simulator3.py \
#                    --bet_type=back \
#                    --bet_name=$bet_name \
#                    --saldo=10000 \
#                    --start_date=$start_date \
#                    --stop_date=$d \
#                    --graph_type=$graph_type \
#                    --size=30 \
#                    --animal=human \
#                    --variant=normal \
#                    --index=2 \
#                    --summary --plot &
#    done
#done

#backbet s football choise = 1 - yes/even/under

#for d in $date_list ; do
#    start_date=$(the_start_date $d $graph_type)
#    for bet_name in $football_names_1 ; do
#                python simulator3.py \
#                    --bet_type=back \
#                    --bet_name=$bet_name \
#                    --saldo=10000 \
#                    --start_date=$start_date \
#                    --stop_date=$d \
#                    --graph_type=$graph_type \
#                    --size=30 \
#                    --animal=human \
#                    --variant=normal \
#                    --index=1 \
#                    --summary --plot &
#    done
#done
