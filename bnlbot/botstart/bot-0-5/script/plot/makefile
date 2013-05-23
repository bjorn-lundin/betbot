#make plots

GRAPH_TYPE := one_hundred_and_four_weeks
STOP_DATE := 2013-05-31
TARGET_DAT_HORSE_BACK := horses_back.dat
TARGET_DAT_HOUND_BACK := hounds_back.dat

horses_back:
	$(BOT_TARGET)/bin/simulator3 --bet_name=winner --saldo=10000 \
                            --stop_date=$(STOP_DATE) --graph_type=$(GRAPH_TYPE) --size=30 \
                            --animal=horse --quiet --bet_type=back --price=3 --delta=1.0 --db_name=bfhistory
	cat $(TARGET_DAT_HORSE_BACK) |awk '{print $6, $7, $8, $3, $4, $5}' > back_horse.dat
	sort -n < back_horse.dat > back_horse_sorted.dat
	cat back_horse_sorted.dat | uniq > back_horse_sorted_uniq.dat
	gnuplot -e "graph_type='$(GRAPH_TYPE)'" \


hounds_back:
	cd $(BOT_START)/.. && $(BOT_TARGET)/bin/simulator3 --bet_name=winner --saldo=10000 \
                            --stop_date=$(STOP_DATE) --graph_type=$(GRAPH_TYPE) --size=30 \
                            --animal=hound --quiet --bet_type=back --price=3.0 --delta=1.0 --db_name=bfhistory
	cd $(BOT_START)/../sims && cat $(TARGET_DAT_HORSE_BACK) |awk '{print $6, $7, $8, $3, $4, $5}' > back_horse.dat
	cd $(BOT_START)/../sims && sort -n < back_horse.dat > back_horse_sorted.dat
	cd $(BOT_START)/../sims && cat back_horse_sorted.dat | uniq > back_horse_sorted_uniq.dat
	gnuplot -e "graph_type='$(GRAPH_TYPE)'" \
                -e "start_date='$(START_DATE)'" \
                -e "datafile='$(TARGET_DAT_HORSE_BACK)'" back_horse.gpl



2.7 +/- 03 = -10758
3.0 +/- 1.0



$BOT_TARGET/bin/simulator4 --bet_name=winner --saldo=10000 \
--stop_date=2013-05-31 --graph_type=one_hundred_and_four_weeks --size=30 \
--animal=horse --quiet --bet_type=back  --db_name=bfhistory