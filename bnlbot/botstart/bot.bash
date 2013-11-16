#!/bin/bash

BOT_USER=$1

#while getopts "u:" OPT; do
##  echo "$OPT - $OPTARG"
#  case $OPT in
#    u)  BOT_USER=$OPTARG ;;
#    *)
#      echo "$0 -u user" >&2
#      exit 1
#      ;;
#  esac
#done
#dialog --msgbox "$OPT - $OPTARG"  7 45
#
#
#[ -z $OPTARG ] && echo "missing user" >&2 

export BOT_USER

#BOT_START is set in .bashrc
export BOT_HOME=$BOT_START/user/$BOT_USER
export BOT_ROOT=$BOT_START/bot-1-1
export BOT_TARGET=$BOT_ROOT/target
export BOT_CONFIG=$BOT_ROOT/config
export BOT_SCRIPT=$BOT_ROOT/script
export BOT_SOURCE=$BOT_ROOT/source
export BOT_DOC=$BOT_ROOT/docbook

#dialog --msgbox "run with BOT_USER= $BOT_USER"  7 45

