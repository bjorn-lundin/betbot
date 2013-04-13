#!/bin/bash

OLD_PWD=$(pwd)
cd history/historic_data

file_list=$(ls *other*.zip)
for f in $file_list ; do
  unzip $f

  file_list_2=$(ls *other*.csv)
  for f2 in $file_list_2 ; do
    grep \"4339\" $f2 > $f2.dogs
    python ../../betfair_historic_data_importer.py --file=$f2.dogs
    rm $f2 $f2.dogs
    mv $f ../treated/
  done

done
cd $OLD_PWD


