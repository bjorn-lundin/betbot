#!/bin/bash
# orig in /etc/rc.local
#su bnl --login --command "nohup /usr/bin/python3 /bnlbot/botstart/bot-1-0/source/python/login_cert_handler.py &"

#the systemd takes care about detachment and user to run it - and restarts if killed
/usr/bin/python3 /bnlbot/bnlbot/botstart/bot-1-0/source/python/login_cert_handler.py
