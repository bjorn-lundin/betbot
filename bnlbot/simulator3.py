# coding=iso-8859-15
#from time import sleep, time
import datetime
#import psycopg2
import os
import sys
from db import Db
from market import Market
from optparse import OptionParser
import subprocess


class BetSimulator(object):
    
    def __init__(self, opts):
        self.Db = Db()
        self.conn = self.Db.conn
        self.saldo = opts.saldo
        self.price = opts.price
        self.delta_price = opts.delta_price
        self.start_date = opts.start_date
        self.stop_date = opts.stop_date
        self.next_bet_time = None
        self.bet_type = opts.bet_type
        self.bet_name = opts.bet_name
        self.markets = []
        self.runners = []
        self.winners = []
        self.all_runners = []
        self.all_winners = []
        self.selection_id = None
        self.bet_won = False
        self.size = opts.size
        self.animal = opts.animal
        self.verbose = opts.verbose
        self.summary = opts.summary
        self.start_timer_value = None
        self.stop_timer_value = None
        self.plot = opts.plot
        
    ########################## 	    
    
    
    def start_timer(self) :
        if self.verbose:
            self.start_timer_value = datetime.datetime.now()
            
    def stop_timer(self) :
        if self.verbose:
            self.stop_timer_value = datetime.datetime.now()
            
    def stop_and_print_timer(self, text) :
        if self.verbose:
            self.stop_timer()    
            sys.stderr.write(text + ' ' + \
            str(self.stop_timer_value - self.start_timer_value) +'\n')
    
    
    def get_markets(self):
        self.start_timer()
        
        if self.animal == 'horse' :
            animal = '%/7/%'
        elif self.animal == 'hound' :
            animal = '%/4339/%'
        elif self.animal == 'human' :
            animal = '%/1/%'
        else :
            animal = 'not found'
#        print 'animal',animal
        cur = self.conn.cursor()
        
        if self.bet_name.lower() == 'plats' :
        
            cur.execute("select * from \
                     DRY_MARKETS \
                     where EVENT_DATE::date >= %s \
                     and EVENT_DATE::date <= %s \
                     and MARKET_NAME = %s \
                     and EVENT_HIERARCHY like %s \
                     and exists (select 'x' from DRY_RESULTS where \
                         DRY_MARKETS.MARKET_ID = DRY_RESULTS.MARKET_ID) \
                     order by EVENT_DATE",
             (self.start_date, self.stop_date, self.bet_name, animal))
        elif self.bet_name.lower() == 'vinnare' :
        # psycopg needs %% instead of % when literal ...
            cur.execute("select * from \
                     DRY_MARKETS \
                     where EVENT_DATE::date >= %s \
                     and EVENT_DATE::date <= %s \
                      and lower(MARKET_NAME) not like '%% v %%'  \
                      and lower(MARKET_NAME) not like '%%forecast%%'  \
                      and lower(MARKET_NAME) not like '%%tbp%%'  \
                      and lower(MARKET_NAME) not like '%%challenge%%'  \
                      and lower(MARKET_NAME) not like '%%fc%%'  \
                      and lower(MENU_PATH) not like '%%daily win%%'  \
                      and lower(MARKET_NAME) not like '%%reverse%%'  \
                      and lower(MARKET_NAME) not like '%%plats%%'  \
                      and lower(MARKET_NAME) not like '%%place%%'  \
                      and lower(MARKET_NAME) not like '%%without%%'  \
                     and EVENT_HIERARCHY like %s \
                     and exists (select 'x' from DRY_RESULTS where \
                        DRY_MARKETS.MARKET_ID = DRY_RESULTS.MARKET_ID) \
                     order by EVENT_DATE",
             (self.start_date, self.stop_date, animal))
        elif self.bet_name.lower() == 'utvisning?' :
        # psycopg needs %% instead of % when literal ...
            cur.execute("select * from \
                     DRY_MARKETS \
                     where EVENT_DATE::date >= %s \
                     and EVENT_DATE::date <= %s \
                     and MARKET_NAME = %s \
                     and EVENT_HIERARCHY like %s \
                     and exists (select 'x' from DRY_RESULTS where \
                         DRY_MARKETS.MARKET_ID = DRY_RESULTS.MARKET_ID) \
                     order by EVENT_DATE",
             (self.start_date, self.stop_date, self.bet_name, animal))
 

        self.markets = cur.fetchall()
