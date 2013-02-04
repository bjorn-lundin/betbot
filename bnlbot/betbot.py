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
#from game import Game
from market import Market
from funding import Funding
from db import Db
import socket
import logging.handlers
#from operator import itemgetter, attrgetter
import httplib2
import ConfigParser


class SessionError(Exception):
    pass

class OverrideError(Exception):
    pass

class BetBot(object):
    """put bet on games with low odds"""
    BETTING_SIZE = None
    MAX_ODDS = None
    MIN_ODDS = None
    DELTA = None
    PRICE = None
    HOURS_TO_MATCH_START = None
    DELAY_BETWEEN_TURNS_BAD_FUNDING = None
    DELAY_BETWEEN_TURNS_NO_MARKETS =  None
    DELAY_BETWEEN_TURNS =  None
    NETWORK_FAILURE_DELAY = None
    conn = None
    DRY_RUN = True
    BET_CATEGORY = None
    
    MIN_NO_OF_RUNNERS = None
    INCLUDE_STARTED = None
    EVENTS = None
    ALLOWED_MARKET_NAMES = None
    NO_OF_WINNERS = None
    COUNTRIES = None
    MAX_NO_OF_RUNNERS = None
    NOT_ALLOWED_MARKET_NAMES = None    
    
    USERNAME = None 
    PASSWORD = None 
    PRODUCT_ID = None
    VENDOR_ID = None

     
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
            cur.execute("select * from BETS where MARKET_ID = %s and \
                        SELECTION_ID = %s", 
                 (bet['marketId'],bet['selectionId']))
        else:
            cur.execute("select * from BETS where BET_ID = %s", \
               (resp['bet_id'],))
            
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
                         CODE, SUCCESS, SIZE, BET_TYPE, \
                         RUNNER_NAME, BET_WON ) \
                         values \
                         (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)", \
               (resp['bet_id'], bet['marketId'], bet['selectionId'], \
                resp['price'], resp['code'], resp['success'], \
                resp['size'], bet_type, name, None))
        cur.close()
############################# end insert_bet


#    def get_markets(self):
#        self.log.debug( 'get_markets from BetBot!!!')
#        raise OverrideError('BetBot.get_market MUST be overrridden!!!')
############################# end get_markets

    def do_throttle(self):
        """return only when it is safe to send another data request"""
        wait = self.throttle['next_req'] - time()
        if wait > 0: sleep(wait)
        self.throttle['next_req'] = time() + self.throttle['rps']
############################# end do_throttle

    def check_strategy(self, market_id ):
        self.log.debug( 'check_strategy from BetBot!!!')
        raise OverrideError('BetBot.check_strategy MUST be overrridden!!!')
############################# check_strategy


#################### start get-markets-test
    def get_markets(self):
        """returns a list of markets or an error string"""
        
        markets = self.api.get_all_markets(
              events = self.EVENTS,
              hours = self.HOURS_TO_MATCH_START,
              include_started = self.INCLUDE_STARTED, # exclude in-play markets
              countries = self.COUNTRIES)
              #http://en.wikipedia.org/wiki/List_of_FIFA_country_codes
              #http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3
        if type(markets) is list:
            # sort markets by start time + filter
            for market in markets[:]: 
#                self.log.info( 'market :' + str(market))
             # loop through a COPY of markets 
             #as we're modifying it on the fly...
                markets.remove(market)
                
                #check for NOT allowd names..
                market_ok = True
                if  self.NOT_ALLOWED_MARKET_NAMES:
                    for not_allowed in self.NOT_ALLOWED_MARKET_NAMES :
                        market_ok = market_ok and market['market_name'].decode("iso-8859-1").lower().find(not_allowed) == -1
#                        self.log.info('Not_allowed ' + market['market_name'].decode("iso-8859-1").lower() + ' ' + not_allowed + ' ' + str(market_ok))
                        if not market_ok : 
                            break
                # we now check for allowed market name, if nothing was found above
                if self.ALLOWED_MARKET_NAMES and market_ok : 
                    for allowed in self.ALLOWED_MARKET_NAMES :
                        market_ok = market_ok and market['market_name'].decode("iso-8859-1").lower().find(allowed) > -1
