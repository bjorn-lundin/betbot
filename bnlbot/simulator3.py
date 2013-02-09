# coding=iso-8859-15
#from time import sleep
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
        self.min_price = opts.min_price
        self.max_price = opts.max_price
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
        self.index = opts.index
        self.graph_type = opts.graph_type
        
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
             
        elif (self.bet_name.lower().find('udda') > -1 or
             self.bet_name.lower().find('0.5') > -1 or
             self.bet_name.lower().find('1.5') > -1 or
             self.bet_name.lower().find('2.5') > -1 or
             self.bet_name.lower().find('3.5') > -1 or
             self.bet_name.lower().find('4.5') > -1 or
             self.bet_name.lower().find('5.5') > -1 or
             self.bet_name.lower().find('6.5') > -1 or
             self.bet_name.lower().find('7.5') > -1 or
             self.bet_name.lower().find('8.5') > -1 or
             self.bet_name.lower().find('straff') > -1 or
             self.bet_name.lower().find('utvisning') > -1 or
             self.bet_name.lower().find('lagen') > -1 ):
        # psycopg needs %% instead of % when literal ...
            cur.execute("select * from \
                     DRY_MARKETS \
                     where EVENT_DATE::date >= %s \
                     and EVENT_DATE::date <= %s \
                     and lower(MARKET_NAME) like %s \
                     and EVENT_HIERARCHY like %s \
                     and exists (select 'x' from DRY_RESULTS where \
                         DRY_MARKETS.MARKET_ID = DRY_RESULTS.MARKET_ID) \
                     order by EVENT_DATE",
             (self.start_date, self.stop_date, 
               '%' + self.bet_name.lower() + '%', animal))

        self.markets = cur.fetchall()
        cur.close()
        self.conn.commit()

        

        self.stop_and_print_timer('get_markets ')
    ########################    
    
    def get_runners(self, market_id):
        self.start_timer()
        self.runners = []
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

    def print_saldo(self):
        if self.verbose :
            print self.saldo                          

    #############################
    def check_result(self) :
        self.start_timer()
        if self.selection_id is None :
            return
    
        local_price = 0.0
        if self.bet_type == 'back' :
            self.bet_won = False
            for winner in self.winners :
                if int(self.selection_id) == int(winner[1]) :
                    self.bet_won = True
                    break        
        
            for runner in self.runners:
                if int(self.selection_id) == int(runner[1]) :
                    local_price = float(runner[3])

        elif self.bet_type == 'lay' :
            self.bet_won = True
            for winner in self.winners :
                if int(self.selection_id) == int(winner[1]) :
                    self.bet_won = False
                    break        

            for runner in self.runners:
                if int(self.selection_id) == int(runner[1]) :
                    local_price = float(runner[4])

        else :
            sys.stderr.write('Bad bet type', self.bet_type, \
                             'must be back or lay' + '\n')
            sys.exit(1)

        profit = 0.0
        # take care of 5% commission here
        if self.bet_won :
            if self.bet_type == 'back' :
                profit = 0.95 * self.size * local_price 
            elif self.bet_type == 'lay' :
                #312.59 -> 341.09 ( 5% commission?)
                # 30 * 3.65 = 109,5
                #233.09 + 109.5 - (30 * 0.05) = 341.09
                profit = (self.size * local_price) - (self.size * 0.05) 

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
        if self.bet_type == 'lay' :
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
            found = False
            for dct in sorted_list :
                i = i + 1
                if ( self.min_price  <= tmp_bp and 
                     tmp_bp <= self.max_price and
                     i <= max_turns 
                     ) :
                    selection = int(dct[2]) 
                    lay_odds  = float(dct[1])
                    self.selection_id = int(selection) 
                    #312,59 -> 233.09. bet 30@3.65
                    #312.59 - (30*3.65) + 30 = 233.09 
                    self.saldo = self.saldo - \
                        (self.size * float(lay_odds)) + self.size
                    found = True
#                    sys.stderr.write( \
#                      'min=' +str(self.min_price) + ' ' + \
#                      'odds=' +str(tmp_bp) + ' ' + \
#                      'max=' +str(self.max_price) + '\n')
                    break 
