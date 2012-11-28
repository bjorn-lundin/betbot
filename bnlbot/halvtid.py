# coding=iso-8859-15
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
import socket

class SimpleBot(object):
    """put bet on games with low odds"""
    BETTING_SIZE = 30.0
    MIN_ODDS = 1.04
    HOURS_TO_MATCH_START = 0.25
    DELAY_BETWEEN_TURNS_BAD_FUNDING = 60.0
    DELAY_BETWEEN_TURNS_NO_MARKETS =  60.0
    NETWORK_FAILURE_DELAY = 60.0
    HALV_TIME_ZERO_GOAL_LEAD_TIME = 44
    HALV_TIME_ONE_GOAL_LEAD_TIME = 43
    HALV_TIME_ONE_GOAL_HIGH_ODDS_DIFF_LEAD_TIME = 37
    HALV_TIME_TWO_GOAL_LEAD_TIME_HIGH_ODDS_DIFF = 28
    HIGH_ODDS_DIFF = 30.0
    DELAY_BETWEEN_TURNS = 5.0
    conn = None
    
    def __init__(self):
        rps = 1/2.0 # Refreshes Per Second
        self.api = API('uk') # exchange ('uk' or 'aus')
        self.no_session = True
        self.throttle = {'rps': 1.0 / rps, 'next_req': time()}
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


    def insert_market(self, market):
        m = market[1]
        last_refresh = str(datetime.datetime.fromtimestamp(int(m['last_refresh'])/1000))
        # extract teams from path, if possible
        #\Fotboll\england\premier leauge\10 november\stoke - arsenal
        #\Fotboll\england\premier leauge\10 november\stoke vs arsenal
        #\Fotboll\england\premier leauge\10 november\stoke versus arsenal
        # make path to list, split on '\', and use last item
        
        path_as_list = m['menu_path'].split('\\')
        teams = path_as_list[len(path_as_list) -1].lower()
        
        teams = teams.replace(' - ','|')
        teams = teams.replace(' v ','|')
        teams = teams.replace(' vs ','|')
        teams = teams.replace(' versus ','|')
        list_teams = teams.split('|')
        try: 
            home_team = list_teams[0]
        except :
            home_team = None
        try: 
            away_team = list_teams[1]
        except :
            away_team = None        

        game_id = None
        
        cur8 = self.conn.cursor()
        cur8.execute("select GAMES.XML_SOCCER_ID from \
                MARKETS, \
                GAMES, \
                TEAM_ALIASES HOME_ALIASES, \
                TEAM_ALIASES AWAY_ALIASES \
                where MARKETS.HOME_TEAM = HOME_ALIASES.TEAM_ALIAS \
                and   MARKETS.AWAY_TEAM = AWAY_ALIASES.TEAM_ALIAS \
                and   GAMES.HOME_TEAM_ID = HOME_ALIASES.TEAM_ID \
                and   GAMES.AWAY_TEAM_ID = AWAY_ALIASES.TEAM_ID \
                and   MARKETS.MARKET_ID = %s", (m['market_id'],))
        row = cur8.fetchone()
        if cur8.rowcount >= 1 :
            game_id = row[0]
                        
        cur8.close()

        
        cur7 = self.conn.cursor()
        cur7.execute("SAVEPOINT B")
        cur7.close()
        try  :
            cur = self.conn.cursor()
            cur.execute("insert into MARKETS ( \
                       MARKET_ID, BSP_MARKET, \
                       MARKET_TYPE, EVENT_HIERARCHY, \
                       LAST_REFRESH, TURNING_IN_PLAY, \
                       MENU_PATH, BET_DELAY, \
                       EXCHANGE_ID, COUNTRY_CODE, \
                       MARKET_NAME, MARKET_STATUS, \
                       EVENT_DATE, NO_OF_RUNNERS, \
                       TOTAL_MATCHED, NO_OF_WINNERS, \
                       HOME_TEAM, AWAY_TEAM, \
                       TS, XML_SOCCER_ID) \
                       values \
                      (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s, \
                      %s,%s,%s,%s,%s,%s,%s,%s,%s)",
                      (m['market_id'],     m['bsp_market'],      \
                       m['market_type'],   m['event_hierarchy'], \
                       last_refresh ,      m['turning_in_play'], \
                       m['menu_path'],     m['bet_delay'], \
                       m['exchange_id'],   m['country_code'],    \
                       m['market_name'],   m['market_status'], \
                       m['event_date'],    m['no_of_runners'],   \
                       m['total_matched'], m['no_of_winners'],
                       home_team, away_team, None, game_id))
            cur.close()
