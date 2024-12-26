#/bin/bash

# 1 - create a new db
# 2 - create its tables
# 3 - fill with data for the year
# 4 - extract the data to gzfile

#createdb --encoding=UTF8 bnl_2018
#createdb --encoding=UTF8 bnl_2019
#createdb --encoding=UTF8 bnl_2020
#createdb --encoding=UTF8 bnl_2021
#createdb --encoding=UTF8 bnl_2022
#createdb --encoding=UTF8 bnl_2023

#create_tables_for_new_user.bash (creates tbl.sql)
#psql bnl_2020 < tbl.sql

#cd /usr2/data/db_dumps/fulldb
#pg_dump --clean --create --format=plain bnl_2019 | gzip - > bnl_2019.gz


TABLES="aevents amarkets aprices arunners abalances"

YEARS="2018 2019 2020 2021 2022 2023 2024"

for Y in ${YEARS} ; do
  echo "YEAR ${Y}"
  for T in ${TABLES} ; do
    echo "TABLE ${T}"
    psql --no-psqlrc --command="COPY (SELECT * FROM ${T} WHERE ixxluts::date >= '${Y}-01-01' and ixxluts::date <= '${Y}-12-21' ) TO STDOUT;" > tmp.sql
    psql --no-psqlrc --command="COPY ${T} FROM STDIN;" bnl_${Y} < tmp.sql
  done
done
rm -rf tmp.sql

