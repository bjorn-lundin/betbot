# coding=iso-8859-15
from time import sleep, time
import datetime
import psycopg2
import urllib2
import httplib2
import ssl
import xml.etree.ElementTree as etree 
import os
import sys
import socket
from db import Db
import logging.handlers

#  <market id="107893032" displayName="USA / Aque (US) 9th Jan - 17:30 TO BE PLACED">
#    <name>TO BE PLACED</name>
#    <country countryID="2">USA</country>
#    <menuHint>USA / Aque (US) 9th Jan</menuHint>
#    <startDate date="09/01/2013" time="17:30" sort="634933494000000000">09-Jan 17:30</startDate>
#    <marketType>Place</marketType>
#    <betType>Odds</betType>
#    <nonRunners list=""/>
#    <winners count="2" list=" Raffies Star,  Fit Fightin Feline" selectionIdList="6969167, 6969171">
#      <winner selectionId="6969167" raceNumber="1"> Raffies Star</winner>
#      <winner selectionId="6969171" raceNumber="7"> Fit Fightin Feline</winner>
#    </winners>
#  </market>
 
class Market(object):
    def __init__(self, root, conn):
        self.id = None
        self.display_name = None
        self.market_type = None
        self.selection_id_list = None
        self.bet_id = None
        self.selection_id = None
        self.bet_type = None
        self.size = None
        self.price = None
        
        self.conn = conn
         
        for elem in root :
#            print 'elem', elem
            if   elem.tag == 'market' :
                self.id = elem.get('id')
            elif elem.tag == 'Name' :
                self.display_name = elem.get('displayName')
            elif elem.tag == 'marketType' :
                self.market_type = elem.text
            elif elem.tag == 'winners' :
                self.selection_id_list = []
            elif elem.tag == 'winner' :
                self.selection_id_list.append(elem.get('selectionId'))

    def print_me(self):         
        self.log.info('id: ' + str(self.id) + \
                      ' name: ' + self.display_name + \
                      ' market_type: ' + str(self.market_type) + \
                      ' selection_id_list: ' + str(self.selection_id_list) )


    def bet_exists(self):
        cur = self.conn.cursor()
        cur.execute("select BET_ID, SELECTION_ID, BET_TYPE, " \
                    "SIZE, PRICE from BETS where BET_ID= %s", 
                      (self.id,))
        num = cur.rowcount
        if num > 0 :
            row = cur.fetchone()
            self.bet_id = int(row[0])
            self.selection_id = int(row[1])
            self.bet_type = row[2]
            self.size = float(row[3])
            self.price = float(row[4])
        cur.close()
        return num > 0
        
    def treat(self):

        selection_in_winners = False
        for s in self.selection_id_list:
           if s == self.selection : 
               selection_in_winners = True               
        bet_won = False
        back_bet = True
        
        if   self.bet_type == "DRY_RUN_HORSES_WINNER_LAY_BET" :
            if selection_in_winners :
                bet_won = False
                back_bet = False
                
        elif self.bet_type == "DRY_RUN_HORSES_WINNER_BACK_BET" :
            if selection_in_winners :
                bet_won = True
                
        elif self.bet_type == "DRY_RUN_HORSES_PLACE_LAY_BET" :
            if selection_in_winners :
                bet_won = False
                back_bet = False
                
        elif self.bet_type == "DRY_RUN_HORSES_PLACE_BACK_BET" :
            if selection_in_winners :
                bet_won = True
                
        elif self.bet_type == "DRY_RUN_HOUNDS_WINNER_LAY_BET" :
            if selection_in_winners :
                bet_won = False
                back_bet = False
                
        elif self.bet_type == "DRY_RUN_HOUNDS_WINNER_BACK_BET" :
            if selection_in_winners :
                bet_won = True
                
        elif self.bet_type == "DRY_RUN_HOUNDS_PLACE_LAY_BET" :
            if selection_in_winners :
                bet_won = False
                back_bet = False
                
        elif self.bet_type == "DRY_RUN_HOUNDS_PLACE_BACK_BET" :
            if selection_in_winners :
                bet_won = True
                
        else :
          return


        #update db         
        cur = self.conn.cursor()
        
        profit = 0.0

        if bet_won :
            if back_bet :
                profit = 0.95 * size *(price -1)
            else:
                profit = 0.95 * size
        else:
            if back_bet :
                profit = -size         
            else:
                profit = -size * price         
        
        cur.execute("update BETS set PROFIT = %s, " \
                    "BET_PLACED = EVENT_DATE",
                    "BET_WON = %s where BET_ID = %s",
                   (profit, bet_won, self.bet_id))

             
        cur.close()
        self.conn.commit() 

        self.log.info('bet_won ' + str(bet_won) + \
                      ' profit ' + str(profit) + \
                      ' bet_id ' + str(self.bet_id) )


