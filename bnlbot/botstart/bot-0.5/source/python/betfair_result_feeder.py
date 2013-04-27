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
#from db import Db
import logging.handlers
import ConfigParser



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

#        print 'root', root
	if root.tag == 'market' :
	    self.market_id = root.get('id')
#	    print 'self.market_id', self.market_id
        for elem in root :
 #           print 'elem', elem
            if   elem.tag == 'name' :
                self.display_name = elem.get('displayName')
            elif elem.tag == 'marketType' :
#		print 'elem.text', elem.text
                self.market_type = elem.text
            elif elem.tag == 'winners' :
                self.selection_id_list = []
                for w in elem :
#		    print 'w',w
	            if w.tag == 'winner' :
#         		print 'w.get(selid)', w.get('selectionId')
                        self.selection_id_list.append(w.get('selectionId'))

    def print_me(self):
#	if type(self.selection_id_list) is None :
            self.log.info('market_id: ' + str(self.market_id) + \
                      ' name: ' + self.display_name + \
                      ' market_type: ' + str(self.market_type) + \
                      ' selection_id_list: None'  )
#        else :
#            self.log.info('id: ' + str(self.id) + \
#                      ' name: ' + self.display_name + \
#                      ' market_type: ' + str(self.market_type) + \
#                      ' selection_id_list: ' + str(self.selection_id_list)  )


    def bet_exists(self):
        if self.market_id :
            cur = self.conn.cursor()
            cur.execute("select BET_ID, SELECTION_ID, BET_TYPE, " \
                        "SIZE, PRICE from BETS where MARKET_ID= %s and BET_WON is null",
                          (self.market_id,))

            eos = True
            row = cur.fetchone()
            if row  :
                self.bet_id = int(row[0])
                self.selection_id = int(row[1])
                self.bet_type = row[2]
                self.size = float(row[3])
                self.price = float(row[4])
                eos = False
            cur.close()
            self.conn.commit()

            return not eos
        else :
#            self.log.error('market_id is None')
            return False


    def treat(self):

        self.log.info('bet_type '  + str(self.bet_type) + ', self.selection_id ' + \
        str(self.selection_id) + ' self.selection_id_list ' +  str(self.selection_id_list))

        selection_in_winners = False
        for s in self.selection_id_list:
           self.log.info('s '  + str(s))
           if int(s) == int(self.selection_id) :
               selection_in_winners = True

        self.log.info('selection_in_winners '  + str(selection_in_winners) )

        bet_won = False
        back_bet = True

        if  self.bet_type.find('_LAY_BET') > -1 :
            bet_won = not selection_in_winners
            back_bet = False

        elif self.bet_type.find('_BACK_BET') > -1 :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_MORE_THAN_0.5_GOALS" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_MORE_THAN_1.5_GOALS" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_LESS_THAN_2.5_GOALS" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_MORE_THAN_2.5_GOALS" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_LESS_THAN_3.5_GOALS" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_MORE_THAN_3.5_GOALS" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_LESS_THAN_4.5_GOALS" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_MORE_THAN_4.5_GOALS" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_LESS_THAN_5.5_GOALS" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_LESS_THAN_6.5_GOALS" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_LESS_THAN_7.5_GOALS" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_LESS_THAN_8.5_GOALS" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_SENDOFF_NO" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_SCORE_SUM_IS_EVEN" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_BOTH_TEAMS_SCORES" :
            bet_won = selection_in_winners

        elif self.bet_type == "DRY_RUN_TIE_NO_BET" :
            bet_won = selection_in_winners

        else :
          return



        profit = 0.0
        # let view take care of 5% commission
        if bet_won :
            if back_bet :
                profit = 1.0 * self.size * (self.price -1)
            else:
                profit = 1.0 * self.size
        else:
            if back_bet :
                profit = -self.size
            else:
                profit = -self.size * self.price

        #update db
        cur = self.conn.cursor()
        cur.execute("update BETS set PROFIT = %s, " \
                    "BET_WON = %s, CODE = %s where BET_ID = %s",
                   (profit, bet_won, 'S', self.bet_id))
