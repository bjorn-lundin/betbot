# coding=iso-8859-15
from time import sleep, time
import datetime
import psycopg2
import urllib2
import ssl
import xml.etree.ElementTree as etree 
import os
import sys
import socket
#<Team>
#  <Team_Id>29</Team_Id>
#  <Name>Watford</Name>
#  <Country>Scotland</Country>
#  <Stadium>Vicarage Road</Stadium>
#  <HomePageURL>http://www.watfordfc.com</HomePageURL>
#  <WIKILink>http://en.wikipedia.org/wiki/Watford_F.C.</WIKILink>
#</Team> 
 
class Team(object):
    def __init__(self, root):
        self.Id = None
        self.Name = None
        self.Country = None
        self.Stadium = None
        self.Home_Page_URL = None
        self.WIKI_Link = None

        for elem in root :
#            print 'elem', elem
            if   elem.tag == 'Team_Id' :
                self.Id = elem.text
            elif elem.tag == 'Name' :
                self.Name = elem.text
            elif elem.tag == 'Country' :
                self.Country = elem.text
            elif elem.tag == 'Stadium' :
                self.Stadium = elem.text
            elif elem.tag == 'HomePageURL' :
                self.Home_Page_URL = elem.text
            elif elem.tag == 'WIKILink' :
                self.WIKI_Link = elem.text

    def print_me(self): 
        print 'Id', self.Id  
        print 'Name', self.Name 
        print 'Country', self.Country
        print 'Stadium', self.Stadium
        print 'HomePageURL', self.Home_Page_URL
        print 'WIKILink', self.WIKI_Link
        
    def update_db(self, conn):
        cur = conn.cursor()
        cur.execute("select * from TEAMS where TEAM_ID="+ self.Id)
        if cur.rowcount == 0 :
            print 'insert team', self.Id
            self.print_me()
            cur.execute("insert into TEAMS ( \
                        TEAM_ID, TEAM_NAME, COUNTRY, STADIUM, HOME_PAGE_URL, WIKI_LINK ) \
                        values \
                        (%s,%s,%s,%s,%s,%s)", \
             (self.Id, self.Name, self.Country, self.Stadium, \
              self.Home_Page_URL, self.WIKI_Link))
             
        cur.close()
    
###########################################################                    

class Game(object):
###########################################################
    def __init__(self, root):
        self.Xml_Soccer_Id = None
        self.Kickoff = None
        self.Home_Team_Id = None
        self.Away_Team_Id = None
        self.Time_In_Game = None
        self.Home_Goals = None
        self.Away_Goals = None
        self.Found = False
        self.Info = None
        self.tag_count = 0

        for elem in root:
            self.tag_count +=1
            if   elem.tag == 'Id' :
                self.Xml_Soccer_Id = elem.text
                self.Found = True
            elif elem.tag == 'Date' :
                self.Kickoff = elem.text
            elif elem.tag == 'HomeTeam_Id' :
                self.Home_Team_Id = elem.text
            elif elem.tag == 'AwayTeam_Id' :
                self.Away_Team_Id = elem.text
            elif elem.tag == 'Time' :
                #59 mins = 59', loose the pesky "'"
                self.Time_In_Game = elem.text.replace("'","")
            elif elem.tag == 'HomeGoals' :
                self.Home_Goals = elem.text
            elif elem.tag == 'AwayGoals' :
                self.Away_Goals = elem.text
            elif elem.tag == 'AccountInformation' :
                self.Info = elem.text

        if self.tag_count == 0 and root.tag == 'AccountInformation' :
           self.Info = root.text
        if self.tag_count == 0 and root.tag == 'XMLSOCCER.COM' :
           self.Info = root.text



    #############################################################   
    def print_me(self): 
        print 'Xml_Soccer_Id', self.Xml_Soccer_Id  
        print 'Kickoff', self.Kickoff 
        print 'Home_Team_Id', self.Home_Team_Id
        print 'Away_Team_Id', self.Away_Team_Id
        print 'Time_In_Game', self.Time_In_Game
        print 'Home_Goals', self.Home_Goals
        print 'Away_Goals', self.Away_Goals
    ################################################################    
    def print_me_nice(self): 
        print 'Home_Team_Id:', self.Home_Team_Id, \
              'Away_Team_Id:', self.Away_Team_Id, \
              'Time_In_Game:', self.Time_In_Game, \
              'Home_Goals:', self.Home_Goals, \
              'Away_Goals:', self.Away_Goals
    ################################################################
    def print_info(self) :
        print 'Info', self.Info
    ###############################################################

    def update_db(self, conn):
        cur = conn.cursor()
        cur.execute("select * from GAMES where XML_SOCCER_ID = %s", \
                     (self.Xml_Soccer_Id,))
        if cur.rowcount == 0 :
            print 'insert Game', self.Xml_Soccer_Id
            cur.execute("insert into GAMES ( \
                        XML_SOCCER_ID, KICKOFF, HOME_TEAM_ID, \
                        AWAY_TEAM_ID, TIME_IN_GAME, \
                        HOME_GOALS, AWAY_GOALS ) \
                        values \
                        (%s,%s,%s,%s,%s,%s,%s)", \
             (self.Xml_Soccer_Id, self.Kickoff, self.Home_Team_Id, \
              self.Away_Team_Id, self.Time_In_Game, \
              self.Home_Goals, self.Away_Goals))
        else : 
            print 'update Game', self.Xml_Soccer_Id
            cur.execute("update GAMES \
                         set KICKOFF = %s, TIME_IN_GAME = %s, \
                         HOME_GOALS = %s, AWAY_GOALS = %s \
                         where XML_SOCCER_ID = %s ", \
             (self.Kickoff, self.Time_In_Game, self.Home_Goals, \
              self.Away_Goals, self.Xml_Soccer_Id))
             
        print 'insert Game into stats', self.Xml_Soccer_Id
        cur2 = conn.cursor()
        cur2.execute("insert into GAMES_STATS ( \
                        XML_SOCCER_ID, KICKOFF, HOME_TEAM_ID, \
                        AWAY_TEAM_ID, TIME_IN_GAME, \
                        HOME_GOALS, AWAY_GOALS ) \
                        values \
                        (%s,%s,%s,%s,%s,%s,%s)", \
             (self.Xml_Soccer_Id, self.Kickoff, self.Home_Team_Id, \
              self.Away_Team_Id, self.Time_In_Game, \
              self.Home_Goals, self.Away_Goals))
        cur.close()
        cur2.close()
        
        #####################################################

