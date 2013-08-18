#!/bin/bash


#start simulator


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
  export BOT_NAME=bot_killer
  $BOT_TARGET/bin/bot_send --receiver=$SIM --message=exit
done

