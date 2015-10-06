#!/usr/bin/env bash

# Use this script when running the application from
# e.g. cron or in other situaions when virtualenv
# can't be set manually. For reference see
# https://gist.github.com/2199506

### Config ###
AIS_VIRT_ENV="/home/joakim/ais/py_env"
AIS_HOME="/home/joakim/ais/app"
AIS_APP="$AIS_HOME/app.py"
EOD_TIME="22:45"
DEV="false"

export TZ="/usr/share/zoneinfo/Europe/Stockholm"
TIME=`date "+%H:%M"`

if  [ "$DEV" == "true" ] || [ "$TIME" == "$EOD_TIME" ]; then
    export VIRTUAL_ENV=$AIS_VIRT_ENV
    export PATH="$VIRTUAL_ENV/bin:$PATH"
    unset PYTHON_HOME
    #$AIS_APP eod_download
    #$AIS_APP save_files_in_cloud
    #$AIS_APP email_log_stats

    $AIS_APP load_eod_racingcard
    $AIS_APP load_eod_vppoolinfo
    $AIS_APP load_eod_vpresult

    #$AIS_APP load_eod_ddpoolinfo
    #$AIS_APP load_eod_ddresult
    #$AIS_APP save_db_dump_in_cloud
fi

