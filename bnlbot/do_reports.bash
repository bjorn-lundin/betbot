#!/bin/bash

#make some simulations, first day by day

function the_profit_factor {
    variant=$1
    max_profit_factor=0

    if [ "$variant" == 'normal' ] ; then
        max_profit_factor=0
    elif [ "$variant" == 'max_3' ] ; then
        max_profit_factor=3
    elif [ "$variant" == 'max_4' ] ; then
        max_profit_factor=4
    elif [ "$variant" == 'max_5' ] ; then
        max_profit_factor=5
    elif [ "$variant" == 'max_7' ] ; then
        max_profit_factor=7
    else
      echo "bad variant - $variant" >&2
    fi
    echo $max_profit_factor
}
###################

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
    elif [ "$the_graph_type" == 'quadweekly' ] ; then
      start_date=$(date -d "$the_stop_date -27 days" +"%Y-%m-%d")
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
#######################

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



#today=$(date +%Y-%m-%d)
#we have no data for today...
#graph_type_list="daily"

#names_football="Utvisning udda 0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 lagen straff"
#football_names="0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 lagen straff udda utvisning"
#val="1 2"
#bet_types="lay back"


#date_list=$(the_date_list $start_date $yesterday)
date_list="2013-01-30 2013-01-31 2013-02-01 2013-02-02 2013-02-03 2013-02-04 \
2013-02-05 2013-02-06 2013-02-07 2013-02-08 2013-02-09 2013-02-10 2013-02-11 \
2013-02-12 2013-02-13 2013-02-14 2013-02-15 2013-02-16 2013-02-17 2013-02-18 \
2013-02-19 2013-02-20 2013-02-21 2013-02-22 2013-02-23 2013-02-24 2013-02-25 \
2013-02-26 2013-02-20 2013-02-27 2013-02-28 2013-03-01 2013-03-02 2013-03-03 \
"

#2013-03-04
yesterday=$(date +%Y-%m-%d -d "-1 day")
##04-mar-2013
#yesterday=$(date +%d-%b-%Y -d "-1 day")
echo "yesterday = $yesterday"

graph_type_list="daily weekly biweekly quadweekly"
animal_names="winner place"
animals="horse hound"
variants="normal max_3 max_4 max_5"

#date_list="30-jan-2013 31-jan-2013 01-feb-2013 02-feb-2013 03-feb-2013 \
# 04-feb-2013 05-feb-2013 06-feb-2013 07-feb-2013 08-feb-2013 09-feb-2013 10-feb-2013 \
# 11-feb-2013 12-feb-2013 13-feb-2013 14-feb-2013 15-feb-2013 16-feb-2013 17-feb-2013 \
# 18-feb-2013 19-feb-2013 20-feb-2013 21-feb-2013 22-feb-2013 23-feb-2013 24-feb-2013 \
# 25-feb-2013 26-feb-2013 27-feb-2013 28-feb-2013 01-mar-2013 02-mar-2013"

#date_list=$yesterday

#back bet on horses/hound winner/place

#for d in $date_list ; do
#    start_date=$(the_start_date $d $graph_type)
#    if [  $start_date == "2013-01-01" ] ; then
#      echo "graph_type - $graph_type"
#      echo "start_date is first date -> continue with next"
#      continue
#    fi
#
#    echo "$d - $start_date"
#    for bet_name in $animal_names ; do
#        for variant in $variants ; do
#            profit_factor=$(the_profit_factor $variant)
#            for animal in $animals ; do
#                    python simulator3.py \
#                        --bet_type=back \
#                        --bet_name=$bet_name \
#                        --saldo=10000 \
#                        --start_date=$start_date \
#                        --stop_date=$d \
#                        --graph_type=$graph_type \
#                        --size=30 \
#                        --max_profit_factor=$profit_factor \
#                        --variant=$variant \
#                        --animal=$animal \
#                        --summary --plot &
#            done
#        done
#    done
#done

#lay bet on horses/hound winner/place
for d in $date_list ; do
    for graph_type in $graph_type_list ; do
       echo "graph_type - $graph_type"
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
                   profit_factor=$(the_profit_factor $variant)
                   ./simulator \
                           --bet_type=lay \
                           --bet_name=$bet_name \
                           --saldo=10000 \
                           --start_date=$start_date \
                           --stop_date=$d \
                           --graph_type=$graph_type \
                           --size=30 \
                           --max_daily_loss=-400 \
                           --max_profit_factor=$profit_factor \
                           --variant=$variant \
                           --animal=$animal  \
                           --quiet &
   #                        \
   #                        --summary --plot &
               done
           done
           # at least 8 at a time
           sleep 2
           while true ; do
               # let num_pg_conns=$(ps -ef | grep  "bnl betting" | grep -vc grep)
               let num_pg_conns=$(ps -ef | grep  "simulator" | grep -vc grep)
               if [ $num_pg_conns -le 8 ] ; then
                  echo "fewer than 8 simulators running, $(date), break to release more"
                  break
               fi
               echo "$(date) sleeping, waiting for $report - $num_pg_conns connections running"
               sleep 2
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