#        print 'markets', self.markets
#        print 'date', self.date
#        print 'name', self.bet_name
        cur.close()
        self.conn.commit()
#        for market in self.markets :
#        #sys.stderr.write('market ' + str(market[0]) + '\n')
#            self.get_runners(market[0])
#            self.markets[market[0]].runners = self.runners 
#            self.get_winners(market[0])
#            self.markets[market[0]].winners = self.winners 
        

        self.stop_and_print_timer('get_markets ')
    ########################    
    

    def get_all_runners(self):
        self.start_timer()
        cur = self.conn.cursor()
        cur.execute("select * \
                     from DRY_RUNNERS ")

        self.all_runners = cur.fetchall()

        cur.close()
        self.conn.commit()    
        sys.stderr.write('get_all_runners stop ' + \
             str(datetime.datetime.now()) +'\n')
        self.stop_and_print_timer('get_all_runners')
    ########################    

    def get_runners(self, market_id):
        self.start_timer()
        self.runners = []
#        for runner in self.all_runners :
#            if int(runner[0]) == int(market_id):
#                self.runners.append(runner)
#        
        cur = self.conn.cursor()
        cur.execute("select * \
                     from DRY_RUNNERS  \
                     where MARKET_ID = %s", 
                      (market_id,))

        self.runners = cur.fetchall()

        cur.close()
        self.conn.commit()    
        self.stop_and_print_timer('get_runners ')
    ########################    

    def get_winners(self, market_id):
        self.start_timer()
        self.winners = []
#        for winner in self.all_winners :
#            if int(winner[0]) == int(market_id):
#                self.winners.append(winner)

        cur = self.conn.cursor()
        cur.execute("select * \
                     from DRY_RESULTS  \
                     where MARKET_ID = %s", 
                      (market_id,))

        self.winners = cur.fetchall()

        cur.close()
        self.conn.commit()    
        self.stop_and_print_timer('get_winners ')
    ########################    
    def get_all_winners(self):
        self.start_timer()
        cur = self.conn.cursor()
        cur.execute("select * \
                     from DRY_RESULTS")

        self.all_winners = cur.fetchall()

        cur.close()
        self.conn.commit()    
        self.stop_and_print_timer('get_all_winners')
    ########################    


    def print_saldo(self):
        if self.verbose :
            print self.saldo                          

    #############################
    def check_result(self) :
        self.start_timer()
        if self.selection_id is None :
            return
    
        price = 0.0
        if self.bet_type == 'back' :
            self.bet_won = False
            for winner in self.winners :
                if int(self.selection_id) == int(winner[1]) :
                    self.bet_won = True
                    break        
        
            for runner in self.runners:
                if int(self.selection_id) == int(runner[1]) :
                    price = float(runner[3])

        elif self.bet_type == 'lay' :
            self.bet_won = True
            for winner in self.winners :
                if int(self.selection_id) == int(winner[1]) :
                    self.bet_won = False
                    break        
                    
