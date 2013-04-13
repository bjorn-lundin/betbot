#!/bin/bash

OLD_PWD=$(pwd)
cd history/historic_data

file_list=$(ls *horse*.zip)
for f in $file_list ; do
  unzip $f

  file_list_2=$(ls *horse*.csv)
  for f2 in $file_list_2 ; do
    python ../../betfair_historic_data_importer.py --file=$f2
    rm $f2
    mv $f ../treated/
  done

done
cd $OLD_PWD


