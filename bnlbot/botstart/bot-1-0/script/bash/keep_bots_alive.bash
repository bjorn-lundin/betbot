#!/bin/bash
#exit

# should be run from a crontab like
#* * * * * cd / && /home/bnl/svn/botstart/bot-1-0/script/bash/keep_bots_alive.bash
#2 0 * * * cd / && /home/bnl/svn/botstart/bot-1-0/script/bash/dump_db.bash
#install with
#echo "25 3 * * * /home/bnl/svn/do_backup_db.bash" >  crontab.tmp
#crontab -l > crontab.tmp
#echo "* * * * * cd / && /home/bnl/svn/botstart/bot-1-0/script/bash/keep_bots_alive.bash" >>  crontab.tmp
#crontab -r
#cat crontab.tmp | crontab
#crontab -l
#rm crontab.tmp
#echo "* * * * * cd / && /home/bnl/svn/botstart/bot-1-0/script/bash/keep_bots_alive.bash" | crontab

#if we should NOT start it, check here.
#if /var/lock/bot is exists, then exit. created/removed from /etc/init.d/bot

#exit 0

[ -r /var/lock/bot ] && echo "/var/lock/bot exists" && exit 0


TZ='Europe/Stockholm'
export TZ
[ -d /home/bnl/svn/botstart ] && export BOT_START=/home/bnl/svn/botstart
[ -d /bnlbot/botstart ] && export BOT_START=/bnlbot/botstart

date +"%Y-%m-%d %H:%M:%S" > ${BOT_START}/bot-1-0/script/bash/last_run_keeep_alive.dat

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

  #don't make a mail for each user/proc if not allowed to start anyway
  case $BOT_HOUR in
      "00" | "01" | "02" | "03" | "04" | "05" | "06" | "07" | "08" | "09" | "10" | "11")
      return 0
      :
    ;;
    *)
      :
    ;;
  esac


  . $BOT_START/bot.bash $BOT_USER
  #No login file -> give up
  [ ! -r $BOT_HOME/login.ini ] && return 0

  #BOT_USER=$1
  #BOT_NAME=$2
  #EXE_NAME=$3
  #INI_NAME=$4
  #MODE=$5
  #all need this one

  Start_Bot $BOT_USER rpc_tracker rpc_tracker
  sleep 2
  Start_Bot $BOT_USER login_handler login_handler
  sleep 2
  Start_Bot $BOT_USER markets_fetcher markets_fetcher

  Start_Bot $BOT_USER w_fetch_json winners_fetcher_json

  Start_Bot $BOT_USER bet_checker bet_checker

  POLLERS_LIST="poll_01 poll_02 poll_03 poll_04 poll_05 poll_06 poll_07 poll_08 poll_09 poll_10 poll_11 poll_12 poll_13 poll_14"
  for poller in $POLLERS_LIST ; do
    Start_Bot $BOT_USER $poller poll poll.ini
  done

  BET_PLACER_LIST="bet_placer_001 bet_placer_002 bet_placer_003 \
                   bet_placer_004 bet_placer_005 bet_placer_006 \
                   bet_placer_007 bet_placer_008 bet_placer_009 \
                   bet_placer_010 "


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


  #don't make a mail for each user/proc if not allowed to start anyway
  case $BOT_HOUR in
      "00" | "01" | "02" | "03" | "04" | "05" | "06" | "07" | "08" | "09" | "10" | "11")

      Start_Bot $BOT_USER bot_ws bot_web_server
      return 0
    ;;
    *)
      Start_Bot $BOT_USER bot_ws bot_web_server
    ;;
  esac


  IS_TESTER="false"

  Start_Bot $BOT_USER rpc_tracker rpc_tracker 
  sleep 2

  case $BOT_USER in
    dry)
       Start_Bot $BOT_USER markets_fetcher markets_fetcher
       Start_Bot $BOT_USER w_fetch_json winners_fetcher_json
       Start_Bot $BOT_USER bet_checker bet_checker

       DATA_COLLECTORS_LIST="poll_market_1 poll_market_2 \
                             poll_market_3 poll_market_4 \
                             poll_market_5 poll_market_6 \
                             poll_market_7 poll_market_8 \
                             poll_market_9 poll_market_10 \
                             poll_market_11 poll_market_12 \
                             poll_market_13 poll_market_14"

       for collector in $DATA_COLLECTORS_LIST ; do
         Start_Bot $BOT_USER $collector poll_market
       done

     # done above  Start_Bot $BOT_USER bot_ws bot_web_server
    ;;