#                        self.log.info('allowed ' + market['market_name'].decode("iso-8859-1").lower() + ' ' + allowed + ' ' + str(market_ok))
                        if market_ok : 
                            break

                if market_ok:
                    self.log.info('market ' +  market['market_name'].decode("iso-8859-1") + ' ' + str(market))

                
                if (  market_ok
                    and market['market_status'] == 'ACTIVE' # market is active
                    and market['market_type'] == 'O' # Odds market only
                    and int(market['no_of_winners']) == int(self.NO_OF_WINNERS) # winner
                    and int(market['no_of_runners']) >= int(self.MIN_NO_OF_RUNNERS) # minst MIN kusar
                    and int(market['no_of_runners']) <= int(self.MAX_NO_OF_RUNNERS) # max MAX kusar
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
############################# end get_markets test



############################################### get_markets
    def market_in_xmlfeed(self, market_id) :
        Found = False
        cur = self.conn.cursor()
        cur.execute("select * from MARKET_IN_XML_FEED \
                     where MARKET_ID = " + str(market_id))
        row = cur.fetchone()
        rc = cur.rowcount
        cur.close()
        if rc == 1 :
            Found = True
        return Found
############################# market_in_xmlfeed
        
        
        
    def place_bet(self, market_id, selection, wanted_price, name):
        bets = []

        #check type of bet. in not BACKor LAY in self.BET_CATEGORY, assume BACK
        pip = -1 # default to BACK
        bet_type = 'B'
        if self.BET_CATEGORY.find('LAY') > -1 :
            pip = 1         
            bet_type = 'L'
         

        # set price to current back price - 1 pip 
        #(i.e.accept the next worse odds too)
        bet_price = self.api.set_betfair_odds(price = wanted_price, pips = pip)
        bet_size = self.BETTING_SIZE # my stake
        bet = {
            'marketId': market_id,
            'selectionId': selection,
            'betType': bet_type, # set above
            'price': '%.2f' % bet_price, # set string to 2 decimals
            'size': '%.2f' % bet_size,
            'betCategoryType': 'E',
            'betPersistenceType': 'NONE',
            'bspLiability': '0',
            'asianLineId': '0'
            }
        self.log.info('will place ' +str(bet))
    
        bets.append(bet)
        # place bets (if any have been created)
        resp = None
        if bets:    
            funds = Funding(self.api, self.log)
            if funds :
                self.do_throttle()
                funds.check_and_fix_funds()
                if funds.funds_ok:
                    self.do_throttle()
                    if self.DRY_RUN :
                        tmp_str = 'WOULD PLACE BET...\n'
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
                        tmp_str = 'PLACING BETS...\n'
                        resp = self.api.place_bets(bets)
                    
                    tmp_str += 'Bets: ' + str(bets) + '\n'
                    tmp_str += 'Place bets response: ' + str(resp) + '\n'
                    tmp_str += '---------------------------------------------'
                    self.log.info(tmp_str)
                    if resp == 'API_ERROR: NO_SESSION':
                        self.no_session = True
                    if not self.no_session and resp != 'EVENT_SUSPENDED' :
                        self.insert_bet(bets[0], resp[0], self.BET_CATEGORY, name)
                else :
                    self.log.warning( 'Something happened with funds: ' + str(funds))  
                    sleep(self.DELAY_BETWEEN_TURNS_BAD_FUNDING)     

############################ place_bet        
                

    def start(self):
        """start the main loop"""
        # login/monitor status
        login_status = self.login(self.USERNAME, self.PASSWORD, \
                                  self.PRODUCT_ID, self.VENDOR_ID)
        while login_status == 'OK': 
            # get list of markets starting soon
            self.log.info( '-----------------------------------------------')
            markets = self.get_markets()
            if type(markets) is list:
                if len(markets) == 0:
                    # no markets found...
                    tmp_str = 'No markets found.' + \
                              ' Sleeping for ' + \
                         str(self.DELAY_BETWEEN_TURNS_NO_MARKETS) + \
                         ' seconds...'
                    self.log.info(tmp_str)
                    sleep(self.DELAY_BETWEEN_TURNS_NO_MARKETS) # 
                else:
                    self.log.info( 'Found ' + str(len(markets)) +
                          ' markets. Checking strategy...')
                    num = 0
                    for market in markets:
                        num += 1
                        my_market = Market(self.conn, \
                        self.log, market_dict = market[1])
                        self.log.info( '++--++ market # ' + str(num) + '/' +
                                       str(len(markets)) + ' ' +
                        my_market.menu_path.decode("iso-8859-1") +
                        ' --++--++ ')
                        my_market.insert()
                        
                        if not my_market.bet_exists_already(self.BET_CATEGORY) :
                            self.check_strategy(my_market.market_id)
                        else : 
                            self.log.info( 'We have ALREADY bets on market ' +
                                   my_market.market_id)
                        self.conn.commit()
                # check if session is still OK
                if self.no_session:
                    raise SessionError('Start - lost session') 
                self.log.info('sleeping ' + str(self.DELAY_BETWEEN_TURNS) +
                ' s between turns')
                sleep(self.DELAY_BETWEEN_TURNS)
            else:
                self.log.info('market not list ' + str(markets))     

        # main loop ended...
        tmp_str = 'login_status = ' + str(login_status) + '\n'
        tmp_str += 'MAIN LOOP ENDED...\n'
        tmp_str += '---------------------------------------------'
        self.log.info(tmp_str)
############################# end start

    def initialize(self, bet_category): 
            
        config = ConfigParser.ConfigParser()
        config.read('betfair.ini')
            
        self.DELAY_BETWEEN_TURNS_BAD_FUNDING = float(config.get('Global', 'delay_between_turns_bad_funding'))
        self.DELAY_BETWEEN_TURNS_NO_MARKETS  = float(config.get('Global', 'delay_between_turns_no_markets'))
        self.DELAY_BETWEEN_TURNS             = float(config.get('Global', 'delay_between_turns'))
        self.NETWORK_FAILURE_DELAY           = float(config.get('Global', 'network_failure_delay'))


        self.BETTING_SIZE                    = float(config.get(bet_category, 'betting_size'))
        try :
            self.MAX_ODDS                        = float(config.get(bet_category, 'max_odds'))
        except ConfigParser.NoOptionError :
            self.MAX_ODDS = 0.0

        try :
            self.MIN_ODDS                        = float(config.get(bet_category, 'min_odds'))
        except ConfigParser.NoOptionError :
            self.MIN_ODDS = 0.0

        try :
            self.DELTA                           = float(config.get(bet_category, 'delta'))
        except ConfigParser.NoOptionError :
            self.DELTA = 0.0

        try :
            self.PRICE                           = float(config.get(bet_category, 'price'))
        except ConfigParser.NoOptionError :
            self.PRICE = 0.0

        self.HOURS_TO_MATCH_START            = float(config.get(bet_category, 'hours_to_match_start'))
        self.DRY_RUN                         = bool (config.get(bet_category, 'dry_run'))
        self.BET_CATEGORY = bet_category
        if self.DRY_RUN :
            self.BET_CATEGORY                = 'DRY_RUN_' + self.BET_CATEGORY

        tmp_string_1                         = config.get(bet_category, 'events')
        self.EVENTS                          = tmp_string_1.split(',') 
        tmp_string_2                         = config.get(bet_category, 'countries')
        self.COUNTRIES                       = tmp_string_2.split(',') 
        if self.COUNTRIES[0] == 'None' :
            self.COUNTRIES = None
            
        self.INCLUDE_STARTED                 = bool (config.get(bet_category, 'include_started'))
        tmp_string_3                         = config.get(bet_category, 'not_allowed_market_names')
        self.NOT_ALLOWED_MARKET_NAMES        = tmp_string_3.split(',')
        if self.NOT_ALLOWED_MARKET_NAMES[0] == 'None':
            self.NOT_ALLOWED_MARKET_NAMES = None

        tmp_string_4                         = config.get(bet_category, 'allowed_market_names')        
        self.ALLOWED_MARKET_NAMES            = tmp_string_4.split(',')
        if self.ALLOWED_MARKET_NAMES[0] == 'None':
            self.ALLOWED_MARKET_NAMES = None

        self.NO_OF_WINNERS                   = int (config.get(bet_category, 'no_of_winners'))
        self.MIN_NO_OF_RUNNERS               = int (config.get(bet_category, 'min_no_of_runners'))
        self.MAX_NO_OF_RUNNERS               = int (config.get(bet_category, 'max_no_of_runners'))

        login = ConfigParser.ConfigParser()
        login.read('betfair_login.ini')

        self.USERNAME                        = login.get('Login', 'username') 
        self.PASSWORD                        = login.get('Login', 'password')
        self.PRODUCT_ID                      = login.get('Login', 'product_id')
        self.VENDOR_ID                       = login.get('Login', 'vendor_id')

        self.log.info('Countries' + str(self.COUNTRIES))



        if self.MIN_ODDS > self.MAX_ODDS :
            raise Exception('min odds bigger than max odds! impossible ..')

############################# end initialize


    