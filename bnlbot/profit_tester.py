# coding=iso-8859-15
from time import sleep, time
import datetime
import psycopg2
import urllib2
import httplib2
import ssl
import xml.etree.ElementTree as etree 
import os
import sys
import socket
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
        self.bet_type_list = None
        self.bet_date_list = None
        self.bet_list = None
        self.tuple = None
    ########################## 	    
    
    def get_bet_types(self, start_date, stop_date):
        cur = self.conn.cursor()
        cur.execute("select distinct(BET_TYPE) from \
                     BET_WITH_COMMISSION \
                     where BET_PLACED::date >= %s \
                     and BET_PLACED::date <= %s",
                      (start_date, stop_date))
        self.bet_type_list = cur.fetchall()
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
        self.bet_date_list = cur.fetchall()
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
        cur.close()
        self.conn.commit()    
    ########################

#datetime.datetime(2013, 1, 19, 12, 17))

        
    def start(self, start_date, stop_date, typ, delay, min_price, max_price):
        """start the main loop"""
        self.get_bets(start_date, stop_date, typ, min_price, max_price)
        profit = 0.0
        d_last_loss = None
        for rec in self.bet_list:
#            print  rec
            p = float(rec[0])
            d = rec[1]
            ok = True
            if d_last_loss:
               ok = (d >= d_last_loss + datetime.timedelta(0, delay * 3600) )
            
            if ok:
                profit += p
                if p < 0.0 : 
                    d_last_loss = d

        print  typ, start_date, delay, min_price, max_price, profit
        self.conn.close()   
        self.tuple = (start_date, stop_date, typ, delay, profit, min_price, max_price)
        

###################################################################


#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)


parser = OptionParser()
parser.add_option("-n", "--min_price", dest="min_price", action="store", type="float", help="min odds")
parser.add_option("-x", "--max_price", dest="max_price", action="store", type="float", help="max odds")
                  
                  
(options, args) = parser.parse_args()



#print 'options', options
#print 'args', args


first_bet = ProfitTester()
#first_bet.get_bet_dates('2013-01-01', '2013-01-31')
first_bet.get_bet_types('2013-01-01', '2013-01-31')
first_bet.conn.close()
#first_bet.bet_type_list = ['DRY_RUN_HOUNDS_PLACE_BACK_BET']
#first_bet.bet_type_list = ['DRY_RUN_HOUNDS_PLACE_LAY_BET']
#first_bet.bet_type_list = ['DRY_RUN_HOUNDS_WINNER_LAY_BET']
#first_bet.bet_type_list = ['DRY_RUN_HOUNDS_WINNER_FAVORITE_LAY_BET']
#first_bet.bet_type_list = ['DRY_RUN_HORSES_PLACE_BACK_BET']
#first_bet.bet_type_list = ['DRY_RUN_HORSES_PLACE_LAY_BET']
#first_bet.bet_type_list = ['DRY_RUN_HORSES_WINNER_LAY_BET']
#first_bet.bet_type_list = ['DRY_RUN_HORSES_WINNER_FAVORITE_LAY_BET']
#first_bet.bet_type_list = ['%ORSES_PLACE_BACK_BET']


#min_price = float(options.min_price)
#max_price = float(options.max_price)
min_price = options.min_price
max_price = options.max_price

grand_sum = []

lay_price_list = [5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
back_price_list = [1.05, 1.10, 1.15, 1.20, 1.25, 1.30, 1.35, \
                   1.40, 1.45, 1.50, 1.55, 1.60, 1.65, 1.70, \
                   1.75, 1.80, 1.85, 1.90, 1.95, 2.0]
#price_list = [12]
#delay_list = [0,6]
delay_list = [0,1,2,3,4,5,6]

for typ in first_bet.bet_type_list :
   if typ[0].lower().find('lay') > -1 :
        for delay in delay_list:
            for mprice in lay_price_list:
                bet = ProfitTester()
                bet.start('2013-01-17', '2013-01-31', typ, delay, min_price, mprice) 
                grand_sum.append(bet.tuple)


for typ in first_bet.bet_type_list :
   if typ[0].lower().find('lay') == -1 :
        for delay in delay_list:
            for bprice in back_price_list:
                bet = ProfitTester()
                bet.start('2013-01-17', '2013-01-31', typ, delay, bprice, max_price) 
                grand_sum.append(bet.tuple)	