#    ghd)
#       Start_Bot $BOT_USER gh_mark_fetcher markets_fetcher_greyhounds
#       Start_Bot $BOT_USER w_fetch_json winners_fetcher_json
#       Start_Bot $BOT_USER bet_checker bet_checker
#       #DATA_COLLECTORS_LIST="poll_market_1 poll_market_2 poll_market_3 "
#       #for collector in $DATA_COLLECTORS_LIST ; do
#       #  Start_Bot $BOT_USER $collector poll_gh_market
#       #done
#       #
#       #PLAYERS_LIST2="gh_poll_1 gh_poll_2 gh_poll_3 "
#       #for player in $PLAYERS_LIST2 ; do
#       #  Start_Bot $BOT_USER $player long_poll_gh_market
#       #done
#    ;;

  esac

  #zip logfiles every hour, on minute 17 in the background
  if [ $BOT_MINUTE == "17" ] ; then
    tclsh $BOT_SCRIPT/tcl/move_or_zip_old_logfiles.tcl $BOT_USER &
  fi


}

##

function Create_Plots () {
  USR=$1
  DAYS=$2
  TS=$(date +"%Y-%m-%d %T")

  . $BOT_START/bot.bash $USR

  #echo "create plots"
  STRATEGIES=$(${BOT_TARGET}/bin/graph_data --print_strategies)

  #regenerate the graphs
  old_pwd=$(pwd)
  cd ${BOT_SCRIPT}/plot/gui_plot/

  for S in $STRATEGIES ; do

    strategy=$(echo ${S} | tr '[:upper:]' '[:lower:]')
    #create datafiles
    ${BOT_TARGET}/bin/graph_data --betname=${S} --lapsed --days=${DAYS} > ${BOT_START}/user/${USR}/gui_related/settled_vs_lapsed_${DAYS}_${strategy}.dat 2>/dev/null
    ${BOT_TARGET}/bin/graph_data --betname=${S} --profit --days=${DAYS} > ${BOT_START}/user/${USR}/gui_related/profit_vs_matched_${DAYS}_${strategy}.dat 2>/dev/null
    ${BOT_TARGET}/bin/graph_data --betname=${S} --avg_price --days=${DAYS} > ${BOT_START}/user/${USR}/gui_related/avg_price_${DAYS}_${strategy}.dat 2>/dev/null
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

      strategy=$(echo ${S} | tr '[:upper:]' '[:lower:]')
      DATA_FILE=${BOT_START}/user/${USR}/gui_related/${strategy}.dat
      ${BOT_TARGET}/bin/graph_data --startdate="2018-11-01" --equity  --betname=${S}  > ${DATA_FILE} 2>/dev/null
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
  #move to user area and cleanup, and to web server
  rm *.dat
  cp *.png ${BOT_START}/user/${USR}/gui_related/
  rm *.png
  cd ${old_pwd}
}

function check_stuck_markets_fetcher () {
  HOUR=$1
  #don't make a mail for each user/proc if not allowed to start anyway
  case $HOUR in
      "00" | "01" | "02" | "03" | "04" | "05" | "06" | "07" | "08" | "09" | "10" | "11")
      return 0
    ;;
    *)
       :
    ;;
  esac

 #  return 0
  #check that marketfetcher is not stuck
  logfile=$BOT_HOME/log/markets_fetcher.log
  md5file=$BOT_HOME/log/markets_fetcher.md5
  pidfile=$BOT_HOME/locks/markets_fetcher

#  echo "---123--------"

  [ ! -r ${md5file} ] && echo "dummy" > ${md5file}

#  echo "---md5--------"
#  cat  ${md5file}
#  echo "-----------"

  this_sum1=$(md5sum ${logfile})
  last_sum1=$(cat ${md5file})

  this_sum=$(echo ${this_sum1} | cut -d' ' -f1)
  last_sum=$(echo ${last_sum1} | cut -d' ' -f1)

#  echo "---this_sum--------"
#  echo  ${this_sum}
#  echo "---last_sum--------"
#  echo  ${last_sum}
#  echo "-----------"


  if [ "${this_sum}" == "${last_sum}" ] ; then
    echo "do kill stuck markets_fetcher for $BOT_HOME"
    pid=$(cat ${pidfile} | cut -d'|' -f1)
    echo "killing pid $pid"
    kill -term $pid
    sleep 1
    kill -kill $pid
  else
