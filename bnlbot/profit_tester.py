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
    
    def get_bet_types(self, date):
        cur = self.conn.cursor()
        cur.execute("select distinct(BET_TYPE) from \
                     BET_WITH_COMMISSION where BET_PLACED::date = %s", 
                      (date,))
        self.bet_type_list = cur.fetchall()
        cur.close()
        self.conn.commit()    
    ########################    
    
    def get_bet_dates(self, date):
        cur = self.conn.cursor()
        cur.execute("select distinct(BET_PLACED::date) from \
                     BET_WITH_COMMISSION where BET_PLACED::date >= %s \
                     order by BET_PLACED::date", 
                      (date,))
        self.bet_date_list = cur.fetchall()
        cur.close()
        self.conn.commit()    
    ########################    
    
    def get_bets(self, date, bet_type, min_price, max_price):
        cur = self.conn.cursor()
        cur.execute("select PROFIT, BET_PLACED from BET_WITH_COMMISSION \
                     where BET_PLACED::date = %s and BET_TYPE = %s \
                     and PRICE >= %s AND PRICE <= %s \
                     order by BET_PLACED", 
                      (date, bet_type, min_price, max_price))
        self.bet_list = cur.fetchall()
        cur.close()
        self.conn.commit()    
    ########################

#datetime.datetime(2013, 1, 19, 12, 17))

        
    def start(self, dat, typ, delay, min_price, max_price):
        """start the main loop"""
        self.get_bets(dat, typ, min_price, max_price)
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

        print  typ, dat, delay, max_price, profit
        self.conn.close()   
        self.tuple = (dat, typ, delay, profit, max_price)
        

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
first_bet.get_bet_dates('2013-01-13')
first_bet.get_bet_types('2013-01-13')
first_bet.conn.close()
#first_bet.bet_type_list = ['DRY_RUN_HOUNDS_PLACE_BACK_BET']
#first_bet.bet_type_list = ['DRY_RUN_HOUNDS_PLACE_LAY_BET']
#first_bet.bet_type_list = ['DRY_RUN_HOUNDS_WINNER_LAY_BET']
#first_bet.bet_type_list = ['DRY_RUN_HOUNDS_WINNER_FAVORITE_LAY_BET']
#first_bet.bet_type_list = ['DRY_RUN_HORSES_PLACE_BACK_BET']
#first_bet.bet_type_list = ['DRY_RUN_HORSES_PLACE_LAY_BET']
#first_bet.bet_type_list = ['DRY_RUN_HORSES_WINNER_LAY_BET']
#first_bet.bet_type_list = ['DRY_RUN_HORSES_WINNER_FAVORITE_LAY_BET']


#min_price = float(options.min_price)
#max_price = float(options.max_price)
min_price = options.min_price
max_price = options.max_price

grand_sum = []

price_list = [5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]

for dat in first_bet.bet_date_list :
    for typ in first_bet.bet_type_list :
        for delay in [0 , 1 , 2, 3, 4, 5, 6, 8]:
            for max_odds in price_list:
                bet = ProfitTester()
                bet.start(dat, typ, delay, min_price, max_odds) 
                grand_sum.append(bet.tuple)

#sum_0 = 0.0
#sum_1 = 0.0
#sum_2 = 0.0
#sum_3 = 0.0
#sum_4 = 0.0
#sum_5 = 0.0
#sum_6 = 0.0
#sum_8 = 0.0

#sum = []
#for t in grand_sum :
#  if   t[2] == 0 : sum_0 += t[3]
#  elif t[2] == 1 : sum_1 += t[3]
#  elif t[2] == 2 : sum_2 += t[3]
#  elif t[2] == 3 : sum_3 += t[3]
#  elif t[2] == 4 : sum_4 += t[3]
#  elif t[2] == 5 : sum_5 += t[3]
#  elif t[2] == 6 : sum_6 += t[3]
#  elif t[2] == 8 : sum_8 += t[3]

#print 'sum 0', sum_0
#print 'sum 1', sum_1
#print 'sum 2', sum_2
#print 'sum 3', sum_3
#print 'sum 4', sum_4
#print 'sum 5', sum_5
#print 'sum 6', sum_6
#print 'sum 8', sum_8


