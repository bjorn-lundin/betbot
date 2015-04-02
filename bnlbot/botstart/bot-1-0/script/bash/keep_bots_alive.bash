#!/bin/bash

# should be run from a crontab like
#* * * * * cd / && /home/bnl/bnlbot/botstart/bot-0-9/script/bash/keep_bots_alive.bash
#install with

#echo "25 3 * * * /home/bnl/bnlbot/do_backup_db.bash" >  crontab.tmp
#crontab -l > crontab.tmp
#echo "* * * * * cd / && /home/bnl/bnlbot/botstart/bot-1-0/script/bash/keep_bots_alive.bash" >>  crontab.tmp
#crontab -r
#cat crontab.tmp | crontab
#crontab -l
#rm crontab.tmp
#echo "* * * * * cd / && /home/bnl/bnlbot/botstart/bot-1-0/script/bash/keep_bots_alive.bash" | crontab

#if we should NOT start it, check here.
#if /var/lock/bot is exists, then exit. created/removed from /etc/init.d/bot

#exit 0

[ -r /var/lock/bot ] && exit 0

export PG_DUMP=pg_dump
export VACUUMDB=vacuumdb
export REINDEXDB=reindexdb

export DUMP_DIRECTORY="/data/dbdumps"

TZ='Europe/Stockholm'
export TZ   
export BOT_START=/home/bnl/bnlbot/botstart
#defaults. sets $BOT_SOURCE and $BOT_START
. $BOT_START/bot.bash bnl

function Start_Bot () {

  #if the lock can be aquired, the process is NOT running - start it

  ##bot  is not running
  #$ $BOT_TARGET/bin/check_bot_running --botname=market_fetcher
  #$ echo $?
  #0

  ##bot  is running
  #$ $BOT_TARGET/bin/check_bot_running --botname=market_fetcher
  #$ echo $?
  #1
  BOT_USER=$1
  BOT_NAME=$2
  EXE_NAME=$3
  INI_NAME=$4
  MODE=$5

  if [ "$INI_NAME" != "" ] ; then
    INI_NAME=" --inifile=$INI_NAME"
  fi

  if [ "$MODE" != "" ] ; then
    MODE=" --mode=$MODE"
  fi
  
  $BOT_TARGET/bin/check_bot_running --botname=$BOT_NAME  --debug > /dev/null 2>&1
  RESULT=$?
  if [ $RESULT -eq 0 ] ; then
    echo "--------------------------------"
    echo "will run '$BOT_NAME'"
    echo "will run $BOT_TARGET/bin/$EXE_NAME --daemon --user=$BOT_USER $INI_NAME $MODE"
    export BOT_NAME=$BOT_NAME
    $BOT_TARGET/bin/$EXE_NAME --daemon --user=$BOT_USER $INI_NAME $MODE
    echo "Started $BOT_NAME for $BOT_USER"
    echo "--------------------------------"
  fi
}

function Check_Bots_For_User () {

  export BOT_USER=$1
  BOT_WEEK_DAY=$2
  BOT_HOUR=$3
  BOT_MINUTE=$4  
  
  if [ $BOT_USER == "dry" ] ; then
    IS_DATA_COLLECTOR="true"
  else  
    IS_DATA_COLLECTOR="false"
  fi
  
  . $BOT_START/bot.bash $BOT_USER
  #No login file -> give up
  [ ! -r $BOT_HOME/login.ini ] && return 0

  #BOT_USER=$1
  #BOT_NAME=$2
  #EXE_NAME=$3
  #INI_NAME=$4
  #MODE=$5
  #all need this one
  Start_Bot $BOT_USER markets_fetcher markets_fetcher
  
  Start_Bot $BOT_USER poll poll poll.ini
  
  if [ $IS_DATA_COLLECTOR == "true" ] ; then
    Start_Bot $BOT_USER poll_and_log poll_and_log poll_and_log.ini
  fi
    
  Start_Bot $BOT_USER w_fetch_json winners_fetcher_json
  
  if [ $IS_DATA_COLLECTOR == "false" ] ; then
    Start_Bot $BOT_USER bet_checker bet_checker
  fi
  
  case $BOT_MACHINE_ROLE in
    PROD) BOT_LIST="bot" ;;
    TEST) BOT_LIST="bot" ;;
    SIM)  BOT_LIST="" ;;
    *)    BOT_LIST="" ;;
  esac
  
  if [ $IS_DATA_COLLECTOR == "false" ] ; then
    for bot in $BOT_LIST ; do
      if [ $bot == "bot" ] ; then
        Start_Bot $BOT_USER $bot bot betfair.ini
      else
        Start_Bot $BOT_USER $bot bot $bot.ini
      fi
    done
    BET_PLACER_LIST="bet_placer_010 \
                     bet_placer_020 \
                     bet_placer_030 \
                     bet_placer_040 \
                     bet_placer_070 \
                     bet_placer_080 \
                     bet_placer_101 bet_placer_102 \
                     bet_placer_103 bet_placer_104 \
                     bet_placer_105 bet_placer_106 \
                     bet_placer_107 bet_placer_108 \
                     bet_placer_109 bet_placer_110 \
                     bet_placer_111 bet_placer_112 \
                     bet_placer_122 bet_placer_123 \
                     bet_placer_125 bet_placer_126"                     
                     
    for placer in $BET_PLACER_LIST ; do
      Start_Bot $BOT_USER $placer bet_placer bet_placer.ini
    done
  fi
  
  #zip logfiles every hour, on minute 17 in the background
  if [ $BOT_MINUTE == "17" ] ; then
    tclsh $BOT_SCRIPT/tcl/move_or_zip_old_logfiles.tcl $BOT_USER &
  fi
  
  if [ $BOT_HOUR == "05" ] ; then
    if [ $BOT_MINUTE == "10" ] ; then
      Start_Bot $BOT_USER data_mover data_mover
    fi
  fi
  Start_Bot $BOT_USER poll_place poll_place poll.ini
  
  if [ $IS_DATA_COLLECTOR == "false" ] ; then
    if [ $BOT_HOUR == "05" ] ; then
      if [ $BOT_MINUTE == "00" ] ; then
        Start_Bot $BOT_USER saldo_fetcher saldo_fetcher
      fi
    fi
  fi
  
  
}
# start here 

