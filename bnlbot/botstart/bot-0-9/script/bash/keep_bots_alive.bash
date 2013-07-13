#!/bin/bash

#exit 0
# should be run from a crontab like
#* * * * * cd / && /home/bnl/bnlbot/botstart/bot-0-9/script/bash/keep_bots_alive.bash
#install with 
#echo "* * * * * cd / && /home/bnl/bnlbot/botstart/bot-0-9/script/bash/keep_bots_alive.bash" | crontab

TZ='Europe/Stockholm'
export TZ

if [ -z $BOT_START ] ; then
  export BOT_START=$HOME/bnlbot/botstart
fi

#Kommer inte funka i multiuser!
if [ -z $BOT_USER ] ; then
  export BOT_USER=bnl
fi

if [ -z $BOT_TARGET ] ; then
  export BOT_TARGET=$BOT_START/bot-0-9/target
fi

if [ -z $BOT_CONFIG ] ; then
  export BOT_CONFIG=$BOT_START/bot-0-9/config
fi

if [ -z $BOT_HOME ] ; then
  export BOT_HOME=$BOT_START/user/$BOT_USER
fi



#try to lock the file $BOT_TARGET/locks/market_fetcher
$BOT_TARGET/bin/check_bot_running --botname=markets_fetcher
RESULT_MARKETS_FETCHER=$?

#if the lock can be aquired, the process is NOT running - start it

##bot  ÄR INTE igång
#bnl@sebjlun-deb:~/bnlbot/botstart/bot-0-9/source/ada$ $BOT_TARGET/bin/check_bot_running --botname=market_fetcher
#bnl@sebjlun-deb:~/bnlbot/botstart/bot-0-9/source/ada$ echo $?
#0

##bot  ÄR igång
#bnl@sebjlun-deb:~/bnlbot/botstart/bot-0-9/source/ada$ $BOT_TARGET/bin/check_bot_running --botname=market_fetcher
#bnl@sebjlun-deb:~/bnlbot/botstart/bot-0-9/source/ada$ echo $?
#1

if [ $RESULT_MARKETS_FETCHER -eq 0 ] ; then
#  echo "start"
  $BOT_TARGET/bin/markets_fetcher --daemon
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
  kill -term $locked_by_pid 
  sleep 1
  kill -kill $locked_by_pid 
  sleep 1
fi

$BOT_TARGET/bin/winners_fetcher --daemon
############ winners_fetcher stop #########