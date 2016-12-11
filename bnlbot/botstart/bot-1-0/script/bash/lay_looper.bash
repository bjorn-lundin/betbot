#!/bin/bash


EXE=check_lay

function wait_until_all_done {
# bnl@ibm2:~$ ps -ef | grep check_for_greenup_win2 | grep -v grep
# bnl@ibm2:~$ echo $?
# 1
# bnl@ibm2:~$ ps -ef | grep crypto | grep -v grep
# root        23     2  0 19:38 ?        00:00:00 [crypto]
# bnl@ibm2:~$ echo $?
# 0
  while true ; do
    ps -ef | grep ${EXE} | grep -v grep > /dev/null
    R=$?
    #echo $R
    if [ $R -eq 1 ] ; then
      break
    fi  
    sleep 30
  done
}

runners_place_list="4 5 6 7"
addon_odds_list="10 20 30"
max_lay_list="35 40 45 50"
min_lay_list="1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8"


wait_until_all_done

for rp in ${runners_place_list} ; do
  for ao in ${addon_odds_list} ; do
    for max in ${max_lay_list} ; do
      for min in ${min_lay_list} ; do
        echo "bnl_${min}_${max}_${rp}_${ao}.log "
        nohup $BOT_TARGET/bin/check_lay \
         --betname=LAY_${min}_${max}_WIN_${rp}_${ao} \
         --runners_place=${rp} \
         --addon_odds=${ao} \
         --min_price=${min} \
         --max_price=${max} > ./lay_${min}_${max}_win_${rp}_${ao}.log 2>&1 &
      sleep 1     
      done
      wait_until_all_done
    done
  done
done



