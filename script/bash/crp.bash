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



arg1=$1

if [ "$arg1" == "" ] ; then
  #no arg, use $BOT_USER
  arg1=$BOT_USER
fi

if [ "$arg1" == "all" ] ; then
  PID_FILE_DIRECTORIES="ghd dry jmb msm bnl"
else
  PID_FILE_DIRECTORIES=$arg1
fi  

#PID_FILE_DIRECTORIES=$(ls $BOT_HOME/..)
echo""
echo "----------------  $(date)  --------------------------"
for USER in $PID_FILE_DIRECTORIES ; do 
  echo""
  echo " ---------------- user $USER -------------------- "
  DIR=${BOT_HOME}/../${USER}/locks
  PID_FILE=$(ls ${DIR})
  echo "    STARTTIME file         PPID   PID START      CPU   PROCESS"
  for f in $PID_FILE ; do
    case "${f}"  in
      "data_mover" ) ;;
      "saldo_fetcher" ) ;;
      *) 
          PID=$(cut -d'|' -f1  ${DIR}/${f})
          START=$(cut -d'|' -f2  ${DIR}/${f})
          # use grep " $PID " to separate pid 1234 from 12345 and from 851234
          PS_STUFF=$(ps -eo ppid,pid,stime,time | grep " $PID " | grep -v grep)
          if [ "x${PS_STUFF}" == "x" ] ; then
            PS_STUFF=" !!! seemingly not running ----- "
          fi
          echo "$START : ${PS_STUFF} : ${f}"   
      ;;
    esac
    
  
  done
done
echo""
echo "----------------  $(date)  --------------------------"
echo""

