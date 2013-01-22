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
    
    def get_bets(self, date, bet_type):
        cur = self.conn.cursor()
        cur.execute("select PROFIT, BET_PLACED from BET_WITH_COMMISSION \
                     where BET_PLACED::date = %s and BET_TYPE = %s \
                     order by BET_PLACED", 
                      (date, bet_type))
        self.bet_list = cur.fetchall()
        cur.close()
        self.conn.commit()    
    ########################

#datetime.datetime(2013, 1, 19, 12, 17))

        
    def start(self, dat, typ, delay):
        """start the main loop"""
        self.get_bets(dat, typ)
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

        print  dat, typ, delay, profit
        self.conn.close()   
        

###################################################################


#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

first_bet = ProfitTester()
first_bet.get_bet_dates('2013-01-17')
first_bet.get_bet_types('2013-01-17')
first_bet.conn.close()   


for dat in first_bet.bet_date_list :
    for typ in first_bet.bet_type_list :
#        for delay in [0 , 1 , 2, 4, 6, 8, 10, 24]:
        for delay in [0, 6]:
            bet = ProfitTester()
            bet.start(dat, typ, delay) 

