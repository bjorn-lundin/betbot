# coding=iso-8859-15
from time import sleep, time
import datetime
import psycopg2
import os
import sys
from db import Db
from market import Market
from optparse import OptionParser

class BetSimulator(object):
    
    def __init__(self,options):
        self.Db = Db()
        self.conn = self.Db.conn
        self.saldo = options.saldo
        self.min_price = options.min_price
        self.max_price = options.max_price
        self.start_date = options.start_date
        self.stop_date = options.stop_date
        self.next_bet_time = None
        self.bet_type = options.bet_type
        self.bet_name = options.bet_name
        self.markets = []
        self.runners = []
        self.winners = []
        self.all_runners = []
        self.all_winners = []
        self.selection_id = None
        self.bet_won = False
        self.size = options.size
        self.animal = options.animal
        self.verbose = options.verbose
        self.summary = options.summary
    ########################## 	    
    
    def get_markets(self):


#        sys.stderr.write('self.start_date, self.stop_date ' + str(self.start_date) + ',' + str(self.stop_date))

        
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
 

        self.markets = cur.fetchall()
#        print 'markets', self.markets
#        print 'date', self.date
#        print 'name', self.bet_name
        
        cur.close()
        self.conn.commit()
    ########################    
    

    def get_all_runners(self):
        cur = self.conn.cursor()
        cur.execute("select * \
                     from DRY_RUNNERS ")

        self.all_runners = cur.fetchall()

        cur.close()
        self.conn.commit()    
    ########################    

    def get_runners(self, market_id):
        self.runners = []
        for runner in self.all_runners :
            if int(runner[0]) == int(market_id):
                self.runners.append(runner)
        
        return   
        cur = self.conn.cursor()
        cur.execute("select * \
                     from DRY_RUNNERS  \
                     where MARKET_ID = %s  \
                     order by INDEX", 
                      (market_id,))

        self.runners = cur.fetchall()

        cur.close()
        self.conn.commit()    
    ########################    

    def get_winners(self,market_id):
        self.winners = []
        for winner in self.all_winners :
            if int(winner[0]) == int(market_id):
                self.winners.append(winner)
        
        return 
        cur = self.conn.cursor()
        cur.execute("select * \
                     from DRY_RESULTS  \
                     where MARKET_ID = %s", 
                      (market_id,))

        self.winners = cur.fetchall()

        cur.close()
        self.conn.commit()    
    ########################    
    def get_all_winners(self):
        cur = self.conn.cursor()
        cur.execute("select * \
                     from DRY_RESULTS")

        self.all_winners = cur.fetchall()

        cur.close()
        self.conn.commit()    
    ########################    


    def print_saldo(self):
        if self.verbose :
            print self.saldo                          

    #############################
    def check_result(self) :
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
            sys.stderr.write('Bad bet type', self.bet_type, 'must be back or lay' + '\n')
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
                sys.stderr.write('Bad bet type', self.bet_type, 'must be back or lay' + '\n')
                sys.exit(1)
        self.saldo = self.saldo + profit

    #############################
    
    def make_bet(self) : 
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
            back_odds = None
            name = None
            index = None

            max_turns = 0
            number_of_runners = len(sorted_list)
            market = Market(self.conn, None, market_id = market_id, simulate = True)
            if self.animal == 'horse':
#                max_turns = number_of_runners - 4  # there must be at least 5 runners with lower odds
                max_turns = number_of_runners - 2 - market.no_of_winners
            elif self.animal == 'hound':
                max_turns = number_of_runners - 2 - market.no_of_winners
#                max_turns = number_of_runners - 2  # there must be at least 3 runners with lower odds
            else :
                sys.stderr.write('lay bet not implemented for ' + self.animal + '\n')
                sys.exit(1)
                                
            for dct in sorted_list :
                i += 1
                if  self.min_price <= float(dct[1]) and float(dct[1]) <= self.max_price and i <= max_turns :
                    selection = int(dct[2]) 
                    lay_odds  = float(dct[1])
                    back_odds = float(dct[0]) 
                    index     = int(dct[3]) 
                    self.selection_id = int(selection) 
                    #312,59 -> 233.09. bet 30@3.65
                    #312.59 - (30*3.65) + 30 = 233.09 
                    self.saldo = self.saldo - (self.size * float(lay_odds)) + self.size
#                    sys.stderr.write('lay bet on market:' + str(market_id) + \
#                    ' - selection id ' + str(selection) + ' layodds ' + str(lay_odds) + '\n')
                    break 
#            if selection is None :
#                sys.stderr.write('No runner is good enough, skipping this market' + '\n')

        elif self.bet_type == 'back' :
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
            back_odds = None
            name = None
            index = None

            number_of_runners = len(sorted_list)
            max_turns = 1 #number_of_runners - 4  # there must be at least 5 runners with lower odds
