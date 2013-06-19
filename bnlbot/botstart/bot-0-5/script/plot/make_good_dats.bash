#!/bin/bash
#rm lay_bet_hound_place_loop.dat && make lay_bet_hound_place_loop.dat
#rm lay_favorite_bet_horse_place_loop.dat && make lay_favorite_bet_horse_place_loop.dat
#rm -f lay_bet_horse_place_loop.dat && make lay_bet_horse_place_loop.dat

#max  min favby maxloss max profit
#25 |   8 |  2 |    0 |  0 |  101219


LOSS_LIST="0 -600"
FAV_BY_LIST="0 1 2 3"
MIN_ODDS_LIST="8 12 18"
DB_NAME_LIST="betting bfhistory"

for DB_NAME in $DB_NAME_LIST ; do
    echo "dbname $DB_NAME $(date)"
    for MIN_ODDS in $MIN_ODDS_LIST  ; do
        echo "min odds $MIN_ODDS $(date)"
        for LOSS in $LOSS_LIST ; do
            echo "loss $LOSS $(date)"
            for FAV_BY in $FAV_BY_LIST ; do
                echo "fav by $FAV_BY $(date)"
                $BOT_TARGET/bin/sim_equity --db_name=$DB_NAME \
                                           --animal=horse \
                                           --bet_type=lay \
                                           --bet_name=place \
                                           --max_profit_factor=0 \
                                           --max_daily_loss=$LOSS \
                                           --start_date=2006-01-01 \
                                           --stop_date=2013-12-31 \
                                           --size=30 \
                                           --price=$MIN_ODDS \
                                           --delta=25 \
                                           --saldo=10000 \
                                           --favorite_by=$FAV_BY \
                                           --quiet > equity_lay_bet_horse_place_${MIN_ODDS}_25_0_${LOSS}_${FAV_BY}_${DB_NAME}.dat
            done
        done
    done
done






#25 |   8 |  2 | -600 |  0 |  101219
#25 |   8 |  3 |    0 |  0 |  101219
#25 |   8 |  3 | -600 |  0 |  101219
#
#25 |   8 |  0 |    0 |  0 |  101247
#25 |   8 |  0 | -600 |  0 |  101247
#25 |   8 |  1 |    0 |  0 |  101247
#25 |   8 |  1 | -600 |  0 |  101247
#
#25 |  18 |  0 |    0 |  0 |  102019
#25 |  18 |  0 | -600 |  0 |  102019
#25 |  18 |  1 |    0 |  0 |  102019
#25 |  18 |  1 | -600 |  0 |  102019
#25 |  18 |  2 |    0 |  0 |  102019
#25 |  18 |  2 | -600 |  0 |  102019
#25 |  18 |  3 |    0 |  0 |  102019
#25 |  18 |  3 | -600 |  0 |  102019
#
#25 |  12 |  2 |    0 |  0 |  102070
#25 |  12 |  2 | -600 |  0 |  102070
#25 |  12 |  3 |    0 |  0 |  102070
#25 |  12 |  3 | -600 |  0 |  102070
#
#25 |  12 |  0 |    0 |  0 |  102098
#25 |  12 |  0 | -600 |  0 |  102098
#25 |  12 |  1 |    0 |  0 |  102098
#25 |  12 |  1 | -600 |  0 |  102098
