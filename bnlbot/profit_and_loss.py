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

class SimpleBot(object):
    """put bet on games with low odds"""
    DELAY_BETWEEN_TURNS            =  5.0
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


    def update_bet(self, bet ):        
        betid = bet['betId'], 
        profit = bet['profitAndLoss']
        status = bet['betStatus']
        matched_size = bet['matchedSize']
        avg_price = bet['avgPrice']
        bet_placed = bet['placedDate']
        full_market_name = bet['fullMarketName']
        #.decode("iso-8859-1")
        
        the_bet_won = float(profit) >= 0.0
        self.log.info( 'update bet:' + str(betid) + ' to profit= ' + str(profit) + ' bet_won = ' + str(the_bet_won) )
        cur = self.conn.cursor()        
        cur.execute("update BETS " + \
                    "set PROFIT = %s, " + \
                    "BET_WON = %s, " + \
                    "CODE = %s, " + \
                    "SIZE = %s, " + \
                    "PRICE = %s, " + \
                    "BET_PLACED = %s, " + \
                    "FULL_MARKET_NAME = %s " + \
                    "where BET_ID = %s", 
                    (profit, the_bet_won, status, matched_size, avg_price, bet_placed, full_market_name, betid))
        cur.close()
        self.conn.commit()
############################# end update_bet

    def delete_bet(self, bet ):        
        betid = bet['betId'], 
        status = bet['betStatus']

        self.log.info( 'delete bet:' + str(betid) + ' status= ' + str(status) + ' bet = ' + str(bet) )
        cur = self.conn.cursor()        
        cur.execute("delete from BETS where BET_ID = %s", (betid,))
        cur.close()
        self.conn.commit()
############################# end delete_bet

    def get_unsettled_bets(self):
        """returns a list of markets with no profit in db or an error string"""

        self.log.info( 'calling get_unsettled_bets : ' )
        betids = []
        cur = self.conn.cursor()        
        cur.execute("select BET_ID from BETINFO"  \
                    " where CODE <> 'S'"  \
                    " and BET_TYPE not like 'DRY_RUN%'" \
                    " order by BET_ID")

        row = cur.fetchone()
        while row:
            betids.append(int(row[0]))
            row = cur.fetchone()
            
        cur.close()
        self.conn.commit()
        
        bets = []
        for betid in betids :
            self.do_throttle()
            bet = self.api.get_bet(betid) 
            self.log.info( 'betid : ' + str(betid) + ' -> ' + str(bet))            
            if type(bet) is dict :
                bets.append(bet)
        return bets
        
    ############################# end get_unsettled_bet_history

    
    def do_throttle(self):
        """return only when it is safe to send another data request"""
        wait = self.throttle['next_req'] - time()
        if wait > 0: sleep(wait)
        self.throttle['next_req'] = time() + self.throttle['rps']
############################# end do_throttle

    def start(self, uname = '', pword = '', prod_id = '', vend_id = ''):
        """start the main loop"""
        # login/monitor status
        login_status = self.login(uname, pword, prod_id, vend_id)
        while login_status == 'OK': 
            # get list of markets starting soon
            self.log.info( '-----------------------------------------------------------')
            bets = self.get_unsettled_bets()
            if type(bets) is list:
                if len(bets) == 0:
                    # no markets found...
                    s = 'PROFIT_AND_LOSS No unsettled bets found. Sleeping for ' + \
                         str( self.DELAY_BETWEEN_TURNS_NO_MARKETS) + ' seconds...'
                    self.log.info(s)
                    sleep(self.DELAY_BETWEEN_TURNS_NO_MARKETS) # bandwidth saver!
                else:
#                     self.update_zeroed_bet() 
                    for bet in bets:
                        self.log.info( ' marketname:' + \
                                       bet['fullMarketName'].decode("iso-8859-1") + \
                                       str(bet) )
                        if bet['betStatus'] == 'S' :
                            self.update_bet(bet) 
                        elif bet['betStatus'] == 'L' :    
                            self.delete_bet(bet) 
                        elif bet['betStatus'] == 'V' :    
                            self.delete_bet(bet) 
                        elif bet['betStatus'] == 'C' :    
                            self.delete_bet(bet) 
                        else :
                            self.log.info( ' not settled yet, betStatus: ' + bet['betStatus'] + '  ' + \
                                       bet['fullMarketName'].decode("iso-8859-1") )
                            
                            

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
    'logs/profit_and_loss.log',
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
    