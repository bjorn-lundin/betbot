#!/usr/bin/env python
#from time import sleep, time
import datetime
import psycopg2
#import urllib2
#import ssl
#import xml.etree.ElementTree as etree 
from  market import Market


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
        
    def print_team_names(self):
        print 'print_team_names start'
        cur = self.conn.cursor()
        cur.execute("select MENU_PATH from MARKETS order by MENU_PATH")
        rc = cur.rowcount
        print ' cur.rowcount()', rc
        while True : 
            row = cur.fetchone()
            if row == None : break
            row_as_list = row[0].split('\\')
            teams = row_as_list[len(row_as_list) -1].lower()
            teams = teams.replace(' - ','|')
            teams = teams.replace(' v ','|')
            teams = teams.replace(' vs ','|')
            teams = teams.replace(' versus ','|')
            list_teams = teams.split('|')
            try: 
              home_team = list_teams[0]
              away_team = list_teams[1]
              print 'Home:',home_team,' Away:',away_team,'row',row[0]
              cur2 = self.conn.cursor()
              cur2.execute("update MARKETS \
                            set HOME_TEAM = %s , AWAY_TEAM = %s \
                            where MENU_PATH = %s",
                          (home_team, away_team, row[0]))
              print 'Antal hits:', cur2.rowcount
              cur2.close()
              
            except IndexError :
                print 'Warning',list_teams

        self.conn.commit()
        cur.close()

        
    def insert_timestamp(self):
        print 'insert_timestamp start'
        cur = self.conn.cursor()
#        cur.execute("insert into TEST_TIMESTAMP (ID, T) values (%s,%s)" ,(6,'2012-11-12 12:34:45') )
#        cur.execute("insert into TEST_TIMESTAMP (ID, T) values (%s,%s)" ,(7, datetime.datetime.fromtimestamp(1352402876 )) )
        cur.execute("insert into TEST_TIMESTAMP (ID, T) values (%s,%s)" ,(10, datetime.datetime.now()) )
        
        rc = cur.rowcount
        print ' cur.rowcount()', rc
        self.conn.commit()
        cur.close()

              
print 'starting:',datetime.datetime.now()
tst = test_db()
tst.connect_db() 

mark = Market(1234,tst.conn)
mark.try_set_gamestart()
#tst.print_team_names()
#tst.insert_timestamp()
print 'Ending:',datetime.datetime.now()

