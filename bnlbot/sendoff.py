# -*- coding: iso-8859-1 -*- 
"""put bet on games with low odds"""
from betbot import BetBot, SessionError

#from betfair.api import API
from time import sleep
#, time
#import datetime 
#import psycopg2
import urllib2
import ssl
#import os
#import sys
#from game import Game
#from market import Market
#from funding import Funding
#from db import Db
import socket
import logging.handlers
#from operator import itemgetter, attrgetter
import httplib2
#import ConfigParser

class SendOff(BetBot):
    """put bet on games with low odds"""

    def __init__(self, log):
        super(SendOff, self).__init__(log)
############################# end __init__


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
                    temp = [sec_til_start, market]
                    markets.append(temp)
            markets.sort() # sort into time order (earliest game first)
            return markets
        elif markets == 'API_ERROR: NO_SESSION':
            self.no_session = True
        else:
            return markets
############################# end get_markets



    def check_strategy(self, market_id ):
        """check market for suitable bet"""
        if market_id:
            # get market prices
            self.do_throttle()
            prices = self.api.get_market_prices(market_id)
            if type(prices) is dict and prices['status'] == 'ACTIVE':
                # loop through runners and prices and create bets
                # the no-red-card runner is [1]
                name = None
                back_price = None 
                selection = None

                try :
                    odds_yes      = prices['runners'][0]['back_prices'][0]['price']
#                    selection_yes = prices['runners'][0]['selection_id']
                    odds_no       = prices['runners'][1]['back_prices'][0]['price']
                    selection_no  = prices['runners'][1]['selection_id']
                except:
                    self.log.info( '#############################################')
                    self.log.info( 'prices missing some fields, do return ')
                    self.log.info( '#############################################')
                    return

                self.log.info( 'odds utvisning -ja  : ' + str(odds_yes))
                self.log.info( 'odds utvisning -nej :' + str(odds_no))
                

                #no sendoff
                if odds_no and \
                   odds_no >= self.MIN_ODDS :
   
                    back_price = odds_no
                    selection = selection_no

                    self.place_bet(market_id, selection, back_price, name)
                    
                else:
                    self.log.info('bad odds or time in game -> no bet on market ' +
                        str(market_id))

            elif prices == 'API_ERROR: NO_SESSION':
                self.no_session = True
            elif type(prices) is not dict:
                tmp_str = 'check_strategy() ERROR: prices = ' + str(prices) + '\n'
                tmp_str += '---------------------------------------------'
                self.log.info(tmp_str)
############################# check_strategy









######## main ###########
alog = logging.getLogger(__name__)
alog.setLevel(logging.DEBUG)
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
alog.addHandler(FH)
alog.info('Starting application')

#make print flush now!
#sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)



bot = SendOff(alog)
bot.initialize('SENDOFF_NO')

while True:
    try:
        bot.start()
    except urllib2.URLError :
        alog.error( 'Lost network ? . Retry in ' + \
        str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
        sleep (bot.NETWORK_FAILURE_DELAY)

    except ssl.SSLError :
        alog.error( 'Lost network (ssl error) . Retry in ' + \
                    str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
        sleep (bot.NETWORK_FAILURE_DELAY)
       
    except socket.error as ex:
        alog.error( 'Lost network (socket error) . Retry in ' + \
        str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
        sleep (bot.NETWORK_FAILURE_DELAY)

    except httplib2.ServerNotFoundError :
        alog.error( 'Lost network (server not found error) . Retry in ' + \
        str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
        sleep (bot.NETWORK_FAILURE_DELAY)
        
    except SessionError:
        alog.error( 'Lost session.  Retry in ' + \
        str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
        sleep (bot.NETWORK_FAILURE_DELAY)
             
#    except psycopg2.DatabaseError :
#        alog.error( 'Lost db contact . Retry in ' + \
#          str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
#        sleep (bot.NETWORK_FAILURE_DELAY)
#        bot.reconnect()

    except KeyboardInterrupt :
        break

alog.info('Ending application')
logging.shutdown()
    