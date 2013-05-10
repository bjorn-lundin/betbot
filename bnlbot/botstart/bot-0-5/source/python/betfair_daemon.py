#!/usr/bin/env python
import os
import sys
#from asyncproc import Process
import subprocess
import ConfigParser
from time import sleep, time
import datetime

class BetfairDaemon(object) :

    section_list = None
    config = None
    process_list = []

    ##############################################
    def read_config(self) :
        self.config = ConfigParser.ConfigParser()
        cfgfile = os.path.join(os.environ['BOT_START'], 'user', os.environ['BOT_USER'],'betfair_daemon.ini')
        print "reading config from", cfgfile
        self.config.read(cfgfile)
        self.section_list = self.config.sections()
    ##############################################

    def start_processes(self) :
        startdir = os.path.join(os.environ['BOT_SOURCE'], 'python')

        for section in self.section_list :
            run = self.config.getboolean(section,'run')
            name = self.config.get(section,'name')
            bet_name = self.config.get(section,'bet_name')
            the_type = self.config.get(section,'type')
#            print 'section', section
#            print 'name', name
#            print 'run', run
#            print 'type', the_type
#            print "----------------"
#            print
            if run :
#                print 'start', name
                already_running = False
                for proc in self.process_list :
                    if proc[1] == name :
                        already_running = True

 #               print 'already_running', name, already_running

                if not already_running :
                    print str(datetime.datetime.now()), 'start', name
                    args = []
                    #testa pa platform har, mac = /opt/local/bin/python
                    args.append('/usr/bin/python')
                    args.append(os.path.join(startdir,name))
                    args.append('--user=' + os.environ['BOT_USER'])
                    if the_type == 'bot' :
                        args.append('--bet_name=' + bet_name)
                    my_process = subprocess.Popen(args)
                    tmp_tuple = (my_process, name, the_type, section, bet_name)
                    self.process_list.append(tmp_tuple)
                    print tmp_tuple

    ##############################################

    def is_active(self, proc) :
        tmp_tuple = None
        bet_name = None
        section = None
        the_type = None
        for proc_tuple in self.process_list :
            if proc_tuple[0] == proc :
                tmp_tuple = proc_tuple
                bet_name = proc_tuple[4]
                the_type = proc_tuple[2]
                section = proc_tuple[3]  
                break

        

        if tmp_tuple is not None :
            logdir = os.path.join(os.environ['BOT_START'], 'user', os.environ['BOT_USER'])
            if the_type == 'bot' :
                logfile = os.path.join(logdir, 'log', bet_name.lower() + '.log')
            else : 
                logfile = os.path.join(logdir, 'log', section.lower() + '.log')

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
#            print proc_tuple
            proc = proc_tuple[0]
            if self.process_is_alive(proc) :
                if not self.is_active(proc):
                    proc.terminate()
                    print str(datetime.datetime.now()), 'will remove', proc
                    list_of_procs_to_remove.append(proc)
            else :
                print str(datetime.datetime.now()), 'will remove', proc
                list_of_procs_to_remove.append(proc)

        tmp_process_list = [i for i in self.process_list if i[0] \
                            not in list_of_procs_to_remove]

        self.process_list = tmp_process_list
    ##############################################


    def kill_processes(self) :
        for proc_tuple in self.process_list :
            proc = proc_tuple[0]
            print str(datetime.datetime.now()), 'will kill', proc
            proc.terminate()
            print str(datetime.datetime.now()), 'killed', proc
    ##############################################



###############################
#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
sys.stderr = os.fdopen(sys.stderr.fileno(), 'w', 0)

rundir  = os.path.join(os.environ['BOT_START'], 'user', os.environ['BOT_USER'])
runfile = os.path.join(rundir, 'stop_daemon.dat')

#kill file at startup, honor it when running
if os.path.isfile(runfile):
    os.remove(runfile)

daemon = BetfairDaemon()
daemon.read_config()

daemon.start_processes()



while True :
    if os.path.isfile(runfile):
        print "found stopfile, exiting", runfile
        daemon.kill_processes()
        break

#    print str(datetime.datetime.now()), "sleep 3"
    sleep(3)

    daemon.check_processes()
    daemon.start_processes()


