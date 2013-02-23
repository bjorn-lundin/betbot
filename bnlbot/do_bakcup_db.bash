#!/bin/bash

DayOfWeek=$(date +%u)
DROPBOX_DIR=/home/bnl/Dropbox/backup
TARGET_DIR=/home/bnl/programming/backup
#SVN=svn_daily_backup_$DayOfWeek.dmp
PG=pg_daily_backup_$DayOfWeek.dmp
BET=betting_$DayOfWeek.dmp


#SVN_ZIP=$SVN.zip
PG_ZIP=$PG.zip
BET_ZIP=$BET.zip

#rm -f $TARGET_DIR/$SVN
rm -f $TARGET_DIR/$PG
rm -f $TARGET_DIR/$BET

#echo "dumping svn"
#/opt/local/bin/svnadmin dump /opt/local/var/db/svn > $TARGET_DIR/$SVN
echo "vacuum db:s"
#/opt/local/lib/postgresql84/bin/vacuumdb --all --analyze
/usr/bin/vacuumdb --all --analyze
echo "dump db:s"
#/opt/local/lib/postgresql84/bin/pg_dumpall --column-inserts > $TARGET_DIR/$PG
/usr/bin/pg_dumpall --column-inserts > $TARGET_DIR/$PG
echo "dump bets only"
#/opt/local/lib/postgresql84/bin/pg_dump betting  > $TARGET_DIR/$BET
/usr/bin/pg_dump betting  > $TARGET_DIR/$BET

#echo "zip svn to dropbox"
#zip  -j $DROPBOX_DIR/$SVN_ZIP $TARGET_DIR/$SVN && rm -f $TARGET_DIR/$SVN

echo "zip pg to dropbox"
zip  -j $DROPBOX_DIR/$PG_ZIP  $TARGET_DIR/$PG && rm -f $TARGET_DIR/$PG

echo "zip betting to dropbox"
zip  -j $DROPBOX_DIR/$BET_ZIP  $TARGET_DIR/$BET && rm -f $TARGET_DIR/$BET
