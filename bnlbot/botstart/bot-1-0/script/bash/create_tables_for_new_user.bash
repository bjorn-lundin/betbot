#!/bin/bash
 $BOT_TARGET/bin/repo --postgresql=abalances      > tbl.sql
 $BOT_TARGET/bin/repo --postgresql=apriceshistory >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=abets         >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=aevents       >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=aeventsold    >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=amarkets      >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=amarketsold   >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=aprices       >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=apricesold    >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=arunners      >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=arunnersold   >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=astarttimes   >> tbl.sql

echo ""                                       >> tbl.sql
echo "begin;"                                 >> tbl.sql
echo "CREATE SEQUENCE bet_id_serial "         >> tbl.sql
echo "  INCREMENT 1"                          >> tbl.sql
echo "  MINVALUE 1"                           >> tbl.sql
echo "  MAXVALUE 9223372036854775807"         >> tbl.sql
echo "  START 75416"                          >> tbl.sql
echo "  CACHE 1;"                             >> tbl.sql
echo "                                      " >> tbl.sql
echo "CREATE OR REPLACE VIEW all_events AS  " >> tbl.sql
echo " SELECT aevents.eventid,              " >> tbl.sql
echo "    aevents.eventname,                " >> tbl.sql
echo "    aevents.countrycode,              " >> tbl.sql
echo "    aevents.timezone,                 " >> tbl.sql
echo "    aevents.opents,                   " >> tbl.sql
echo "    aevents.eventtypeid,              " >> tbl.sql
echo "    aevents.ixxlupd,                  " >> tbl.sql
echo "    aevents.ixxluts                   " >> tbl.sql
echo "   FROM aevents                       " >> tbl.sql
echo "UNION ALL                             " >> tbl.sql
echo " SELECT aeventsold.eventid,           " >> tbl.sql
echo "    aeventsold.eventname,             " >> tbl.sql
echo "    aeventsold.countrycode,           " >> tbl.sql
echo "    aeventsold.timezone,              " >> tbl.sql
echo "    aeventsold.opents,                " >> tbl.sql
echo "    aeventsold.eventtypeid,           " >> tbl.sql
echo "    aeventsold.ixxlupd,               " >> tbl.sql
echo "    aeventsold.ixxluts                " >> tbl.sql
echo "   FROM aeventsold;                   " >> tbl.sql
echo "                                      " >> tbl.sql
echo "CREATE OR REPLACE VIEW all_markets AS " >> tbl.sql
echo " SELECT amarkets.marketid,            " >> tbl.sql
echo "    amarkets.marketname,              " >> tbl.sql
echo "    amarkets.startts,                 " >> tbl.sql
echo "    amarkets.eventid,                 " >> tbl.sql
echo "    amarkets.markettype,              " >> tbl.sql
echo "    amarkets.status,                  " >> tbl.sql
echo "    amarkets.betdelay,                " >> tbl.sql
echo "    amarkets.numwinners,              " >> tbl.sql
echo "    amarkets.numrunners,              " >> tbl.sql
echo "    amarkets.numactiverunners,        " >> tbl.sql
echo "    amarkets.totalmatched,            " >> tbl.sql
echo "    amarkets.totalavailable,          " >> tbl.sql
echo "    amarkets.ixxlupd,                 " >> tbl.sql
echo "    amarkets.ixxluts                  " >> tbl.sql
echo "   FROM amarkets                      " >> tbl.sql
echo "UNION ALL                             " >> tbl.sql
echo " SELECT amarketsold.marketid,         " >> tbl.sql
echo "    amarketsold.marketname,           " >> tbl.sql
echo "    amarketsold.startts,              " >> tbl.sql
echo "    amarketsold.eventid,              " >> tbl.sql
echo "    amarketsold.markettype,           " >> tbl.sql
echo "    amarketsold.status,               " >> tbl.sql
echo "    amarketsold.betdelay,             " >> tbl.sql
echo "    amarketsold.numwinners,           " >> tbl.sql
echo "    amarketsold.numrunners,           " >> tbl.sql
echo "    amarketsold.numactiverunners,     " >> tbl.sql
echo "    amarketsold.totalmatched,         " >> tbl.sql
echo "    amarketsold.totalavailable,       " >> tbl.sql
echo "    amarketsold.ixxlupd,              " >> tbl.sql
echo "    amarketsold.ixxluts               " >> tbl.sql
echo "   FROM amarketsold;                  " >> tbl.sql
echo "                                      " >> tbl.sql
echo "CREATE OR REPLACE VIEW all_prices AS  " >> tbl.sql
echo " SELECT aprices.pricets,              " >> tbl.sql
echo "    aprices.marketid,                 " >> tbl.sql
echo "    aprices.selectionid,              " >> tbl.sql
echo "    aprices.status,                   " >> tbl.sql
echo "    aprices.backprice,                " >> tbl.sql
echo "    aprices.layprice,                 " >> tbl.sql
echo "    aprices.ixxlupd,                  " >> tbl.sql
echo "    aprices.ixxluts                   " >> tbl.sql
echo "   FROM aprices                       " >> tbl.sql
echo "UNION ALL                             " >> tbl.sql
echo " SELECT apricesold.pricets,           " >> tbl.sql
echo "    apricesold.marketid,              " >> tbl.sql
echo "    apricesold.selectionid,           " >> tbl.sql
echo "    apricesold.status,                " >> tbl.sql
echo "    apricesold.backprice,             " >> tbl.sql
echo "    apricesold.layprice,              " >> tbl.sql
echo "    apricesold.ixxlupd,               " >> tbl.sql
echo "    apricesold.ixxluts                " >> tbl.sql
echo "   FROM apricesold;                   " >> tbl.sql
echo "                                      " >> tbl.sql
echo "CREATE OR REPLACE VIEW all_runners AS " >> tbl.sql
echo " SELECT arunners.marketid,            " >> tbl.sql
echo "    arunners.selectionid,             " >> tbl.sql
echo "    arunners.sortprio,                " >> tbl.sql
echo "    arunners.status,                  " >> tbl.sql
echo "    arunners.handicap,                " >> tbl.sql
echo "    arunners.runnername,              " >> tbl.sql
echo "    arunners.runnernamestripped,      " >> tbl.sql
echo "    arunners.runnernamenum,           " >> tbl.sql
echo "    arunners.ixxlupd,                 " >> tbl.sql
echo "    arunners.ixxluts                  " >> tbl.sql
echo "   FROM arunners                      " >> tbl.sql
echo "UNION ALL                             " >> tbl.sql
echo " SELECT arunnersold.marketid,         " >> tbl.sql
echo "    arunnersold.selectionid,          " >> tbl.sql
echo "    arunnersold.sortprio,             " >> tbl.sql
echo "    arunnersold.status,               " >> tbl.sql
echo "    arunnersold.handicap,             " >> tbl.sql
echo "    arunnersold.runnername,           " >> tbl.sql
echo "    arunnersold.runnernamestripped,   " >> tbl.sql
echo "    arunnersold.runnernamenum,        " >> tbl.sql
echo "    arunnersold.ixxlupd,              " >> tbl.sql
echo "    arunnersold.ixxluts               " >> tbl.sql
echo "   FROM arunnersold;                  " >> tbl.sql
echo "commit;                               " >> tbl.sql
echo "                                      " >> tbl.sql
   
