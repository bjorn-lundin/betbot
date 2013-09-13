#!/bin/bash


CHOICE_FILE=/tmp/project.bash_choice.$$
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
            *      ) . $BOT_START/bot.bash -u $CHOICE -ano_action
        esac 
    ;;
esac
 
rm -f $CHOICE_FILE
#now set the enviroment from inifiles

export BOT_HOME=$BOT_START/user/$BOT_USER
cd $BOT_HOME

dialog --menu "Start/stop system for user $CHOICE" 15 65 8 \
       quit    "Quit"  \
       restart   "Restart" \
       stop    "Stop"                                       2> $CHOICE_FILE
retval=$?
case $retval in
  0) # OK
        CHOICE=$(cat $CHOICE_FILE)  ;# Get the choice from file
        case $CHOICE in
            quit    ) clear && echo "Did nothing, just set some env vars" && env | grep BOT ;;
            restart ) clear && stop_all_bots ;;
            stop    ) clear && echo "use sudo service bot stop " ;;
        esac
  ;;
esac

rm -f $CHOICE_FILE


