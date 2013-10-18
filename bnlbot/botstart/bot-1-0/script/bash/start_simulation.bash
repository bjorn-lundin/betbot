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

SIMULATORS="horses_win_gb \
            horses_win_us \
            horses_win_ie \
            horses_win_fr \
            horses_win_sg \
            horses_win_za \
            horses_win_xx \
            horses_plc_gb \
            horses_plc_us \
            horses_plc_ie \
            horses_plc_fr \
            horses_plc_sg \
            horses_plc_za \
            horses_plc_xx \
            hounds_win_gb \
            hounds_plc_gb \
            hounds_win_xx \
            hounds_plc_xx"

for SIM in $SIMULATORS ; do
  echo "starting $SIM"
  export BOT_NAME=${SIM} && ${BOT_TARGET}/bin/bot --dispatch=${SIM} --user=${BOT_USER} --mode=simulation --daemon --inifile=${SIM}.ini
#  sleep 1
done

export BOT_NAME=markets_sender
echo "starting $BOT_NAME"

$BOT_TARGET/bin/markets_sender --horses --hounds
#$BOT_TARGET/bin/markets_sender --hounds --marketid=$MARKETID