#            print 'insert into markets ', m['market_id']
#            print 'insert into markets ', home_team, '-', away_team
            
        except psycopg2.IntegrityError:
            cur.close()
            cur6 = self.conn.cursor()
            cur6.execute("ROLLBACK TO SAVEPOINT B" )
            cur6.close()
#            print 'ROLLBACK on insert into markets ', home_team, '-', away_team
            if game_id :
                cur7 = self.conn.cursor()
                cur7.execute("update MARKETS set XML_SOCCER_ID = %s \
                              where MARKET_ID = %s \
                              and XML_SOCCER_ID is null", 
                              (game_id, m['market_id']))
                cur7.close()
        
        
        
        for team in list_teams :
            cur2 = self.conn.cursor()
            cur2.execute("select * from TEAM_ALIASES \
                          where TEAM_ALIAS = %s", (team,))
            rc = cur2.rowcount
            cur2.close()
            if rc == 0 :
                print 'Team not found in TEAM_ALIASES:', team
                cur3 = self.conn.cursor()
                cur3.execute("SAVEPOINT A")
                cur3.close()
                try  :
                    cur4 = self.conn.cursor()
                    cur4.execute("insert into UNIDENTIFIED_TEAMS \
                                 (TEAM_NAME,COUNTRY_CODE) values (%s,%s)",
                                 (team, m['country_code']))
                    cur4.close()
                except psycopg2.IntegrityError:
                    cur5 = self.conn.cursor()
                    cur5.execute("ROLLBACK TO SAVEPOINT A" )
                    cur5.close()
                    
#        print 'insert into markets ', m['market_id'], 'done'
                                        
############################# end insert_market
        

    def insert_bet(self, bet, resp, bet_type):
        print 'insert bet', bet, resp
        cur = self.conn.cursor()
        cur.execute("select * from BETS where BET_ID = %s", (resp['bet_id'],))
        if cur.rowcount == 0 :
            print 'insert bet', resp['bet_id']
            cur.execute("insert into BETS ( \
                         BET_ID, MARKET_ID, SELECTION_ID, PRICE, \
                         CODE, SUCCESS, SIZE, BET_TYPE ) \
                         values \
                         (%s,%s,%s,%s,%s,%s,%s,%s)", \
               (resp['bet_id'],bet['marketId'], bet['selectionId'], \
                resp['price'], resp['code'], resp['success'], \
                resp['size'], bet_type))
        cur.close()
############################# end insert_bet


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
                if (    market['market_name'] == 'Halvtid' # 
                    and market['market_status'] == 'ACTIVE' # market is active
                    and market['market_type'] == 'O' # Odds market only
                    and market['no_of_winners'] == 1 # single winner market
                    and market['bet_delay'] > 0 # started -
                    ):
                    # calc seconds til start of game
                    delta = market['event_date'] - self.api.API_TIMESTAMP
                    # 1 day = 86400 sec
                    sec_til_start = delta.days * 86400 + delta.seconds
#                    print 'market', market['market_id'], market['menu_path'], \
#                       'will start in', sec_til_start, 'seconds Halvtid'
                    temp = [sec_til_start, market]
                    markets.append(temp)
            markets.sort() # sort into time order (earliest game first)
            return markets
        elif markets == 'API_ERROR: NO_SESSION':
            self.no_session = True
        else:
            return markets
############################# end get_markets

    def do_throttle(self):
        """return only when it is safe to send another data request"""
        wait = self.throttle['next_req'] - time()
        if wait > 0: sleep(wait)
        self.throttle['next_req'] = time() + self.throttle['rps']
