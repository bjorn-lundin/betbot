# coding=iso-8859-15
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
                    #print '???', '|' + line + '|'                  
                if dummy :        
#                    print 'game started', dummy, 'minutes ago', '|' + line + '|'
                    self.time_in_game = dummy

            except : 
                pass
                return
#                print 'failed to get time in game', line
            
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
        
        self.home_team = temp['home_team'].strip().lower()
        self.away_team = temp['away_team'].strip().lower()
        scores = temp["score"].split('-')
        self.home_goals = scores[0]
        self.away_goals = scores[1]


        # see if we have the teams in team aliases
        cur2 = self.conn.cursor()
        cur2.execute("select TEAM_ID from TEAM_ALIASES \
                      where TEAM_ALIAS = %s", (self.home_team,))
        row = cur2.fetchone()
        if cur2.rowcount == 1 :
            self.home_team_id = row[0]
        else :
            print self.home_team, 'is missing in TEAM_ALIASES'
        cur2.close()
        
        cur3 = self.conn.cursor()
        cur3.execute("select TEAM_ID from TEAM_ALIASES \
                      where TEAM_ALIAS = %s", (self.away_team,))
        row = cur3.fetchone()
        if cur3.rowcount == 1 :
            self.away_team_id = row[0] 
        else :
            print self.away_team, 'is missing in TEAM_ALIASES'
        cur3.close()

        # now ,get the match id
        cur4 = self.conn.cursor()
        cur4.execute("select XML_SOCCER_ID from GAMES \
                      where HOME_TEAM_ID = %s and AWAY_TEAM_ID = %s", 
                      (self.home_team_id,self.away_team_id))
        row = cur4.fetchone()
        if cur4.rowcount == 1 :
            self.id = row[0]
        else :
            print self.home_team, 'is missing in TEAM_ALIASES'
        cur4.close()




    #############################################################   
    def print_me(self): 
        print 'id', self.id  
        print 'kickoff', self.kickoff 
        print 'home_team_id', self.home_team_id
        print 'away_team_id', self.away_team_id
        print 'home_team', self.home_team
        print 'away_team', self.away_team
        print 'time_in_game', self.time_in_game
        print 'home_goals', self.home_goals
        print 'away_goals', self.away_goals
    ################################################################    
    def print_me_nice(self): 
        print 'home_team:', self.home_team, \
              'away_team:', self.away_team, \
              'time_in_game:', self.time_in_game, \
              'home_goals:', self.home_goals, \
              'away_goals:', self.away_goals, \
              'home_team_id:', self.home_team_id, \
              'away_team_id:', self.away_team_id
    ################################################################
    def print_info(self) :
        print 'info', self.info
    ###############################################################

    def update_db(self):
        cur = self.conn.cursor()
        cur.execute("select * from GAMES where HOME_TEAM_ID = %s \
                     and AWAY_TEAM_ID = %s", \
                     (self.home_team_id, self.away_team_id))
        if cur.rowcount == 0 :
            print 'insert Game', self.id
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
            print 'update Game', self.id
            cur.execute("update GAMES \
                         set TIME_IN_GAME = %s , \
                         HOME_GOALS = %s , AWAY_GOALS = %s \
                         where XML_SOCCER_ID = %s ", \
             (self.time_in_game, self.home_goals, \
              self.away_goals, self.id))
             
        print 'insert Game into stats', self.id
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
    
    conn = None
    get_all_teams = True
    lines = None
    
    def __init__(self):
        rps = 1/31.0 # Refreshes Per Second
        self.no_session = True
        self.throttle = {'rps': 1.0 / rps, 'next_req': time()}

    def get_feed(self): 
        """get the feed"""
        self.LAST_TIMESTAMP = str(time())
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
        self.lines = self.my_list.split("\n")
        
    def do_throttle(self):
        """return only when it is safe to send another data request"""
        print 'Wait for', 15, 'seconds'
        sleep(15)       
        
    def start(self):
        """start the main loop"""
        for line in self.lines :
                stripped_line = line.strip()
                if stripped_line.find('Referenser') > -1 :
                        break
                my_game = Game(stripped_line, self.conn)
                if my_game.found :
                    my_game.print_me_nice()
                    my_game.update_db()
                    
        self.conn.commit()    
###################################################################

#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)



feed = Live_Feeder()

print 'Starting up:', datetime.datetime.now()

#bot.conn = psycopg2.connect("dbname='bnl' \
#                             user='bnl' \
#                             host='nonodev.com' \
#                             password='BettingFotboll1$'") 

feed.conn = psycopg2.connect("dbname='betting' \
                              user='bnl' \
                              host='192.168.0.24' \
                              password='None'")

while True:
    print '------------------ loop start:', datetime.datetime.now(), '-----------------------'
    try:
        feed.get_feed()
        feed.start() 
    except urllib2.URLError as ex:
        print "URLError error({0}): {1}".format(ex.errno, ex.strerror)
        print 'Lost network. Retry in', feed.NETWORK_FAILURE_DELAY, 'seconds'
        sleep (feed.NETWORK_FAILURE_DELAY) 

    except ssl.SSLError as ex:
        print "URLError error({0}): {1}".format(ex.errno, ex.strerror)
        print 'Lost network (ssl error). Retry in', feed.NETWORK_FAILURE_DELAY, 'seconds'
        sleep (feed.NETWORK_FAILURE_DELAY)

    except socket.error as ex:
        print "URLError error({0}): {1}".format(ex.errno, ex.strerror)
        print 'Lost network (socket error). Retry in', feed.NETWORK_FAILURE_DELAY, 'seconds'
        sleep (feed.NETWORK_FAILURE_DELAY)

    print '------------------ loop stop:', datetime.datetime.now(), '-----------------------'    
    feed.do_throttle()

# main loop ended...
print 'MAIN LOOP ENDED...\n---------------------------------------------'
print 'Ending:', datetime.datetime.now()


