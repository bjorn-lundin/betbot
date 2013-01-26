#!/bin/bash

DAT_FILES=$(ls *.dat)

for DAT_FILE in $DAT_FILES ; do 
#   echo $DAT_FILE
   echo $DAT_FILE |grep -i lay
   is_lay=$?
   TYP=$(echo $DAT_FILE | cut -d'-' -f1)
   START_DATE=$(echo $DAT_FILE | cut -d'-' -f2)
   TMP_STOP_DATE=$(echo $DAT_FILE | cut -d'-' -f3)
   STOP_DATE=$(echo $TMP_STOP_DATE | cut -d'.' -f1)
   typ=$(echo $TYP | tr '[A-Z]' '[a-z]')
#      echo $typ
   gnuplot \
     -e "typ='$typ'" \
     -e "start_date='$START_DATE'" \
     -e "stop_date='$STOP_DATE'" \
     -e "is_lay=$is_lay" \
     plot_bets.gpl
done