############################# end do_throttle


    def check_strategy(self, market_id = '', path=''):
        """check market for suitable bet"""
        if market_id:
            # get market prices
            self.do_throttle()
            prices = self.api.get_market_prices(market_id)
            if type(prices) is dict and prices['status'] == 'ACTIVE':
                # loop through runners and prices and create bets
                # the no-red-card runner is [1]
                my_market = Market(market_id, self.conn)                
                bets = []
                back_price = None 
                selection = None

                my_game = Game(self.conn, my_market.home_team_id, \
                               my_market.away_team_id)    
                if not my_game.found :
                    print datetime.datetime.now(), 'game not found home_team_id', \
                          my_market.home_team_id, \
                          'away_team_id', my_market.away_team_id
                    return    

                try:
                    my_time = int(my_game.time_in_game)
                except ValueError:
                    my_time = 1000                         

                if my_time > 47 : 
                    print 'Halftime, to late for bets (47 min)'
                    print 'Tid förflutet', my_game.time_in_game
                    return
                    
                    
                try :
                    odds_home_victory = prices['runners'][0]['back_prices'][0]['price']
                    odds_away_victory = prices['runners'][1]['back_prices'][0]['price']
                    odds_draw = prices['runners'][2]['back_prices'][0]['price']
                    selection_home_victory = prices['runners'][0]['selection_id']
                    selection_away_victory = prices['runners'][1]['selection_id']
                    selection_draw = prices['runners'][2]['selection_id']
                except:
                    print '#############################################'
                    print 'prices missing some fields, do return', \
                           my_market.home_team_name, '-', \
                           my_market.away_team_name