#    echo "md5 is different"
    :
  fi
  echo $this_sum > ${md5file}
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

#when in mecedit via nano
#bnl@pibetbot:~ $ ps -ef | grep keep_bots_alive.bash
#bnl      25954 24135  0 14:20 pts/0    00:00:00 /bin/sh /usr/bin/sensible-editor /bnlbot/botstart/bot-1-0/script/bash/keep_bots_alive.bash
#bnl      25962 25954  0 14:20 pts/0    00:00:02 /bin/nano /bnlbot/botstart/bot-1-0/script/bash/keep_bots_alive.bash
#bnl      30625 25671  0 14:35 pts/2    00:00:00 grep --color=auto keep_bots_alive.bash

NUM_RUNNING=$(ps -ef | grep -v grep | grep /bin/sh | grep -v sensible-editor | grep -c keep_bots_alive.bash)
#echo "NUM_RUNNING: $NUM_RUNNING $(date)"

if [ $NUM_RUNNING -gt 1 ] ; then
  exit 0
fi

case $BOT_MACHINE_ROLE in
  PROD)
    # reboot each night. Postgres did lock up once and lock kept by dead processes
    if [ $HOUR == "02" ] ; then
      if [ $MINUTE == "01" ] ; then
        sudo service postgresql stop
        sudo reboot
      fi
    fi
    #check the bots, and startup if  necessary
    USER_LIST_PLAYERS_ONLY="bnl jmb msm"
    SYSTEM_USER_LIST="dry"
#   "ael soc"

    for USR in $USER_LIST_PLAYERS_ONLY ; do
      Check_Bots_For_User $USR $WEEK_DAY $HOUR $MINUTE
      if [ $HOUR == "12" ] ; then
        if [ $MINUTE == "24" ] ; then
          #Create_Plots $USR 7
          Create_Plots $USR 42
        fi
      fi
      if [ $HOUR == "23" ] ; then
        if [ $MINUTE == "01" ] ; then
          #Create_Plots $USR 7
          Create_Plots $USR 42
        fi
      fi
      # was lock in db held by dead? psql check_stuck_markets_fetcher
    done

    for USR in $SYSTEM_USER_LIST ; do
      Check_System_Bots_For_User $USR $WEEK_DAY $HOUR $MINUTE
      check_stuck_markets_fetcher $HOUR
    done

  ;;
  *)
  #do nothing on non-PROD hosts
  exit 0 ;;
esac

if [ $MINUTE == "20" ] ; then
  $BOT_SCRIPT/bash/duckdns.bash ; # update dyndns once per hour
fi

TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
TEMP=$(($TEMP/1000))
echo "$(date -Is) $TEMP" >> $BOT_START/data/temperaturelog/$(date +%F)-temperature.dat

PCT="/tmp/percent.tcl"
echo 'puts [expr [lindex $argv 0] * 100  / [lindex $argv 1]]' > $PCT

# check filling degree
#1 kb blocks
#90%
export ALARM_SIZE=90
DAY_FILE=$(date +"%F")
ALARM_TODAY_FILE=/tmp/alarm_${DAY_FILE}

MAIL_LIST="b.f.lundin@gmail.com"

#DISK_LIST="sda1 sda3 root"
DISK_LIST="sda2"

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

case $HOUR  in

  "00" | "01" | "02" | "03" | "04" | "05" | "06" | "07" | "08" | "09" | "10" | "11")
   # do nothing
   ;;
  "12"| "13" | "14" | "15" | "16" | "17" | "18" | "19" | "20" | "21" | "22" | "23")
   # do checks

    . $BOT_START/bot.bash bnl
    psql --command="select * from AEVENTS where COUNTRYCODE='ww'" --quiet --tuples-only >/dev/null
    R=$?
    DAY2_FILE=$(date +"%F")
    DB_ALARM_TODAY_FILE=/tmp/db_alarm_${DAY2_FILE}

    if [ $R != "0" ] ; then
      for RECIPENT in $MAIL_LIST ; do
        if [ ! -r ${DB_ALARM_TODAY_FILE} ] ; then
          echo "db seems to be down, psql does not get access to BNL" | mail --subject="is db up and running on $(hostname) ?" $RECIPENT
          echo "db seems to be down, psql does not get access to BNL" | $BOT_TARGET/bin/aws_mail --subject="is db up and running on $(hostname) ?"
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
  ;;
esac