#########################################################################

class Live_Feeder(object):
    """get xml feeds"""

    NETWORK_FAILURE_DELAY = 60.0
    API_KEY = "URDMKQYKXHCSBZISMRQUICHZUFQBUZQIPBWGSTCNQNXBXGPIGB"
    URL_ALL_TEAMS = "http://www.xmlsoccer.com/FootballDataDemo.asmx/GetAllTeams?ApiKey=" + API_KEY
    URL_LIVE_SCORE = "http://www.xmlsoccer.com/FootballDataDemo.asmx/GetLiveScore?ApiKey=" + API_KEY
    
    conn = None
    get_all_teams = True
    
    def __init__(self):
        rps = 1/31.0 # Refreshes Per Second
        self.no_session = True
        self.throttle = {'rps': 1.0 / rps, 'next_req': time()}

    def get_feed(self):
        """get the feed"""
        # return the root element (XMLSOCCER.COM)
        response = urllib2.urlopen(self.URL_LIVE_SCORE)
        xmlstring = response.read()
        return etree.fromstring(xmlstring)        

    def get_teams(self):
        """get the teams"""
        # return the root element (XMLSOCCER.COM)
        response = urllib2.urlopen(self.URL_ALL_TEAMS)
        xmlstring = response.read()
        return etree.fromstring(xmlstring)        
        
    def do_throttle(self):
        """return only when it is safe to send another data request"""
#        wait = self.throttle['next_req'] - time()
#        if wait > 0: 
        print 'Wait for', 32, 'seconds'
        sleep(32)
#        self.throttle['next_req'] = time() + self.throttle['rps']
        
    def start(self):
        """start the main loop"""
        if self.get_all_teams :
            teamroot = self.get_teams()
#            print 'teamroot', teamroot
            for t in teamroot :
                print(t)
                team = Team(t)
                team.print_me()
                if team.Id:
                    team.update_db(self.conn)
            self.get_all_teams = False
            
            
        gameroot = self.get_feed()
#        print 'gameroot', gameroot
        elem_count = 0
        for g in gameroot : 
            elem_count +=1

        if elem_count:
            for g in gameroot :
#                print(g)
                liveGame = Game(g)
                if liveGame.Found  :
                    liveGame.print_me_nice()
                    liveGame.update_db(self.conn)
        else:
            liveGame = Game(gameroot)  
            liveGame.print_info()
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
feed.do_throttle()
while True:
    print '------------------ loop start:', datetime.datetime.now(), '-----------------------'
    try:
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
