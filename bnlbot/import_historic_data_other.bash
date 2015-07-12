#!/bin/bash

trap 'echo you hit Ctrl-C, now exiting..; exit' SIGINT SIGQUIT

OLD_PWD=$(pwd)
cd $BOT_ROOT/history/data/untreated

file_list=$(ls *other*.zip)

let tot=0
let cnt=0

for f in $file_list ; do
  let tot=$((tot +1))
done

for f in $file_list ; do

  let cnt=$((cnt +1))
  echo "treating $cnt / $tot $(date)"
  unzip $f

  file_list_2=$(ls *other*.csv)
  for f2 in $file_list_2 ; do
    # ONLY dogs, no australian races, 
#    cat $f2 | grep 4339 | grep -v AUS > $f2.dogs
    cat $f2 | grep \"1\" |grep "Half Time Score" | grep \"PE\"  > $f2.dogs
    cat $f2 | grep \"1\" |grep "Correct Score"   | grep \"PE\" | grep -v "Correct Score 2" >> $f2.dogs
    cat $f2 | grep \"1\" |grep "Match Odds"      | grep \"PE\" | grep -v "Match Odds and" >> $f2.dogs
    python ../../../../../betfair_historic_data_importer.py --file=$f2.dogs
    rm $f2 $f2.dogs
  done
  mv $f ../treated/

done
cd $OLD_PWD
vacuumdb --all --analyze
reindexdb --all
vacuumdb --all --analyze
