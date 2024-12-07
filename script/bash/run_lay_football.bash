#!/bin/bash

HALF_TIME_SCORE_LOG=$BOT_SCRIPT/plot/lay_football/half_time_score
CORRECT_SCORE_LOG=$BOT_SCRIPT/plot/lay_football/correct_score

#MARKET_TYPE_LIST="HALF_TIME_SCORE CORRECT_SCORE"
MAX_ODDS_MATCH_LIST="2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 \
               3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 \
               4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 \
               5.0 5.1 5.2 5.3 5.4 5.5 5.6 5.7 5.8 5.9 \
               6.0 6.1 6.2 6.3 6.4 6.5 6.6 6.7 6.8 6.9 \
               7.0 7.1 7.2 7.3 7.4 7.5 7.6 7.7 7.8 7.9"

MAX_ODDS_SCORE_LIST="4 5 6  7  8  9 10 11 12 13 14 15 \
                  16 17 18 19 20 21 22 23 24 25 \
                  26 27 28 29 30 31 32 33 34 35"


CC_LIST="XX BR GB ES IT FR MX NL IL PT DE TR BE IS CO CL GR QA SA RU AE EE IN EG EC PA MY AR \
BH LV ZA CR FI DZ UY CH JM BO MT AG AZ VE AW PS HK IR VN US ID TT SG HN OM HR PE MA KW NO PY TJ YY"
                  
CC_LIST="XX BR GB ES IT FR MX NL IL PT DE TR BE YY"
               

function Check_For_Max_Processes {
  #check every 10 secs if enought proces are running,
  #else break loop, and let for loop start one more process
  while :
  do 
    NUM_PROCESSES=$(ps -ef | grep -v grep| grep -c bin/lay_football)
    echo "num running $NUM_PROCESSES for $1"
    if  [ $NUM_PROCESSES -le 12 ] ; then
      echo "breaking for $1"
      break
    else
      echo "sleep 10 for $1"
      sleep 10    
    fi
  done
}

               
rm -f *.dat

for COUNTRY_CODE in $CC_LIST ; do
#  for MAX_ODDS_MATCH in $MAX_ODDS_MATCH_LIST ; do
#    for MAX_ODDS_SCORE in $MAX_ODDS_SCORE_LIST ; do
      LOG_FILE=$HALF_TIME_SCORE_LOG\_$COUNTRY_CODE.dat
      echo "start HALF_TIME_SCORE $COUNTRY_CODE $MAX_ODDS_SCORE $MAX_ODDS_MATCH $LOG_FILE"
      $BOT_TARGET/bin/lay_football --market_type=HALF_TIME_SCORE \
                                   --country_code=$COUNTRY_CODE \
                                   --min_odds_score=4 \
                                   --max_odds_score=35 \
                                   --min_odds_match=2 \
                                   --max_odds_match=7.9 >> $LOG_FILE
#      Check_For_Max_Processes "HALF_TIME_SCORE"
#    done
    #get a blank line between sets
#    echo "" >> $LOG_FILE
#  done
  
#  for MAX_ODDS_MATCH in $MAX_ODDS_MATCH_LIST ; do
#    for MAX_ODDS_SCORE in $MAX_ODDS_SCORE_LIST ; do
      LOG_FILE=$CORRECT_SCORE_LOG\_$COUNTRY_CODE.dat
      echo "start CORRECT_SCORE $COUNTRY_CODE $MAX_ODDS_SCORE $MAX_ODDS_MATCH $LOG_FILE"
      $BOT_TARGET/bin/lay_football --market_type=CORRECT_SCORE \
                                   --country_code=$COUNTRY_CODE \
                                   --min_odds_score=4 \
                                   --max_odds_score=35 \
                                   --min_odds_match=2 \
                                   --max_odds_match=7.9 >> $LOG_FILE
#      Check_For_Max_Processes "CORRECT_SCORE"
#    done
    #get a blank line between sets
#    echo "" >> $LOG_FILE
#  done
done

