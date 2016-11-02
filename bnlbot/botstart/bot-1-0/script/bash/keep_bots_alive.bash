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

NUM_RUNNING=$(ps -ef | grep -v grep | grep -c keep_bots_alive.bash)
#if [ $NUM_RUNNING -gt 2 ] ; then
#  exit 0
#fi

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

#  case $BOT_MACHINE_ROLE in
#    PROD) BOT_LIST="bot" ;;
#    TEST) BOT_LIST="bot" ;;
#    SIM)  BOT_LIST="" ;;
#    *)    BOT_LIST="" ;;
#  esac

  Start_Bot $BOT_USER bet_checker bet_checker

  POLLERS_LIST="poll_1 poll_2 poll_3 poll_4"
  for poller in $POLLERS_LIST ; do
    Start_Bot $BOT_USER $poller poll poll.ini
  done

  #for bot in $BOT_LIST ; do
  #  if [ $bot == "bot" ] ; then
  #    Start_Bot $BOT_USER $bot bot betfair.ini
  #  else
  #    Start_Bot $BOT_USER $bot bot $bot.ini
  #  fi
  #done
  BET_PLACER_LIST="bet_placer_001 bet_placer_002 bet_placer_003 \
                   bet_placer_004 bet_placer_005 bet_placer_006 \
                   bet_placer_007 bet_placer_008 bet_placer_009 \
                   bet_placer_010 bet_placer_011 bet_placer_012 \
                   bet_placer_013 bet_placer_014 bet_placer_015 \
                   bet_placer_016 bet_placer_017 bet_placer_018 \
                   bet_placer_019 bet_placer_020 bet_placer_021 \
                   bet_placer_022 bet_placer_023"

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

  if [ $BOT_HOUR == "00" ] ; then
    if [ $BOT_MINUTE == "01" ] ; then
    #  Start_Bot $BOT_USER data_mover data_mover
      $BOT_TARGET/bin/race_time --rpc
    fi
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

    ael)
      Start_Bot $BOT_USER markets_fetcher markets_fetcher
      Start_Bot $BOT_USER w_fetch_json winners_fetcher_json
      Start_Bot $BOT_USER bet_checker bet_checker

      POLLERS_LIST="poll_bounds_1 poll_bounds_2 poll_bounds_3 poll_bounds_4"

      for poller in $POLLERS_LIST ; do
        Start_Bot $BOT_USER $poller poll_bounds poll_bounds.ini
      done
      IS_TESTER="true"

    ;;

    #ghd)
    #   Start_Bot $BOT_USER gh_mark_fetcher markets_fetcher_greyhounds
    #   Start_Bot $BOT_USER w_fetch_json winners_fetcher_json
    #   Start_Bot $BOT_USER bet_checker bet_checker
    #   DATA_COLLECTORS_LIST="poll_market_1 poll_market_2 poll_market_3 "
    #   for collector in $DATA_COLLECTORS_LIST ; do
    #     Start_Bot $BOT_USER $collector poll_gh_market
    #   done
    #
    #   PLAYERS_LIST2="gh_poll_1 gh_poll_2 gh_poll_3 "
    #   for player in $PLAYERS_LIST2 ; do
    #     Start_Bot $BOT_USER $player long_poll_gh_market
    #   done
    #;;

    soc)
       Start_Bot $BOT_USER markets_fetcher markets_fetcher_soccer
       Start_Bot $BOT_USER w_fetch_json winners_fetcher_json
       Start_Bot $BOT_USER bet_checker bet_checker
       Start_Bot $BOT_USER poll_soccer poll_soccer
       Start_Bot $BOT_USER live_feed football_live_feed
       #DATA_COLLECTORS_LIST="poll_market_s01 poll_market_s02 poll_market_s03 poll_market_s04 \
       #                      poll_market_s05 poll_market_s06 poll_market_s07 poll_market_s08 \
       #                      poll_market_s09 poll_market_s10 poll_market_s11 poll_market_s12 \
       #                      poll_market_s13 poll_market_s14 poll_market_s15 poll_market_s16 \
       #                      poll_market_s17 poll_market_s18 poll_market_s19 poll_market_s20"

       #for collector in $DATA_COLLECTORS_LIST ; do
       #  Start_Bot $BOT_USER $collector poll_soccer
       #done

      # Start_Bot $BOT_USER menu_parser menu_parser

       #PLAYERS_LIST2="gh_poll_1 gh_poll_2 gh_poll_3 "
       #for player in $PLAYERS_LIST2 ; do
       #  Start_Bot $BOT_USER $player long_poll_gh_market
       #done
    ;;


  esac

  #zip logfiles every hour, on minute 17 in the background
  if [ $BOT_MINUTE == "17" ] ; then
    tclsh $BOT_SCRIPT/tcl/move_or_zip_old_logfiles.tcl $BOT_USER &
  fi

  #if [ $BOT_HOUR == "13" ] ; then
  #  if [ $BOT_MINUTE == "10" ] ; then
  #    Start_Bot $BOT_USER data_mover data_mover
  #  fi
  #fi

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

