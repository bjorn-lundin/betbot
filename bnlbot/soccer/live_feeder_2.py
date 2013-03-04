# -*- coding: iso-8859-1 -*- 
from time import sleep, time
import datetime
import psycopg2
import urllib2
import ssl
import xml.etree.ElementTree as etree 
from xml.etree.ElementTree import XMLParser
import os
import sys
import socket
import subprocess
import signal
import logging.handlers
    
from db import Db
    
    
class Alarm(Exception):
    pass

def alarm_handler(signum, frame):
    raise Alarm    
    
###########################################################                    

class Game(object):
###########################################################
    def __init__(self, line, conn):
        

        self.conn = conn
        self.id = None
        self.kickoff = None
        self.home_team_id = None
        self.away_team_id = None
        self.home_team = None
        self.away_team = None
        self.time_in_game = None
        self.home_goals = None
        self.away_goals = None
        self.found = False
        """treat a line"""
        # [FT|HT|0-120] | 'Football' [#] home_team | [home_score-away_score] | away_team 'Football'
#        print '|' + line + '|'
#        print 'len(line)', len(line)
        if len(line) == 0:
            return
        
        if len(line) >= 2 and line[0:2] == 'HT' :
#            print 'Halftime', '|' + line + '|'
            self.time_in_game = 'HT'

            
        elif len(line) >= 2 and line[0:2] == 'FT' :
#            print 'Fulltime', '|' + line + '|'
            self.time_in_game = 'FT'
        elif len(line) >= 3 and line[0:3] == 'ATE' :
#            print 'Extratime', '|' + line + '|'
            self.time_in_game = 'ATE'
            
        elif len(line) >= 3 and  line[2] == ':' :
 #           print 'Not started', '|' + line + '|'
            self.time_in_game = 'NS'
            
        elif len(line) >= 10 and line.find('Yellowcard') > -1 :
 #           print 'Yellowcard', '|' + line + '|'
            return
        elif len(line) >= 7 and line.find('Redcard') > -1 :
 #           print 'Redcard', '|' + line + '|'
            return
        elif len(line) >= 4 and line.find('Goal') > -1 :
#            print 'Goal', '|' + line + '|'
            return
        elif len(line) >= 6 and line.find('Postp.') > -1 :
#            print 'Postponed', '|' + line + '|'
            return
        elif len(line) >= 4 and line.find('Pen.') > -1 :
#            print 'Postponed', '|' + line + '|'
            return
        elif len(line) >= 5 and line.find('Aban.') > -1 :
#            print 'Postponed', '|' + line + '|'
            return
        elif len(line) >= 2 and line.find('WO') > -1 :
