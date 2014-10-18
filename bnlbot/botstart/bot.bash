#!/bin/bash

BOT_USER=$1


export BOT_USER

#BOT_START is set in .bashrc
export BOT_HOME=$BOT_START/user/$BOT_USER
export BOT_ROOT=$BOT_START/bot-1-0
export BOT_TARGET=$BOT_ROOT/target
export BOT_CONFIG=$BOT_ROOT/config
export BOT_SCRIPT=$BOT_ROOT/script
export BOT_SOURCE=$BOT_ROOT/source
export BOT_DOC=$BOT_ROOT/docbook
export REPO_ENGINE=$BOT_TARGET/bin/repo


#amazon machines starts with 'ip'

HOSTNAME=$(hostname)
case $HOSTNAME in
  ip*)
    export BOT_MACHINE_ROLE=PROD
    ;;  
  new.nonodev.com)    
    export BOT_MACHINE_ROLE=PROD
    ;;
  prod*)    
    export BOT_MACHINE_ROLE=PROD
    ;;
  sebjlun*)
    export BOT_MACHINE_ROLE=SIM
    ;;
  tova)
    export BOT_MACHINE_ROLE=TEST
    ;;
  *)  
    export BOT_MACHINE_ROLE=$HOSTNAME
    ;;
esac


case $HOSTNAME in
  ip*) 
    export BOT_MODE=real
    ;;
  new.nonodev.com)    
    export BOT_MODE=real
    ;;
  prod*)    
    export BOT_MODE=real
    ;;
    *)
    export BOT_MODE=simulation
    ;;
esac


#dialog --msgbox "run with BOT_USER= $BOT_USER"  7 45

