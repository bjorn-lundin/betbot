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


.PHONY : log
log :
	$(MAKE) all 2>&1 | tee make.log


.PHONY : adabot tables
all: tables adabot
#/etc/logrotate.d/bnlbot


tables : $(ST)/table_history.ads  $(ST)/table_alinks.ads \
         $(ST)/table_aevents.ads  $(ST)/table_amarkets.ads \
         $(ST)/table_arunners.ads $(ST)/table_aprices.ads \
         $(ST)/table_abets.ads    $(ST)/table_abalances.ads \
         $(ST)/table_apricesfinish.ads $(ST)/table_araceprices.ads \
         $(ST)/table_aracepricesold.ads \
         $(ST)/table_aeventsold.ads  $(ST)/table_amarketsold.ads \
         $(ST)/table_arunnersold.ads $(ST)/table_apricesold.ads
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
    

$(ST)/table_abets.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_abets.xml
	$(TP) -t abets > $(ST)/table_abets.ada
	cd $(ST) && gnatchop -w -gnat05 table_abets.ada
	cd $(ST) && rm table_abets.ada
	$(TP) -p abets > $(ST)/abets.sql


$(ST)/table_abalances.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_abalances.xml
	$(TP) -t abalances > $(ST)/table_abalances.ada
	cd $(ST) && gnatchop -w -gnat05 table_abalances.ada
	cd $(ST) && rm table_abalances.ada
	$(TP) -p abalances > $(ST)/abalances.sql

$(ST)/table_aracepricesold.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_aracepricesold.xml
	$(TP) -t aracepricesold > $(ST)/table_aracepricesold.ada
	cd $(ST) && gnatchop -w -gnat05 table_aracepricesold.ada
	cd $(ST) && rm table_aracepricesold.ada
	$(TP) -p aracepricesold > $(ST)/aracepricesold.sql

$(ST)/table_amarketsold.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_amarketsold.xml
	$(TP) -t amarketsold > $(ST)/table_amarketsold.ada
	cd $(ST) && gnatchop -w -gnat05 table_amarketsold.ada
	cd $(ST) && rm table_amarketsold.ada
	$(TP) -p amarketsold > $(ST)/amarketsold.sql

$(ST)/table_aeventsold.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_aeventsold.xml
	$(TP) -t aeventsold > $(ST)/table_aeventsold.ada
	cd $(ST) && gnatchop -w -gnat05 table_aeventsold.ada
	cd $(ST) && rm table_aeventsold.ada
	$(TP) -p aeventsold > $(ST)/aeventsold.sql

$(ST)/table_arunnersold.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_arunnersold.xml
	$(TP) -t arunnersold > $(ST)/table_arunnersold.ada
	cd $(ST) && gnatchop -w -gnat05 table_arunnersold.ada
	cd $(ST) && rm table_arunnersold.ada
	$(TP) -p arunnersold > $(ST)/arunnersold.sql

$(ST)/table_apricesold.ads : $(TPG) $(BOT_CONFIG)/repository/tables/table_apricesold.xml
	$(TP) -t apricesold > $(ST)/table_apricesold.ada
	cd $(ST) && gnatchop -w -gnat05 table_apricesold.ada
	cd $(ST) && rm table_apricesold.ada
	$(TP) -p apricesold > $(ST)/apricesold.sql

$(C_CONSTANTS_EXE) : $(C_CONSTANTS_SOURCE)
	gcc -o $(C_CONSTANTS_EXE) $(C_CONSTANTS_SOURCE)

$(C_CONSTANTS_OUTPUT) : $(C_CONSTANTS_EXE)
	$(C_CONSTANTS_EXE) > $(C_CONSTANTS_OUTPUT)    
    
clean:
	gnatclean -P adabot
	gnatclean -P global
	rm $(ST)/table*.ad[abs]