#            print 'Walk Over', '|' + line + '|'
            return
            
        else :
            try :
                if line[3] == ' ' :
                    dummy = int(line[0:3])
                elif line[2] == ' ' :
                    dummy = int(line[0:2])
                elif line[1] == ' ' :
                    dummy = int(line[0:1])
                else :
                    pass    
                    return
                if dummy :        
                    self.time_in_game = dummy

            except : 
                pass
                return
            
        # [FT|HT|0-120]  'Football' [#] home_team  [home_score-away_score] away_team 'Football'
        #now parse the line. We have the time, and the line is a valid game
        #the home_team is between ] and [
        
        self.found = True
        
        line = line.replace("Football",'|')
        line = line.replace("Football",'|')
        line = line.replace("[",'|')
        line = line.replace("]",'|')

        keys = ['time_in_game', 'home_team', 'score', 'away_team','dummy']
        vals = line.split("|")
        temp = dict(zip(keys, vals))
        
	
	if  'home_team' in temp.keys() :
            self.home_team = temp['home_team'].strip().lower()
	else:
            self.home_team = ""
		
	if  'away_team' in temp.keys()  :
            self.away_team = temp['away_team'].strip().lower()
	else:
            self.away_team = ""
	    
        if  'score' in temp.keys()   :
            scores = temp["score"].split('-')
            self.home_goals = scores[0]
            self.away_goals = scores[1]
	else:
            scores = ""
           
            self.away_goals = -1

        if self.home_goals == "" : 
            self.home_goals = -2
        if self.away_goals == "" : 
            self.away_goals = -2

        # see if we have the teams in team aliases
        cur2 = self.conn.cursor()
        cur2.execute("select TEAM_ID from TEAM_ALIASES \
                      where TEAM_ALIAS = %s", (self.home_team,))
        row = cur2.fetchone()
        rc = cur2.rowcount
        cur2.close()

        if rc == 1 :
            self.home_team_id = row[0]
        else :
            log.warning( self.home_team.decode("iso-8859-1") + ' is missing in TEAM_ALIASES')
            cur20 = self.conn.cursor()
            cur20.execute("SAVEPOINT A")
            cur20.close()
            try  :
                cur21 = self.conn.cursor()
                cur21.execute("insert into UNIDENTIFIED_TEAMS \
                             (TEAM_NAME,COUNTRY_CODE) values (%s,%s)",
                             (self.home_team, 'UNK'))
                cur21.close()
            except psycopg2.IntegrityError:
                cur22 = self.conn.cursor()
                cur22.execute("ROLLBACK TO SAVEPOINT A" )
                cur22.close()
        
        
        
        cur3 = self.conn.cursor()
        cur3.execute("select TEAM_ID from TEAM_ALIASES \
                      where TEAM_ALIAS = %s", (self.away_team,))
        row = cur3.fetchone()
        rc = cur3.rowcount
        cur3.close()
        
        if rc == 1 :
            self.away_team_id = row[0] 
        else :
            log.warning( self.away_team.decode("iso-8859-1") + ' is missing in TEAM_ALIASES')
            cur10 = self.conn.cursor()
            cur10.execute("SAVEPOINT A")
            cur10.close()
            try  :
                cur11 = self.conn.cursor()
                cur11.execute("insert into UNIDENTIFIED_TEAMS \
                             (TEAM_NAME,COUNTRY_CODE) values (%s,%s)",
                             (self.away_team, 'UNK'))
                cur11.close()
            except psycopg2.IntegrityError:
                cur12 = self.conn.cursor()
                cur12.execute("ROLLBACK TO SAVEPOINT A" )
                cur12.close()
            
            
            

        # now ,get the match id
        cur4 = self.conn.cursor()
        cur4.execute("select XML_SOCCER_ID from GAMES \
                      where HOME_TEAM_ID = %s and AWAY_TEAM_ID = %s", 
                      (self.home_team_id,self.away_team_id))
        row = cur4.fetchone()
        if cur4.rowcount == 1 :
            self.id = row[0]
        else :
            if self.home_team and self.away_team :
                log.warning( self.home_team.decode("iso-8859-1") + ', ' + self.away_team.decode("iso-8859-1") + ' are missing in GAMES')
        cur4.close()


    #############################################################   
    def print_me(self): 
        print 'id', self.id  
        print 'kickoff', self.kickoff 
        print 'home_team_id', self.home_team_id
        print 'away_team_id', self.away_team_id
        print 'home_team', self.home_team.decode("iso-8859-1")
        print 'away_team', self.away_team.decode("iso-8859-1")
        print 'time_in_game', self.time_in_game
        print 'home_goals', self.home_goals
        print 'away_goals', self.away_goals
    ################################################################    
    def print_me_nice(self): 
        print 'home_team:', self.home_team.decode("iso-8859-1"), \
              'away_team:', self.away_team.decode("iso-8859-1"), \
              'time_in_game:', self.time_in_game, \
              'home_goals:', self.home_goals, \
              'away_goals:', self.away_goals, \
              'home_team_id:', self.home_team_id, \
              'away_team_id:', self.away_team_id
    ################################################################
    def print_info(self) :
        log.info( 'info ' + self.info)
    ###############################################################

    def update_db(self):
        cur = self.conn.cursor()
        cur.execute("select * from GAMES where HOME_TEAM_ID = %s \
                     and AWAY_TEAM_ID = %s", \
                     (self.home_team_id, self.away_team_id))
                     
        if self.home_team_id is None :
            return
        if self.away_team_id is None :
            return
        if self.home_goals == '?' :
            self.home_goals = 0
        if self.away_goals == '?' :
            self.away_goals = 0
                
        if cur.rowcount == 0 :
            log.info('insert Game ' + str(self.id) + ' ' + self.home_team.decode("iso-8859-1") + ' - ' + self.away_team.decode("iso-8859-1"))
            cur.execute("insert into GAMES ( \
                        KICKOFF, HOME_TEAM_ID, \
                        AWAY_TEAM_ID, TIME_IN_GAME, \
                        HOME_GOALS, AWAY_GOALS ) \
                        values \
                        (%s,%s,%s,%s,%s,%s)", \
             ( self.kickoff, self.home_team_id, \
              self.away_team_id, self.time_in_game, \
              self.home_goals, self.away_goals))
        else : 
            log.info('update Game ' + str(self.id) + ' ' + self.home_team.decode("iso-8859-1") + ' - ' + \
                       self.away_team.decode("iso-8859-1") + '   ' + str(self.time_in_game) + \
                  '    [' + str(self.home_goals) + '-' + str(self.away_goals) + ']')
            cur.execute("update GAMES \
                         set TIME_IN_GAME = %s , \
                         HOME_GOALS = %s , AWAY_GOALS = %s \
                         where XML_SOCCER_ID = %s ", \
             (self.time_in_game, self.home_goals, \
              self.away_goals, self.id))
             
        cur2 = self.conn.cursor()
        cur2.execute("insert into GAMES_STATS ( \
                        XML_SOCCER_ID, KICKOFF, HOME_TEAM_ID, \
                        AWAY_TEAM_ID, TIME_IN_GAME, \
                        HOME_GOALS, AWAY_GOALS ) \
                        values \
                        (%s,%s,%s,%s,%s,%s,%s)", \
             (self.id, self.kickoff, self.home_team_id, \
              self.away_team_id, self.time_in_game, \
              self.home_goals, self.away_goals))
        cur.close()
        cur2.close()
        
        #####################################################






