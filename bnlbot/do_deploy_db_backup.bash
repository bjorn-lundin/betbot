#!/bin/bash

#import new db from dropbox



DB_NAME=betting

SRC=/home/bnl/Dropbox/backup
TRG=/home/bnl/db


while getopts "n:" opt; do
  case $opt in
    n)
      num_of_backup=$OPTARG
      ;;
    *)
      echo "$0 -n backum num (1-7)" >&2
      exit 1
      ;;
  esac
done

if [ -z $num_of_backup ] ; then
  echo "backup number bad" >&2
  exit 1
elif [ $num_of_backup -lt 1 ] ; then
  echo "backup number bad, too small (min 1)" >&2
  exit 1
elif [ $num_of_backup -gt 7 ] ; then
  echo "backup number bad, too big (max 7)" >&2
  exit 1
fi

[ ! -d $TRG ] && mkdir -p $TRG


ZIP_FILE=$DB_NAME\_$num_of_backup\.dmp.zip
DMP_FILE=$DB_NAME\_$num_of_backup\.dmp


echo "copy $ZIP_FILE to $TRG" >&2
rm -f $TRG/$ZIP_FILE
cp $SRC/$ZIP_FILE $TRG/$ZIP_FILE



PWD=$(pwd)
cd $TRG
echo "delete old dump, $DMP_FILE" >&2
rm -f $DMP_FILE
echo "unzip $ZIP_FILE to $DMP_FILE" >&2
unzip $ZIP_FILE


#delete/createthe old db
echo "drop   db $DB_NAME" >&2
dropdb $DB_NAME
echo "create db $DB_NAME" >&2
createdb $DB_NAME

echo commit\; >> $DMP_FILE

echo "import db $DB_NAME" >&2
psql $DB_NAME < $DMP_FILE
cd $PWD


echo "vacuum db $DB_NAME" >&2

vacuumdb --dbname=$DB_NAME --analyze

echo "done" >&2

