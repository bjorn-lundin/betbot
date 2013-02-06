#!/usr/bin/env python
import os
import sys
#from asyncproc import Process
import subprocess
import ConfigParser
from time import sleep


class BetfairDaemon(object) :
        
    section_list = None
    config = None 
    process_list = []

    ##############################################    
    def read_config(self) :
        self.config = ConfigParser.ConfigParser()
        self.config.read('betfair_daemon.ini')
        self.section_list = self.config.sections()
    ##############################################
    
    def process_is_alive(self, process) :
        result = process.poll()
        return result is None 
    ##############################################

    def check_processes(self) :
        list_of_procs_to_remove = []
        for proc in self.process_list :
            if self.process_is_alive(proc) :
                if not self.check_is_active(proc):
                    proc.terminate()
                    list_of_procs_to_remove.append(proc)
            else :
                list_of_procs_to_remove.append(proc)

        tmp_process_list = [i for i in self.process_list if i \
                            not in list_of_procs_to_remove]
                            
        self.process_list = tmp_process_list
    ##############################################


###############################
#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)



daemon = BetfairDaemon()
daemon.read_config()

for section in daemon.section_list :
    run = daemon.config.getboolean(section,'run')
    name = daemon.config.get(section,'name')
    the_type = daemon.config.get(section,'type')
    print 'section', section   
    print 'name', name
    print 'run', run
    print 'type', the_type
    print "----------------"
    print
    if run:
        args = []
        args.append('/usr/bin/python')
        args.append(name)
#        print args
        my_process = subprocess.Popen(args)  
        daemon.process_list.append(my_process)


for proc in daemon.process_list :
    print 'proc', proc


print "sleep 10"
sleep(10)


for proc in daemon.process_list :
    print "check if alive"
    print proc.poll()

    print "kill if alive"
    print proc.terminate()

print "done"



#        self.DELAY_BETWEEN_TURNS_BAD_FUNDING = float(config.get('Global', 'delay_between_turns_bad_funding'))
#        self.DELAY_BETWEEN_TURNS_NO_MARKETS  = float(config.get('Global', 'delay_between_turns_no_markets'))
#        self.DELAY_BETWEEN_TURNS             = float(config.get('Global', 'delay_between_turns'))
#        self.NETWORK_FAILURE_DELAY           = float(config.get('Global', 'network_failure_delay'))



