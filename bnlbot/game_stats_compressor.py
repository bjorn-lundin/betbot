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
import signal
import logging.handlers
    
from db import Db
    
    
    
###########################################################                    

class Game_Stats_Compresssor(object):
###########################################################
    def __init__(self, log):

        db = Db() 
        self.conn = db.conn 
        self.log = log
        self.SLEEP_TIME_BETWEEN_TURNS = 30

    ###############################################################

    def treat_row(self, row):
        self.log.debug('treat ' + str(row))
        #1 - finns raden i games_stats_uniq?
        #dvs finns en rad med samma XML_SOCCER_ID,  HOME_GOALS och AWAY_GOALS?
        #nej -> insert into games_stats_uniq, delete from games_stats
        #ja  ->                               delete from games_stats_uniq
        id            = row[0]
        event_time    = row[1]
        xml_soccer_id = row[2]
        kickoff       = row[3]
        home_team_id  = row[4]
        away_team_id  = row[5]
        time_in_game  = row[6]
        home_goals    = row[7]
        away_goals    = row[8]
        
        cur = self.conn.cursor()
        cur.execute("select * from GAMES_STATS_UNIQ \
                     where XML_SOCCER_ID = %s \
                     and HOME_GOALS = %s \
                     and AWAY_GOALS = %s", \
                     (xml_soccer_id, 
                      home_goals, away_goals))
         
        rc_games_stats_uniq = cur.rowcount
        cur.close()
        
        if rc_games_stats_uniq == 0 :
            self.log.debug('insert ' + str(row))
            cur = self.conn.cursor()
            cur.execute("insert into GAMES_STATS_UNIQ ( \
                        ID, EVENTTIME, XML_SOCCER_ID, \
                        KICKOFF, HOME_TEAM_ID, \
                        AWAY_TEAM_ID, TIME_IN_GAME, \
                        HOME_GOALS, AWAY_GOALS ) \
                        values \
                        (%s,%s,%s,%s,%s,%s,%s,%s,%s)", \
               (id, event_time, xml_soccer_id,
                kickoff, home_team_id, 
                away_team_id, time_in_game, 
                home_goals, away_goals))
            cur.close()
              
        cur = self.conn.cursor()
        cur.execute("delete from GAMES_STATS where ID = %s",(id,))
        cur.close()
        
    #####################################################

        
    def do_throttle(self):
        """return only when it is safe to send another data request"""
        log.info('Wait for ' + str(self.SLEEP_TIME_BETWEEN_TURNS) + ' seconds')
        sleep(self.SLEEP_TIME_BETWEEN_TURNS)       
    #####################################################
        
    def start(self):
        """start the main loop,"""
        
        cur = self.conn.cursor()
        cur.execute("select * from GAMES_STATS order by ID limit 1000")
        
        while True :
            row = cur.fetchone()
            if not row : 
                self.do_throttle()   
                break
            self.treat_row(row)    
        cur.close()
        self.conn.commit()
 
    ###################################################################

#make print flush now!
#sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
FH = logging.handlers.RotatingFileHandler(
    'logs/game_stats_compressor.log',
    mode = 'a',
    maxBytes = 500000,
    backupCount = 10,
    encoding = 'iso-8859-15',
    delay = False
) 
FH.setLevel(logging.DEBUG)
FORMATTER = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
FH.setFormatter(FORMATTER)
log.addHandler(FH)
log.info('Starting application')

compressor = Game_Stats_Compresssor(log)

while True:
    log.info( '------------------ MAIN LOOP START -----------------------')
    try:
        compressor.start() 
    except KeyboardInterrupt :
        break
        
    log.info( '------------------ MAIN LOOP STOP -----------------------')

# main loop ended...
log.info('Ending application')
logging.shutdown()

