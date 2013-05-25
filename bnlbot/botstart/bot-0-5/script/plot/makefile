#make plots

GRAPH_TYPE := one_hundred_and_four_weeks
STOP_DATE := 2013-05-31
SIZE := 30
SALDO := 10000
DB_NAME := betting
BET_TYPE := winner
TARGET_DAT_HORSE_BACK_WINNER := horse_back_winner.dat
TARGET_DAT_HOUND_BACK_WINNER := hound_back_winner.dat
TARGET_DAT_HORSE_LAY_WINNER := horse_lay_winner.dat
TARGET_DAT_HOUND_LAY_WINNER := hound_lay_winner.dat
TARGET_PNG := hitratio.png
TARGET_BACK_PNG := hitratio_back.png
TARGET_LAY_PNG := hitratio_lay.png

#horses_back:
#	$(BOT_TARGET)/bin/simulator6 --bet_name=winner --saldo=10000 \
#                            --stop_date=$(STOP_DATE) --graph_type=$(GRAPH_TYPE) --size=30 \
#                            --animal=horse --quiet --bet_type=back --price=3 \
#                            --delta=1.0 --db_name=bfhistory > $(TARGET_DAT_HORSE_BACK)
#	gnuplot -e "graph_type='$(GRAPH_TYPE)'"



$(TARGET_PNG) : hitratio.gpl \
              $(TARGET_DAT_HORSE_BACK_WINNER) \
              $(TARGET_DAT_HOUND_BACK_WINNER) \
              $(TARGET_DAT_HORSE_LAY_WINNER) \
              $(TARGET_DAT_HOUND_LAY_WINNER)
	gnuplot -e "graph_type='$(GRAPH_TYPE)'" \
                -e "stop_date='$(STOP_DATE)'" \
                -e "db_name='$(DB_NAME)'" \
                -e "target_png='$(TARGET_PNG)'" \
                -e "horse_lay_winner='$(TARGET_DAT_HORSE_LAY_WINNER)'" \
                -e "hound_lay_winner='$(TARGET_DAT_HOUND_LAY_WINNER)'" \
                -e "horse_back_winner='$(TARGET_DAT_HORSE_BACK_WINNER)'" \
                -e "hound_back_winner='$(TARGET_DAT_HOUND_BACK_WINNER)'" hitratio.gpl
	display $(TARGET_PNG)

$(TARGET_LAY_PNG) : hitratio_lay.gpl \
              $(TARGET_DAT_HORSE_LAY_WINNER) \
              $(TARGET_DAT_HOUND_LAY_WINNER)
	gnuplot -e "graph_type='$(GRAPH_TYPE)'" \
                -e "stop_date='$(STOP_DATE)'" \
                -e "db_name='$(DB_NAME)'" \
                -e "target_png='$(TARGET_LAY_PNG)'" \
                -e "horse_lay_winner='$(TARGET_DAT_HORSE_LAY_WINNER)'" \
                -e "hound_lay_winner='$(TARGET_DAT_HOUND_LAY_WINNER)'" hitratio_lay.gpl
	display $(TARGET_LAY_PNG)


$(TARGET_BACK_PNG) : hitratio_back.gpl \
              $(TARGET_DAT_HORSE_BACK_WINNER) \
              $(TARGET_DAT_HOUND_BACK_WINNER)
	gnuplot -e "graph_type='$(GRAPH_TYPE)'" \
                -e "stop_date='$(STOP_DATE)'" \
                -e "db_name='$(DB_NAME)'" \
                -e "target_png='$(TARGET_BACK_PNG)'" \
                -e "horse_back_winner='$(TARGET_DAT_HORSE_BACK_WINNER)'" \
                -e "hound_back_winner='$(TARGET_DAT_HOUND_BACK_WINNER)'" hitratio_back.gpl
	display $(TARGET_BACK_PNG)

$(TARGET_DAT_HORSE_BACK_WINNER) : $(BOT_TARGET)/bin/simulator6
	$(BOT_TARGET)/bin/simulator6 --animal=horse \
                                     --bet_name=winner \
                                     --graph_type=$(GRAPH_TYPE) \
                                     --size=$(SIZE) \
                                     --saldo=$(SALDO) \
                                     --price=1 \
                                     --delta=1 \
                                     --favorite_by=0 \
                                     --stop_date=$(STOP_DATE) \
                                     --db_name=$(DB_NAME) \
                                     --bet_type=back \
                                     --quiet > $(TARGET_DAT_HORSE_BACK_WINNER)


$(TARGET_DAT_HORSE_LAY_WINNER) : $(BOT_TARGET)/bin/simulator6
	$(BOT_TARGET)/bin/simulator6 --animal=horse \
                                     --bet_name=winner \
                                     --graph_type=$(GRAPH_TYPE) \
                                     --size=$(SIZE) \
                                     --saldo=$(SALDO) \
                                     --price=1 \
                                     --delta=1 \
                                     --favorite_by=0 \
                                     --stop_date=$(STOP_DATE) \
                                     --db_name=$(DB_NAME) \
                                     --bet_type=lay \
                                     --quiet > $(TARGET_DAT_HORSE_LAY_WINNER)


$(TARGET_DAT_HOUND_BACK_WINNER) : $(BOT_TARGET)/bin/simulator6
	$(BOT_TARGET)/bin/simulator6 --animal=hound \
                                     --bet_name=winner \
                                     --graph_type=$(GRAPH_TYPE) \
                                     --size=$(SIZE) \
                                     --saldo=$(SALDO) \
                                     --price=1 \
                                     --delta=1 \
                                     --favorite_by=0 \
                                     --stop_date=$(STOP_DATE) \
                                     --db_name=$(DB_NAME) \
                                     --bet_type=back \
                                     --quiet > $(TARGET_DAT_HOUND_BACK_WINNER)


$(TARGET_DAT_HOUND_LAY_WINNER) : $(BOT_TARGET)/bin/simulator6
	$(BOT_TARGET)/bin/simulator6 --animal=hound \
                                     --bet_name=winner \
                                     --graph_type=$(GRAPH_TYPE) \
                                     --size=$(SIZE) \
                                     --saldo=$(SALDO) \
                                     --price=1 \
                                     --delta=1 \
                                     --favorite_by=0 \
                                     --stop_date=$(STOP_DATE) \
                                     --db_name=$(DB_NAME) \
                                     --bet_type=lay \
                                     --quiet > $(TARGET_DAT_HOUND_LAY_WINNER)

.PHONY : show
show:
	display $(TARGET_PNG)


.PHONY : clean
clean :
	rm $(TARGET_PNG) \
           $(TARGET_DAT_HORSE_BACK_WINNER) \
           $(TARGET_DAT_HOUND_BACK_WINNER) \
           $(TARGET_DAT_HORSE_LAY_WINNER) \
           $(TARGET_DAT_HOUND_LAY_WINNER)