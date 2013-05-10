#!/bin/bash



function do_stop {
  clear && echo "will stop system at $BOT_USER_HOME" && touch $BOT_USER_HOME/stop_daemon.dat && rm -f $BOT_USER_HOME/start_daemon.dat
  sleep 4
}

function do_start {
  echo "Will start system"
  OLD_PWD=$(pwd)
  cd $BOT_USER_HOME
  nohup python $BOT_SOURCE/python/betfair_daemon.py --user=$BOT_USER &
  touch $BOT_USER_HOME/start_daemon.dat
  cd $OLD_PWD
}


export CHOICE_FILE=/tmp/project.bash_choice.$$
dialog --menu "              Setting project variables" 15 65 8 \
                          quit     "Quit" \
                          bnl      "bnl" \
                          jmb      "jmb" \
                          mama     "mama"                        2> $CHOICE_FILE
retval=$?
case $retval in
    0)  # This is the OK button
        CHOICE=$(cat $CHOICE_FILE)  ;# Get the choice from file
        case $CHOICE in
            quit   ) clear && return;;
            *      ) clear && . $BOT_START/bot.bash -u$CHOICE -ano_action
        esac 
    ;;
esac
 
rm -f $CHOICE_FILE
#now set the enviroment from inifiles


export BOT_USER_HOME=$BOT_START/user/$BOT_USER
cd $BOT_USER_HOME

dialog --menu "Start/stop system for user $CHOICE" 15 65 8 \
       quit    "Quit"  \
       restart "Restart" \
       start   "Start" \
       stop    "Stop"                                       2> $CHOICE_FILE
retval=$?
case $retval in
  0) # OK
        CHOICE=$(cat $CHOICE_FILE)  ;# Get the choice from file
        case $CHOICE in
            restart ) clear && ps -ef | grep python && do_stop && do_start ;;
            quit    ) clear && echo "Did nothing, just set some env vars" && env | grep BOT ;;
            start   ) clear
                      if [[ -r  $BOT_USER_HOME/start_daemon.dat ]] ; then
                        echo "system already running. stop it first"  
                      else 
                        do_start
                      fi
                    ;;
            stop    ) do_stop ;;
        esac
  ;;
esac

rm -f $CHOICE_FILE


