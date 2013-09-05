#!/bin/bash
tclsh $BOT_SCRIPT/tcl/make_table_package.tcl -p abalances > tbl.sql
tclsh $BOT_SCRIPT/tcl/make_table_package.tcl -p abethistory >> tbl.sql
tclsh $BOT_SCRIPT/tcl/make_table_package.tcl -p abets >> tbl.sql
tclsh $BOT_SCRIPT/tcl/make_table_package.tcl -p aevents >> tbl.sql
tclsh $BOT_SCRIPT/tcl/make_table_package.tcl -p amarkets >> tbl.sql
tclsh $BOT_SCRIPT/tcl/make_table_package.tcl -p anonrunners >> tbl.sql
tclsh $BOT_SCRIPT/tcl/make_table_package.tcl -p aprices >> tbl.sql
tclsh $BOT_SCRIPT/tcl/make_table_package.tcl -p arunners >> tbl.sql
tclsh $BOT_SCRIPT/tcl/make_table_package.tcl -p awinners >> tbl.sql
