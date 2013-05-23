#!/bin/bash

start_date=2013-01-30
stop_date=$(date +%Y-%m-%d)
date_list=""
this_date=$start_date
i=0
while true ; do
    this_date=$(date --date="$start_date +$i day" +"%Y-%m-%d")
    echo $this_date

    if [ "$this_date" == "$stop_date" ] ;then
      break
    fi

    date_list="$date_list $this_date"
    i=$(expr $i + 1)
done
echo $date_list
