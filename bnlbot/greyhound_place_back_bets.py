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

class GreyHoundPlaceBackBetBot(BetBot):
    """put bet on games with low odds"""
    
    def __init__(self, log):
        super(GreyHoundPlaceBackBetBot, self).__init__(log)
        
############################# end __init__



    def get_markets(self):
        """returns a list of markets or an error string"""
        # NOTE: get_all_markets is NOT subject to data charges!
#        print datetime.datetime.now(), 'api.get_all_markets start'
#  'Horse Racing': '7', 
#  'Greyhound Racing': '4339', 

        markets = self.api.get_all_markets(
              events = ['4339'],
              hours = self.HOURS_TO_MATCH_START,
              include_started = False, # exclude in-play markets
              countries = ['GBR','USA','ZAF','FRA','IRL','NZL'])
#               countries = None)
#        print datetime.datetime.now(), 'api.get_all_markets stop'
              #http://en.wikipedia.org/wiki/List_of_FIFA_country_codes
              #http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3
        if type(markets) is list:
            # sort markets by start time + filter
            for market in markets[:]:
                self.log.info( 'market :' + str(market))
             # loop through a COPY of markets 
             #as we're modifying it on the fly...
                markets.remove(market)
                if (    market['market_name'] == 'Plats' # 
                    and market['market_status'] == 'ACTIVE' #
                    and market['market_type'] == 'O' # Odds market only
                    and market['no_of_winners'] >= 2 # kan vara fler än 3
                    and market['no_of_runners'] >= 6 # 
                    and market['bet_delay'] == 0 # not started
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
            self.log.info( 'prices :' + str(prices))
            if type(prices) is dict and prices['status'] == 'ACTIVE':
                # loop through runners and prices and create bets
                # the no-red-card runner is [1]
                bets = []
                selection = None
                
                race_list = []
                for runner in prices['runners'] :
                    try :
                        tmp_bp = runner['back_prices'][0]['price']
                    except:
                        tmp_bp = 1001                        
                    try :
                        tmp_lp = runner['lay_prices'][0]['price']
                    except:
                        tmp_lp = 1001                        
                    try :
                        sel_id = runner['selection_id']
                    except:
                        sel_id = -1                        
                    try :
                        idx = runner['order_index']
                    except:
                        idx = -1                        
                        
                    self.log.info( 'UNSORTED back/lay/selection/idx ' + 
                            str(tmp_bp) + '/' + 
                            str(tmp_lp) + '/' + 
                            str(sel_id) + '/' + 
                            str(idx)                         )
                    tmp_dict = {}
                    tmp_dict['bp'] = tmp_bp 
                    tmp_dict['lp'] = tmp_lp 
                    tmp_dict['sel_id'] = sel_id 
                    tmp_dict['idx'] = idx 
                    tmp_tuple = (tmp_bp, tmp_lp, sel_id, idx)
                    race_list.append(tmp_tuple)    

                sorted_list = sorted(race_list, reverse=False)
                i = 0  
                
                selection = None
                lay_odds = None
                back_odds = None
                name = None
                index = None
                for dct in sorted_list :
                    i += 1
                    self.log.info( 'SORTED back/lay/selection/idx ' + \
                            str(dct[0]) + '/' + \
                            str(dct[1]) + '/' + \
                            str(dct[2]) + '/' + \
                            str(dct[3])                         )
                            #pick the first hound with reasonable odds, 
                            #but it must 
                            #be 1 of the 3 from the top of the unreversed 
                            #list
                    if ( dct[0] <= self.MAX_ODDS and  
                         dct[0] >= self.MIN_ODDS and 
                         i <= 1
                       ) :
                        self.log.info( 'will bet on ' + \
                            str(dct[0]) + '/' + \
                            str(dct[1]) + '/' + \
                            str(dct[2]) + '/' + \
                            str(dct[3])                         )
                        selection = dct[2] 
                        lay_odds  = dct[1] 
                        back_odds = dct[0] 
                        index     = dct[3] 
                        break 
 
                if not selection :
                    self.log.info( 'No good runner found, exit check_strategy')
                    return
 
                
                # get the name
                if selection : 
                    self.do_throttle()
                    bf_market = self.api.get_market(market_id)
                    if bf_market and type(bf_market) is dict :
                        self.log.info('bf_market ' + str(bf_market))
                        for runner in bf_market['runners'] :
                            if runner['selection_id'] == selection :
                                name = runner['name']
                                break

                if not name :
                    self.log.info( 'No name for chosen runner found, \
                                   exit check_strategy')
                    return
                                
                # we have a name,selection and layodds.
                  
                self.log.info( 'odds back : ' + str(back_odds))
                self.log.info( 'odds lay  : ' + str(lay_odds))
                self.log.info( 'selection : ' + str(selection))
                self.log.info( 'name      : ' + str(name))
                self.log.info( 'index     : ' + str(index))
                                    
                if back_odds and selection:
                    # set price to current back price - 1 pip 
                    #(i.e.accept the next worse odds too)
                    bet_price = self.api.set_betfair_odds(price = back_odds, \
                                                          pips = -4)
                    bet_size = self.BETTING_SIZE # my stake
                    bet = {
                        'marketId': market_id,
                        'selectionId': selection,
                        'betType': 'B', # we bet winners
                        'price': '%.2f' % bet_price, #set string to 2 decimals
                        'size': '%.2f' % bet_size,
                        'betCategoryType': 'E',
                        'betPersistenceType': 'NONE',
                        'bspLiability': '0',
                        'asianLineId': '0'
                        }
                    bets.append(bet)
                else:
                    self.log.info('bad odds  -> no bet on market ' +
                         str(market_id) )
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
                            tmp_str += 'Place bets response: ' + \
                                        str(resp) + '\n'
                            tmp_str += '--------------------------------------'
                            self.log.info(tmp_str)
                            if resp == 'API_ERROR: NO_SESSION':
                                self.no_session = True
                            if not self.no_session and \
                                  resp != 'EVENT_SUSPENDED' :
                                self.insert_bet(bets[0], resp[0], \
                                             bet_category, name)
                        else :
                            self.log.warning('Something happened with funds: ' +
                            str(funds))  
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



bot = GreyHoundPlaceBackBetBot(alog)
bot.initialize('HOUNDS_PLACE_BACK_BET')

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
    