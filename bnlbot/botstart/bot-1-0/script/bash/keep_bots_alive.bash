#!/bin/bash

# should be run from a crontab like
#* * * * * cd / && /home/bnl/bnlbot/botstart/bot-1-0/script/bash/keep_bots_alive.bash
#2 0 * * * cd / && /home/bnl/bnlbot/botstart/bot-1-0/script/bash/dump_db.bash
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

  Start_Bot $BOT_USER bet_checker bet_checker

  POLLERS_LIST="poll_1 poll_2 poll_3 poll_4 poll_5 poll_6 poll_7 poll_8"
  for poller in $POLLERS_LIST ; do
    Start_Bot $BOT_USER $poller poll poll.ini
  done

  BET_PLACER_LIST="bet_placer_001 bet_placer_002 bet_placer_003 \
                   bet_placer_004 bet_placer_005 bet_placer_006 \
                   bet_placer_007 bet_placer_008 bet_placer_009 \
                   bet_placer_010 bet_placer_011 bet_placer_012 "
                   
#                   bet_placer_013 bet_placer_014 bet_placer_015 \
#                   bet_placer_016 bet_placer_017 bet_placer_018 "

  for placer in $BET_PLACER_LIST ; do
    Start_Bot $BOT_USER $placer bet_placer bet_placer.ini
  done

  if [ $BOT_HOUR == "23" ] ; then
    if [ $BOT_MINUTE == "00" ] ; then
      Start_Bot $BOT_USER saldo_fetcher saldo_fetcher
    fi
  fi

  #zip logfiles every hour, on minute 17 in the background
  if [ $BOT_MINUTE == "17" ] ; then
    tclsh $BOT_SCRIPT/tcl/move_or_zip_old_logfiles.tcl $BOT_USER &
  fi

}


##
function Check_System_Bots_For_User () {

  export BOT_USER=$1
  BOT_WEEK_DAY=$2
  BOT_HOUR=$3
  BOT_MINUTE=$4

  . $BOT_START/bot.bash $BOT_USER
  #No login file -> give up
  [ ! -r $BOT_HOME/login.ini ] && return 0

  #BOT_USER=$1
  #BOT_NAME=$2
  #EXE_NAME=$3
  #INI_NAME=$4
  #MODE=$5

  IS_TESTER="false"

  case $BOT_USER in
    dry)
       Start_Bot $BOT_USER markets_fetcher markets_fetcher
       Start_Bot $BOT_USER w_fetch_json winners_fetcher_json
       Start_Bot $BOT_USER bet_checker bet_checker

       DATA_COLLECTORS_LIST="poll_market_1 poll_market_2 \
                             poll_market_3 poll_market_4 \
                             poll_market_5 poll_market_6 \
                             poll_market_7 poll_market_8"

       for collector in $DATA_COLLECTORS_LIST ; do
         Start_Bot $BOT_USER $collector poll_market
       done

       Start_Bot $BOT_USER bot_ws bot_web_server
    ;;

    #ael)
    #  Start_Bot $BOT_USER markets_fetcher markets_fetcher
    #  Start_Bot $BOT_USER w_fetch_json winners_fetcher_json
    #  Start_Bot $BOT_USER bet_checker bet_checker
    #
    #  POLLERS_LIST="poll_bounds_1 poll_bounds_2 poll_bounds_3 poll_bounds_4"
    #
    #  for poller in $POLLERS_LIST ; do
    #    Start_Bot $BOT_USER $poller poll_bounds poll_bounds.ini
    #  done
    #  IS_TESTER="true"
    #
    #;;

    ghd)
       Start_Bot $BOT_USER gh_mark_fetcher markets_fetcher_greyhounds
       Start_Bot $BOT_USER w_fetch_json winners_fetcher_json
       Start_Bot $BOT_USER bet_checker bet_checker
       #DATA_COLLECTORS_LIST="poll_market_1 poll_market_2 poll_market_3 "
       #for collector in $DATA_COLLECTORS_LIST ; do
       #  Start_Bot $BOT_USER $collector poll_gh_market
       #done
       #
       #PLAYERS_LIST2="gh_poll_1 gh_poll_2 gh_poll_3 "
       #for player in $PLAYERS_LIST2 ; do
       #  Start_Bot $BOT_USER $player long_poll_gh_market
       #done
    ;;

    #soc)
    #   Start_Bot $BOT_USER markets_fetcher markets_fetcher_soccer
    #   Start_Bot $BOT_USER w_fetch_json winners_fetcher_json
    #   Start_Bot $BOT_USER bet_checker bet_checker
    #   #Start_Bot $BOT_USER poll_soccer poll_soccer
    #   Start_Bot $BOT_USER live_feed football_live_feed
    #   #DATA_COLLECTORS_LIST="poll_market_s01 poll_market_s02 poll_market_s03 poll_market_s04 \
    #   #                      poll_market_s05 poll_market_s06 poll_market_s07 poll_market_s08 \
    #   #                      poll_market_s09 poll_market_s10 poll_market_s11 poll_market_s12 \
    #   #                      poll_market_s13 poll_market_s14 poll_market_s15 poll_market_s16 \
    #   #                      poll_market_s17 poll_market_s18 poll_market_s19 poll_market_s20"
    #
    #   #for collector in $DATA_COLLECTORS_LIST ; do
    #   #  Start_Bot $BOT_USER $collector poll_soccer
    #   #done
    #
    #  # Start_Bot $BOT_USER menu_parser menu_parser
    #
    #   #PLAYERS_LIST2="gh_poll_1 gh_poll_2 gh_poll_3 "
    #   #for player in $PLAYERS_LIST2 ; do
    #   #  Start_Bot $BOT_USER $player long_poll_gh_market
    #   #done
    #;;


  esac

  #zip logfiles every hour, on minute 17 in the background
  if [ $BOT_MINUTE == "17" ] ; then
    tclsh $BOT_SCRIPT/tcl/move_or_zip_old_logfiles.tcl $BOT_USER &
  fi


  #if [ $IS_TESTER == "true" ] ; then
  #  case $BOT_MINUTE in
  #      00) $BOT_TARGET/bin/stat_maker --update_only ;;
  #      05) $BOT_TARGET/bin/stat_maker --update_only ;;
  #      10) $BOT_TARGET/bin/stat_maker --update_only ;;
  #      15) $BOT_TARGET/bin/stat_maker --update_only ;;
  #      50) $BOT_TARGET/bin/stat_maker --update_only ;;
  #      25) $BOT_TARGET/bin/stat_maker --update_only ;;
  #      50) $BOT_TARGET/bin/stat_maker --update_only ;;
  #      35) $BOT_TARGET/bin/stat_maker --update_only ;;
  #      50) $BOT_TARGET/bin/stat_maker --update_only ;;
  #      45) $BOT_TARGET/bin/stat_maker --update_only ;;
  #      50) $BOT_TARGET/bin/stat_maker --update_only ;;
  #      55) $BOT_TARGET/bin/stat_maker --update_only ;;
  #  esac
  ##  A=NULL
  #fi
}

