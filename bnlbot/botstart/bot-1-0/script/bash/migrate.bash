#!/bin/bash
SQL_FILE=/tmp/drop_all.sql
#echo "truncate history;"     > $SQL_FILE
echo "truncate abalances;"   >> $SQL_FILE
echo "truncate abets;"       >> $SQL_FILE
echo "truncate aevents;"     >> $SQL_FILE
echo "truncate amarkets;"    >> $SQL_FILE
echo "truncate aprices;"     >> $SQL_FILE
echo "truncate arunners;"    >> $SQL_FILE
echo "commit;"               >> $SQL_FILE

USER_LIST="bnl jmb dry"

for u in $USER_LIST ; do
  # empty all tables
  echo "empty db $u"
  psql --host=db.nonodev.com --no-psqlrc --file=$SQL_FILE --dbname=$u --username=bnl
  # and import
  echo "dump/import db $u"
  pgdump --host=localhost $u bnl | psql --host=db.nonodev.com --no-psqlrc ---dbname=$u --username=bnl
done

rm -f $SQL_FILE
