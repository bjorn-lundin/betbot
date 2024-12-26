#/bin/bash

#createdb --encoding=UTF8 bnl_2018
#createdb --encoding=UTF8 bnl_2019
#createdb --encoding=UTF8 bnl_2020
#createdb --encoding=UTF8 bnl_2021
#createdb --encoding=UTF8 bnl_2022
#createdb --encoding=UTF8 bnl_2023
#TABLES="abets aevents amarkets apriceshistory aprices arunners "


TABLES="aevents amarkets aprices arunners abalances"

YEARS="2018 2019 2020 2021 2022 2023 2024"

for Y in ${YEARS} ; do
  for T in ${TABLES} ; do
    cmd_exp="COPY (SELECT * FROM ${T} WHERE ixxluts::date >= ${Y}'-01-01' and ixxluts::date <= ${Y}'-12-21' ) TO STDOUT;"
    cmd_imp="COPY ${T} FROM STDIN;"
    echo "psql --command=${cmd_exp} bnl | psql --command=${cmd_imp} bnl_${YEAR}"
  done
done


#psql --command="COPY (SELECT * FROM my_table WHERE created_at > '2012-05-01') TO STDOUT;" source_db |
#psql --command="COPY my_table FROM STDIN;" target_db


