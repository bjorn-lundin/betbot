# -*- coding: iso-8859-1 -*- 
"""put bet on games with low odds"""
from betfair.api import API
from time import sleep, time
import datetime 
import psycopg2
import urllib2
import ssl
import os
import sys
from game import Game
from drymarket import DryMarket
from funding import Funding
from db import Db
from dryrunner import DryRunner
import socket
import logging.handlers
from operator import itemgetter, attrgetter
import httplib2
import ConfigParser





class SimpleBot(object):
    """put bet on games with low odds"""
    HOURS_TO_MATCH_START = 0.02 # 4,8 min
    DELAY_BETWEEN_TURNS_NO_MARKETS =  15.0
    DELAY_BETWEEN_TURNS =  5.0
    NETWORK_FAILURE_DELAY = 60.0
    conn = None

     
    def __init__(self, log):
        rps = 1/2.0 # Refreshes Per Second
        self.api = API('uk') # exchange ('uk' or 'aus')
        self.no_session = True
        self.throttle = {'rps': 1.0 / rps, 'next_req': time()}
        db = Db() 
        self.conn = db.conn 
        self.log = log
        
############################# end __init__
    def reconnect(self):
        db = Db() 
        self.conn = db.conn 

    def login(self, uname = '', pword = '', prod_id = '', vend_id = ''):
        """login to betfair"""
        if uname and pword and prod_id and vend_id:
            resp = self.api.login(uname, pword, prod_id, vend_id)
            if resp == 'OK': 
                self.no_session = False
            return resp
        else:
            return 'login() ERROR: INCORRECT_INPUT_PARAMETERS'
############################# end login



    def get_markets(self):
        """returns a list of markets or an error string"""
        # NOTE: get_all_markets is NOT subject to data charges!
#        print datetime.datetime.now(), 'api.get_all_markets start'
#  'Horse Racing': '7', 
#self.HOURS_TO_MATCH_START
#               countries = None)
        markets = self.api.get_all_markets(
              events = ['7','4339'],
              hours = self.HOURS_TO_MATCH_START,
              include_started = False, # exclude in-play markets
              countries = None)

              #http://en.wikipedia.org/wiki/List_of_FIFA_country_codes
              #http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3
        if type(markets) is list:
            # sort markets by start time + filter
            for market in markets[:]:
             # loop through a COPY of markets 
             #as we're modifying it on the fly...
                markets.remove(market)
                market_ok = True
                
                if (  market_ok
                    and market['market_status'] == 'ACTIVE' # market is active
                    and market['market_type'] == 'O' # Odds market only
                    and market['bet_delay'] == 0 # not started
                    ):
                    # calc seconds til start of game
                    delta = market['event_date'] - self.api.API_TIMESTAMP
                    # 1 day = 86400 sec
                    sec_til_start = delta.days * 86400 + delta.seconds 
                    temp = [sec_til_start, market]
                    markets.append(temp)
                    self.log.info( 'market :' + str(market))
            markets.sort() # sort into time order (earliest game first)
            return markets
        elif markets == 'API_ERROR: NO_SESSION':
            self.no_session = True
        else:
            return markets
############################# end get_markets

    def do_throttle(self):
        """return only when it is safe to send another data request"""
        wait = self.throttle['next_req'] - time()
        if wait > 0: sleep(wait)
        self.throttle['next_req'] = time() + self.throttle['rps']
############################# end do_throttle

    def check_strategy(self, market_id ):
        """check market for suitable bet"""
        if market_id:
            # get market prices
            self.do_throttle()
            prices = self.api.get_market_prices(market_id)
            self.log.info( 'prices :' + str(prices))
            if type(prices) is dict and prices['status'] == 'ACTIVE':
                bets = []
                lay_price = None 
                selection = None
                
                race_list = []
                for runner in prices['runners'] :
                    try :
                        bp = runner['back_prices'][0]['price']
                    except:
                        bp = 1001                        
                    try :
                        lp = runner['lay_prices'][0]['price']
                    except:
                        lp = 1001                        
                    try :
                        sel_id = runner['selection_id']
                    except:
                        sel_id = -1                        
                    try :
                        idx = runner['order_index']
                    except:
                        idx = -1                        
                        
                    self.log.info( 'UNSORTED back/lay/selection/idx ' + \
                            str(bp) + '/' + \
                            str(lp) + '/' + \
                            str(sel_id) + '/' + \
                            str(idx)  )
                    d = {}
                    d['market_id'] = market_id
                    d['bp'] = bp 
                    d['lp'] = lp 
                    d['sel_id'] = sel_id
                    d['idx'] = idx 
                    
                    dr = DryRunner(d)
                    dr.insert()


    def start(self, uname = '', pword = '', prod_id = '', vend_id = ''):
        """start the main loop"""
        # login/monitor status
        login_status = self.login(uname, pword, prod_id, vend_id)
        while login_status == 'OK': 
            # get list of markets starting soon
            self.log.info( '-----------------------------------------------------------')
            markets = self.get_markets()
            if type(markets) is list:
                if len(markets) == 0:
                    # no markets found...
                    s = 'DRY_RUN_MARKET_GETTER No markets found. Sleeping for ' + \
                         str( self.DELAY_BETWEEN_TURNS_NO_MARKETS) + ' seconds...'
                    self.log.info(s)
                    sleep(self.DELAY_BETWEEN_TURNS_NO_MARKETS) # bandwidth saver!
                else:
                    self.log.info( 'Found ' + str(len(markets)) + \
                          ' markets. Checking strategy...')
                    num = 0
                    for market in markets:
                        num += 1
                        my_market = DryMarket(self.conn, self.log, market_dict = market[1])
                        self.log.info( '--++--++ market # ' + str(num) + '/' + \
                                       str(len(markets)) + ' ' + \
                                       my_market.menu_path.decode("iso-8859-1") + ' --++--++ ')
                        my_market.insert()
                        self.check_strategy(my_market.market_id)

                        self.conn.commit()
                # check if session is still OK
                if self.no_session:
                    login_status = self.login(uname, pword, prod_id, vend_id)
                    s = 'API ERROR: NO_SESSION. Login resp =' + \
                         str(login_status) + '\n'
                    s += '---------------------------------------------'
                    self.log.info(s)
                self.log.info('sleeping ' + str(self.DELAY_BETWEEN_TURNS) + ' s between turns')
                sleep(self.DELAY_BETWEEN_TURNS)
        # main loop ended...
        s = 'login_status = ' + str(login_status) + '\n'
        s += 'MAIN LOOP ENDED...\n'
        s += '---------------------------------------------'
        self.log.info(s)
############################# end start

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


config = ConfigParser.ConfigParser()
config.read('betfair.ini')

username = config.get('Login', 'username') 
password =  config.get('Login', 'password')

bot = SimpleBot(log)

while True:
    try:
        bot.start(username, password, '82', '0') # product id 82 = free api
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
    