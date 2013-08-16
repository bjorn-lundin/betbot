###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################

UNAME := $(shell uname)

TP := tclsh $(BOT_SCRIPT)/tcl/make_table_package.tcl
ST := $(BOT_SOURCE)/ada/global/tables

OBJECT_DIR_JSON := $(BOT_TARGET)/objects/json
OBJECT_DIR_BOT  := $(BOT_TARGET)/objects/bot
EXE_DIR_BOT     := $(BOT_TARGET)/bin
PIPE_DIR_BOT    := $(BOT_TARGET)/pipes
LOCK_DIR_BOT    := $(BOT_TARGET)/locks
LOG_DIR_BOT     := $(BOT_TARGET)/log


.PHONY : json_test adabot tables

all: tables adabot 
#/etc/logrotate.d/bnlbot


tables : $(ST)/table_history.ads  $(ST)/table_history2.ads \
         $(ST)/table_aevents.ads  $(ST)/table_amarkets.ads \
         $(ST)/table_arunners.ads $(ST)/table_aprices.ads \
         $(ST)/table_awinners.ads $(ST)/table_abets.ads \
         $(ST)/table_anonrunners.ads $(ST)/table_abalances.ads \
         $(ST)/table_drymarkets.ads $(ST)/table_dryrunners.ads \
         $(ST)/table_dryresults.ads  $(ST)/table_abethistory.ads \
         
$(EXE_DIR_BOT) :
	mkdir -p $(EXE_DIR_BOT)

$(PIPE_DIR_BOT) :
	mkdir -p $(PIPE_DIR_BOT)

$(LOCK_DIR_BOT) :
	mkdir -p $(LOCK_DIR_BOT)
    
$(LOG_DIR_BOT) :
	mkdir -p $(LOG_DIR_BOT)

$(OBJECT_DIR_BOT) :
	mkdir -p $(OBJECT_DIR_BOT)

$(OBJECT_DIR_JSON) :
	mkdir -p $(OBJECT_DIR_JSON)

#json_test : $(OBJECT_DIR_JSON) $(EXE_DIR_BOT) $(EXE_DIR_BOT)/test.json 
#	gnatmake -P json_test

adabot : $(OBJECT_DIR_BOT) $(EXE_DIR_BOT) $(PIPE_DIR_BOT) $(LOCK_DIR_BOT) $(LOG_DIR_BOT)
	gnatmake -P adabot

#$(EXE_DIR_BOT)/test.json :
#	cp  $(BOT_SOURCE)/ada/local/json/test.json $(EXE_DIR_BOT)/
    
$(ST)/table_history.ads : $(BOT_CONFIG)/repository/tables/table_history.xml
	$(TP) -t history > $(ST)/table_history.ada
	cd $(ST) && gnatchop -w -gnat05 table_history.ada
	cd $(ST) && rm table_history.ada
	$(TP) -p history > $(ST)/history.sql

$(ST)/table_history2.ads : $(BOT_CONFIG)/repository/tables/table_history2.xml
	$(TP) -t history2 > $(ST)/table_history2.ada
	cd $(ST) && gnatchop -w -gnat05 table_history2.ada
	cd $(ST) && rm table_history2.ada
	$(TP) -p history2 > $(ST)/history2.sql

$(ST)/table_amarkets.ads : $(BOT_CONFIG)/repository/tables/table_amarkets.xml
	$(TP) -t amarkets > $(ST)/table_amarkets.ada
	cd $(ST) && gnatchop -w -gnat05 table_amarkets.ada
	cd $(ST) && rm table_amarkets.ada
	$(TP) -p amarkets > $(ST)/amarkets.sql

$(ST)/table_aevents.ads : $(BOT_CONFIG)/repository/tables/table_aevents.xml
	$(TP) -t aevents > $(ST)/table_aevents.ada
	cd $(ST) && gnatchop -w -gnat05 table_aevents.ada
	cd $(ST) && rm table_aevents.ada
	$(TP) -p aevents > $(ST)/aevents.sql

$(ST)/table_arunners.ads : $(BOT_CONFIG)/repository/tables/table_arunners.xml
	$(TP) -t arunners > $(ST)/table_arunners.ada
	cd $(ST) && gnatchop -w -gnat05 table_arunners.ada
	cd $(ST) && rm table_arunners.ada
	$(TP) -p arunners > $(ST)/arunners.sql

