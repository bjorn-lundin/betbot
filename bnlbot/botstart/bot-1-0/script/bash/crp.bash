#!/bin/bash


#31767|2014-05-02 12:16:01.280|2014-05-02 12:26:01.280|
#
#
#function crp {
#  echo " PID  STIME TIME      CMD"
#  for U in $USERS ; do
#    echo "---- $U --------------------------------------------------------"
#    ps -eo pid,stime,time,cmd | grep bot | grep user=$U | grep -v grep
#  done
#  echo "----------------------------------------------------------------"
#  date
#}


PID_FILE_DIRECTORIES="bnl jmb"

for USER in PID_FILE_DIRECTORIES ; do 
  echo " -- user $dir --- "
  PID_FILE=$(ls ${BOT_HOME}/${USER}/locks)
  for f in $PID_FILE ; do
    PID=$(cut -d'|' -f1 $f)
    START=$(cut -d'|' -f2 $f)
    PS_STUFF=$(ps -eo pid,stime,time,cmd | grep $PID)
    echo "$START : $PS_STUFF"    
  done
done


