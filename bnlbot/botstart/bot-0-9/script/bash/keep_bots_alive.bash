#!/bin/bash

#exit 0
# should be run from a crontab like
#* * * * * cd / && /home/bnl/bnlbot/botstart/bot-0-9/script/bash/keep_bots_alive.bash
#install with
#echo "* * * * * cd / && /home/bnl/bnlbot/botstart/bot-0-9/script/bash/keep_bots_alive.bash" | crontab

#if we should NOT start it, check here. 
#if /var/lock/bot is exists, then exit. created/removed from /etc/init.d/bot

[ -r /var/lock/bot ] && exit 0

TZ='Europe/Stockholm'
export TZ

export BOT_START=$HOME/bnlbot/botstart

#Kommer inte funka i multiuser!
export BOT_USER=bnl

export BOT_START=$HOME/bnlbot/botstart
. $BOT_START/bot.bash -u$BOT_USER -a no

#env | sort


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
  /usr/bin/python $BOT_SOURCE/python/login_daemon.py &
fi

#start the mailer proxy daemon if not running
#pi@raspberrypi ~/bnlbot/botROOT/source/ada $ ps -ef | grep winners_fetcher|  grep -v grep
#pi@raspberrypi ~/bnlbot/botstart/bot-0-9/source/ada $ echo $?
#1
#pi@raspberrypi ~/bnlbot/botstart/bot-0-9/source/ada $ ps -ef | grep winners_fetcher|  grep -v grep
#pi       22629     1 73 23:52 ?        00:00:19 /home/pi/bnlbot/botstart/bot-0-9/target/bin/winners_fetcher --daemon
#pi@raspberrypi ~/bnlbot/botstart/bot-0-9/source/ada $ echo $?
#0

ps -ef | grep mail_proxy.py|  grep -v grep >/dev/null
RESULT_MAIL_PROXY=$?
if [ $RESULT_MAIL_PROXY -eq 1 ] ; then
  /usr/bin/python $BOT_SOURCE/python/mail_proxy.py &
fi


#try to lock the file $BOT_TARGET/locks/market_fetcher
$BOT_TARGET/bin/check_bot_running --botname=markets_fetcher >/dev/null 2>&1
RESULT_MARKETS_FETCHER=$?

#if the lock can be aquired, the process is NOT running - start it

##bot  is not running
#bnl@sebjlun-deb:~/bnlbot/botstart/bot-0-9/source/ada$ $BOT_TARGET/bin/check_bot_running --botname=market_fetcher
#bnl@sebjlun-deb:~/bnlbot/botstart/bot-0-9/source/ada$ echo $?
#0

##bot  is running
#bnl@sebjlun-deb:~/bnlbot/botstart/bot-0-9/source/ada$ $BOT_TARGET/bin/check_bot_running --botname=market_fetcher
#bnl@sebjlun-deb:~/bnlbot/botstart/bot-0-9/source/ada$ echo $?
#1

if [ $RESULT_MARKETS_FETCHER -eq 0 ] ; then
  export BOT_NAME=markets_fetcher
  $BOT_TARGET/bin/markets_fetcher --daemon
fi

########### bot_checker ############
$BOT_TARGET/bin/check_bot_running --botname=bot_checker > /dev/null 2>&1
RESULT_BOT_CHECKER=$?
if [ $RESULT_BOT_CHECKER -eq 0 ] ; then
  export BOT_NAME=bet_checker
  $BOT_TARGET/bin/bet_checker --daemon
fi

########### bot ############
$BOT_TARGET/bin/check_bot_running --botname=bot > /dev/null 2>&1
RESULT_BOT=$?
if [ $RESULT_BOT -eq 0 ] ; then
  export BOT_NAME=bot
  $BOT_TARGET/bin/bot --user=$BOT_USER --daemon
fi


########### saldo_fetcher ############
$BOT_TARGET/bin/check_bot_running --botname=saldo_fetcher > /dev/null 2>&1
RESULT_SALDO_FETCHER=$?
if [ $RESULT_SALDO_FETCHER -eq 0 ] ; then
  export BOT_NAME=saldo_fetcher
  $BOT_TARGET/bin/saldo_fetcher --daemon
fi

######## winners_fetcher ###########

#who holds the lock, and since when, and when expires
locked_by_pid=$(cat $BOT_TARGET/locks/winners_fetcher | cut -d'|' -f1)
lock_placed=$(cat $BOT_TARGET/locks/winners_fetcher | cut -d'|' -f2)
lock_expires=$(cat $BOT_TARGET/locks/winners_fetcher | cut -d'|' -f3)

now=$(date "+ %F %T")

#convert to epoch, compare integers is easy
epoch_now=$(date --date="$now" +%s)
epoch_lock_expires=$(date --date="$lock_expires" +%s)

# kill if lock is more than 10 minutes old (time is in lockfile)
if [ $epoch_now -gt $epoch_lock_expires ] ; then
  kill -term $locked_by_pid >/dev/null 2>&1
  sleep 1
  kill -kill $locked_by_pid >/dev/null 2>&1
  sleep 1
fi

export BOT_NAME=winners_fetcher
$BOT_TARGET/bin/winners_fetcher --daemon
############ winners_fetcher stop #########
