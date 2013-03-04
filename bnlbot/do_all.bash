#!/bin/bash


#day of week
dow=$(date +"%u")
deploy=1
while getopts "n:d:" opt; do
  case $opt in
    n)
      dow=$OPTARG
      ;;

    d)
      deploy=$OPTARG
      ;;

    *)
      echo "$0 [-d  -n day_of_week]" >&2
      echo "    -d deploy" >&2
      exit 1
      ;;
  esac
done



#drop the old db and import the new db
if [ $deploy == "1" ] ; then
  ./do_deploy_db_backup.bash -n $dow
fi

./do_reports.bash

#ok, lets make the pngs and move to dropbox
#./do_map.bash
