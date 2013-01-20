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
    HOURS_TO_MATCH_START = None
    DELAY_BETWEEN_TURNS_BAD_FUNDING = None
    DELAY_BETWEEN_TURNS_NO_MARKETS =  None
    DELAY_BETWEEN_TURNS =  None
    NETWORK_FAILURE_DELAY = None
    conn = None
    DRY_RUN = True
    BET_CATEGORY = None
    
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


    def get_markets(self):
        self.log.debug( 'get_markets from BetBot!!!')
        raise OverrideError('BetBot.get_market MUST be overrridden!!!')
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
                    tmp_str = 'GREYHOUND_BACK_BETS No markets found.' + \
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
        # main loop ended...
        tmp_str = 'login_status = ' + str(login_status) + '\n'
        tmp_str += 'MAIN LOOP ENDED...\n'
        tmp_str += '---------------------------------------------'
        self.log.info(tmp_str)
############################# end start

    def initialize(self, bet_category): 
            
        config = ConfigParser.ConfigParser()
        config.read('betfair.ini')
            
        self.BETTING_SIZE                    = float(config.get(bet_category, 'betting_size'))
        self.MAX_ODDS                        = float(config.get(bet_category, 'max_odds'))
        self.MIN_ODDS                        = float(config.get(bet_category, 'min_odds'))
        self.HOURS_TO_MATCH_START            = float(config.get(bet_category, 'hours_to_match_start'))
        self.DELAY_BETWEEN_TURNS_BAD_FUNDING = float(config.get(bet_category, 'delay_between_turns_bad_funding'))
        self.DELAY_BETWEEN_TURNS_NO_MARKETS  = float(config.get(bet_category, 'delay_between_turns_no_markets'))
        self.DELAY_BETWEEN_TURNS             = float(config.get(bet_category, 'delay_between_turns'))
        self.NETWORK_FAILURE_DELAY           = float(config.get(bet_category, 'network_failure_delay'))
        self.DRY_RUN                         = bool (config.get(bet_category, 'dry_run'))
        self.BET_CATEGORY = bet_category
        if self.DRY_RUN :
            self.BET_CATEGORY = 'DRY_RUN_' + self.BET_CATEGORY

        self.USERNAME                        = config.get('Login', 'username') 
        self.PASSWORD                        = config.get('Login', 'password')
        self.PRODUCT_ID                      = config.get('Login', 'product_id')
        self.VENDOR_ID                       = config.get('Login', 'vendor_id')

############################# end initialize


    