#!/bin/bash

killall lay_during_football
rm dats/*

EXE=lay_during_football

ps -ef |grep -v grep| grep -ic $EXE

function Wait () {
  NUM=$(ps -ef |grep -v grep| grep -ic $EXE)
  echo "$NUM before loop $1 $2 $3"
  while [ $NUM -ge 10 ] ; do
    NUM=$(ps -ef |grep -v grep| grep -ic $EXE)
    echo "$NUM inside loop, wait 10 secs $(date)"
    sleep 10  
  done
}

function Wait_Until_Done () {
  NUM=$(ps -ef |grep -v grep| grep -ic $EXE)
  echo "$NUM before loop Wait_Until_Done"
  while [ $NUM -ge 1 ] ; do
    NUM=$(ps -ef |grep -v grep| grep -ic $EXE)
    echo "$NUM inside loop, wait 10 secs in Wait_Until_Done $(date)" 
    sleep 10  
  done
}


#BACK_AT_ODDS_LIST="1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.5"
#DRAW_ODDS_LIST="4 6 8 10 12 14 16 18 20 22 24 26 28 30"
#OTHER_ODDS_LIST="5 10 15 20 25 30 35 40"

#BACK_AT_ODDS_LIST="1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95"
#DRAW_ODDS_LIST="03 04 05 06"
#OTHER_ODDS_LIST="04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22"
#
#for ba in $BACK_AT_ODDS_LIST ; do
#  for do in $DRAW_ODDS_LIST ; do
#    for oo in $OTHER_ODDS_LIST ; do
#        $BOT_TARGET/bin/lay_during_football --back_at_price=$ba --draw_min_back=$do --other_min_back=$oo --plot > dats/${ba}_${do}_${oo}.dat 2>&1 &
#        sleep 1
#        Wait $ba $do $oo
#    done
#  done 
#done 
#
#grep "Total profit" dats/*.dat | cut -d'=' -f2 | sort --numeric-sort | uniq | tail
#tail -n1 dats/*.dat | cut -d'|' -f5 | sort --numeric-sort | uniq | tail


FILE_LIST="1.50_03_19.dat 1.55_03_19.dat 1.60_03_19.dat 1.65_03_19.dat 1.70_03_19.dat 1.75_03_19.dat \
           1.80_03_19.dat 1.85_03_19.dat 1.45_03_18.dat 1.50_03_18.dat 1.55_03_18.dat 1.60_03_18.dat \
	      1.90_03_18.dat 1.95_03_18.dat 1.65_03_18.dat 1.70_03_18.dat 1.75_03_18.dat 1.80_03_18.dat 1.85_03_18.dat"

for f in  in $FILE_LIST ; do
  ba=$(echo $f | cut -d'_' -f1)
  do=$(echo $f | cut -d'_' -f2)
  oo=$(echo $f | cut -d'_' -f3)
  #loose .dat
  oo=$(echo $oo| cut -d'.' -f1)
  
  $BOT_TARGET/bin/lay_during_football --back_at_price=$ba --draw_min_back=$do --other_min_back=$oo --plot > dats/${ba}_${do}_${oo}.dat 2>&1 &
  sleep 1
  Wait $ba $do $oo
done 

Wait_Until_Done

grep "Total profit" dats/*.dat | cut -d'=' -f2 | sort --numeric-sort | uniq | tail
tail -n1 dats/*.dat | cut -d'|' -f5 | sort --numeric-sort | uniq | tail