#                    print prices
                    print '#############################################'
                    return


                    
                print 'game :' , my_market.home_team_name, ' - ', \
                       my_market.away_team_name
                print 'odds hemmaseger :', odds_home_victory
                print 'odds bortaseger :', odds_away_victory
                print 'odds oavgjort   :', odds_draw
                print 'Hemma           :', my_game.home_goals
                print 'Borta           :', my_game.away_goals
                print 'Tid             :', my_game.time_in_game
                
                bet_category = None

                #away victory? 2 goal lead, early, and big odds diff
                if odds_away_victory and \
                   odds_home_victory and \
                   odds_away_victory >= self.MIN_ODDS and \
                   odds_away_victory - odds_home_victory > self.HIGH_ODDS_DIFF and \
                   my_game.away_goals - my_game.home_goals  >= 2 and \
                   my_game.time_in_game_numeric and \
                   int(my_game.time_in_game) >= self.HALV_TIME_TWO_GOAL_LEAD_TIME_HIGH_ODDS_DIFF :

                    back_price = odds_away_victory
                    selection = selection_away_victory
                    bet_category = 'AWAY_HALV_TIME_TWO_GOAL_LEAD_TIME_HIGH_ODDS_DIFF'

                #home victory? 2 goal lead, early, and big odds diff
                elif odds_away_victory and \
                     odds_home_victory and \
                     odds_home_victory >= self.MIN_ODDS and \
                     odds_home_victory - odds_away_victory > self.HIGH_ODDS_DIFF and \
                     my_game.home_goals - my_game.away_goals  >= 2 and \
                     my_game.time_in_game_numeric and \
                     int(my_game.time_in_game) >= self.HALV_TIME_TWO_GOAL_LEAD_TIME_HIGH_ODDS_DIFF :

                    back_price = odds_home_victory
                    selection = selection_home_victory
                    bet_category = 'HOME_HALV_TIME_TWO_GOAL_LEAD_TIME_HIGH_ODDS_DIFF'

                #away victory? 2 goal lead, early, and big odds diff
                elif odds_away_victory and \
                   odds_home_victory and \
                   odds_away_victory >= self.MIN_ODDS and \
                   odds_away_victory - odds_home_victory > self.HIGH_ODDS_DIFF and \
                   my_game.away_goals - my_game.home_goals  >= 1 and \
                   my_game.time_in_game_numeric and \
                   int(my_game.time_in_game) >= self.HALV_TIME_ONE_GOAL_HIGH_ODDS_DIFF_LEAD_TIME :

                    back_price = odds_away_victory
                    selection = selection_away_victory
                    bet_category = 'AWAY_HALV_TIME_ONE_GOAL_HIGH_ODDS_DIFF_LEAD_TIME'

                #home victory? 2 goal lead, early, and big odds diff
                elif odds_away_victory and \
                     odds_home_victory and \
                     odds_home_victory >= self.MIN_ODDS and \
                     odds_home_victory - odds_away_victory > self.HIGH_ODDS_DIFF and \
                     my_game.home_goals - my_game.away_goals  >= 1 and \
                     my_game.time_in_game_numeric and \
                     int(my_game.time_in_game) >= self.HALV_TIME_ONE_GOAL_HIGH_ODDS_DIFF_LEAD_TIME :

                    back_price = odds_home_victory
                    selection = selection_home_victory
                    bet_category = 'HOME_HALV_TIME_ONE_GOAL_HIGH_ODDS_DIFF_LEAD_TIME'

                #home victory? 1 goal lead, fairly soon end halftime
                elif odds_home_victory and \
                     odds_home_victory >= self.MIN_ODDS and \
                     my_game.home_goals - my_game.away_goals  >= 1 and \
                     my_game.time_in_game_numeric and \
                     int(my_game.time_in_game) >= self.HALV_TIME_ONE_GOAL_LEAD_TIME :
                   
                    back_price = odds_home_victory
                    selection = selection_home_victory
                    bet_category = 'HOME_HALV_TIME_ONE_GOAL_LEAD_TIME'

                #away victory? 1 goal lead, fairly soon end halftime
                elif odds_away_victory and \
                     odds_away_victory >= self.MIN_ODDS and \
                     my_game.away_goals - my_game.home_goals  >= 1 and \
                     my_game.time_in_game_numeric and \
                     int(my_game.time_in_game) >= self.HALV_TIME_ONE_GOAL_LEAD_TIME :

                    back_price = odds_away_victory
                    selection = selection_away_victory
                    bet_category = 'AWAY_HALV_TIME_ONE_GOAL_LEAD_TIME'

                #tie halftime victory?  soon end halftime
                elif odds_draw and \
                     odds_draw >= self.MIN_ODDS and \
                     my_game.home_goals - my_game.away_goals  == 0 and \
                     my_game.time_in_game_numeric and \
                     int(my_game.time_in_game) >= self.HALV_TIME_ZERO_GOAL_LEAD_TIME :

                    back_price = odds_draw
                    selection = selection_draw
                    bet_category = 'TIE_HALV_TIME_ZERO_GOAL_LEAD_TIME'

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
#                    print datetime.datetime.now(), 'bet', bet, 'path', path
                else:
                    print datetime.datetime.now(),  \
                         'bad odds or time in game -> no bet on market', \
                          market_id, my_market.home_team_name, '-', \
                                 my_market.away_team_name
                # place bets (if any have been created)
                if bets:
#                    resp = 'bnl-no-bet'
                    resp = self.api.place_bets(bets)
                    s = 'PLACING BETS...\n'
                    s += 'Bets: ' + str(bets) + '\n'
                    s += 'Place bets response: ' + str(resp) + '\n'
                    s += '---------------------------------------------'
                    print s
                    self.insert_bet(bets[0], resp[0], bet_category)
#                    a=d
                    # check session
                    if resp == 'API_ERROR: NO_SESSION':
                        self.no_session = True
            elif prices == 'API_ERROR: NO_SESSION':
                self.no_session = True
            elif type(prices) is not dict:
                s = 'check_strategy() ERROR: prices = ' + str(prices) + '\n'
                s += '---------------------------------------------'
                print s
