#!/bin/bash

#day of week
dow=$(date +"%u")

#drop the old db and import the new db
./do_deploy_db_backup.bash -n $dow

report_type_list="daily weekly biweekly"

for report in report_type_list ; do

    ./do_reports.bash -g $report

    # wait for all to complete
    # the are done when none has touched
    # directory sims for 20 seconds

    last_access=$(stat --format="%X" sims)
    now=$(date +"%s")
    time_since_last_access=$(expr $now - $last_access)

    while [ $time_since_last_access -lt 20 ]; do
      last_access=$(stat --format="%X" sims)
      now=$(date +"%s")
      time_since_last_access=$(expr $now - $last_access)
      sleep 10
    done

    #ok, lets make the pngs and move to dropbox
    ./do_map.bash
done
