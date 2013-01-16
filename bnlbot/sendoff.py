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
from market import Market
from funding import Funding
from db import Db
import socket
import logging.handlers
import ConfigParser

class SimpleBot(object):
    """put bet on games with low odds"""
    BETTING_SIZE = 30.0
    MIN_ODDS = 1.25
    HOURS_TO_MATCH_START = 0.1
    DELAY_BETWEEN_TURNS_BAD_FUNDING = 60.0
    DELAY_BETWEEN_TURNS_NO_MARKETS =  60.0
    NETWORK_FAILURE_DELAY = 60.0
    DELAY_BETWEEN_TURNS = 30.0
    conn = None
    DRY_RUN = True
    
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


        

    def insert_bet(self, bet, resp, bet_type, name):
        self.log.info( 'insert bet' )
        cur = self.conn.cursor()
        
        if self.DRY_RUN :
            # get a new bet id, we are in dry_run mode
            cur.execute("select * from BETS where MARKET_ID = %s and SELECTION_ID = %s", 
                 (bet['marketId'],bet['selectionId']))
        else:
            cur.execute("select * from BETS where BET_ID = %s", (resp['bet_id'],))
            
        if cur.rowcount == 0 :
            if self.DRY_RUN :
               cur2 = self.conn.cursor()
               cur2.execute("select nextval('bet_id_serial')")
               row = cur2.fetchone()
               cur2.close()
               resp['bet_id'] = row[0]
                            
            self.log.debug( 'insert bet ' + str(resp['bet_id']))
                       
            cur.execute("insert into BETS ( \
                         BET_ID, MARKET_ID, SELECTION_ID, PRICE, \
                         CODE, SUCCESS, SIZE, BET_TYPE, RUNNER_NAME, BET_WON ) \
                         values \
                         (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)", \
               (resp['bet_id'], bet['marketId'], bet['selectionId'], \
                resp['price'], resp['code'], resp['success'], \
                resp['size'], bet_type, name, None))
        cur.close()
############################# end insert_bet


    def get_markets(self):
        """returns a list of markets or an error string"""
        # NOTE: get_all_markets is NOT subject to data charges!
        markets = self.api.get_all_markets(
              events = ['1','14'],
              hours = self.HOURS_TO_MATCH_START,
              countries = None)
#              countries = ['GBR'])
              #http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3
        if type(markets) is list:
            # sort markets by start time + filter
            for market in markets[:]:
            # loop through a COPY of markets as we're modifying it on the fly...
                markets.remove(market)
                if (    market['market_name'] == 'Utvisning?' # 
                    and market['market_status'] == 'ACTIVE' # market is active
                    and market['market_type'] == 'O' # Odds market only
                    and market['no_of_winners'] == 1 # single winner market
                    and market['bet_delay'] == 0 # not started -
                    ):
                    # calc seconds til start of game
                    delta = market['event_date'] - self.api.API_TIMESTAMP
                    # 1 day = 86400 sec
                    sec_til_start = delta.days * 86400 + delta.seconds
