#!/bin/bash
#start simulator
while getopts "m:" opt; do
#  echo "$opt - $OPTARG"

  case $opt in
    m)  MARKETID=$OPTARG ;;
    *)
      echo "$0 -m marketid" >&2
      echo "   marketid > than given are treated" >&2
      exit 1
      ;;
  esac
done

SIMULATORS="horse_win_gb \
            horse_win_us \
            horse_win_ie \
            horse_win_fr \
            horse_win_sg \
            horse_win_za \
            horse_win_xx \
            horse_plc_gb \
            horse_plc_us \
            horse_plc_ie \
            horse_plc_fr \
            horse_plc_sg \
            horse_plc_za \
            horse_plc_xx \
            hound_win_xx \
            hound_plc_xx"

for SIM in $SIMULATORS ; do
  echo "starting $SIM"
  export BOT_NAME=$SIM && $BOT_TARGET/bin/bot --dispatch=$SIM --user=$BOT_USER --mode=simulation --daemon
#  sleep 1
done

export BOT_NAME=markets_sender
echo "starting $BOT_NAME"

#$BOT_TARGET/bin/markets_sender --marketid=$MARKETID --horses --hounds
$BOT_TARGET/bin/markets_sender --hounds --marketid=$MARKETID