function create_dump () {

  #WD=/data/db_dumps/script
  DATE=$(date +"%d")
  YEAR=$(date +"%Y")
  MONTH=$(date +"%m")
  TARGET_DIR=/data/db_dumps/${YEAR}/${MONTH}/${DATE}

  [ ! -d $TARGET_DIR ] && mkdir -p $TARGET_DIR

  export PATH=/usr/bin:$PATH

  DB_LIST="ael bnl dry ghd jmb msm soc"
  TABLE_LIST="aevents amarkets aprices apriceshistory arunners abets"

  for DBNAME in ${DB_LIST} ; do
    for TABLE in ${TABLE_LIST} ; do
      pg_dump --schema-only --dbname=${DBNAME} --table=${TABLE} > ${TARGET_DIR}/${DBNAME}_${YEAR}_${MONTH}_${DATE}_${TABLE}_schema.dmp
      pg_dump --data-only  --dbname=${DBNAME} --column-inserts --table=${TABLE} | gzip > ${TARGET_DIR}/${DBNAME}_${YEAR}_${MONTH}_${DATE}_${TABLE}.dmp.gz
      R=$?
      if [ $R -eq 0 ] ; then
        case ${TABLE} in
          abets)  echo "null" > /dev/null ;;
              *)  psql --no-psqlrc --dbname=${DBNAME} --command="truncate table ${TABLE}" ;;
        esac
      fi
    done
  done

  #DB_LIST="${DB_LIST} ${DBNAME}"
  #
  for DBNAME in ${DB_LIST} ; do
    vacuumdb --dbname=${DBNAME} --analyze
  # # reindexdb --dbname=${DBNAME} --system
  # # reindexdb --dbname=${DBNAME}
  done

}

# start here

HOUR=$(date +"%H")
MINUTE=$(date +"%M")
WEEK_DAY=$(date +"%u")
DAY=$(date +"%d")

case $BOT_MACHINE_ROLE in
  PROD)
    #check the bots, and startup if  necessary
    USER_LIST_PLAYERS_ONLY="bnl jmb msm"
    SYSTEM_USER_LIST="ael dry soc"
#   "ghd soc"

    HOST=db.nonodev.com
    for USR in $USER_LIST_PLAYERS_ONLY ; do
      Check_Bots_For_User $USR $WEEK_DAY $HOUR $MINUTE
    done

    for USR in $SYSTEM_USER_LIST ; do
      Check_System_Bots_For_User $USR $WEEK_DAY $HOUR $MINUTE
    done

    if [ $HOUR == "00" ] ; then
      if [ $MINUTE == "01" ] ; then
          create_dump
      fi
    fi

    #if [ $DAY == "1" ] ; then
    #  if [ $HOUR == "13" ] ; then
    #    if [ $MINUTE == "12" ] ; then
    #      SLEEPTIME=1
    #      for USR in $USER_LIST ; do
    #        #Start one every 20 min in the background
    #        (sleep $SLEEPTIME && $PG_DUMP --host=$HOST --username=bnl --dbname=$USR | gzip > ${DUMP_DIRECTORY}/${USR}_${WEEK_DAY}.dmp.gz) &
    #        (( SLEEPTIME = SLEEPTIME +1200 ))
    #      done
    #    fi
    #  fi
    #fi


    #if [ $HOUR == "13" ] ; then
    #  if [ $MINUTE == "20" ] ; then
    #    for USR in $USER_LIST_PLAYERS_ONLY ; do
    #
    #    #Start one every 5 min in the background, both with and without system tables
    #    SLEEPTIME=1
    #    (sleep $SLEEPTIME && $REINDEXDB --host=$HOST --username=bnl --dbname=$USR --system) &
    #    (( SLEEPTIME = SLEEPTIME +10 ))
    #    (sleep $SLEEPTIME && $REINDEXDB --host=$HOST --username=bnl --dbname=$USR ) &
    #    (( SLEEPTIME = SLEEPTIME +300 ))
    #    done
    #  fi
    #fi

   # if [ $MINUTE == "05" ] || [ $MINUTE == "25" ] || [ $MINUTE == "45" ] ; then
   #   for USR in $USER_LIST_PLAYERS_ONLY ; do
   #     Create_Plots $USR 42
   #     Create_Plots $USR 182
   #   done
   # fi

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








