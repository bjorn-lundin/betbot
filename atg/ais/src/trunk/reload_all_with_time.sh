#!/bin/sh
AIS_VIRT_ENV="/home/joakim/.virtualenvs/ais"
AIS_HOME="/home/joakim/projects/ais/atg/ais/src/trunk"
AIS_APP="$AIS_HOME/app.py"

export VIRTUAL_ENV=$AIS_VIRT_ENV
export PATH="$VIRTUAL_ENV/bin:$PATH"
unset PYTHON_HOME

commands="
init_db
load_eod_raceday
"

#load_eod_racingcard
#load_eod_vppoolinfo
#load_eod_vpresult
#load_eod_ddpoolinfo
#load_eod_ddresult

for command in $commands
do
  echo "Running $command"
  echo "Start at `date`"
  $AIS_APP $command
  echo "End at `date`"
  echo
done

exit

