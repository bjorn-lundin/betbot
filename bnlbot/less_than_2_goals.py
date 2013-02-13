# -*- coding: iso-8859-1 -*-
"""put bet on games with low odds"""
from betbot import BetBot, SessionError, TooCloseToLossError

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

class LessThan2Goals(BetBot):
    """put bet on games with low odds"""

    def __init__(self, log):
        super(LessThan2Goals, self).__init__(log)

############################# end __init__

    def check_strategy(self, market_id ):
        """check market for suitable bet"""
        if market_id:
            # get market prices
            self.do_throttle()
            prices = self.api.get_market_prices(market_id)
            if type(prices) is dict and prices['status'] == 'ACTIVE':
                # loop through runners and prices and create bets
                # the no-red-card runner is [1]
                back_price = None
                selection = None
                name = None
                try :
                    odds_under      = float(prices['runners'][0]['back_prices'][0]['price'])
                    selection_under = int(prices['runners'][0]['selection_id'])
                    odds_over       = float(prices['runners'][1]['back_prices'][0]['price'])
                    selection_over  = int(prices['runners'][1]['selection_id'])
                except:
                    self.log.info( '#############################################')
                    self.log.info( 'prices missing some fields, do return ')
                    self.log.info( '#############################################')
                    return

                self.log.info( 'odds under : ' + str(odds_under))
                self.log.info( 'odds over  : ' + str(odds_over))

                #odds_over, ie more than 0 goals
                if ( self.PRICE - self.DELTA <= odds_over and
                     odds_over <= self.PRICE + self.DELTA
                         ):

                    back_price = odds_under
                    selection = selection_under

                    self.place_bet(market_id, selection, back_price, name)

                else:
                    self.log.info('bad odds or time in game -> no bet on market ' +
                        str(market_id))

            elif prices == 'API_ERROR: NO_SESSION':
                self.no_session = True
            elif type(prices) is not dict:
                s = 'check_strategy() ERROR: prices = ' + str(prices) + '\n'
                s += '---------------------------------------------'
                self.log.info(s)
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



bot = LessThan2Goals(alog)
bot.initialize('LESS_THAN_1.5_GOALS')

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

    except TooCloseToLossError as e :
        alog.error( 'Too close in time to last loss.  Retry in ' + \
        str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
        alog.error(e.args)
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
