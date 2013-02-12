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

    def __init__(self, root, conn, log):
        self.bet_id = None
        self.market_id = None
        self.display_name = None
        self.market_type = None
        self.selection_id_list = None
        self.bet_id = None
        self.selection_id = None
        self.bet_type = None
        self.size = None
        self.price = None
        self.conn = conn
        self.log = log

#        print 'root.tag: ', root.tag , 'text',  root.text
        if root.tag == 'market' :
            self.market_id = root.get('id')
#	    print 'self.market_id', self.market_id

            for elem in root :
                if   elem.tag == 'name' :
                    self.display_name = elem.get('displayName')
                elif elem.tag == 'marketType' :
                    self.market_type = elem.text
                elif elem.tag == 'winners' :
                    self.selection_id_list = []
                for w in elem :
                    if w.tag == 'winner' :
                        self.selection_id_list.append(w.get('selectionId'))



    def result_exists(self):
        eos = False
        if self.selection_id_list :
            for sid in self.selection_id_list :
                cur = self.conn.cursor()
                cur.execute("select * from DRY_RESULTS where MARKET_ID = %s and SELECTION_ID = %s",
                      (self.market_id, sid))
                eos = True
                row = cur.fetchone()
                cur.close()
                if row  :
                    eos = False

                if eos:
                    break

        return not eos


    def result_insert(self):
#	print 'resultinsert',self.market_id, self.selection_id_list
        if self.selection_id_list :
            for sid in self.selection_id_list :

                cur7 = self.conn.cursor()
                cur7.execute("SAVEPOINT RES_GET_B")
                cur7.close()
                try  :

                    cur = self.conn.cursor()
                    cur.execute("insert into DRY_RESULTS (MARKET_ID, SELECTION_ID) values (%s,%s)",
                       (self.market_id, sid))
                    cur.close()
                except psycopg2.IntegrityError:
                    self.log.info('duplicate index self.market_id, sid ' +  str(self.market_id) + ' ' + str(sid))
                    cur.close()
                    cur6 = self.conn.cursor()
                    cur6.execute("ROLLBACK TO SAVEPOINT RES_GET_B" )
                    cur6.close()


#########################################################################

class Result_Feeder(object):
    """get xml feeds"""

    DELAY_BETWEEN_TURNS = 60.0
    NETWORK_FAILURE_DELAY = 60.0
    URL = 'http://rss.betfair.com/RSS.aspx?format=xml&sportID='
    URL_HORSES = URL + '7'
    URL_HOUNDS = URL + '4339'
    URL_SOCCER = URL + '1'
    get_horses = True
    get_hounds = True
    get_soccer = True
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
        response = urllib2.urlopen(url, timeout = 30)
    #catch the timeout at main loop
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
        self.log.info('Wait for '  + str(s) + ' seconds')
        sleep(32)
#        self.throttle['next_req'] = time() + self.throttle['rps']

    def start(self):
        """start the main loop"""

        if self.get_horses :
            self.log.info('Fetcing horses')
            markets = self.fetch_horses()
            self.log.info('Fetched horses')
            for m in markets :
                market = Market(m, self.conn, self.log)
                if market.market_id and not market.result_exists() :
                    market.result_insert()

        if self.get_hounds :
            self.log.info('Fetcing hounds')
            markets = self.fetch_hounds()
            self.log.info('Fetched hounds')
            for m in markets :
                market = Market(m, self.conn, self.log)
                if market.market_id and not market.result_exists() :
                    market.result_insert()

        if self.get_soccer :
            self.log.info('Fetcing soccer')
            markets = self.fetch_soccer()
            self.log.info('Fetched soccer')
            for m in markets :
                market = Market(m, self.conn, self.log)
                if market.market_id and not market.result_exists() :
                    market.result_insert()

        self.conn.commit()
###################################################################

######## main ###########
log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
FH = logging.handlers.RotatingFileHandler(
    'logs/' + __file__.split('.')[0] +'.log',
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
        log.info( 'sleep between turns ' + str(bot.DELAY_BETWEEN_TURNS) + 'seconds')
        sleep (bot.DELAY_BETWEEN_TURNS)

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
