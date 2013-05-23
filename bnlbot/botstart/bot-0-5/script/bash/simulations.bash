#!/bin/bash

ODDS_DIFF_LIST="0 1 2 3 4 5"

for fav in $ODDS_DIFF_LIST ; do
  echo "$fav"
  $BOT_TARGET/bin/simulator4 --bet_name=winner --saldo=10000 --stop_date=2013-03-31 \
  --graph_type=one_hundred_and_four_weeks --size=30 --animal=horse \
  --quiet --bet_type=back  --db_name=bfhistory --favorite_by=$fav --winners_only
done


#fav=1 ger bäst resultat



  $BOT_TARGET/bin/simulator5 --bet_name=place --saldo=10000 --stop_date=2013-03-31 \
  --graph_type=one_hundred_and_four_weeks --size=30 --animal=horse \
  --quiet --bet_type=back  --db_name=bfhistory --favorite_by=1 --winners_only --price=2 --delta=0.9
