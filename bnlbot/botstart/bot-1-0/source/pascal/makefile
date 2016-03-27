
OPTS := -MObjFPC -g 
todays_profit : todays_profit.lpr
	fpc $(OPTS) todays_profit.lpr

test_float : test_float.lpr
	fpc $(OPTS) test_float.lpr

.PHONY :clean
clean :
	rm -f todays_profit test_float *.o *.ppu