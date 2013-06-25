#!/bin/bash

trap 'echo you hit Ctrl-C, now exiting..; exit' SIGINT SIGQUIT

OLD_PWD=$(pwd)
cd history/historic_data

let tot=0
let cnt=0
file_list=$(ls *horse*.zip)

for f in $file_list ; do
  let tot=$((tot +1))
done

for f in $file_list ; do

  let cnt=$((cnt +1))
  echo "treating $cnt / $tot $(date)"
  unzip $f

  file_list_2=$(ls *horse*.csv)
  for f2 in $file_list_2 ; do
    # no australian races, and no IN_PLAY
    cat $f2 | grep -v AUS | grep -v IP | grep "TO BE PLACED" > $f2.horses
    python ../../betfair_historic_data_importer.py --file=$f2.horses
    rm $f2 $f2.horses
  done
  mv $f ../treated/

done
cd $OLD_PWD



