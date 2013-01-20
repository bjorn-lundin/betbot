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
from operator import itemgetter, attrgetter
import httplib2
import ConfigParser

class SimpleBot(object):
    """put bet on games with low odds"""
    DELAY_BETWEEN_TURNS            =  4.0
    NETWORK_FAILURE_DELAY          = 60.0
    DELAY_BETWEEN_TURNS_NO_MARKETS =  5.0
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
        while True :
            # get list of markets starting soon
            self.log.info( '-----------------------------------------------------------')
            now = datetime.datetime.now()
            # send saldo at 01:00 (utc = 00:00:00)            
            if now.hour == 1 and now.minute == 1 and 0 < now.second and now.second < 5 :
                login_status = self.login(uname, pword, prod_id, vend_id)
                if login_status == 'OK': 
                    funds = Funding(self.api, self.log)
                    self.do_throttle()
                    funds.mail_saldo()


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
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

config = ConfigParser.ConfigParser()
config.read('betfair_login.ini')

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
    