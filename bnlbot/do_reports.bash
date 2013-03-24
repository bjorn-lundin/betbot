#!/bin/bash

#make some simulations, first day by day

#date_list="2013-01-30 2013-01-31 2013-02-01 2013-02-02 2013-02-03 2013-02-04 \
#2013-02-05 2013-02-06 2013-02-07 2013-02-08 2013-02-09 2013-02-10 2013-02-11 \
#2013-02-12 2013-02-13 2013-02-14 2013-02-15 2013-02-16 2013-02-17 2013-02-18 \
#2013-02-19 2013-02-20 2013-02-21 2013-02-22 2013-02-23 2013-02-24 2013-02-25 \
#2013-02-26 2013-02-20 2013-02-27 2013-02-28 2013-03-01 2013-03-02 2013-03-03 \
#2013-03-04 2013-03-05 2013-03-06 2012-03-07 2013-03-08 2013-03-09 2013-03-10 \
#2013-03-11 2013-03-12 2013-03-13 2013-03-14 2013-03-15 2013-03-16 2013-03-17"

yesterday=$(date +%Y-%m-%d -d "-1 day")
echo "yesterday = $yesterday"

graph_type_list="daily weekly biweekly quadweekly"
animal_names="winner place"
animals="horse hound"

date_list=$yesterday

#back/lay, , normal,max_3,max_4,max_5 in simulator
#loop here on date, daily/weekly/biweekly/quadweekly, winner/place, horses/hound
for d in $date_list ; do
    for graph_type in $graph_type_list ; do
       for bet_name in $animal_names ; do
           for animal in $animals ; do
               echo "graph_type - $graph_type $start_date - $d bet_name - $ bet_name"
               ./simulator \
                       --bet_name=$bet_name \
                       --saldo=10000 \
                       --stop_date=$d \
                       --graph_type=$graph_type \
                       --size=30 \
                       --animal=$animal  \
                       --quiet &
              # at least 8 at a time
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
done