HOUR=$(date +"%H")
MINUTE=$(date +"%M")
WEEK_DAY=$(date +"%u")
DAY=$(date +"%d")
       
case $BOT_MACHINE_ROLE in
  PROD)
    #check the bots, and startup if  necessarry
    USER_LIST=$(ls $BOT_START/user)
    USER_LIST_PLAYERS_ONLY="bnl jmb"
    
    HOST=db.nonodev.com
    for USR in $USER_LIST ; do
      Check_Bots_For_User $USR $WEEK_DAY $HOUR $MINUTE
    done
  
# until we got data disk    if [ $HOUR == "05" ] ; then
# until we got data disk      if [ $MINUTE == "10" ] ; then
# until we got data disk        SLEEPTIME=1
# until we got data disk        for USR in $USER_LIST ; do
# until we got data disk          #Start one every 20 min in the background
# until we got data disk          (sleep $SLEEPTIME && $PG_DUMP --host=$HOST --username=bnl --dbname=$USR | gzip > ${DUMP_DIRECTORY}/${USR}_${WEEK_DAY}.dmp.gz) &
# until we got data disk          (( SLEEPTIME = SLEEPTIME +1200 ))
# until we got data disk        done
# until we got data disk      fi
# until we got data disk    fi
    
    if [ $DAY == "01" ] ; then
      if [ $HOUR == "01" ] ; then
        if [ $MINUTE == "37" ] ; then
          SLEEPTIME=1
          for USR in $USER_LIST ; do
            #Start one every 20 min in the background
            (sleep $SLEEPTIME && $PG_DUMP --host=$HOST --username=bnl --dbname=$USR | gzip > ${DUMP_DIRECTORY}/${USR}_${WEEK_DAY}.dmp.gz) &
            (( SLEEPTIME = SLEEPTIME +1200 ))
          done
        fi
      fi
    fi
    
    if [ $MINUTE == "40" ] ; then
      for USR in $USER_LIST_PLAYERS_ONLY ; do
        #Start one every 2 min in the background
        SLEEPTIME=1
        (sleep $SLEEPTIME && $VACUUMDB --host=$HOST --username=bnl --dbname=$USR --analyze) &
        (( SLEEPTIME = SLEEPTIME +120 ))
      done
    fi
    
    if [ $HOUR == "05" ] ; then
      if [ $MINUTE == "00" ] ; then
        for USR in $USER_LIST_PLAYERS_ONLY ; do
        
        #Start one every 5 min in the background, both with and without system tables
        SLEEPTIME=1
        (sleep $SLEEPTIME && $REINDEXDB --host=$HOST --username=bnl --dbname=$USR --system) &
        (( SLEEPTIME = SLEEPTIME +10 ))
        (sleep $SLEEPTIME && $REINDEXDB --host=$HOST --username=bnl --dbname=$USR ) &
        (( SLEEPTIME = SLEEPTIME +300 ))          
        done
      fi
    fi  
  
  ;;
  *) 
  #do nothing on non-PROD hosts
  exit 0 ;;
esac

PCT="/tmp/percent.tcl"
echo 'puts [expr [lindex $argv 0] * 100  / [lindex $argv 1]]' > $PCT

# check filling degree
#1 kb blocks
#90%
export ALARM_SIZE=90
DAY_FILE=$(date +"%F")
ALARM_TODAY_FILE=/tmp/alarm_${DAY_FILE}

MAIL_LIST="b.f.lundin@gmail.com joakim@birgerson.com"

DISK_LIST="8af81777-14a7-448d-99f9-58b712945f73"  

for DISK in $DISK_LIST ; do
  USED_SIZE=$( df  | grep $DISK | awk '{print $3}')
  DISK_SIZE=$( df  | grep $DISK | awk '{print $2}')
  FS=$( df  | grep $DISK | awk '{print $1}')
  PERCENTAGE=$(tclsh $PCT $USED_SIZE $DISK_SIZE)
  for RECIPENT in $MAIL_LIST ; do
   if [ $PERCENTAGE -gt $ALARM_SIZE ] ; then
   
     if [ ! -r ${ALARM_TODAY_FILE} ] ; then
       df -h | mail --subject="disk ${FS} - ${DISK} almost full ( ${PERCENTAGE} %) on $(hostname)" $RECIPENT
       touch ${ALARM_TODAY_FILE}
     fi  
   fi
  done
  df -h | $BOT_TARGET/bin/aws_mail --subject="disk ${FS} - ${DISK} almost full ( ${PERCENTAGE} %) on $(hostname)"
done

#delete old alarmfiles

ALARM_FILES=$(ls /tmp/alarm*  2>/dev/null)

for f in $ALARM_FILES ; do
  if [ $f != $ALARM_TODAY_FILE ] ; then
    rm -f $f
  fi
done
  







