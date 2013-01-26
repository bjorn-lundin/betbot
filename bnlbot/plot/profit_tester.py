# coding=iso-8859-15
from time import sleep, time
import datetime
import psycopg2
#import urllib2
#import httplib2
#import ssl
#import xml.etree.ElementTree as etree 
import os
import sys
#import socket
from db import Db
from optparse import OptionParser

#  <market id="107893032" displayName="USA / Aque (US) 9th Jan - 17:30 TO BE PLACED">
#    <name>TO BE PLACED</name>
#    <country countryID="2">USA</country>
#    <menuHint>USA / Aque (US) 9th Jan</menuHint>
#    <startDate date="09/01/2013" time="17:30" sort="634933494000000000">09-Jan 17:30</startDate>
#    <marketType>Place</marketType>
#    <betType>Odds</betType>
#    <nonRunners list=""/>
#    <winners count="2" list=" Raffies Star,  Fit Fightin Feline" selectionIdList="6969167, 6969171">
#      <winner selectionId="6969167" raceNumber="1"> Raffies Star</winner>
#      <winner selectionId="6969171" raceNumber="7"> Fit Fightin Feline</winner>
#    </winners>
#  </market>
 
class ProfitTester(object):
    
    def __init__(self):
        self.Db = Db()
        self.conn = self.Db.conn
        self.bet_type_list = []
        self.bet_date_list = []
        self.bet_list = []
        self.tuple = None
    ########################## 	    
    
    def get_bet_types(self, bet_type, start_date, stop_date):
    
        if bet_type != None:
            self.bet_type_list.append(bet_type)
            return
    
        cur = self.conn.cursor()
        cur.execute("select distinct(BET_TYPE) from \
                     BET_WITH_COMMISSION \
                     where BET_PLACED::date >= %s \
                     and BET_PLACED::date <= %s",
                      (start_date, stop_date))

        rows = cur.fetchall()
        for row in rows:
            self.bet_type_list.append(row[0])  
        
#        self.bet_type_list = cur.fetchall()
        cur.close()
        self.conn.commit()    
    ########################    
    
    def get_bet_dates(self, start_date, stop_date):
        cur = self.conn.cursor()
        cur.execute("select distinct(BET_PLACED::date) \
                     from BET_WITH_COMMISSION \
                     where BET_PLACED::date >= %s \
                     and BET_PLACED::date <= %s \
                     order by BET_PLACED::date", 
                      (start_date, stop_date))
#        self.bet_date_list = cur.fetchall()
        rows = cur.fetchall()
        for row in rows:
            self.bet_date_list.append(row[0])  

        cur.close()
        self.conn.commit()    
    ########################    
    
    def get_bets(self, start_date, stop_date, bet_type, min_price, max_price):
        cur = self.conn.cursor()
        cur.execute("select PROFIT, BET_PLACED from BET_WITH_COMMISSION \
                     where BET_PLACED::date >= %s \
                     and BET_PLACED::date <= %s \
                     and BET_TYPE like %s \
                     and PRICE >= %s AND PRICE <= %s \
                     order by BET_PLACED", 
                      (start_date, stop_date, bet_type, min_price, max_price))
        self.bet_list = cur.fetchall()

#        rows = cur.fetchall()
#        for row in rows:
#            self.bet_list.append(row)  

        cur.close()
        self.conn.commit()    
    ########################

    def print_bet_types(self, as_comment = True) : 
        tmp_list = sorted(self.bet_type_list)
        for row in tmp_list :
            if as_comment : 
                print '#', row
            else :
                print row
        
    ########################
    def print_bet_dates(self, as_comment = True) : 
        tmp_list = sorted(self.bet_date_list)
        for row in tmp_list :
            if as_comment : 
                print '#', row
            else :
                print row
    ########################

#datetime.datetime(2013, 1, 19, 12, 17))

        
    def start(self, start_date, stop_date, typ, delay, min_price, max_price):
        """start the main loop"""
        self.get_bets(start_date, stop_date, typ, min_price, max_price)
        profit = 0.0
        d_last_loss = None
        for rec in self.bet_list:
#            print 'rec', rec
            p = float(rec[0])
            d = rec[1]
            ok = True
            if d_last_loss:
               ok = (d >= d_last_loss + datetime.timedelta(0, delay * 3600) )
            
            if ok:
                profit += p
                if p < 0.0 : 
                    d_last_loss = d
            
        print delay, min_price, max_price, profit
        self.conn.close()   
        self.tuple = (start_date, stop_date, typ, delay, profit, min_price, max_price)
        

###################################################################

#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

parser = OptionParser()
parser.add_option("-n", "--min_price", dest="min_price", action="store", type="float", help="min odds")
parser.add_option("-x", "--max_price", dest="max_price", action="store", type="float", help="max odds")
parser.add_option("-t", "--bet_type", dest="bet_type", action="store", type="string", help="list bet types")
parser.add_option("-s", "--start_date", dest="start_date", action="store", type="string", help="start date")
parser.add_option("-e", "--stop_date", dest="stop_date", action="store", type="string", help="stop date")
parser.add_option("-q", "--quit_one", dest="quit_one", action="store_true", help="stop after one action", default=False)

                  
(options, args) = parser.parse_args()

min_price = options.min_price
max_price = options.max_price
start_date = options.start_date
stop_date = options.stop_date
bet_type = options.bet_type
quit_one = options.quit_one

if bet_type == "":
    bet_type = None

if quit_one == None:
    quit_one = False


#print 'options', options
#print 'args', args


first_bet = ProfitTester()
first_bet.get_bet_dates(start_date, stop_date)
first_bet.get_bet_types(bet_type, start_date, stop_date)
first_bet.conn.close()

first_bet.print_bet_types()
first_bet.print_bet_dates()

if quit_one :
    sys.exit()

grand_sum = []

lay_price_list = [5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
back_price_list = [1.0, 1.05, 1.10, 1.15, 1.20, 1.25, 1.30, 1.35, \
                   1.40, 1.45, 1.50, 1.55, 1.60, 1.65, 1.70, \
                   1.75, 1.80, 1.85, 1.90, 1.95, 2.0]

delay_list = [0,1,2,3,4,5,6]

for typ in first_bet.bet_type_list :
   if typ[0].lower().find('lay') > -1 :
        for delay in delay_list:
            for mprice in lay_price_list:
                bet = ProfitTester()
                bet.start(start_date, stop_date, typ, delay, min_price, mprice) 
                grand_sum.append(bet.tuple)


for typ in first_bet.bet_type_list :
   if typ[0].lower().find('lay') == -1 :
        for delay in delay_list:
            for bprice in back_price_list:
                bet = ProfitTester()
                bet.start(start_date, stop_date, typ, delay, bprice, max_price) 
                grand_sum.append(bet.tuple)	
