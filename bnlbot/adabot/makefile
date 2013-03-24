###############################################################################
#                                                                             #
#                                JSON_Test                                    #
#                                                                             #
#                                Make File                                    #
#                                                                             #
#                      Copyright (C) 2011, Thomas Løcke                       #
#                                                                             #
# JSON_Test is free software; you can redistribute it and/or modify it under  #
# terms of the GNU General Public License as published by the Free Software   #
# Foundation; either version 2, or (at your option) any later version.        #
# JSON_Test is distributed in the hope that it will be useful, but WITHOUT    #
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or       #
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for    #
# more details. You should have received a copy of the GNU General Public     #
# License distributed with JSON_Test. If not, write to the Free Software      #
# Foundation, 51 Franklin Street, Fifth Floor, Boston, MA 02110 - 1301, USA.  #
#                                                                             #
###############################################################################

DAT := plot/balance.dat
TMP := plot/balance.tmp

UNAME := $(shell uname)

ifeq ($(UNAME),Linux)
  PSQL := /usr/bin/psql
  HOST := localhost
  SHOW_PNG := display
endif

ifeq ($(UNAME),Darwin)
  PSQL := /opt/local/bin/psql92
  HOST := 192.168.0.13
  SHOW_PNG := open
endif



all: json_test adabot

.PHONY : json_test simulator

json_test :
	gnatmake -P json_test

adabot :
	gnatmake -P adabot

.PHONY : balance_plot
balance_plot:
	$(PSQL) -h $(HOST) --command="select cast(eventdate as date), saldo from balance order by eventdate" betting > $(DAT)
	cat $(DAT) | grep -v event > $(TMP)
	cat $(TMP) | grep -v rows > $(DAT)
	cat $(DAT) | grep -v "\-\-" > $(TMP)
	cat $(TMP) > $(DAT)
	rm $(TMP)
	cd plot && gnuplot balance.gpl
	cd plot && $(SHOW_PNG) balance.png



clean:
	gnatclean -P json_test
	gnatclean -P adabot
	gnatclean -P global