$(ST)/table_aprices.ads : $(BOT_CONFIG)/repository/tables/table_aprices.xml
	$(TP) -t aprices > $(ST)/table_aprices.ada
	cd $(ST) && gnatchop -w -gnat05 table_aprices.ada
	cd $(ST) && rm table_aprices.ada
	$(TP) -p aprices > $(ST)/aprices.sql

    
$(ST)/table_awinners.ads : $(BOT_CONFIG)/repository/tables/table_awinners.xml
	$(TP) -t awinners > $(ST)/table_awinners.ada
	cd $(ST) && gnatchop -w -gnat05 table_awinners.ada
	cd $(ST) && rm table_awinners.ada
	$(TP) -p awinners > $(ST)/awinners.sql

#$(ST)/table_animals.ads : $(BOT_CONFIG)/repository/tables/table_animals.xml
#	$(TP) -t animals > $(ST)/table_animals.ada
#	cd $(ST) && gnatchop -w -gnat05 table_animals.ada
#	cd $(ST) && rm table_animals.ada
#	$(TP) -p animals > $(ST)/animals.sql

$(ST)/table_abets.ads : $(BOT_CONFIG)/repository/tables/table_abets.xml
	$(TP) -t abets > $(ST)/table_abets.ada
	cd $(ST) && gnatchop -w -gnat05 table_abets.ada
	cd $(ST) && rm table_abets.ada
	$(TP) -p abets > $(ST)/abets.sql
    
$(ST)/table_anonrunners.ads : $(BOT_CONFIG)/repository/tables/table_anonrunners.xml
	$(TP) -t anonrunners > $(ST)/table_anonrunners.ada
	cd $(ST) && gnatchop -w -gnat05 table_anonrunners.ada
	cd $(ST) && rm table_anonrunners.ada
	$(TP) -p anonrunners > $(ST)/anonrunners.sql

$(ST)/table_abalances.ads : $(BOT_CONFIG)/repository/tables/table_abalances.xml
	$(TP) -t abalances > $(ST)/table_abalances.ada
	cd $(ST) && gnatchop -w -gnat05 table_abalances.ada
	cd $(ST) && rm table_abalances.ada
	$(TP) -p abalances > $(ST)/abalances.sql

$(ST)/table_drymarkets.ads : $(BOT_CONFIG)/repository/tables/table_drymarkets.xml
	$(TP) -t drymarkets > $(ST)/table_drymarkets.ada
	cd $(ST) && gnatchop -w -gnat05 table_drymarkets.ada
	cd $(ST) && rm table_drymarkets.ada
	$(TP) -p drymarkets > $(ST)/drymarkets.sql

$(ST)/table_dryrunners.ads : $(BOT_CONFIG)/repository/tables/table_dryrunners.xml
	$(TP) -t dryrunners > $(ST)/table_dryrunners.ada
	cd $(ST) && gnatchop -w -gnat05 table_dryrunners.ada
	cd $(ST) && rm table_dryrunners.ada
	$(TP) -p dryrunners > $(ST)/dryrunners.sql

$(ST)/table_dryresults.ads : $(BOT_CONFIG)/repository/tables/table_dryresults.xml
	$(TP) -t dryresults > $(ST)/table_dryresults.ada
	cd $(ST) && gnatchop -w -gnat05 table_dryresults.ada
	cd $(ST) && rm table_dryresults.ada
	$(TP) -p dryresults > $(ST)/dryresults.sql

$(ST)/table_abethistory.ads : $(BOT_CONFIG)/repository/tables/table_abethistory.xml
	$(TP) -t abethistory > $(ST)/table_abethistory.ada
	cd $(ST) && gnatchop -w -gnat05 table_abethistory.ada
	cd $(ST) && rm table_abethistory.ada
	$(TP) -p abethistory > $(ST)/abethistory.sql

#/etc/logrotate.d/bnlbot: 
#	echo "/home/bnl/bnlbot/botstart/bot-0-9/target/log/*.log { \
#       size 2M \
#       rotate 10 \
#       copytruncate \
#       delaycompress \
#       compress \
#       notifempty \
#       missingok \
#       su bnl bnl \
#    }"




    
clean:
#	gnatclean -P json_test
	gnatclean -P adabot
	gnatclean -P global
	rm $(ST)/table*.ad[abs]

