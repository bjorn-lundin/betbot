#!/bin/bash

betname_list=$(psql --host=betbot.nonobet.com --username=bnl --command="select distinct(betname) from abets where startts > '2017-01-01 00:00:00' order by betname" | grep '00')

for b in $betname_list ; do
  min=$(echo ${b} | cut -d'_' -f8)
  max=$(echo ${b} | cut -d'_' -f9)
  
  echo ${b}
  $BOT_TARGET/bin/profit_min_max --checkonly --betname=${b} --min=-${min} --max=${max} 2>&1 | grep "Total"
done
