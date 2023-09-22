#!/bin/bash

if [ "x$1" == "x" ] ; then
  echo "FAIL : no user passed as argumet!"
  return 1
fi

BOT_USER=$1
export BOT_USER

#BOT_START is set in .bashrc
export BOT_HOME=$BOT_START/user/$BOT_USER
export BOT_ROOT=$BOT_START/bot-1-0
export BOT_TARGET=$BOT_ROOT/target
export BOT_CONFIG=$BOT_ROOT/config
export BOT_SCRIPT=$BOT_ROOT/script
export BOT_SOURCE=$BOT_ROOT/source
export BOT_DATA=$BOT_ROOT/data
export BOT_DOC=$BOT_ROOT/docbook
export BOT_HISTORY=$BOT_ROOT/history
export REPO_ENGINE=$BOT_TARGET/bin/repo

#amazon machines starts with 'ip'

HOSTNAME=$(hostname)
case $HOSTNAME in
  pibetbot*)
    export BOT_MACHINE_ROLE=PROD
    export BOT_XML_SOURCE=LIB
    export BOT_GNATCOLL_SOURCE=LOCAL
    ;;
  *imac*)
    export BOT_MACHINE_ROLE=SIM
    export BOT_XML_SOURCE=GNAT
    export BOT_GNATCOLL_SOURCE=LOCAL
    ;;

  *iMac*)
    export BOT_MACHINE_ROLE=SIM
    export BOT_XML_SOURCE=GNAT
    export BOT_GNATCOLL_SOURCE=LOCAL
    export ADA_PROJECT_PATH=/usr/share/gpr:/home/bnl/betfair/betbot/bnlbot/botstart/bot-1-0/source/ada
    ;;

  *iMac.lan*)
    export BOT_MACHINE_ROLE=SIM
    export BOT_XML_SOURCE=GNAT
    export BOT_GNATCOLL_SOURCE=LOCAL
    export ADA_PROJECT_PATH=/usr/share/gpr:/home/bnl/betfair/betbot/bnlbot/botstart/bot-1-0/source/ada
    ;;

  HP-Mini*)
    export BOT_MACHINE_ROLE=PROD
    export BOT_XML_SOURCE=LOCAL
    export BOT_GNATCOLL_SOURCE=LOCAL
    ;;
  prod*)
    export BOT_MACHINE_ROLE=SIM
    export BOT_XML_SOURCE=GNAT
    export BOT_GNATCOLL_SOURCE=LOCAL
    ;;
  ip*)
    export BOT_MACHINE_ROLE=SIM
    export BOT_XML_SOURCE=GNAT
    export BOT_GNATCOLL_SOURCE=LOCAL
    ;;
  sebjlun*)
    export BOT_MACHINE_ROLE=SIM
    export BOT_XML_SOURCE=GNAT
    export BOT_GNATCOLL_SOURCE=LOCAL
    ;;
  tp*)
    export BOT_MACHINE_ROLE=SIM
    export BOT_XML_SOURCE=GNAT
    export BOT_GNATCOLL_SOURCE=LOCAL
    ;;
  raspberrypi*)
    export BOT_MACHINE_ROLE=DISPLAY
    export BOT_XML_SOURCE=LOCAL
    export BOT_GNATCOLL_SOURCE=LOCAL
    ;;
  w541)
    export BOT_MACHINE_ROLE=SIM
    export BOT_XML_SOURCE=GNAT
    export BOT_GNATCOLL_SOURCE=LOCAL
    ;;
  *)
    export BOT_MACHINE_ROLE=$HOSTNAME
    ;;
esac


case $HOSTNAME in
  ip*)
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

