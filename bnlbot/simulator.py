# coding=iso-8859-15
from time import sleep, time
import datetime
import psycopg2
import os
import sys
from db import Db
from optparse import OptionParser

class BetSimulator(object):
    
    def __init__(self,min_price, max_price, bet_type, bet_name, date, saldo, size, animal):
        self.Db = Db()
        self.conn = self.Db.conn
        self.saldo = saldo
        self.min_price = min_price
        self.max_price = max_price
        self.date = date
        self.next_bet_time = None
        self.bet_type = bet_type
        self.bet_name = bet_name
        self.markets = []
        self.runners = []
        self.winners = []
        self.selection_id = None
        self.bet_won = False
        self.size = size
        self.animal = animal
    ########################## 	    
    
    def get_markets(self):
        
        if self.animal == 'horse' :
            animal = '%/7/%'
        elif self.animal == 'hound' :
            animal = '%/4339/%'
        else :
            animal = 'not found'
        
        cur = self.conn.cursor()
        cur.execute("select * from \
                     DRY_MARKETS \
                     where EVENT_DATE::date = %s \
                     and MARKET_NAME = %s \
                     and EVENT_HIERARCHY like %s \
                     and exists (select 'x' from DRY_RESULTS where \
                                 DRY_MARKETS.MARKET_ID = DRY_RESULTS.MARKET_ID) \
                     order by EVENT_DATE",
             (self.date, self.bet_name, animal))

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
        print 'saldo', self.saldo                          

    #############################
    def check_result(self) :
        price = 0.0
        if self.bet_type == 'back' :
            self.bet_won = False
            for winner in self.winners :
                if self.selection_id == int(winner[1]) :
                    self.bet_won = True
                    break        
        
            for runner in self.runners:
                if self.selection_id == int(runner[1]) :
                    price = float(runner[3])

        elif self.bet_type == 'lay' :
            self.bet_won = True
            for winner in self.winners :
                if self.selection_id == winner[1] :
                    self.bet_won = False
                    break        

            for runner in self.runners:
                if self.selection_id == runner[1] :
                    price = float(runner[4])

        else :
            print 'Bad bet type', self.bet_type, 'must be back or lay'    
            a = 1/0



        profit = 0.0
        # take care of 5% commission here
        if self.bet_won :
            if self.bet_type == 'back' :
                profit = 0.95 * self.size * price 
            else:
                profit = 0.95 * self.size + self.size * price 

        
        self.saldo += profit         
        print 'bet won', str(self.bet_won)
    #############################
    
    def make_bet(self) : 
        self.selection_id = None
        race_list = []
        if self.bet_type == 'lay' :
     
            for runner in self.runners :
                tmp_bp = float(runner[3]) 
                tmp_lp = float(runner[4])  
                sel_id = int(runner[1]) 
                idx    = int(runner[2])  
           
                tmp_tuple = (tmp_bp, tmp_lp, sel_id, idx)
                race_list.append(tmp_tuple)    

            sorted_list = sorted(race_list, reverse=True)
            i = 0  
                
            selection = None
            lay_odds = None
            back_odds = None
            name = None
            index = None

            number_of_runners = len(sorted_list)
            max_turns = number_of_runners - 4  # there must be at least 5 runners with lower odds
            for dct in sorted_list :
                i += 1
                if  self.min_price <= float(dct[1]) and float(dct[1]) <= self.max_price and i <= max_turns :
                    selection = int(dct[2]) 
                    lay_odds  = float(dct[1])
                    back_odds = float(dct[0]) 
                    index     = int(dct[3]) 
                    self.selection_id = int(selection) 
                    self.saldo -= self.size * float(lay_odds) 
                    break 
      

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
            for dct in sorted_list :
                i += 1
                if  self.min_price <= float(dct[0]) and float(dct[0]) <= self.max_price and i <= max_turns :
                    selection = float(dct[2])
                    lay_odds  = float(dct[1]) 
                    back_odds = int(dct[0]) 
                    index     = int(dct[3]) 
                    self.selection_id = int(selection) 
                    self.saldo -=  self.size         
                    break 
        else :
            print 'Bad bet type', self.bet_type, 'must be back or lay'    
            a = 1/0
            
        ##############################################

###################################################################

#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

parser = OptionParser()
parser.add_option("-n", "--min_price", dest="min_price", action="store", type="float", help="min odds")
parser.add_option("-x", "--max_price", dest="max_price", action="store", type="float", help="max odds")
parser.add_option("-t", "--bet_type",  dest="bet_type",  action="store", type="string", help="bet type")
parser.add_option("-b", "--bet_name",  dest="bet_name",  action="store", type="string", help="bet name")
parser.add_option("-d", "--date",      dest="date",      action="store", type="string", help="date")
parser.add_option("-s", "--saldo",     dest="saldo",     action="store", type="float", help="start sum")
parser.add_option("-z", "--size",      dest="size",      action="store", type="float", help="bet size")
parser.add_option("-a", "--animal",    dest="animal",    action="store", type="string", help="animal")

                  
(options, args) = parser.parse_args()


print 'options', options
print 'args', args


simrun = BetSimulator(options.min_price, 
                      options.max_price, 
                      options.bet_type, 
                      options.bet_name, 
                      options.date, 
                      options.saldo,
                      options.size,
                      options.animal)
                          
                          
simrun.get_markets()

min_saldo = simrun.saldo
max_saldo = simrun.saldo
for market in simrun.markets :
    simrun.print_saldo()                          
    simrun.get_runners(market[0])
    simrun.get_winners(market[0])
    simrun.make_bet()
    
    if simrun.selection_id is not None :
        simrun.print_saldo()                          
        simrun.check_result()
        
    if  simrun.saldo < min_saldo : 
        min_saldo = simrun.saldo
    if  simrun.saldo > max_saldo : 
        max_saldo = simrun.saldo

print '------'  
print 'min', min_saldo                
print 'max', max_saldo                
                        
#lay_price_list = [5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
#back_price_list = [1.0, 1.05, 1.10, 1.15, 1.20, 1.25, 1.30, 1.35, \
#                   1.40, 1.45, 1.50, 1.55, 1.60, 1.65, 1.70, \
#                   1.75, 1.80, 1.85, 1.90, 1.95, 2.0]
#delay_list = [0,1,2,3,4,5,6]


