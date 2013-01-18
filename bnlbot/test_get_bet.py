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


class SimpleBot(object):
    """put bet on games with low odds"""
    BETTING_SIZE = 30.0
    MIN_ODDS = 1.7
    MAX_ODDS = 20.04
    HOURS_TO_MATCH_START = 0.1
    DELAY_BETWEEN_TURNS_BAD_FUNDING = 60.0
    DELAY_BETWEEN_TURNS_NO_MARKETS =  60.0
    NETWORK_FAILURE_DELAY = 60.0
    DELAY_BETWEEN_TURNS = 5.0
    conn = None
    
    def __init__(self, log):
        rps = 1/4.0 # Refreshes Per Second
        self.api = API('uk') # exchange ('uk' or 'aus')
        self.no_session = True
        self.throttle = {'rps': 1.0 / rps, 'next_req': time()}
        db = Db() 
        self.conn = db.conn 
        self.log = log
        
############################# end __init__


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

    def do_throttle(self):
        """return only when it is safe to send another data request"""
        wait = self.throttle['next_req'] - time()
        if wait > 0: sleep(wait)
        self.throttle['next_req'] = time() + self.throttle['rps']
############################# end do_throttle






    def start(self, uname = '', pword = '', prod_id = '', vend_id = ''):
        """start the main loop"""
        # login/monitor status
        self.do_throttle()
        login_status = self.login(uname, pword, prod_id, vend_id)
        while login_status == 'OK':
            # get list of markets starting soon
            self.log.info( '-----------------------------------------------------------')
            self.do_throttle()
            bet = self.api.get_bet(24433816381)
            self.log.info(bet)
            break

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
    'logs/test_get_bet.log',
    mode = 'a',
    maxBytes = 500000,
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
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

bot = SimpleBot(log)

while True:
    try:
        bot.start('bnlbnl', 'rebecca1', '82', '0') # product id 82 = free api
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