############################# check_strategy


    def start(self, uname = '', pword = '', prod_id = '', vend_id = ''):
        """start the main loop"""
        # login/monitor status
        login_status = self.login(uname, pword, prod_id, vend_id)
        while login_status == 'OK':
            # get list of markets starting soon
            print '-----------------------------------------------------------'
            markets = self.get_markets()
            if type(markets) is list:
                if len(markets) == 0:
                    # no markets found...
                    print datetime.datetime.now(), 'HALVTID No markets found. Sleep', \
                          self.DELAY_BETWEEN_TURNS_NO_MARKETS, 's.'
                    sleep(self.DELAY_BETWEEN_TURNS_NO_MARKETS) #bandwidth saver
                else:
                    print datetime.datetime.now(), 'Found', len(markets), \
                          'markets. Checking strategy...'
                    for market in markets:
                        market_id = market[1]['market_id']
#                        print 'will insert market, market_id', market_id, 'path', market[1]['menu_path']
                        self.insert_market(market)
#                        print 'has inserted market, market_id', market_id, 'path', market[1]['menu_path']
                        # do we have bets on this market?
                        my_market = Market(market_id, self.conn)
                        my_market.try_set_gamestart(market[1]['bet_delay'])
                        
                        if not my_market.market_in_xmlfeed() :
                            print datetime.datetime.now(), \
                                  'market not in xmlfeed', \
                                   my_market.home_team_name, '-', \
                                   my_market.away_team_name
                        else :
                            mu_bets = self.api.get_mu_bets(market_id)
                            if mu_bets == 'NO_RESULTS':
#                                print 'We have no bets on market', market_id, \
#                                        'path-', market[1]['menu_path']
                                # we have no bets on this market...
                                self.do_throttle()
                                funds = Funding(self.api)
                                self.do_throttle()
                                funds.check_and_fix_funds()
                                if funds.funds_ok:
                                    self.do_throttle()
                                    self.check_strategy(market_id, market[1]['menu_path'])
                                else :    
                                    print 'Something happened with funds', funds 
                                    sleep(self.DELAY_BETWEEN_TURNS_BAD_FUNDING)     
                            else : 
                                print 'We have ALREADY bets on market', \
                                       market_id,  \
                                       my_market.home_team_name, '-', \
                                       my_market.away_team_name
                                    
                        self.conn.commit()
                # check if session is still OK
                if self.no_session:
                    login_status = self.login(uname, pword, prod_id, vend_id)
                    s = 'API ERROR: NO_SESSION. Login resp =' + \
                         str(login_status) + '\n'
                    s += '---------------------------------------------'
                    print s
            print 'sleeping', self.DELAY_BETWEEN_TURNS, 's between turns'
            sleep(self.DELAY_BETWEEN_TURNS)
        # main loop ended...
        s = 'login_status = ' + str(login_status) + '\n'
        s += 'MAIN LOOP ENDED...\n'
        s += '---------------------------------------------'
        print datetime.datetime.now(), s
############################# end start

#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

bot = SimpleBot()
print 'Starting up:', datetime.datetime.now()
bot.conn = psycopg2.connect("dbname='betting' \
                             user='bnl' \
                             host='192.168.0.24' \
                             password=None") 
#bot.conn = psycopg2.connect("dbname='bnl' \
#                             user='bnl' \
#                             host='nonodev.com' \
#                             password='BettingFotboll1$'") 
while True:
    try:
        bot.start('bnlbnl', 'rebecca1', '82', '0') # product id 82 = free api
    except urllib2.URLError :
        print 'Lost network. Retry in', bot.NETWORK_FAILURE_DELAY, 'seconds'
        sleep (bot.NETWORK_FAILURE_DELAY) 

    except ssl.SSLError :
        print 'Lost network (ssl error). Retry in', bot.NETWORK_FAILURE_DELAY, 'seconds'
        sleep (bot.NETWORK_FAILURE_DELAY)

    except socket.error as ex:
        print "URLError error({0}): {1}".format(ex.errno, ex.strerror)
        print 'Lost network (socket error). Retry in', bot.NETWORK_FAILURE_DELAY, 'seconds'
        sleep (bot.NETWORK_FAILURE_DELAY)
    
print 'Ending:', datetime.datetime.now()

