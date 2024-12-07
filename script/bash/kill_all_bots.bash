#!/bin/bash

LIST=$(ps -ef | grep botstart/bot-1-0/target/bin | grep -v grep | awk  '{print $2}')

echo "$0 japp $(date)" > /tmp/kill_all_bots.txt
touch /var/lock/bot

for pid in $LIST ; do
  kill -term $pid
done

sleep 1

LIST=$(ps -ef | grep botstart/bot-1-0/target/bin | grep -v grep | awk  '{print $2}')

for pid in $LIST ; do
  kill -kill $pid
done



