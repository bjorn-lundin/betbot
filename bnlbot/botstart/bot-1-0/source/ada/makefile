###############################################################################
#                                                                             #
#                                Make File                                    #
#                                                                             #
###############################################################################


EXE_DIR_BOT     := $(subst \,/, $(BOT_TARGET)/bin)
LOG_DIR_BOT     := $(subst \,/, $(BOT_TARGET)/log)
TARGET_ADA_INFO_SPEC := $(subst \,/, $(BOT_SOURCE)/ada/local/bot/bot_svn_info.ads)
PIPE_DIR_BOT     := $(subst \,/, $(BOT_TARGET)/pipes)

C_CONSTANTS_OUTPUT := $(subst \,/, $(BOT_SOURCE)/ada/global/c_constants.ads)
C_CONSTANTS_SOURCE := $(subst \,/, $(BOT_SOURCE)/c/c_constants.c)
C_CONSTANTS_EXE    := $(subst \,/, $(BOT_TARGET)/bin/c_constants)

TABLES := $(subst \,/, $(BOT_CONFIG)/repository/tables/table_*.xml)
TERMS := $(subst \,/, $(BOT_CONFIG)/repository/terms/trm_*.xml)
XSDS := $(subst \,/, $(BOT_CONFIG)/repository/*.xsd)

.PHONY : all adabot tables log bot

all : log

log :
	$(MAKE) bot 2>&1 | tee make.log

bot : tables adabot

$(REPO_ENGINE) :
	gnatmake -p -P adabot repo

tables: $(REPO_ENGINE) $(TABLES) $(TERMS) $(XSDS)
	$(REPO_ENGINE) --table_makefile > $(BOT_SOURCE)/ada/global/tables/makefile
	cd $(BOT_SOURCE)/ada/global/tables && $(MAKE)
    
$(EXE_DIR_BOT) :
	mkdir -p $(EXE_DIR_BOT)

$(LOG_DIR_BOT) :
	mkdir -p $(LOG_DIR_BOT)

$(PIPE_DIR_BOT) :
	mkdir -p $(PIPE_DIR_BOT)

.PHONY : $(TARGET_ADA_INFO_SPEC)
$(TARGET_ADA_INFO_SPEC):
	$(BOT_SCRIPT)/bash/create_revision_info.bash $(TARGET_ADA_INFO_SPEC)

adabot : $(TARGET_ADA_INFO_SPEC) $(EXE_DIR_BOT) $(LOG_DIR_BOT) $(PIPE_DIR_BOT) $(C_CONSTANTS_OUTPUT)
	@echo "building on host $(HOSTNAME) with mode $(BOT_MODE) and role $(BOT_MACHINE_ROLE)"
	gnatmake -p -P adabot

$(C_CONSTANTS_EXE) : $(C_CONSTANTS_SOURCE)
	gcc -o $(C_CONSTANTS_EXE) $(C_CONSTANTS_SOURCE)

$(C_CONSTANTS_OUTPUT) : $(C_CONSTANTS_EXE)
	$(C_CONSTANTS_EXE) > $(C_CONSTANTS_OUTPUT)    
    
clean:
	gnatclean -P adabot
	gnatclean -P global
	cd $(BOT_SOURCE)/ada/global/tables && $(MAKE) clean

