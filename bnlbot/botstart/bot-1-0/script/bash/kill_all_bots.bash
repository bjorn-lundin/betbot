#!/bin/bash

LIST=$(ps -ef | grep /bnlbot/botstart/bot-1-0/target/bin | awk  '{print $2}')

#echo "$0 japp" > /bnlbot/botstart/bot-1-0/bevis.txt
touch /var/lock/bot

for pid in $LIST ; do
  kill -term $pid
done

sleep 1

for pid in $LIST ; do
  kill -kill $pid
done



