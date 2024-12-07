#!/bin/bash

if [ "x$1" == "x" ] ; then
  echo "FAIL : no user passed as argumet!"
  return 1
fi

BOT_USER=$1
export BOT_USER

#BOT_START is set in .bashrc
#export BOT_ROOT=/usr2/betbot
export BOT_HOME=$BOT_ROOT/user/$BOT_USER
export BOT_TARGET=$BOT_ROOT/target
export BOT_CONFIG=$BOT_ROOT/config
export BOT_SCRIPT=$BOT_ROOT/script
export BOT_SOURCE=$BOT_ROOT/source
export BOT_DATA=$BOT_ROOT/data
export BOT_DOC=$BOT_ROOT/docbook
export BOT_HISTORY=$BOT_ROOT/history
export REPO_ENGINE=$BOT_TARGET/bin/repo

HOSTNAME=$(hostname)
case $HOSTNAME in
  pibetbot)
    export BOT_MACHINE_ROLE=PROD
    export BOT_XML_SOURCE=LIB
    export BOT_MODE=real
    ;;

  ibmtc)
    export BOT_MACHINE_ROLE=PROD
    export BOT_XML_SOURCE=GNAT
    export BOT_MODE=real
    ;;

  iMac)
    export BOT_MACHINE_ROLE=SIM
    export BOT_XML_SOURCE=GNAT
    export BOT_MODE=real
    ;;

  *)
    export BOT_MACHINE_ROLE=$HOSTNAME
    export BOT_MODE=simulation
    ;;
esac


#dialog --msgbox "run with BOT_USER= $BOT_USER"  7 45

