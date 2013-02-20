#!/bin/bash

#day of week
dow=$(date +"%u")

#drop the old db and import the new db
#./do_deploy_db_backup.bash -n $dow

report_type_list="daily weekly biweekly"
#report_type_list="daily"

for report in $report_type_list ; do
    echo "report - $report"
    ./do_reports.bash -g $report
    #>/dev/null 2>&1

    # wait for all to complete
    # the are done when none has touched
    # directory sims for 20 seconds
    sleep 10

    while true ; do
      let num_pg_conns=$(ps -ef | grep  "bnl betting" | grep -vc grep)
      if [ $num_pg_conns -eq 0 ] ; then
         echo "$(date) no more connections, break"
         break
      fi
      echo "$(date) sleeping, waiting for $report - $num_pg_conns connections running"
      sleep 10
    done

    #ok, lets make the pngs and move to dropbox
    ./do_map.bash
done
