#!/bin/bash 
 
SQL_FILE=/tmp/drop_all.sql
echo "drop table abalances;"         > $SQL_FILE
echo "drop table abets;"            >> $SQL_FILE
echo "drop table aevents;"          >> $SQL_FILE
echo "drop table amarkets;"         >> $SQL_FILE
echo "drop table aprices;"          >> $SQL_FILE
echo "drop table arunners;"         >> $SQL_FILE
echo "drop sequence bet_id_serial;" >> $SQL_FILE

# drop all tables
psql --no-psqlrc --file=$SQL_FILE nono

rm -f $SQL_FILE

#reads pwd from .pgpass

# /usr/lib/postgresql/9.3/bin/pg_dump

pg_dump -h nonodev.com -U bnl bnls | psql --no-psqlrc nono

