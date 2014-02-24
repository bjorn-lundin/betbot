#!/bin/bash
SQL_FILE=/tmp/drop_all.sql
#echo "truncate history;"     > $SQL_FILE
echo "drop table abalances;"   >> $SQL_FILE
echo "drop table abets;"       >> $SQL_FILE
echo "drop table aevents;"     >> $SQL_FILE
echo "drop table amarkets;"    >> $SQL_FILE
echo "drop table aprices;"     >> $SQL_FILE
echo "drop table arunners;"    >> $SQL_FILE
echo "drop sequence bet_id_serial;" >> $SQL_FILE


USER_LIST="jmb dry"


echo "empty db bnl"
psql --host=db.nonodev.com --no-psqlrc --file=$SQL_FILE --dbname=bnl --username=bnl
# and import
echo "dump/import db bnl"
pg_dump --host=nonodev.com --username=bnl bnls | psql --host=db.nonodev.com --no-psqlrc --dbname=bnl --username=bnl

for u in $USER_LIST ; do
  # empty all tables
  echo "empty db $u"
  psql --host=db.nonodev.com --no-psqlrc --file=$SQL_FILE --dbname=$u --username=bnl
  # and import
  echo "dump/import db $u"
  pg_dump --host=nonodev.com --username=bnl $u | psql --host=db.nonodev.com --no-psqlrc --dbname=$u --username=bnl
done

rm -f $SQL_FILE
