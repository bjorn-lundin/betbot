#!/bin/bash


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

export BOT_USER

#BOT_START is set in .bashrc
export BOT_HOME=$BOT_START/user/$BOT_USER
export BOT_ROOT=$BOT_START/bot-0-9
export BOT_TARGET=$BOT_ROOT/target
export BOT_CONFIG=$BOT_ROOT/config
export BOT_SCRIPT=$BOT_ROOT/script
export BOT_SOURCE=$BOT_ROOT/source

