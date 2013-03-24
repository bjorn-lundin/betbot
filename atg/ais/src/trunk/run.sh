# Use this script when running the application from 
# e.g. cron or in other situaions when virtualenv
# can't be set manually. For reference see
# https://gist.github.com/2199506

#!/bin/sh
#export VIRTUAL_ENV="/home/joabi/production/ais/py_env"
export VIRTUAL_ENV="/home/sejoabi/pip_test_env"
export PATH="$VIRTUAL_ENV/bin:$PATH"
unset PYTHON_HOME
exec "${@:-$SHELL}"
