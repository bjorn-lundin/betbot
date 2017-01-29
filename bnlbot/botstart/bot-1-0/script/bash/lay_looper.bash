#!/bin/bash

EXE=sim_back_1_2_3

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
    sleep 5
  done
}


function wait_until_less_than_8 {
# bnl@ibm2:~$ ps -ef | grep check_for_greenup_win2 | grep -v grep
# bnl@ibm2:~$ echo $?
# 1
# bnl@ibm2:~$ ps -ef | grep crypto | grep -v grep
# root        23     2  0 19:38 ?        00:00:00 [crypto]
# bnl@ibm2:~$ echo $?
# 0
  while true ; do
    cnt=$(ps -ef | grep -v grep |grep -c ${EXE})
    R=$?
    #echo $R
    if [ $cnt -lt 8 ] ; then
      break
    fi  
    sleep 5
  done
}



num_bets_list="1 2 3 4 5 6 7 8 9 10 11"
first_bet_list="1 2 3 4 5 6"
max_lay_delta_list="2"
place_num_list="1 2 3 4 5"
max_back_list="2 3 4 5 6 7 8 9 10 11 12 13 14"

wait_until_all_done

for num_bets in ${num_bets_list} ; do
  for first_bet in ${first_bet_list} ; do
    for place_num in ${place_num_list} ; do
      for max_back in ${max_back_list} ; do
        for max_lay_delta in ${max_lay_delta_list} ; do
          name=${num_bets}_${first_bet}_${place_num}_${max_back}_${max_lay_delta}
          echo "${name}.log "
          nohup ${BOT_TARGET}/bin/${EXE} --animal=hound \
           --num_bets=${num_bets} \
           --first_bet=${first_bet} \
           --place_num=${place_num} \
           --max_back_price=${max_back} \
           --max_lay_price_delta=${max_lay_delta} > ./${name}.log 2>&1 &
        sleep 1
        wait_until_less_than_8
        done
      done
      date
    done
  done
done