#            sys.stderr.write('runner to choose from ' + str(sorted_list) + '\n')
            for dct in sorted_list :
                i += 1
                if  self.min_price <= float(dct[0]) and float(dct[0]) <= self.max_price and i <= max_turns :
                    selection = float(dct[2])
                    lay_odds  = float(dct[1]) 
                    back_odds = int(dct[0]) 
                    index     = int(dct[3]) 
                    self.selection_id = int(selection) 
                    self.saldo = self.saldo - self.size         
#                    sys.stderr.write('good runner ' + str(dct) + '\n')
                    break 
#                else: 
#                    sys.stderr.write('bad  runner ' + str(dct) + '\n')
                
                
                   
#            if selection is None :
#                sys.stderr.write('No runner is good enough, skipping this market' + '\n')
                    
        else :
            sys.stderr.write('Bad bet type', self.bet_type, 'must be back or lay' + '\n')
            sys.exit(1)
            
        ##############################################

###################################################################

#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
sys.stderr = os.fdopen(sys.stderr.fileno(), 'w', 0)

parser = OptionParser()
parser.add_option("-n", "--min_price", dest="min_price", action="store", type="float", help="min odds")
parser.add_option("-x", "--max_price", dest="max_price", action="store", type="float", help="max odds")
parser.add_option("-t", "--bet_type",  dest="bet_type",  action="store", type="string", help="bet type")
parser.add_option("-b", "--bet_name",  dest="bet_name",  action="store", type="string", help="bet name")
parser.add_option("-d", "--start_date",dest="start_date",action="store", type="string", help="start date")
parser.add_option("-g", "--stop_date", dest="stop_date", action="store", type="string", help="stop date")
parser.add_option("-s", "--saldo",     dest="saldo",     action="store", type="float", help="start sum")
parser.add_option("-z", "--size",      dest="size",      action="store", type="float", help="bet size")
parser.add_option("-a", "--animal",    dest="animal",    action="store", type="string", help="animal")
parser.add_option("-v", "--verbose",   dest="verbose",   action="store_true", help="verbose", default=False)
parser.add_option("-e", "--summary",   dest="summary",   action="store_true", help="summary", default=False)

(options, args) = parser.parse_args()

#sys.stderr.write('options ' + str(options))
#print 'args', args

## start test
hound_place_lay_price_list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
lay_price_list = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
back_price_list=[1.0, 1.20, 1.40, 1.60, 1.80, \
                 2.0, 2.20, 2.40, 2.60, 2.80, \
                 3.0, 3.20, 3.40, 3.60, 3.80, \
                 4.0, 4.20, 4.40, 4.60, 4.80, \
                 5.0, 5.20, 5.40, 5.60, 5.80 ]


hound_date_list = ['2013-01-30', '2013-01-31'] 
horse_date_list = hound_date_list
human_date_list = hound_date_list 

price_list = ""
if options.bet_type == "lay"  :
    price_list = lay_price_list
elif  options.bet_type == "back" :
    price_list = back_price_list
else:
    sys.stderr.write( "bad bet_type " + str(options.bet_type))
    sys.exit(1)



if options.animal == 'hound' :
    date_list = hound_date_list
    if options.bet_type == "lay" :
        price_list = lay_price_list
               
        if options.bet_name == "Plats" :
            price_list = hound_place_lay_price_list

        elif options.bet_type == "back" :
            price_list = back_price_list

elif options.animal == 'horse' :
    date_list = horse_date_list
    if options.bet_type == "lay" :
        price_list = lay_price_list
    elif options.bet_type == "back" :
        price_list = back_price_list

elif options.animal == 'human':
    date_list = human_date_list
    if options.bet_type == "lay" :
        price_list = lay_price_list
    elif options.bet_type == "back"  :
        price_list = back_price_list


##stop test

simrun = BetSimulator(options)
simrun.get_all_runners()
simrun.get_all_winners()

for the_date in date_list :
    for minimum_price in price_list:
        for maximum_price in price_list:
            simrun.min_price = minimum_price    
            simrun.max_price = maximum_price 
            simrun.saldo = options.saldo   
            datadir = 'sims'
            filname = 'simulation-' + simrun.animal +'-' + simrun.bet_name + '-' + simrun.bet_type \
                + '-' + simrun.start_date + '-' + simrun.stop_date + '.dat'
            fil = datadir + '/' + filname                      
                          
            simrun.get_markets()

            min_saldo = simrun.saldo
            max_saldo = simrun.saldo
            for market in simrun.markets :
#    sys.stderr.write('market ' + str(market[0]) + '\n')

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
                      options.bet_type + ' ' + str(minimum_price) + ' ' + \
                      str(maximum_price) + ' ' + str(min_saldo) + ' ' + \
                      str(simrun.saldo) + ' ' + str(max_saldo)
            if simrun.summary :
                print line
                with open(fil, 'a') as text_file:
                    text_file.write(line + '\n')




#    sys.stderr.write('min/max/res ' + str(min_saldo) + '/' + str(max_saldo) + '/' + str(simrun.saldo) + '\n')
	
