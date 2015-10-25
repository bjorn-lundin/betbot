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
export BOT_START=/home/bnl/svn/bnlbot/botstart
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

  Start_Bot $BOT_USER w_fetch_json winners_fetcher_json

  Start_Bot $BOT_USER long_poll_m long_poll_market
  
  
  case $BOT_MACHINE_ROLE in
    PROD) BOT_LIST="bot" ;;
    TEST) BOT_LIST="bot" ;;
    SIM)  BOT_LIST="" ;;
    *)    BOT_LIST="" ;;
  esac

  if [ $IS_DATA_COLLECTOR == "false" ] ; then

    Start_Bot $BOT_USER bet_checker bet_checker
    
#    POLLERS_LIST="poll_1 poll_2 poll_3 poll_4"
#    for poller in $POLLERS_LIST ; do
#      Start_Bot $BOT_USER $poller poll poll.ini
#    done
    
 
#   BET_PLACER_LIST="bet_placer_001 bet_placer_002 bet_placer_003 \
#                    bet_placer_004 bet_placer_005 bet_placer_006 \
#                    bet_placer_007 bet_placer_008 bet_placer_009 \
#                    bet_placer_010 bet_placer_011 bet_placer_012"
#
#    for placer in $BET_PLACER_LIST ; do
#      Start_Bot $BOT_USER $placer bet_placer bet_placer.ini
#    done


  fi

  #zip logfiles every hour, on minute 17 in the background
  if [ $BOT_MINUTE == "17" ] ; then
    tclsh $BOT_SCRIPT/tcl/move_or_zip_old_logfiles.tcl $BOT_USER &
  fi

  if [ $BOT_HOUR == "05" ] ; then
    if [ $BOT_MINUTE == "10" ] ; then
      $BOT_TARGET/bin/race_time --rpc
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
    USER_LIST_PLAYERS_ONLY="bnl"

    HOST=localhost
    for USR in $USER_LIST ; do
      Check_Bots_For_User $USR $WEEK_DAY $HOUR $MINUTE
    done
  ;;
  
  LONGPOLL)  
    #check the bots, and startup if  necessarry
    USER_LIST=$(ls $BOT_START/user)
    USER_LIST_PLAYERS_ONLY="bnl"

    HOST=localhost
    for USR in $USER_LIST ; do
      Check_Bots_For_User $USR $WEEK_DAY $HOUR $MINUTE
    done
  ;;
  *)
  #do nothing on non-PROD hosts
  exit 0 ;;
esac