#                sys.stderr.write( \
#                      'min=' +str(self.min_price) + ' ' + \
#                      'odds=' +str(tmp_bp) + ' ' + \
#                      'max=' +str(self.max_price) + ' ' + \
#                      'Found: ' + str(found) + '\n')


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
                        self.selection_id = int(selection) 
                        self.saldo = self.saldo - self.size         
                    break 
                                                
            elif self.animal == 'human':
                    
                if (self.bet_name.lower().find('utvisning') > -1 or
                    self.bet_name.lower().find('0.5') > -1 or
                    self.bet_name.lower().find('1.5') > -1 or
                    self.bet_name.lower().find('2.5') > -1 or
                    self.bet_name.lower().find('3.5') > -1 or
                    self.bet_name.lower().find('4.5') > -1 or                
                    self.bet_name.lower().find('5.5') > -1 or
                    self.bet_name.lower().find('6.5') > -1 or                
                    self.bet_name.lower().find('7.5') > -1 or                
                    self.bet_name.lower().find('8.5') > -1 or                
                    self.bet_name.lower().find('lagen') > -1 or
                    self.bet_name.lower().find('straff') > -1 or
                    self.bet_name.lower().find('udda') > -1 ):         

                 #fotboll med ja/nej alternativ, där vi väljer ett av två värden.
#                 index = 1 = ja/even/under
#                 index = 2 = nej/udda/över
#                        odds_yes      = prices['runners'][0]['back_prices'][0]['price']
#                        selection_yes = prices['runners'][0]['selection_id']
#                        odds_no       = prices['runners'][1]['back_prices'][0]['price']
#                        selection_no  = prices['runners'][1]['selection_id']
                    # index 1 = ja, index 2 = nej
                    found = False
                    tmp_bp = -1
                    for runner in self.runners :
                        tmp_bp = float(runner[3])  
                        tmp_lp = float(runner[4]) 
                        sel_id = int(runner[1])  
                        idx    = int(runner[2])  
                        if idx == int(self.index) :
                            found = True   
                            break
                        # we have the alternative  
                    if ( self.price - self.delta_price <= tmp_bp and 
                         tmp_bp <= self.price + self.delta_price and found
                         ):
                        self.selection_id = sel_id
                        self.saldo = self.saldo - self.size    
                else :
                    sys.stderr.write('Bad bet name', self.bet_name, \
                              'Utvisning?' + '\n')
                        
            else :
                sys.stderr.write('Bad animal', self.animal, \
                              'must be horse or hound' + '\n')
        else :
            sys.stderr.write('Bad bet type', self.bet_type, \
                              'must be back or lay' + '\n')
            sys.exit(1)
            
        self.stop_and_print_timer('make_bet    ')
        ##############################################

###################################################################

def list_creator(start, increment, stop):
    tmp_list = []
    tmp_value = start
    while tmp_value <= stop :
        str_tmp = str('%.2f' % tmp_value)
        tmp_list.append(float(str_tmp))
        tmp_value += increment 
    return tmp_list
    
##################################################################

#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
sys.stderr = os.fdopen(sys.stderr.fileno(), 'w', 0)

parser = OptionParser()
parser.add_option("-n", "--price", dest="price", action="store", \
                  type="float", help="avg odds")
parser.add_option("-x", "--delta_price", dest="delta_price", action="store", \
                  type="float", help="delta odds")
parser.add_option("-N", "--min_price", dest="min_price", action="store", \
                  type="float", help="min odds")
parser.add_option("-X", "--max_price", dest="max_price", action="store", \
                  type="float", help="max odds")
parser.add_option("-t", "--bet_type",  dest="bet_type",  action="store", \
                  type="string", help="bet type")
parser.add_option("-b", "--bet_name",  dest="bet_name",  action="store", \
                  type="string", help="bet name")
parser.add_option("-d", "--start_date", dest="start_date", action="store", \
                  type="string", help="start date")
parser.add_option("-f", "--stop_date", dest="stop_date", action="store", \
                  type="string", help="stop date")
parser.add_option("-s", "--saldo",     dest="saldo",     action="store", \
                  type="float", help="start sum")
parser.add_option("-z", "--size",      dest="size",      action="store", \
                  type="float", help="bet size")
parser.add_option("-a", "--animal",    dest="animal",    action="store", \
                  type="string", help="animal")
parser.add_option("-v", "--verbose",   dest="verbose",  action="store_true", \
                  help="verbose", default=False)