##

function Create_Plots () {
  USR=$1
  DAYS=$2
  TS=$(date +"%Y-%m-%d %T")

  . $BOT_START/bot.bash $USR


  STRATEGIES=$(${BOT_TARGET}/bin/graph_data --print_strategies)

  #regenerate the graphs
  old_pwd=$(pwd)
  cd ${BOT_SCRIPT}/plot/gui_plot/

  for S in $STRATEGIES ; do

      if [ $S == "LAY_160_200" ] ; then
        ST="HORSES_WIN_LAY_FINISH_160_200_1"
      elif [ $S == "LAY_1_10_25_4" ] ; then
        ST="HORSES_WIN_LAY_FINISH_1.10_25.0_4"
      else
        ST=$S
      fi

    strategy=$(echo ${ST} | tr '[:upper:]' '[:lower:]')
    #create datafiles
    ${BOT_TARGET}/bin/graph_data --betname=${ST} --lapsed --days=${DAYS} > ${BOT_START}/user/${USR}/gui_related/settled_vs_lapsed_${DAYS}_${strategy}.dat 2>/dev/null
    ${BOT_TARGET}/bin/graph_data --betname=${ST} --profit --days=${DAYS} > ${BOT_START}/user/${USR}/gui_related/profit_vs_matched_${DAYS}_${strategy}.dat 2>/dev/null
    ${BOT_TARGET}/bin/graph_data --betname=${ST} --avg_price --days=${DAYS} > ${BOT_START}/user/${USR}/gui_related/avg_price_${DAYS}_${strategy}.dat 2>/dev/null
    #put it in wd of gnuplot
    cp ${BOT_START}/user/${USR}/gui_related/*.dat ./
    DF1="settled_vs_lapsed_${DAYS}_${strategy}"
    gnuplot \
      -e "data_file='$DF1'" \
      -e "ts='$TS'" \
      -e "user='$USR'" \
      -e "days='$DAYS'" \
      settled_vs_lapsed.gpl 2>/dev/null
    DF2="profit_vs_matched_${DAYS}_${strategy}"
    gnuplot \
      -e "data_file='$DF2'" \
      -e "ts='$TS'" \
      -e "user='$USR'" \
      -e "days='$DAYS'" \
      profit_vs_matched.gpl 2>/dev/null
    DF2="avg_price_${DAYS}_${strategy}"
    gnuplot \
      -e "data_file='$DF2'" \
      -e "ts='$TS'" \
      -e "user='$USR'" \
      -e "days='$DAYS'" \
      avg_price.gpl 2>/dev/null
  done

  if [ $DAYS == "42" ] ; then
    FILES=""
    for S in $STRATEGIES ; do

      if [ $S == "LAY_160_200" ] ; then
        ST="HORSES_WIN_LAY_FINISH_160_200_1"
      elif [ $S == "LAY_1_10_25_4" ] ; then
        ST="HORSES_WIN_LAY_FINISH_1.10_25.0_4"
      else
        ST=$S
      fi

      strategy=$(echo ${ST} | tr '[:upper:]' '[:lower:]')
      DATA_FILE=${BOT_START}/user/${USR}/gui_related/${strategy}.dat
      ${BOT_TARGET}/bin/graph_data --equity  --betname=${ST}  > ${DATA_FILE} 2>/dev/null
      FILES="${FILES} ${DATA_FILE}"

      #one plot for each:
      gnuplot \
        -e "files='$DATA_FILE'" \
        -e "ts='$TS'" \
        -e "target_png='${strategy}.png'" \
        -e "user='$USR'" \
        equity.gpl  2>/dev/null
    done
      #one plot for all together:

    gnuplot \
      -e "files='$FILES'" \
      -e "ts='$TS'" \
      -e "target_png='equity.png'" \
      -e "user='$USR'" \
      equity.gpl  2>/dev/null
  fi
  #move to user area and cleanup
  rm *.dat
  cp *.png ${BOT_START}/user/${USR}/gui_related/
  rm *.png
  cd ${old_pwd}
}


# start here

HOUR=$(date +"%H")
MINUTE=$(date +"%M")
WEEK_DAY=$(date +"%u")
DAY=$(date +"%d")

#
#ps
#bnl      13563 13562  0 17:45 ?        00:00:00 /bin/sh -c cd / && /home/bnl/bnlbot/botstart/bot-1-0/script/bash/keep_bots_alive.bash
#bnl      13565 13563  0 17:45 ?        00:00:00 /bin/bash /home/bnl/bnlbot/botstart/bot-1-0/script/bash/keep_bots_alive.bash
#bnl      13573 13565  0 17:45 ?        00:00:00 /bin/bash /home/bnl/bnlbot/botstart/bot-1-0/script/bash/keep_bots_alive.bash

NUM_RUNNING=$(ps -ef | grep -v grep | grep /bin/sh |  grep -c keep_bots_alive.bash)
#echo "NUM_RUNNING: $NUM_RUNNING $(date)"

if [ $NUM_RUNNING -gt 1 ] ; then
  exit 0
fi    

case $BOT_MACHINE_ROLE in
  PROD)
    
    #check the bots, and startup if  necessary
    USER_LIST_PLAYERS_ONLY="bnl jmb msm"
    SYSTEM_USER_LIST="dry soc ghd"
#   "ael soc"

    HOST=db.nonodev.com
    for USR in $USER_LIST_PLAYERS_ONLY ; do
      Check_Bots_For_User $USR $WEEK_DAY $HOUR $MINUTE
    done

    for USR in $SYSTEM_USER_LIST ; do
      Check_System_Bots_For_User $USR $WEEK_DAY $HOUR $MINUTE
    done

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

DISK_LIST="xvda xvdf"

for DISK in $DISK_LIST ; do
  USED_SIZE=$( df  | grep $DISK | awk '{print $3}')
  DISK_SIZE=$( df  | grep $DISK | awk '{print $2}')
  FS=$( df  | grep $DISK | awk '{print $1}')
  PERCENTAGE=$(tclsh $PCT $USED_SIZE $DISK_SIZE)
  for RECIPENT in $MAIL_LIST ; do
   if [ $PERCENTAGE -gt $ALARM_SIZE ] ; then
     if [ ! -r ${ALARM_TODAY_FILE} ] ; then
       df -h | mail --subject="disk ${FS} - ${DISK} almost full ( ${PERCENTAGE} %) on $(hostname)" $RECIPENT
       df -h | $BOT_TARGET/bin/aws_mail --subject="disk ${FS} - ${DISK} almost full ( ${PERCENTAGE} %) on $(hostname)"
       touch ${ALARM_TODAY_FILE}
     fi
   fi
  done
done

#delete old alarmfiles

ALARM_FILES=$(ls /tmp/alarm*  2>/dev/null)

for f in $ALARM_FILES ; do
  if [ $f != $ALARM_TODAY_FILE ] ; then
    rm -f $f
  fi
done

#db check

if [ $HOUR != "11" ] ; then
#  echo "1"
  . $BOT_START/bot.bash bnl
  psql --command="select * from aevents where countrycode='ww'" --quiet --tuples-only >/dev/null
  R=$?
  DAY2_FILE=$(date +"%F")
  DB_ALARM_TODAY_FILE=/tmp/db_alarm_${DAY2_FILE}

  if [ $R != "0" ] ; then
    for RECIPENT in $MAIL_LIST ; do
      if [ ! -r ${DB_ALARM_TODAY_FILE} ] ; then
        echo "db seems to be down, psql does not get access to BNL" | mail --subject="is db up and running on $(hostname) ?" $RECIPENT
        touch ${DB_ALARM_TODAY_FILE}
      fi
    done
  fi

  #delete old alarmfiles
  DB_ALARM_FILES=$(ls /tmp/db_alarm*  2>/dev/null)

  for f in $DB_ALARM_FILES ; do
    if [ $f != $DB_ALARM_TODAY_FILE ] ; then
      rm -f $f
    fi
  done
fi
