#!/bin/bash


#start simulator


SIMULATORS="horse_win_gb \
            horse_win_us \
            horse_win_ie \
            horse_win_fr \
            horse_win_sg \
            horse_win_za \
            horse_win_xx \
            horse_plc_xx \
            hound_win_xx \
            hound_plc_xx"
            
            
for SIM in $SIMULATORS ; do

  export BOT_NAME=$SIM
  echo "starting $BOT_NAME"
  $BOT_TARGET/bin/bot --user=$BOT_USER --mode=simulation --daemon
  sleep 1 
done

export BOT_NAME=markets_sender
echo "starting $BOT_NAME"

$BOT_TARGET/bin/markets_sender



