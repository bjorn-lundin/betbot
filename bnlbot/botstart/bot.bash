#!/bin/bash

INI_READER=$BOT_START/bot-0-9/target/bin/ini_reader


while getopts "a:u:" opt; do
#  echo "$opt - $OPTARG"

  case $opt in
    a)  action=$OPTARG ;;
    u)  BOT_USER=$OPTARG ;;
    *)
      echo "$0 -a action [stop|start] -u user" >&2
      return 1
      ;;
  esac
done


[ -z $action ] && echo "missing action" >&2 && return 1
[ -z $BOT_USER ] && echo "missing user" >&2 && return 1

BETFAIR_INI_FILE=$BOT_START/user/$BOT_USER/betfair.ini
#echo $BETFAIR_INI_FILE
LOGIN_INI_FILE=$BOT_START/user/$BOT_USER/login.ini
#echo $LOGIN_INI_FILE

export BOT_HOME=$BOT_START/user/$BOT_USER
export BOT_USER

# set environment. some (most) of the envvars contain other envvars, resolve them via eval
#BOT_START is set in .bashrc
#INI_BOT_START=$($INI_READER  --ini=$INI_FILE --section=system --variable=bot_start  --default="Not_found")
#export BOT_START=$(eval echo $INI_BOT_START)

INI_BOT_ROOT=$($INI_READER   --ini=$BETFAIR_INI_FILE --section=system --variable=bot_root   --default="Not_found")
export BOT_ROOT=$(eval echo $INI_BOT_ROOT)

INI_BOT_CONFIG=$($INI_READER --ini=$BETFAIR_INI_FILE --section=system --variable=bot_config --default="Not_found")
export BOT_CONFIG=$(eval echo $INI_BOT_CONFIG)

INI_BOT_TARGET=$($INI_READER --ini=$BETFAIR_INI_FILE --section=system --variable=bot_target --default="Not_found")
export BOT_TARGET=$(eval echo $INI_BOT_TARGET)

INI_BOT_SOURCE=$($INI_READER --ini=$BETFAIR_INI_FILE --section=system --variable=bot_source --default="Not_found")
export BOT_SOURCE=$(eval echo $INI_BOT_SOURCE)

INI_BOT_SCRIPT=$($INI_READER --ini=$BETFAIR_INI_FILE --section=system --variable=bot_script --default="Not_found")
export BOT_SCRIPT=$(eval echo $INI_BOT_SCRIPT)


INI_BOT_DATABASE_NAME=$($INI_READER --ini=$LOGIN_INI_FILE --section=database --variable=name --default="Not_found")
export BOT_DATABASE_NAME=$(eval echo $INI_BOT_DATABASE_NAME)

INI_BOT_DATABASE_HOSTNAME=$($INI_READER --ini=$LOGIN_INI_FILE --section=database --variable=host --default="Not_found")
export BOT_DATABASE_HOSTNAME=$(eval echo $INI_BOT_DATABASE_HOSTNAME)

INI_BOT_DATABASE_USERNAME=$($INI_READER --ini=$LOGIN_INI_FILE --section=database --variable=username --default="Not_found")
export BOT_DATABASE_USERNAME=$(eval echo $INI_BOT_DATABASE_USERNAME)

INI_BOT_DATABASE_PASSWORD=$($INI_READER --ini=$LOGIN_INI_FILE --section=database --variable=password --default="Not_found")
export BOT_DATABASE_PASSWORD=$(eval echo $INI_BOT_DATABASE_PASSWORD)