#                    print 'market', market['market_id'], market['menu_path'], \
#                       'will start in', sec_til_start, 'seconds Halvtid'
                    temp = [sec_til_start, market]
                    markets.append(temp)
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
            if type(prices) is dict and prices['status'] == 'ACTIVE':
                # loop through runners and prices and create bets
                # the no-red-card runner is [1]
                my_market = Market(self.conn, self.log, market_id = market_id)                
                bets = []
                back_price = None 
                selection = None
                bet_category = None

                my_game = Game(self.conn, my_market.home_team_id, \
                               my_market.away_team_id)    
                if not my_game.found :
                    self.log.info('game not found home_team_id ' + 
                         str(my_market.home_team_id) + 
                        ' home_team_id ' + str(my_market.away_team_id))
                    return    

                try:
                    my_time = int(my_game.time_in_game)
                except ValueError:
                    my_time = 1000                         

                try :
                    odds_yes      = prices['runners'][0]['back_prices'][0]['price']
                    selection_yes = prices['runners'][0]['selection_id']
                    odds_no       = prices['runners'][1]['back_prices'][0]['price']
                    selection_no  = prices['runners'][1]['selection_id']
                except:
                    self.log.info( '#############################################')
                    self.log.info( 'prices missing some fields, do return ' +
                           my_market.home_team_name.decode("iso-8859-1") + ' - ' + 
                           my_market.away_team_name.decode("iso-8859-1"))
                    self.log.info( '#############################################')
                    return

                self.log.info( 'game :' + my_market.home_team_name.decode("iso-8859-1") + ' - ' + \
                                 my_market.away_team_name.decode("iso-8859-1"))
                self.log.info( 'odds utvisning -ja  : ' + str(odds_yes))
                self.log.info( 'odds utvisning -nej :' + str(odds_no))
                

                #no sendoff
                if odds_no and \
                   odds_no >= self.MIN_ODDS :
			   
                    back_price = odds_no
                    selection = selection_no
                    if self.DRY_RUN :
                        bet_category = 'DRY_RUN_SENDOFF_NO'
                    else :
                        bet_category = 'SENDOFF_NO'


                if back_price and selection:
                    # set price to current back price - 1 pip 
                    #(i.e.accept the next worse odds too)
                    bet_price = self.api.set_betfair_odds(price = back_price, pips = -1)
                    bet_size = self.BETTING_SIZE # my stake
                    bet = {
                        'marketId': market_id,
                        'selectionId': selection,
                        'betType': 'B', # we bet on winner, not loose
                        'price': '%.2f' % bet_price, # set string to 2 decimals
                        'size': '%.2f' % bet_size,
                        'betCategoryType': 'E',
                        'betPersistenceType': 'NONE',
                        'bspLiability': '0',
                        'asianLineId': '0'
                        }
                    bets.append(bet)
                else:
                    self.log.info('bad odds or time in game -> no bet on market ' +
                         str(market_id) + ' ' + my_market.home_team_name.decode("iso-8859-1") + '-' + 
                                 my_market.away_team_name.decode("iso-8859-1"))
                # place bets (if any have been created)
                if bets:    
                    funds = Funding(self.api, self.log)
                    self.do_throttle()
                    funds.check_and_fix_funds()
                    if funds.funds_ok:
                        self.do_throttle()
                        if self.DRY_RUN :
                            s = 'WOULD PLACE BET...\n'
                            resp1 = {                            
                                     'bet_id'  : -1 ,
                                     'price'   : bet['price'], 
                                     'code'    : 'OK',
                                     'success' : True, 
                                     'size'    : bet['size']
                            }
                            resp = []
                            resp.append(resp1)
                        else:
                            s = 'PLACING BETS...\n'
                            resp = self.api.place_bets(bets)
                            
                        s += 'Bets: ' + str(bets) + '\n'
                        s += 'Place bets response: ' + str(resp) + '\n'
                        s += '---------------------------------------------'
                        self.log.info(s)
                        if resp == 'API_ERROR: NO_SESSION':
                            self.no_session = True
                        if not self.no_session and resp != 'EVENT_SUSPENDED' :
                            self.insert_bet(bets[0], resp[0], bet_category, None)
                    else :
                        self.log.warning( 'Something happened with funds: ' + str(funds))  
                        sleep(self.DELAY_BETWEEN_TURNS_BAD_FUNDING)     
            elif prices == 'API_ERROR: NO_SESSION':
                self.no_session = True
            elif type(prices) is not dict:
                s = 'check_strategy() ERROR: prices = ' + str(prices) + '\n'
                s += '---------------------------------------------'
                self.log.info(s)
############################# check_strategy


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
                    s = 'UTVISNING No markets found. Sleeping for ' +  \
                         str(self.DELAY_BETWEEN_TURNS_NO_MARKETS) + ' seconds...'
                    self.log.info(s)
                    sleep(self.DELAY_BETWEEN_TURNS_NO_MARKETS) #bandwidth saver  
                else:
                    self.log.info( 'Found ' + str(len(markets)) + \
                          ' markets. Checking strategy...')
                    num = 0
                    for market in markets:
                        num += 1
                        my_market = Market(self.conn, self.log,  market_dict = market[1])
                        self.log.info( '--++--++ market # ' + str(num) + '/' + \
                                       str(len(markets)) + ' ' + \
                                       my_market.home_team_name.decode("iso-8859-1") + '-' + \
                                       my_market.away_team_name.decode("iso-8859-1") + ' --++--++ ')
                        my_market.insert()
                        my_market.try_set_gamestart()
                        
                        if not my_market.market_in_xmlfeed() :
                            self.log.info( 'market not in xmlfeed: ' + 
                                  my_market.home_team_name.decode("iso-8859-1") + '-' + 
                                  my_market.away_team_name.decode("iso-8859-1"))
                        else :
                            if not my_market.bet_exists_already() :    
                                # we have no bets on this market...
                                self.check_strategy(my_market.market_id)
                            else : 
                                self.log.info( 'We have ALREADY bets on market ' + \
                                       my_market.market_id + ' ' + \
                                       my_market.home_team_name.decode("iso-8859-1") + ' - ' + \
                                       my_market.away_team_name.decode("iso-8859-1"))
                                    
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
    'logs/sendoff.log',
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

    except psycopg2.DatabaseError :
        log.error( 'Lost db contact . Retry in ' + str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
        sleep (bot.NETWORK_FAILURE_DELAY)
        bot.reconnect()
        
    except KeyboardInterrupt :
        break
    
log.info('Ending application')
logging.shutdown()

