#!/usr/bin/env python
import os
import sys
#from asyncproc import Process
import subprocess
import ConfigParser
from time import sleep, time


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
    
    def start_processes(self) :
        for section in self.section_list :
            run = self.config.getboolean(section,'run')
            name = self.config.get(section,'name')
            the_type = self.config.get(section,'type')
#            print 'section', section   
#            print 'name', name
#            print 'run', run
#            print 'type', the_type
#            print "----------------"
#            print
            if run :
                already_running = False
                for proc in self.process_list :
                    if proc[1] == name :
                        already_running = True
                if not already_running :
                    print 'start', name
                    args = []
                    args.append('/opt/local/bin/python')
                    args.append(name)
                    my_process = subprocess.Popen(args)  
                    tmp_tuple = (my_process, name, the_type, section)
                    self.process_list.append(tmp_tuple)

    ##############################################

    def check_is_active(self, proc) :
        tmp_tuple = None
        for proc_tuple in self.process_list :
            if proc_tuple[0] == proc :
                tmp_tuple = proc_tuple
                break
        
        if tmp_tuple is not None :
            logfile = 'logs/' + tmp_tuple[3] + '.log'  
            t = os.path.getmtime(logfile)
            #if updated within 2 minutes. gmtime(0) is epoch of now()
            return int(time()) - t < 120
        else :
            return False      
    
    ###########################################

    
    def process_is_alive(self, process) :
        result = process.poll()
        return result is None 
    ##############################################

    def check_processes(self) :
        list_of_procs_to_remove = []
        for proc_tuple in self.process_list :
            print proc_tuple
            proc = proc_tuple[0]
            if self.process_is_alive(proc) :
                if not self.check_is_active(proc):
                    proc.terminate()
                    print 'will remove', proc
                    list_of_procs_to_remove.append(proc)
            else :
                print 'will remove', proc
                list_of_procs_to_remove.append(proc)

        tmp_process_list = [i for i in self.process_list if i[0] \
                            not in list_of_procs_to_remove]
                            
        self.process_list = tmp_process_list
    ##############################################


###############################
#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)



daemon = BetfairDaemon()
daemon.read_config()

daemon.start_processes()



while True :
    print "sleep 10"
    sleep(10)

    daemon.check_processes()
    daemon.start_processes()





