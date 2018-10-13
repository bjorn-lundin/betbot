#!/bin/bash
export PATH=/bin:/usr/bin:$PATH
TZ='Europe/Stockholm'
export TZ


function create_dump () {

  #WD=/data/db_dumps/script
  DATE=$(date +"%d")
  YEAR=$(date +"%Y")
  MONTH=$(date +"%m")
  TARGET_DIR=/data/db_dumps/${YEAR}/${MONTH}/${DATE}

  [ ! -d $TARGET_DIR ] && mkdir -p $TARGET_DIR

  DB_LIST="bnl dry jmb msm"
  TABLE_LIST="aevents amarkets aprices apriceshistory arunners abets"

  for DBNAME in ${DB_LIST} ; do
    for TABLE in ${TABLE_LIST} ; do
      pg_dump --schema-only --dbname=${DBNAME} --table=${TABLE} > ${TARGET_DIR}/${DBNAME}_${YEAR}_${MONTH}_${DATE}_${TABLE}_schema.dmp
      #pg_dump --data-only  --dbname=${DBNAME} --table=${TABLE} | gzip > ${TARGET_DIR}/${DBNAME}_${YEAR}_${MONTH}_${DATE}_${TABLE}.tar.gz
      pg_dump --data-only  --dbname=${DBNAME} --table=${TABLE} | gzip > ${TARGET_DIR}/${DBNAME}_${YEAR}_${MONTH}_${DATE}_${TABLE}.zip

      R=$?
      if [ $R -eq 0 ] ; then
        case ${TABLE} in
          abets)  echo "null" > /dev/null ;;
              *)  psql --no-psqlrc --dbname=${DBNAME} --command="truncate table ${TABLE}" ;;
        esac
      fi
    done
  done

  #DB_LIST="${DB_LIST} ${DBNAME}"
  #
  for DBNAME in ${DB_LIST} ; do
    vacuumdb --dbname=${DBNAME} --analyze
  # # reindexdb --dbname=${DBNAME} --system
  # # reindexdb --dbname=${DBNAME}
  done
}
exit 0
create_dump