#########################################################################

class Result_Feeder(object):
    """get xml feeds"""

    NETWORK_FAILURE_DELAY = 60.0
    URL = 'http://rss.betfair.com/RSS.aspx?format=xml&sportID='
    URL_HORSES = URL + '7'
    URL_HOUNDS = URL + '4339'
    URL_SOCCER = URL + '1'
    get_horses = True
    get_hounds = True
    get_soccer = False
    conn = None
    
    def __init__(self, log):
        rps = 1/4.0 # Refreshes Per Second
        self.no_session = True
        self.throttle = {'rps': 1.0 / rps, 'next_req': time()}
        db = Db() 
        self.conn = db.conn 
        self.log = log



    def fetch(self, url):
        """get the feed"""
        response = urllib2.urlopen(url)
        xmlstring = response.read()
        return etree.fromstring(xmlstring)        
        
    def fetch_horses(self):
        return self.fetch(self.URL_HORSES) 

    def fetch_hounds(self):
        return self.fetch(self.URL_HOUNDS) 

    def fetch_soccer(self):
        return self.fetch(self.URL_SOCCER) 

        
    def do_throttle(self):
        """return only when it is safe to send another data request"""
#        wait = self.throttle['next_req'] - time()
#        if wait > 0: 
        print 'Wait for', 32, 'seconds'
        sleep(32)
#        self.throttle['next_req'] = time() + self.throttle['rps']
        
    def start(self):
        """start the main loop"""
        if self.get_horses :
            markets = self.fetch_horses()
            for m in markets :
                self.log.info(str(m))
                market = Market(m, self.conn)
                if market.bet_exists() :
                    market.treat()
                    
        if self.get_hounds :
            markets = self.fetch_hounds()
            for m in markets :
                self.log.info(str(m))
                market = Market(m, self.conn)
                if market.bet_exists() :
                    market.treat()
                    
        if self.get_soccer :
            markets = self.fetch_soccer()
            for m in markets :
                self.log.info(str(m))
                market = Market(m, self.conn)
                if market.bet_exists() :
                    market.treat()

        self.conn.commit()    
###################################################################

######## main ###########
log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
FH = logging.handlers.RotatingFileHandler(
    'logs/betfair_result_feeder.log',
    mode = 'a',
    maxBytes = 5000000,
    backupCount = 10,
    encoding = 'iso-8859-1',
    delay = False
) 
FH.setLevel(logging.DEBUG)
FORMATTER = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
FH.setFormatter(FORMATTER)
log.addHandler(FH)
log.info('Starting application')

#make print flush now!
#sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

bot = Result_Feeder(log)

while True:
    try:
        bot.start() 
    except urllib2.URLError :
        log.error( 'Lost network ? . Retry in ' + str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
        sleep (bot.NETWORK_FAILURE_DELAY)

    except ssl.SSLError :
        log.error( 'Lost network (ssl error) . Retry in ' + str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
        sleep (bot.NETWORK_FAILURE_DELAY)
       
    except socket.error as ex:
        log.error( 'Lost network (socket error) . Retry in ' + str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
        sleep (bot.NETWORK_FAILURE_DELAY)
	
    except httplib2.ServerNotFoundError :
        log.error( 'Lost network (server not found error) . Retry in ' + str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
        sleep (bot.NETWORK_FAILURE_DELAY)
#    except psycopg2.DatabaseError :
#        log.error( 'Lost db contact . Retry in ' + str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
#        sleep (bot.NETWORK_FAILURE_DELAY)
#        bot.reconnect()
	
    except KeyboardInterrupt :
        break

log.info('Ending application')
logging.shutdown()
    