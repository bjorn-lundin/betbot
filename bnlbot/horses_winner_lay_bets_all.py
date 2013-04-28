# -*- coding: iso-8859-1 -*-
"""put bet on games with low odds"""

from betbot import BetBot, SessionError, TooCloseToLossError, RecoveredFromLossError
from time import sleep
import urllib2
import ssl
import socket
import logging.handlers
import httplib2
from market import Market



class HorsesWinnerLayBetBot(BetBot):
    """put bet on games with low odds"""

    def __init__(self, log):
        super(HorsesWinnerLayBetBot, self).__init__(log)

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
                selection = None

                race_list = []
                for runner in prices['runners'] :
                    try :
                        tmp_bp = float(runner['back_prices'][0]['price'])
                    except:
                        tmp_bp = 1001.0
                    try :
                        tmp_lp = float(runner['lay_prices'][0]['price'])
                    except:
                        tmp_lp = 1001.0
                    try :
                        sel_id = int(runner['selection_id'])
                    except:
                        sel_id = -1
                    try :
                        idx = int(runner['order_index'])
                    except:
                        idx = -1

                    self.log.info( 'UNSORTED back/lay/selection/idx ' +
                            str(tmp_bp) + '/' +
                            str(tmp_lp) + '/' +
                            str(sel_id) + '/' +
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

                market = Market(self.conn, self.log, market_id = market_id)
                # there must be at least 3 runners with lower odds
                number_of_runners = len(sorted_list)
                max_turns = number_of_runners - 2 - market.no_of_winners

                favorite_odds = 100.0
                #loop through list and keep last entry -> favorite
                for dct in sorted_list :
                    favorite_odds = float(dct[1])


                for dct in sorted_list :
                    i = i + 1
                    if i >= max_turns  :
                        self.log.info('number_of_runners = ' \
                            + str(number_of_runners) + \
                            'max turns = ' + str(max_turns) + ' i = ' + str(i))
                        self.log.info('Too close to winner positon, exit')
                        return

                    self.log.info( 'SORTED back/lay/selection/idx ' + \
                            str(dct[0]) + '/' + \
                            str(dct[1]) + '/' + \
                            str(dct[2]) + '/' + \
                            str(dct[3])                         )
                    if  (self.MIN_ODDS <= float(dct[1]) and
                         float(dct[1]) <= self.MAX_ODDS and
                          i <= max_turns) :
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

                if favorite_odds >= 5.0 :
                    self.log.info( 'Favorite sucks, odds= '+ str(favorite_odds) + ' must be >= 5.0 - exit check_strategy')
                    return


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
                            if int(runner['selection_id']) == int(selection) :
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



bot = HorsesWinnerLayBetBot(alog)
bot.initialize('HORSES_WINNER_LAY_BET_ALL')

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

    except RecoveredFromLossError as e :
        alog.info( 'won enough - waiting for tomorrow ' + \
        str(bot.NETWORK_FAILURE_DELAY) + 'seconds')
        alog.info(e.args)
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
