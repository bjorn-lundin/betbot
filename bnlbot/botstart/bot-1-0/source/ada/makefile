###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################

UNAME := $(shell uname)

TPG :=  $(subst \,/, $(BOT_SCRIPT)/tcl/make_table_package.tcl)
TP := tclsh $(TPG)
ST := $(subst \,/, $(BOT_SOURCE)/ada/global/tables)

OBJECT_DIR_JSON := $(subst \,/, $(BOT_TARGET)/objects/json)
OBJECT_DIR_BOT  := $(subst \,/, $(BOT_TARGET)/objects/bot)
EXE_DIR_BOT     := $(subst \,/, $(BOT_TARGET)/bin)
LOG_DIR_BOT     := $(subst \,/, $(BOT_TARGET)/log)
TARGET_ADA_INFO_SPEC := $(subst \,/, $(BOT_SOURCE)/ada/local/bot/bot_svn_info.ads)
PIPE_DIR_BOT     := $(subst \,/, $(BOT_TARGET)/pipes)

C_CONSTANTS_OUTPUT := $(BOT_SOURCE)/ada/global/c_constants.ads
C_CONSTANTS_SOURCE := $(BOT_SOURCE)/c/c_constants.c
C_CONSTANTS_EXE    := $(BOT_TARGET)/bin/c_constants

.PHONY : adabot tables

all: tables adabot
#/etc/logrotate.d/bnlbot


tables : $(ST)/table_history.ads  $(ST)/table_alinks.ads \
         $(ST)/table_aevents.ads  $(ST)/table_amarkets.ads \
         $(ST)/table_arunners.ads $(ST)/table_aprices.ads \
         $(ST)/table_abets.ads    $(ST)/table_abalances.ads \
         $(ST)/table_apricesfinish.ads $(ST)/table_araceprices.ads \
         $(ST)/table_aracepricesold.ads \
#$(ST)/table_anonrunners.ads         
#$(ST)/table_awinners.ads
#$(ST)/table_abethistory.ads $(ST)/table_history2.ads
#$(ST)/table_dryresults.ads $(ST)/table_drymarkets.ads $(ST)/table_dryrunners.ads

$(EXE_DIR_BOT) :
	mkdir -p $(EXE_DIR_BOT)

$(LOG_DIR_BOT) :
	mkdir -p $(LOG_DIR_BOT)

$(OBJECT_DIR_BOT) :
	mkdir -p $(OBJECT_DIR_BOT)

$(OBJECT_DIR_JSON) :
	mkdir -p $(OBJECT_DIR_JSON)
    
$(PIPE_DIR_BOT) :
	mkdir -p $(PIPE_DIR_BOT)

.PHONY : $(TARGET_ADA_INFO_SPEC)
$(TARGET_ADA_INFO_SPEC):
	$(BOT_SCRIPT)/bash/create_revision_info.bash $(TARGET_ADA_INFO_SPEC)

adabot : $(TARGET_ADA_INFO_SPEC) $(OBJECT_DIR_BOT) $(EXE_DIR_BOT) $(LOG_DIR_BOT) $(PIPE_DIR_BOT) $(C_CONSTANTS_OUTPUT)
	@echo "building on host $(HOSTNAME) with mode $(BOT_MODE) and role $(BOT_MACHINE_ROLE)"
	gnatmake -P adabot

$(ST)/table_history.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_history.xml
	$(TP) -t history > $(ST)/table_history.ada
	cd $(ST) && gnatchop -w -gnat05 table_history.ada
	cd $(ST) && rm table_history.ada
	$(TP) -p history > $(ST)/history.sql

$(ST)/table_alinks.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_alinks.xml
	$(TP) -t alinks > $(ST)/table_alinks.ada
	cd $(ST) && gnatchop -w -gnat05 table_alinks.ada
	cd $(ST) && rm table_alinks.ada
	$(TP) -p alinks > $(ST)/alinks.sql
    
#$(ST)/table_history2.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_history2.xml
#	$(TP) -t history2 > $(ST)/table_history2.ada
#	cd $(ST) && gnatchop -w -gnat05 table_history2.ada
#	cd $(ST) && rm table_history2.ada
#	$(TP) -p history2 > $(ST)/history2.sql

$(ST)/table_amarkets.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_amarkets.xml
	$(TP) -t amarkets > $(ST)/table_amarkets.ada
	cd $(ST) && gnatchop -w -gnat05 table_amarkets.ada
	cd $(ST) && rm table_amarkets.ada
	$(TP) -p amarkets > $(ST)/amarkets.sql

$(ST)/table_aevents.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_aevents.xml
	$(TP) -t aevents > $(ST)/table_aevents.ada
	cd $(ST) && gnatchop -w -gnat05 table_aevents.ada
	cd $(ST) && rm table_aevents.ada
	$(TP) -p aevents > $(ST)/aevents.sql

$(ST)/table_arunners.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_arunners.xml
	$(TP) -t arunners > $(ST)/table_arunners.ada
	cd $(ST) && gnatchop -w -gnat05 table_arunners.ada
	cd $(ST) && rm table_arunners.ada
	$(TP) -p arunners > $(ST)/arunners.sql

