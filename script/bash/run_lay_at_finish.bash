#!/bin/bash

BP_LIST="2 3 4 5"
MIN_ODDS_LIST="7 10 15 20 25 30 35"
MAX_ODDS_LIST="25 30 35 40 45 50"

echo "" > result.txt

for bp in $BP_LIST ; do
  for mi in $MIN_ODDS_LIST ; do
    for ma in $MAX_ODDS_LIST ; do
        $BOT_TARGET/bin/lay_at_finish --best_position=$bp --min_odds=$mi --max_odds=$ma >> result.txt 2>&1
    done
  done 
done 
