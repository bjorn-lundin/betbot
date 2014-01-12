#!/bin/bash

#exit 0
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

[ -r /var/lock/bot ] && exit 0

TZ='Europe/Stockholm'
export TZ
export BOT_START=/home/bnl/bnlbot/botstart
#defaults. sets $BOT_SOURCE and $BOT_START
. $BOT_START/bot.bash bnl


#start the login daemon if not running
#pi@raspberrypi ~/bnlbot/botROOT/source/ada $ ps -ef | grep winners_fetcher|  grep -v grep
#pi@raspberrypi ~/bnlbot/botstart/bot-0-9/source/ada $ echo $?
#1
#pi@raspberrypi ~/bnlbot/botstart/bot-0-9/source/ada $ ps -ef | grep winners_fetcher|  grep -v grep
#pi       22629     1 73 23:52 ?        00:00:19 /home/pi/bnlbot/botstart/bot-0-9/target/bin/winners_fetcher --daemon
#pi@raspberrypi ~/bnlbot/botstart/bot-0-9/source/ada $ echo $?
#0

ps -ef | grep login_daemon.py|  grep -v grep >/dev/null
RESULT_LOGIN_DAEMON=$?
if [ $RESULT_LOGIN_DAEMON -eq 1 ] ; then
  echo "Started login_daemon"
  /usr/bin/python $BOT_SOURCE/python/login_daemon.py &
fi

#start the mailer proxy daemon if not running
#pi@raspberrypi ~/bnlbot/botROOT/source/ada $ ps -ef | grep winners_fetcher|  grep -v grep
#pi@raspberrypi ~/bnlbot/botstart/bot-0-9/source/ada $ echo $?
#1
#pi@raspberrypi ~/bnlbot/botstart/bot-0-9/source/ada $ ps -ef | grep winners_fetcher|  grep -v grep
#pi       22629     1 73 23:52 ?        00:00:19 /home/pi/bnlbot/botstart/bot-0-9/target/bin/winners_fetcher --daemon
#pi@raspberrypi ~/bnlbot/botstart/bot-0-9/source/ada $ echo $?
#

#ps -ef | grep mail_proxy.py|  grep -v grep >/dev/null
#RESULT_MAIL_PROXY=$?
#if [ $RESULT_MAIL_PROXY -eq 1 ] ; then
#  echo "Started mail_proxy"
#  /usr/bin/python $BOT_SOURCE/python/mail_proxy.py &
#fi