$(ST)/table_aprices.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_aprices.xml
	$(TP) -t aprices > $(ST)/table_aprices.ada
	cd $(ST) && gnatchop -w -gnat05 table_aprices.ada
	cd $(ST) && rm table_aprices.ada
	$(TP) -p aprices > $(ST)/aprices.sql

$(ST)/table_apricesfinish.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_apricesfinish.xml
	$(TP) -t apricesfinish > $(ST)/table_apricesfinish.ada
	cd $(ST) && gnatchop -w -gnat05 table_apricesfinish.ada
	cd $(ST) && rm table_apricesfinish.ada
	$(TP) -p apricesfinish > $(ST)/apricesfinish.sql

$(ST)/table_araceprices.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_araceprices.xml
	$(TP) -t araceprices > $(ST)/table_araceprices.ada
	cd $(ST) && gnatchop -w -gnat05 table_araceprices.ada
	cd $(ST) && rm table_araceprices.ada
	$(TP) -p araceprices > $(ST)/araceprices.sql
    
$(ST)/table_aracepricesold.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_aracepricesold.xml
	$(TP) -t aracepricesold > $(ST)/table_aracepricesold.ada
	cd $(ST) && gnatchop -w -gnat05 table_aracepricesold.ada
	cd $(ST) && rm table_aracepricesold.ada
	$(TP) -p aracepricesold > $(ST)/aracepricesold.sql
    
#$(ST)/table_awinners.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_awinners.xml
#	$(TP) -t awinners > $(ST)/table_awinners.ada
#	cd $(ST) && gnatchop -w -gnat05 table_awinners.ada
#	cd $(ST) && rm table_awinners.ada
#	$(TP) -p awinners > $(ST)/awinners.sql

#$(ST)/table_animals.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_animals.xml
#	$(TP) -t animals > $(ST)/table_animals.ada
#	cd $(ST) && gnatchop -w -gnat05 table_animals.ada
#	cd $(ST) && rm table_animals.ada
#	$(TP) -p animals > $(ST)/animals.sql

$(ST)/table_abets.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_abets.xml
	$(TP) -t abets > $(ST)/table_abets.ada
	cd $(ST) && gnatchop -w -gnat05 table_abets.ada
	cd $(ST) && rm table_abets.ada
	$(TP) -p abets > $(ST)/abets.sql

#$(ST)/table_anonrunners.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_anonrunners.xml
#	$(TP) -t anonrunners > $(ST)/table_anonrunners.ada
#	cd $(ST) && gnatchop -w -gnat05 table_anonrunners.ada
#	cd $(ST) && rm table_anonrunners.ada
#	$(TP) -p anonrunners > $(ST)/anonrunners.sql

$(ST)/table_abalances.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_abalances.xml
	$(TP) -t abalances > $(ST)/table_abalances.ada
	cd $(ST) && gnatchop -w -gnat05 table_abalances.ada
	cd $(ST) && rm table_abalances.ada
	$(TP) -p abalances > $(ST)/abalances.sql

#$(ST)/table_drymarkets.ads : $(BOT_CONFIG)/repository/tables/table_drymarkets.xml
#	$(TP) -t drymarkets > $(ST)/table_drymarkets.ada
#	cd $(ST) && gnatchop -w -gnat05 table_drymarkets.ada
#	cd $(ST) && rm table_drymarkets.ada
#	$(TP) -p drymarkets > $(ST)/drymarkets.sql
#
#$(ST)/table_dryrunners.ads : $(BOT_CONFIG)/repository/tables/table_dryrunners.xml
#	$(TP) -t dryrunners > $(ST)/table_dryrunners.ada
#	cd $(ST) && gnatchop -w -gnat05 table_dryrunners.ada
#	cd $(ST) && rm table_dryrunners.ada
#	$(TP) -p dryrunners > $(ST)/dryrunners.sql
#
#$(ST)/table_dryresults.ads : $(BOT_CONFIG)/repository/tables/table_dryresults.xml
#	$(TP) -t dryresults > $(ST)/table_dryresults.ada
#	cd $(ST) && gnatchop -w -gnat05 table_dryresults.ada
#	cd $(ST) && rm table_dryresults.ada
#	$(TP) -p dryresults > $(ST)/dryresults.sql

#$(ST)/table_abethistory.ads : $(BOT_CONFIG)/repository/tables/table_abethistory.xml
#	$(TP) -t abethistory > $(ST)/table_abethistory.ada
#	cd $(ST) && gnatchop -w -gnat05 table_abethistory.ada
#	cd $(ST) && rm table_abethistory.ada
#	$(TP) -p abethistory > $(ST)/abethistory.sql

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


$(C_CONSTANTS_EXE) : $(C_CONSTANTS_SOURCE)
	gcc -o $(C_CONSTANTS_EXE) $(C_CONSTANTS_SOURCE)

$(C_CONSTANTS_OUTPUT) : $(C_CONSTANTS_EXE)
	$(C_CONSTANTS_EXE) > $(C_CONSTANTS_OUTPUT)    
    
clean:
	gnatclean -P adabot
	gnatclean -P global
	rm $(ST)/table*.ad[abs]

