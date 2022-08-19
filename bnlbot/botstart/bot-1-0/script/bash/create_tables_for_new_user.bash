#!/bin/bash
 $BOT_TARGET/bin/repo --postgresql=abalances      > tbl.sql
 $BOT_TARGET/bin/repo --postgresql=apriceshistory >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=abets         >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=aevents       >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=amarkets      >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=aprices       >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=arunners      >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=astarttimes   >> tbl.sql
$BOT_TARGET/bin/repo --postgresql=okmarkets   >> tbl.sql
$BOT_TARGET/bin/repo --postgresql=arewards   >> tbl.sql
echo ""                                       >> tbl.sql
echo "begin;"                                 >> tbl.sql
echo "CREATE SEQUENCE bet_id_serial "         >> tbl.sql
echo "  INCREMENT 1"                          >> tbl.sql
echo "  MINVALUE 1"                           >> tbl.sql
echo "  MAXVALUE 9223372036854775807"         >> tbl.sql
echo "  START 200000"                         >> tbl.sql
echo "  CACHE 1;"                             >> tbl.sql
echo "                                      " >> tbl.sql
echo "commit;                               " >> tbl.sql
echo "                                      " >> tbl.sql

