#!/bin/bash
 $BOT_TARGET/bin/repo --postgresql=abalances      > tbl.sql
 $BOT_TARGET/bin/repo --postgresql=apriceshistory >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=abets         >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=aevents       >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=amarkets      >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=aprices       >> tbl.sql
 $BOT_TARGET/bin/repo --postgresql=arunners      >> tbl.sql
