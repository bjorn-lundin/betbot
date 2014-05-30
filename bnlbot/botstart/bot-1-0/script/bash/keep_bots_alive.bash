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

#if we should NOT start it, check here.
#if /var/lock/bot is exists, then exit. created/removed from /etc/init.d/bot

#exit 0

[ -r /var/lock/bot ] && exit 0

export PG_DUMP=/usr/lib/postgresql/9.3/bin/pg_dump
export VACUUMDB=/usr/lib/postgresql/9.3/bin/vacuumdb

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
    export BOT_NAME
    $BOT_TARGET/bin/$EXE_NAME --daemon --user=$BOT_USER $INI_NAME $MODE
    echo "Started $BOT_NAME for $BOT_USER"
    echo "--------------------------------"
  fi
}

function Check_Bots_For_User () {

  export BOT_USER=$1

  . $BOT_START/bot.bash $BOT_USER
  #No login file -> give up
  [ ! -r $BOT_HOME/login.ini ] && return 0

  #BOT_USER=$1
  #BOT_NAME=$2
  #EXE_NAME=$3
  #INI_NAME=$4
  #MODE=$5

  Start_Bot $BOT_USER markets_fetcher markets_fetcher
  Start_Bot $BOT_USER poll poll poll.ini
#  Start_Bot $BOT_USER poll_and_log poll_and_log poll_and_log.ini
  Start_Bot $BOT_USER saldo_fetcher saldo_fetcher
  Start_Bot $BOT_USER w_fetch_json winners_fetcher_json
  Start_Bot $BOT_USER bet_checker bet_checker
  
  case $BOT_MACHINE_ROLE in
    PROD) BOT_LIST="bot" ;;
    TEST) BOT_LIST="bot" ;;
    SIM)  BOT_LIST="horses_win_gb horses_win_ie football football_2" ;;
    *)    BOT_LIST="" ;;
  esac
  for bot in $BOT_LIST ; do
    if [ $bot == "bot" ] ; then
      Start_Bot $BOT_USER $bot bot betfair.ini
    else
      Start_Bot $BOT_USER $bot bot $bot.ini
    fi
  done

  BET_PLACER_LIST="bet_placer_10 bet_placer_11 bet_placer_20 bet_placer_21 bet_placer_30 bet_placer_31"
  for placer in $BET_PLACER_LIST ; do
    Start_Bot $BOT_USER $placer bet_placer bet_placer.ini
  done

#  BET_PLACER_LIST="football_better"
#  for placer in $BET_PLACER_LIST ; do
#    Start_Bot $BOT_USER $placer football_better $placer.ini $BOT_MODE
#  done

  #zip logfiles every hour, on minute 17 in the background
  MINUTE=$(date +"%M")
  if [ $MINUTE == "17" ] ; then
    tclsh $BOT_SCRIPT/tcl/move_or_zip_old_logfiles.tcl $BOT_USER &
  fi
  
  
  HOUR=$(date +"%H")
  if [ $HOUR == "05" ] ; then
    if [ $MINUTE == "20" ] ; then
      Start_Bot $BOT_USER data_mover data_mover
    fi
  fi
  
}
# start here 
case $BOT_MACHINE_ROLE in
  PROD)
    #check the bots, and startup if  necessarry
    #USER_LIST=$(ls $BOT_START/user)
    USER_LIST="bnl jmb"
    HOST=db.nonodev.com
    for USR in $USER_LIST ; do
      Check_Bots_For_User $USR
    done
  
    HOUR=$(date +"%H")
    MINUTE=$(date +"%M")
    if [ $HOUR == "11" ] ; then
      if [ $MINUTE == "45" ] ; then
        WEEK_DAY=$(date +"%u")
        for USR in $USER_LIST ; do
          $PG_DUMP --host=$HOST --username=bnl $USR | gzip > /home/bnl/datadump/${USR}_${WEEK_DAY}.dmp.gz &
        done
      fi
    fi
    
    if [ $MINUTE == "40" ] ; then
       $VACUUMDB --all --analyze --host=$HOST --username=bnl &
    fi
  
  ;;
  *) 
  #do nothing on non-PROD hosts
  exit 0 ;;
esac