parser.add_option("-e", "--summary",   dest="summary",  action="store_true", \
                  help="summary", default=False)
parser.add_option("-p", "--plot",      dest="plot"   ,  action="store_true", \
                  help="plot",    default=False)
parser.add_option("-i", "--index",      dest="index"   ,   action="store", \
                  help="index")
parser.add_option("-g", "--graph_type", dest="graph_type",  action="store", \
                  help="graph type")

(options, args) = parser.parse_args()

sys.stderr.write('options ' + str(options))
#print 'args', args

## start test

if options.animal == 'hound' :
    if options.bet_type == "lay" :
        if options.bet_name == "Plats" :    
            price_list = list_creator(1, 1, 15)
            delta_list = list_creator(1, 1, 10)
        elif options.bet_name == "Vinnare" :    
            price_list = list_creator(1, 1, 30)
            delta_list = list_creator(1, 1, 30)
    elif options.bet_type == "back" :
        if options.bet_name == "Plats" :    
            price_list = list_creator(1, 0.2, 4)
            delta_list = list_creator(0.1, 0.1, 2)
        elif options.bet_name == "Vinnare" :    
            price_list = list_creator(1, 0.2, 6)
            delta_list = list_creator(0.1, 0.1, 2)
            
    else:
        sys.stderr.write( "bad bet_type " + str(options.bet_type))
        sys.exit(1)

elif options.animal == 'horse' :
    if options.bet_type == "lay" :
        if options.bet_name == "Plats" :    
            price_list = list_creator(1, 1, 15)
            delta_list = list_creator(1, 1, 15)
        elif options.bet_name == "Vinnare" :    
            price_list = list_creator(1, 1, 50)
            delta_list = list_creator(1, 1, 20)
    elif options.bet_type == "back" :
        if options.bet_name == "Plats" :    
            price_list =  list_creator(1, 0.2, 4)
            delta_list = list_creator(0.1, 0.1, 2)
        elif options.bet_name == "Vinnare" :    
            price_list = list_creator(1, 0.2, 9)
            delta_list = list_creator(0.1, 0.1, 2)
    else:
        sys.stderr.write( "bad bet_type " + str(options.bet_type))
        sys.exit(1)

elif options.animal == 'human':
    if options.bet_type == "lay" :
        price_list = list_creator(1, 1, 10)
        delta_list = list_creator(1, 1, 10)
    elif options.bet_type == "back"  :
        price_list = list_creator(1, 0.05, 7.0)
        delta_list = list_creator(0.1, 0.1, 2)
    else:
        sys.stderr.write( "bad bet_type " + str(options.bet_type))
        sys.exit(1)

else:
    sys.stderr.write( "bad animal " + str(options.animal))
    sys.exit(1)

##stop test

simrun = BetSimulator(options)
datadir = ''
filname = ''


simrun.get_markets()

for price in price_list:
    for delta in delta_list:
        simrun.saldo = options.saldo
        
        
        if options.bet_type == "back" :
            simrun.price = price            
            simrun.delta_price = delta        
        elif options.bet_type == "lay" :
            simrun.min_price = price            
            simrun.max_price = delta        

        
        datadir = 'sims'
        filname = 'simulation3-' + simrun.animal +'-' + \
            simrun.bet_name + '-' + simrun.bet_type \
                + '-' + simrun.start_date + '-' \
                + simrun.stop_date + "-" + str(simrun.index) + '.dat'
        fil = datadir + '/' + filname                      
        
#        simrun.get_markets()
        
        min_saldo = simrun.saldo
        max_saldo = simrun.saldo
        for market in simrun.markets :

            simrun.get_runners(market[0])
            simrun.get_winners(market[0])
            simrun.make_bet()
            
            if  simrun.saldo > max_saldo : 
                max_saldo = simrun.saldo
            if  simrun.saldo < min_saldo : 
                min_saldo = simrun.saldo
        
            if simrun.selection_id is not None :
                simrun.check_result()
        
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
    -e \"index=\'" + str(simrun.index) + "\'\" \
    -e \"start_date=\'" + simrun.start_date + "\'\" \
    -e \"stop_date=\'" + simrun.stop_date + "\'\" \
    -e \"datafil=\'" + filname + "\'\" \
    -e \"datadir=\'" + datadir + "\'\" plot_simulation3.gpl"

    p = subprocess.Popen(cmd, shell=True)