#            sys.stderr.write('bet won ' + str(self.bet_won) + '\n')

            for runner in self.runners:
                if int(self.selection_id) == int(runner[1]) :
                    price = float(runner[4])

        else :
            sys.stderr.write('Bad bet type', self.bet_type, \
                             'must be back or lay' + '\n')
            sys.exit(1)

        profit = 0.0
        # take care of 5% commission here
        if self.bet_won :
            if self.bet_type == 'back' :
                profit = 0.95 * self.size * price 
            elif self.bet_type == 'lay' :
                #312.59 -> 341.09 ( 5% commission?)
                # 30 * 3.65 = 109,5
                #233.09 + 109.5 - (30 * 0.05) = 341.09
                profit = (self.size * price) - (self.size * 0.05) 

                    #312,59 -> 233.09. bet 30@3.65
                    #312.59 - (30*3.65) + 30 = 233.09 
            else :
                sys.stderr.write('Bad bet type', self.bet_type, \
                                 'must be back or lay' + '\n')
                sys.exit(1)
        self.saldo = self.saldo + profit

        self.stop_and_print_timer('check_result')
    #############################
    
    def make_bet(self) : 
        self.start_timer()
        self.selection_id = None
        race_list = []
        if self.bet_type == 'lay_will_be_impl' :
            market_id = 0
            for runner in self.runners :
                tmp_bp = float(runner[3]) 
                tmp_lp = float(runner[4])  
                sel_id = int(runner[1]) 
                idx    = int(runner[2])  
                market_id = int(runner[0])
                tmp_tuple = (tmp_bp, tmp_lp, sel_id, idx)
                race_list.append(tmp_tuple)    

            sorted_list = sorted(race_list, reverse=True)
            i = 0  
                
            selection = None
            lay_odds = None

            max_turns = 0
            number_of_runners = len(sorted_list)
            my_market = Market(self.conn, None, \
                      market_id = market_id, simulate = True)
            if self.animal == 'horse':
# there must be at least 3 runners with lower odds
                max_turns = number_of_runners - 3 - my_market.no_of_winners
            elif self.animal == 'hound':
# there must be at least 3 runners with lower odds
                max_turns = number_of_runners - 3 - my_market.no_of_winners
            else :
                sys.stderr.write('lay bet not implemented for '\
                                  + self.animal + '\n')
                sys.exit(1)
                                
            for dct in sorted_list :
                i += 1
                if  (self.min_price <= float(dct[1]) and 
                     float(dct[1]) <= self.max_price and 
                     i <= max_turns 
                     ) :
                    selection = int(dct[2]) 
                    lay_odds  = float(dct[1])
#                    back_odds = float(dct[0]) 
#                    index     = int(dct[3]) 
                    self.selection_id = int(selection) 
                    #312,59 -> 233.09. bet 30@3.65
                    #312.59 - (30*3.65) + 30 = 233.09 
                    self.saldo = self.saldo - \
                        (self.size * float(lay_odds)) + self.size
                    break 


        elif self.bet_type == 'back' :
            if self.animal == 'horse' or self.animal == 'hound':
                for runner in self.runners :
                    tmp_bp = float(runner[3])  
                    tmp_lp = float(runner[4]) 
                    sel_id = int(runner[1])  
                    idx    = int(runner[2])  
               
                    tmp_tuple = (tmp_bp, tmp_lp, sel_id, idx)
                    race_list.append(tmp_tuple)    
    
                sorted_list = sorted(race_list, reverse=False)
                i = 0  
                    
                selection = None
                lay_odds = None
    
                number_of_runners = len(sorted_list)
                max_turns = 1 #number_of_runners - 4  
                # there must be at least 5 runners with lower odds
    
                for dct in sorted_list :
                    i += 1
                    if ( self.price - self.delta_price <= float(dct[0]) and 
                         float(dct[0]) <= self.price + self.delta_price and 
                         i <= max_turns ):
                        selection = float(dct[2])
    #                    lay_odds  = float(dct[1]) 
    #                    back_odds = int(dct[0]) 
    #                    index     = int(dct[3]) 
                        self.selection_id = int(selection) 
                        self.saldo = self.saldo - self.size         
    #                    sys.stderr.write('good runner ' + str(dct) + '\n')
                    break 
                        
                        
                        
            elif self.animal == 'human_will_be_impl':
                if self.bet_name.lower() == 'utvisning?' :         
                 #fotboll med ja/nej alternativ, där vi väljer NEJ
#                        odds_yes      = prices['runners'][0]['back_prices'][0]['price']
#                        selection_yes = prices['runners'][0]['selection_id']
#                        odds_no       = prices['runners'][1]['back_prices'][0]['price']
#                        selection_no  = prices['runners'][1]['selection_id']
                    # index 1 = ja, index 2 = nej
                    
                    tmp_bp = -1
                    for runner in self.runners :
                        tmp_bp = float(runner[3])  
                        tmp_lp = float(runner[4]) 
                        sel_id = int(runner[1])  
                        idx    = int(runner[2])  
                        if idx == 2 :
