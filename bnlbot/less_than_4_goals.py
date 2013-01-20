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
from funding import Funding
#from db import Db
import socket
import logging.handlers
#from operator import itemgetter, attrgetter
import httplib2
#import ConfigParser

class LessThan4Goals(BetBot):
    """put bet on games with low odds"""

    def __init__(self, log):
        super(LessThan4Goals, self).__init__(log)
        
############################# end __init__


    def get_markets(self):
        """returns a list of markets or an error string"""
        # NOTE: get_all_markets is NOT subject to data charges!
#        print datetime.datetime.now(), 'api.get_all_markets start'
        markets = self.api.get_all_markets(
              events = ['1','14'],
              hours = self.HOURS_TO_MATCH_START,
              countries = None)
#              countries = ['GBR'])
#        print datetime.datetime.now(), 'api.get_all_markets stop'
              #http://en.wikipedia.org/wiki/List_of_FIFA_country_codes
              #http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3
        if type(markets) is list:
            # sort markets by start time + filter
            for market in markets[:]:
             # loop through a COPY of markets 
             #as we're modifying it on the fly...
                markets.remove(market)
               
                market_ok = market['market_name'].find('ver/under 3.5 m') > -1
                if (  market_ok # 'ver/under 0.5 m'
                    and market['market_status'] == 'ACTIVE' # market is active
                    and market['market_type'] == 'O' # Odds market only
                    and market['no_of_winners'] == 1 # single winner market
                    and market['bet_delay'] == 0 # not started, but 0.1 hours until start
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
                bets = []
                back_price = None 
                selection = None
                name = None
                try :
                    odds_under      = prices['runners'][0]['back_prices'][0]['price']
                    selection_under = prices['runners'][0]['selection_id']
                    odds_over       = prices['runners'][1]['back_prices'][0]['price']
                    selection_over  = prices['runners'][1]['selection_id']
                except:
                    self.log.info( '#############################################')
                    self.log.info( 'prices missing some fields, do return ')
                    self.log.info( '#############################################')
                    return
                
                self.log.info( 'odds under : ' + str(odds_under))
                self.log.info( 'odds over  : ' + str(odds_over))
                
                #odds_over, ie more than 0 goals
                if odds_under and \
                   odds_under >= self.MIN_ODDS :

                        back_price = odds_under
                        selection = selection_under

                       
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
                         str(market_id))
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



bot = LessThan4Goals(alog)
bot.initialize('LESS_THAN_3.5_GOALS')

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
    