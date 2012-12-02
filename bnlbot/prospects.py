#!/usr/bin/env python
#from time import sleep, time
import datetime
import psycopg2
#import urllib2
#import ssl
#import xml.etree.ElementTree as etree 
from  market import Market
import difflib
import sys
import os

class test_db(object):
    conn = None 
    def __init__(self):
        return   
    
    def connect_db(self):
        self.conn = psycopg2.connect("dbname='betting' user='bnl' host='192.168.0.24' password=None") 
    
    def start(self):
        """start the main loop"""
        # main loop ended...
        s = 'MAIN LOOP ENDED...\n'
        s += '---------------------------------------------'
        print s
        
    def difflib_test(self):
        print 'print_team_names start'
        cur = self.conn.cursor()
        cur.execute("select away_team from markets")
        rows = cur.fetchall()
        cur.close()
#        print rows
        cur2 = self.conn.cursor()
        cur2.execute("select team_alias from team_aliases")
        rows2 = cur2.fetchall()
        cur2.close()
#        print rows2

        rows52 = []  
        for row in rows2 :
            rows52.append(row[0])


        rows5 = []  
        for row in rows :
            rows5.append(row[0])
            
        
        for row in rows5 :
            rows3 = difflib.get_close_matches(row,rows52)
            print row, ' -> ',  rows3

        self.conn.commit()

        

#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
              
print 'starting:',datetime.datetime.now()
tst = test_db()
tst.connect_db() 
tst.difflib_test()

#mark = Market(1234,tst.conn)
#mark.try_set_gamestart()
#tst.print_team_names()
#tst.insert_timestamp()
print 'Ending:',datetime.datetime.now()