#                            sys.stderr.write('found ix=1, tmp_bp= ' + str(tmp_bp) + '\n')
                            break
                        # we have the Yes alternative  
                    if ( self.min_price <= tmp_bp and 
                         tmp_bp <= self.max_price
                        ):
                        self.selection_id = sel_id
                        self.saldo = self.saldo - self.size         
            else :
                sys.stderr.write('Bad animla', self.animal, \
                              'must be horse or hound' + '\n')
        else :
            sys.stderr.write('Bad bet type', self.bet_type, \
                              'must be back or lay' + '\n')
            sys.exit(1)
            
        self.stop_and_print_timer('make_bet    ')
        ##############################################

###################################################################

#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
sys.stderr = os.fdopen(sys.stderr.fileno(), 'w', 0)

parser = OptionParser()
parser.add_option("-n", "--price", dest="price", action="store", \
                  type="float", help="avg odds")
parser.add_option("-x", "--delta_price", dest="delta_price", action="store", \
                  type="float", help="delta odds")
parser.add_option("-t", "--bet_type",  dest="bet_type",  action="store", \
                  type="string", help="bet type")
parser.add_option("-b", "--bet_name",  dest="bet_name",  action="store", \
                  type="string", help="bet name")
parser.add_option("-d", "--start_date", dest="start_date", action="store", \
                  type="string", help="start date")
parser.add_option("-g", "--stop_date", dest="stop_date", action="store", \
                  type="string", help="stop date")
parser.add_option("-s", "--saldo",     dest="saldo",     action="store", \
                  type="float", help="start sum")
parser.add_option("-z", "--size",      dest="size",      action="store", \
                  type="float", help="bet size")
parser.add_option("-a", "--animal",    dest="animal",    action="store", \
                  type="string", help="animal")
parser.add_option("-v", "--verbose",   dest="verbose",   action="store_true", \
                  help="verbose", default=False)
parser.add_option("-e", "--summary",   dest="summary",   action="store_true", \
                  help="summary", default=False)
parser.add_option("-p", "--plot",      dest="plot"   ,   action="store_true", \
                  help="plot",    default=False)

(options, args) = parser.parse_args()

#sys.stderr.write('options ' + str(options))
#print 'args', args

## start test
hound_place_lay_price_list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
horse_place_lay_price_list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]


