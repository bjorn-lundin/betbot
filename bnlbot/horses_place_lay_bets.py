# -*- coding: iso-8859-1 -*- 
"""put bet on games with low odds"""

from betbot import BetBot, SessionError
from time import sleep
import urllib2
import ssl
import socket
import logging.handlers
import httplib2



class HorsesPlaceLayBetBot(BetBot):
    """put bet on games with low odds"""

    def __init__(self, log):
        super(HorsesPlaceLayBetBot, self).__init__(log)
        
############################# end __init__

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
#                lay_price = None 
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
                        
                    self.log.info( 'UNSORTED back/lay/selection/idx ' + \
                            str(tmp_bp) + '/' + \
                            str(tmp_lp) + '/' + \
                            str(sel_id) + '/' + \
                            str(idx)                         )
                    tmp_tuple = (tmp_bp, tmp_lp, sel_id, idx)
                    race_list.append(tmp_tuple)    

                sorted_list = sorted(race_list, reverse=True)
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
                            #pick the first hore with reasonable odds, but it must 
                            #be 1 of the 3 from the top of the reversed list
                    if dct[1] <= self.MAX_ODDS and  dct[1] >= self.MIN_ODDS and i <= 3 :
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
                    self.log.info( 'No name for chosen runner found, exit check_strategy')
                    return
                                
                # we have a name,selection and layodds.
                  
                self.log.info( 'odds back : ' + str(back_odds))
                self.log.info( 'odds lay  : ' + str(lay_odds))
                self.log.info( 'selection : ' + str(selection))
                self.log.info( 'name      : ' + str(name))
                self.log.info( 'index     : ' + str(index))
                                    
                if lay_odds and selection:
                    self.place_bet(market_id, selection, lay_odds, name)
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

bot = HorsesPlaceLayBetBot(alog)
bot.initialize('HORSES_PLACE_LAY_BET')

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
    