#########################################################################

class Live_Feeder(object):
    """get xml feeds"""

    NETWORK_FAILURE_DELAY = 60.0
    URL_LIVE_SCORE = "http://www.goalserve.com/updaters/soccerupdate.aspx"
    SLEEP_TIME_BETWEEN_TURNS = 1
    conn = None
    get_all_teams = True
    lines = None
    
    def __init__(self, log):
        rps = 1/31.0 # Refreshes Per Second
        self.no_session = True
        self.throttle = {'rps': 1.0 / rps, 'next_req': time()}
        db = Db() 
        self.conn = db.conn 
        self.log = log
    ####################################
        
        
    def get_feed(self): 
        """get the feed"""

        signal.signal(signal.SIGALRM, alarm_handler)
        signal.alarm(60)  # 1 minute
        
        self.LAST_TIMESTAMP = str(time())
        try : 
            self.my_list = subprocess.check_output("lynx \
                                                -dump \
                                                --image_links=0 \
                                                --hiddenlinks=ignore \
                                                --notitle \
                                                --nolist  " + \
                                                self.URL_LIVE_SCORE + \
                                                '?tmp=' + \
                                                self.LAST_TIMESTAMP, \
                                                shell=True)
        except subprocess.CalledProcessError :
            signal.alarm(0)
            raise             
                                                
        #reset the alarm
        signal.alarm(0)
        self.lines = self.my_list.split("\n")
        
    def do_throttle(self):
        """return only when it is safe to send another data request"""
        log.info('Wait for ' + str(self.SLEEP_TIME_BETWEEN_TURNS) + ' seconds')
        sleep(self.SLEEP_TIME_BETWEEN_TURNS)       
        
    def start(self):
        """start the main loop"""
        for line in self.lines :
                stripped_line = line.strip()
                if stripped_line.find('Referenser') > -1 :
                        break
                my_game = Game(stripped_line, self.conn)
                if my_game.found :
                    my_game.update_db()
                    
        self.conn.commit()    
###################################################################

#make print flush now!
#sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
FH = logging.handlers.RotatingFileHandler(
    'logs/' + __file__.split('.')[0] +'.log',
    mode = 'a',
    maxBytes = 500000,
    backupCount = 10,
    encoding = 'iso-8859-1',
    delay = False
) 
FH.setLevel(logging.DEBUG)
FORMATTER = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
FH.setFormatter(FORMATTER)
log.addHandler(FH)
log.info('Starting application')



feed = Live_Feeder(log)


while True:
    log.info( '------------------ LOOP START -----------------------')
    try:
        feed.get_feed()
        feed.start() 
    except subprocess.CalledProcessError as ex:
        log.error( 'Lost network ? . Retry in ' + str(feed.NETWORK_FAILURE_DELAY) + 'seconds')
        sleep (feed.NETWORK_FAILURE_DELAY)

    except Alarm:
        log.error( "Oops, feed took too long, try again next turn!")

    except KeyboardInterrupt :
        break
        
    log.info( '------------------ LOOP STOP -----------------------')
    feed.do_throttle()

# main loop ended...
log.info('Ending application')
logging.shutdown()