lay_price_list = [ 1,  2,  3,  4,  5,  6,  7,  8,  9, 10, \
                  11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
back_price_list = [1.0, 1.20, 1.40, 1.60, 1.80, \
                   2.0, 2.20, 2.40, 2.60, 2.80, \
                   3.0, 3.20, 3.40, 3.60, 3.80, \
                   4.0, 4.20, 4.40, 4.60, 4.80, \
                   5.0, 5.20, 5.40, 5.60, 5.80, \
                   6.0, 6.20, 6.40, 6.60, 6.80, \
                   7.0, 7.20, 7.40, 7.60, 7.80, \
                   8.0, 8.20, 8.40, 8.60, 8.80]


hound_place_back_price_list = [1.0, 1.20, 1.40, 1.60, 1.80, \
                   2.0, 2.20, 2.40, 2.60, 2.80, \
                   3.0, 3.20, 3.40, 3.60, 3.80 ]

horse_place_back_price_list = [1.0, 1.20, 1.40, 1.60, 1.80, \
                   2.0, 2.20, 2.40, 2.60, 2.80, \
                   3.0, 3.20, 3.40, 3.60, 3.80 ]


hound_winner_back_price_list = [1.0, 1.20, 1.40, 1.60, 1.80, \
                   2.0, 2.20, 2.40, 2.60, 2.80, \
                   3.0, 3.20, 3.40, 3.60, 3.80, \
                   4.0, 4.20, 4.40, 4.60, 4.80, \
                   5.0, 5.20, 5.40, 5.60, 5.80, 6.00]

horse_winner_back_price_list = back_price_list


sendoff_price_list = [1.00, 1.05, 1.10, 1.15, 1.20, 1.25, \
                      1.30, 1.35, 1.40, 1.45, 1.50, 1.55, \
                      1.60, 1.65, 1.70, 1.75, 1.80, 1.85, \
                      1.90, 1.95, 2.00, 2.05, 2.10, 2.15 ]

delta_list = [0.1, 0.2, 0.3, 0.4, 0.5]

price_list = ""
if options.bet_type == "lay"  :
    price_list = lay_price_list
elif  options.bet_type == "back" :
    price_list = back_price_list
else:
    sys.stderr.write( "bad bet_type " + str(options.bet_type))
    sys.exit(1)

if options.animal == 'hound' :
    if options.bet_type == "lay" :
        price_list = lay_price_list
               
        if options.bet_name == "Plats" :
            price_list = hound_place_lay_price_list

    elif options.bet_type == "back" :
        if options.bet_name == "Plats" :    
            price_list = hound_place_back_price_list
        elif options.bet_name == "Vinnare" :    
            price_list = hound_winner_back_price_list

elif options.animal == 'horse' :
    if options.bet_type == "lay" :
        price_list = lay_price_list
    elif options.bet_type == "back" :
        if options.bet_name == "Plats" :    
            price_list = horse_place_back_price_list
        elif options.bet_name == "Vinnare" :    
            price_list = horse_winner_back_price_list

elif options.animal == 'human':
    if options.bet_type == "lay" :
        price_list = lay_price_list
    elif options.bet_type == "back"  :
        price_list = back_price_list


##stop test

simrun = BetSimulator(options)
datadir = ''
filname = ''
for price in price_list:
    for delta in delta_list:
        simrun.saldo = options.saldo
        simrun.price = price            
        simrun.delta_price = delta            
        datadir = 'sims'
        filname = 'simulation3-' + simrun.animal +'-' + \
            simrun.bet_name + '-' + simrun.bet_type \
                + '-' + simrun.start_date + '-' + simrun.stop_date + '.dat'
        fil = datadir + '/' + filname                      
        
#            sys.exit(0)
                        
        simrun.get_markets()
        
        min_saldo = simrun.saldo
        max_saldo = simrun.saldo
        for market in simrun.markets :
        #sys.stderr.write('market ' + str(market[0]) + '\n')
        
            simrun.print_saldo()                          
            simrun.get_runners(market[0])
            simrun.get_winners(market[0])
            simrun.make_bet()
            simrun.print_saldo()                          
            if  simrun.saldo > max_saldo : 
                max_saldo = simrun.saldo
            if  simrun.saldo < min_saldo : 
                min_saldo = simrun.saldo
        
            if simrun.selection_id is not None :
                simrun.check_result()
                simrun.print_saldo()                          
        
            if  simrun.saldo > max_saldo : 
                max_saldo = simrun.saldo
            if  simrun.saldo < min_saldo : 
                min_saldo = simrun.saldo
        
        line = options.animal + ' ' + options.bet_name + ' ' + \
                options.bet_type + ' ' + str(delta) + ' ' \
                + str(price) + ' ' + str(min_saldo) + ' ' + \
                str(simrun.saldo) + ' ' + str(max_saldo)
        
        if simrun.summary :
                print line
        
        simrun.start_timer()
        with open(fil, 'a') as text_file:
            text_file.write(line + '\n')
        simrun.stop_and_print_timer('write       ')

if simrun.plot : 
    cmd = "gnuplot \
    -e \"animal=\'" + simrun.animal + "\'\" \
    -e \"bet_name=\'" + simrun.bet_type + "\'\" \
    -e \"bet_type=\'" + simrun.bet_name + "\'\" \
    -e \"start_date=\'" + simrun.start_date + "\'\" \
    -e \"stop_date=\'" + simrun.stop_date + "\'\" \
    -e \"datafil=\'" + filname + "\'\" \
    -e \"datadir=\'" + datadir + "\'\" plot_simulation3.gpl"

    p = subprocess.Popen(cmd, shell=True)