function Check_Bots_For_User () {

  export BOT_USER=$1
  
  . $BOT_START/bot.bash $BOT_USER 
  
  [ ! -r $BOT_HOME/login.ini ] && return 0
    
  #try to lock the file $BOT_TARGET/locks/market_fetcher
  #$BOT_TARGET/bin/check_bot_running --botname=markets_fetcher >/dev/null 2>&1
  #RESULT_MARKETS_FETCHER=$?
  #if [ $RESULT_MARKETS_FETCHER -eq 0 ] ; then
  #  export BOT_NAME=markets_fetcher
  #  $BOT_TARGET/bin/markets_fetcher --daemon
  #fi
  ps -ef | grep bin/markets_fetcher | grep -v grep | grep user=$BOT_USER >/dev/null
  RESULT_MARKETS_FETCHER=$?
  if [ $RESULT_MARKETS_FETCHER -eq 1 ] ; then
    echo "Started markets_fetcher $BOT_USER"
    export BOT_NAME=markets_fetcher
    $BOT_TARGET/bin/markets_fetcher --daemon --user=$BOT_USER
  fi
  
  #if the lock can be aquired, the process is NOT running - start it
  
  ##bot  is not running
  #bnl@sebjlun-deb:~/bnlbot/botstart/bot-0-9/source/ada$ $BOT_TARGET/bin/check_bot_running --botname=market_fetcher
  #bnl@sebjlun-deb:~/bnlbot/botstart/bot-0-9/source/ada$ echo $?
  #0
  
  ##bot  is running
  #bnl@sebjlun-deb:~/bnlbot/botstart/bot-0-9/source/ada$ $BOT_TARGET/bin/check_bot_running --botname=market_fetcher
  #bnl@sebjlun-deb:~/bnlbot/botstart/bot-0-9/source/ada$ echo $?
  #1
  
  ########## bot ############
  
  
  case $BOT_MACHINE_ROLE in 
    PROD) BOT_LIST="bot" ;;
    TEST) BOT_LIST="bot" ;;
    SIM)  BOT_LIST="horses_plc_gb horses_win_gb hounds_plc_gb hounds_win_gb" ;;
    *)    BOT_LIST="" ;;
  esac
  
  for bot in $BOT_LIST ; do
    if [[ $bot != "bot" ]] ; then
      ps -ef | grep bin/bot | grep "user=$BOT_USER" | grep "inifile=$bot" | grep -v grep >/dev/null
    else
      ps -ef | grep bin/bot | grep "user=$BOT_USER" | grep "inifile=betfair.ini" | grep -v grep >/dev/null
    fi
    
    RESULT_BOT=$?
    if [ $RESULT_BOT -eq 1 ] ; then
      echo "Started $bot $BOT_USER - bot_home=$BOT_HOME -- bot=$bot"
      export BOT_NAME=$bot
      if [[ $bot != "bot" ]] ; then
        $BOT_TARGET/bin/bot --daemon --user=$BOT_USER --mode=$BOT_MODE --inifile=$bot.ini
      else
        $BOT_TARGET/bin/bot --daemon --user=$BOT_USER --mode=$BOT_MODE --inifile=betfair.ini
      fi      
    fi
  done 
  
  ps -ef | grep bin/saldo_fetcher | grep user=$BOT_USER | grep -v grep >/dev/null
  RESULT_SALDO_FETCHER=$?
  if [ $RESULT_SALDO_FETCHER -eq 1 ] ; then
    echo "Started saldo_fetcher $BOT_USER"
    export BOT_NAME=saldo_fetcher
    $BOT_TARGET/bin/saldo_fetcher --daemon --user=$BOT_USER
  fi
  
  ps -ef | grep bin/winners_fetcher_json | grep user=$BOT_USER | grep -v grep >/dev/null
  RESULT_WJ_FETCHER=$?
  if [ $RESULT_WJ_FETCHER -eq 1 ] ; then
    echo "Started winners_fetcher_json $BOT_USER"
    export BOT_NAME=w_fetch_json
    $BOT_TARGET/bin/winners_fetcher_json --daemon --user=$BOT_USER
  fi
  
  #zip logfiles every hour, on minute 17 in the background
  MINUTE=$(date +"%M")
  
  if [[ $MINUTE == "17" ]] ; then
    tclsh $BOT_SCRIPT/tcl/move_or_zip_old_logfiles.tcl $BOT_USER & 
  fi 

}

USER_LIST=$(ls $BOT_START/user)


case $BOT_MACHINE_ROLE in 
  PROD) USER_LIST="bnl jmb" ;;
     *) USER_LIST="bnl"     ;;
esac  

  
for USER in $USER_LIST ; do
#  echo "start $USER"
  Check_Bots_For_User $USER
#  echo "stop $USER"
done
 
case $BOT_MACHINE_ROLE in 
  PROD)
    HOUR=$(date +"%H")
    MINUTE=$(date +"%M")  
    if [[ $HOUR == "02" ]] ; then
      if [[ $MINUTE == "05" ]] ; then
        WEEK_DAY=$(date +"%u")
        pg_dump jmb  | gzip > /home/bnl/datadump/jmb_${WEEK_DAY}.dmp.gz &
        sleep 30
        pg_dump bnls | gzip > /home/bnl/datadump/bnls_${WEEK_DAY}.dmp.gz &
      fi
    fi
  ;;  
    
esac


