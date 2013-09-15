#!/bin/bash


#start simulator


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
  export BOT_NAME=bot_killer
  $BOT_TARGET/bin/bot_send --receiver=$SIM --message=exit
done

