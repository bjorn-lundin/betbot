# coding=iso-8859-15
from time import sleep, time
import datetime
import psycopg2
import os
import sys
from db import Db
from optparse import OptionParser

class BetSimulator(object):
    
    def __init__(self,options):
        self.Db = Db()
        self.conn = self.Db.conn
        self.saldo = options.saldo
        self.min_price = options.min_price
        self.max_price = options.max_price
        self.date = options.date
        self.next_bet_time = None
        self.bet_type = options.bet_type
        self.bet_name = options.bet_name
        self.markets = []
        self.runners = []
        self.winners = []
        self.selection_id = None
        self.bet_won = False
        self.size = options.size
        self.animal = options.animal
        self.verbose = options.verbose
        self.summary = options.summary
    ########################## 	    
    
    def get_markets(self):
        
        if self.animal == 'horse' :
            animal = '%/7/%'
        elif self.animal == 'hound' :
            animal = '%/4339/%'
        elif self.animal == 'human' :
            animal = '%/1/%'
        else :
            animal = 'not found'
        
        cur = self.conn.cursor()
        
        if self.bet_name.lower() == 'plats' :
        
            cur.execute("select * from \
                     DRY_MARKETS \
                     where EVENT_DATE::date = %s \
                     and MARKET_NAME = %s \
                     and EVENT_HIERARCHY like %s \
                     and exists (select 'x' from DRY_RESULTS where \
                                 DRY_MARKETS.MARKET_ID = DRY_RESULTS.MARKET_ID) \
                     order by EVENT_DATE",
             (self.date, self.bet_name, animal))
        elif self.bet_name.lower() == 'vinnare' :
            cur.execute("select * from \
                     DRY_MARKETS \
                     where EVENT_DATE::date = %s \
                     and lower(MARKET_NAME) not in \
                     ('challenge', 'tbp', 'forecast', 'fc', \
                     'reverse', 'without', 'plats', 'place')   \
                     and EVENT_HIERARCHY like %s \
                     and exists (select 'x' from DRY_RESULTS where \
                                 DRY_MARKETS.MARKET_ID = DRY_RESULTS.MARKET_ID) \
                     order by EVENT_DATE",
             (self.date, animal))


        self.markets = cur.fetchall()
#        print 'markets', self.markets
#        print 'date', self.date
#        print 'name', self.bet_name
        
        cur.close()
        self.conn.commit()
    ########################    
    
    def get_runners(self, market_id):
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
        cur = self.conn.cursor()
        cur.execute("select * \
                     from DRY_RESULTS  \
                     where MARKET_ID = %s", 
                      (market_id,))

        self.winners = cur.fetchall()

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
                    
            sys.stderr.write('bet won ' + str(self.bet_won) + '\n')

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
            if self.animal == 'horse':
                max_turns = number_of_runners - 4  # there must be at least 5 runners with lower odds
            elif self.animal == 'hound':
                max_turns = number_of_runners - 2  # there must be at least 3 runners with lower odds
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
                    sys.stderr.write('lay bet on market:' + str(market_id) + ' - selection id ' + str(selection) + '\n')
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
parser.add_option("-d", "--date",      dest="date",      action="store", type="string", help="date")
parser.add_option("-s", "--saldo",     dest="saldo",     action="store", type="float", help="start sum")
parser.add_option("-z", "--size",      dest="size",      action="store", type="float", help="bet size")
parser.add_option("-a", "--animal",    dest="animal",    action="store", type="string", help="animal")
parser.add_option("-v", "--verbose",   dest="verbose",   action="store_true", help="verbose", default=False)
parser.add_option("-e", "--summary",   dest="summary",   action="store_true", help="summary", default=False)

                  
(options, args) = parser.parse_args()


#print 'options', options
#print 'args', args


simrun = BetSimulator(options)
                          
                          
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


    sys.stderr.write('min/max/res ' + str(min_saldo) + '/' + str(max_saldo) + '/' + str(simrun.saldo) + '\n')
	
if simrun.summary :
    print options.animal, options.bet_name, \
          options.bet_type, options.min_price, \
          options.max_price, min_saldo, simrun.saldo, max_saldo
#    print 'min', min_saldo                
#    print 'max', max_saldo                
#    print 'res', simrun.saldo      
                        
#lay_price_list = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
#back_price_list = [1.0, 1.05, 1.10, 1.15, 1.20, 1.25, 1.30, 1.35, \
#                   1.40, 1.45, 1.50, 1.55, 1.60, 1.65, 1.70, \
#                   1.75, 1.80, 1.85, 1.90, 1.95, 2.0]
#delay_list = [0,1,2,3,4,5,6]