#                    "BET_PLACED = EVENT_DATE, " \
        cur.close()

        cur2 = self.conn.cursor()
        cur2.execute("update BETS set BET_PLACED = (select EVENT_DATE from MARKETS where MARKETS.MARKET_ID = BETS.MARKET_ID ) " \
                    "where BET_ID = %s and BET_PLACED is null",
                   (self.bet_id,))
        cur2.close()


        cur3 = self.conn.cursor()
        cur3.execute("select MARKET_ID from BETS where BET_WON is null")
        rows = cur3.fetch()
        cur3.close()

        for row in rows :
            marketid = row[0]
            self.log.info('ongoing bet, marketid ' + str(marketid))
            cur4 = self.conn.cursor()
            cur4.execute("select bet_id from MARKETS where MARKET_ID = %s and EVENT_DATE < (select current_date - interval '1 day')", (marketid,))
            badrows = cur4.fetch()
            cur4.close()

            for badrow in badrows :
                bad_bet_id = badrow[0]
                self.log.info('deleting too old bet bet ' + str(bad_bet_id))
                cur5 = self.conn.cursor()
                cur5.execute("delete from BETS where BET_ID = %s)", (bad_bet_id,))
                cur5.close()

        self.conn.commit()

        self.log.info('bet_won ' + str(bet_won) + \
                      ' profit ' + str(profit) + \
                      ' bet_id ' + str(self.bet_id) )


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
    get_soccer = False
    conn = None

    def __init__(self, log):
        rps = 1/4.0 # Refreshes Per Second
        self.no_session = True
        self.throttle = {'rps': 1.0 / rps, 'next_req': time()}

        self.log = log



    def fetch(self, url):
        """get the feed"""
        response = urllib2.urlopen(url, timeout = 120)
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
  #              self.log.info(str(m))
                market = Market(m, self.conn, self.log)
                if market.bet_exists() :
                    #market.print_me()
                    market.treat()

        if self.get_hounds :
            self.log.info('Fetching hounds')
            markets = self.fetch_hounds()
            self.log.info('Fetched hounds')
            for m in markets :
#                self.log.info(str(m))
                market = Market(m, self.conn, self.log)
                if market.bet_exists() :
                    #market.print_me()
                    market.treat()

        if self.get_soccer :
            self.log.info('Fetching soccer')
            markets = self.fetch_soccer()
            self.log.info('Fetched soccer')
            for m in markets :
  #              self.log.info(str(m))
                market = Market(m, self.conn, self.log)
                if market.bet_exists() :
                    #market.print_me()
                    market.treat()

        self.conn.commit()
###################################################################

######## main ###########
log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)

homedir = os.path.join(os.environ['BOT_START'], 'user', os.environ['BOT_USER'])
logfile = os.path.join(homedir, 'log',  __file__.split('.')[0] + '.log')

FH = logging.handlers.RotatingFileHandler(
    logfile,
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

login = ConfigParser.ConfigParser()
login.read(os.path.join(homedir, 'login.ini'))

bfusername   = login.get('betfair', 'username')
bfpassword   = login.get('betfair', 'password')
bfproduct_id = login.get('betfair', 'product_id')
bfvendor_id  = login.get('betfair', 'vendor_id')

dbname     = login.get('database', 'name')
dbhost     = login.get('database', 'host')
dbusername = login.get('database', 'username')
dbpassword = login.get('database', 'password')


bot = Result_Feeder(log)

bot.conn = psycopg2.connect('dbname=' + dbname +  \
                            ' user=' + dbusername + \
                            ' host=' + dbhost + \
                            ' password='+ dbpassword)
bot.conn.set_client_encoding('latin1')


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
