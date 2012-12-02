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
#        cur = self.conn.cursor()
#        cur.execute("select away_team from markets")
#        rows = cur.fetchall()
#        cur.close()
##        print rows
#        cur2 = self.conn.cursor()
#        cur2.execute("select team_alias from team_aliases")
#        rows2 = cur2.fetchall()
#        cur2.close()
##        print rows2
#
#        rows52 = []  
#        for row in rows2 :
#            rows52.append(row[0])
#
#
#        rows5 = []  
#        for row in rows :
#            rows5.append(row[0])
#            
#        
#        for row in rows5 :
#            rows3 = difflib.get_close_matches(row,rows52)
#            print row, ' -> ',  rows3
#
#        self.conn.commit()
#
####
        cur1 = self.conn.cursor()
        my_dict = dict()
        cur1.execute("select ID, TEAM_NAME from UNIDENTIFIED_TEAMS \
                      order by EVENTTIME desc")
        row = cur1.fetchone()
        if cur1.rowcount >= 1 :
            my_dict['unk_id']   = row[0] 
            my_dict['unk_name'] = row[1]
            print "my_dict " , my_dict
        cur1.close() 
        
        cur2 = self.conn.cursor()
        cur2.execute("select TEAM_ID, TEAM_ALIAS from TEAM_ALIASES")
        my_whole_list = []
        
        rows2 = cur2.fetchone()
        print "row2" , rows2
        while rows2 :
            my_whole_list.append(rows2[1])
            rows2 = cur2.fetchone()
        cur2.close()
        print "passed 1, my_whole_list" ,my_whole_list 

        tmp = 'moreco'
#        tmp.append(my_dict['unk_name'])
        print "passed tmp ", tmp
        result_list_name = difflib.get_close_matches(tmp, my_whole_list)
        
        if len(result_list_name) == 0 :
            result_list_name =  ['-', '-', '-']
        elif len(result_list_name) == 1 :
            result_list_name.append('-')
            result_list_name.append('-')
        elif len(result_list_name) == 2 :
            result_list_name.append('-')
        
        result_list_id = []
        print "passed result_list_name " , result_list_name
        for r in result_list_name :
            cur4 = self.conn.cursor()
            cur4.execute("select TEAM_ID from TEAM_ALIASES \
                      where TEAM_ALIAS = %s", (r,))
            print "r " , r
            rows4 = cur4.fetchone()
            if rows4 :
                result_list_id.append(rows4[0])
                print "rows4[0] ",rows4[0]
            cur4.close()

        if len(result_list_id) == 0 :
            result_list_id =  [-1, -1, -1]
        elif len(result_list_id) == 1 :
            result_list_id.append(-1)
            result_list_id.append(-1)
        elif len(result_list_id) == 2 :
            result_list_id.append(-1)
        
        print "result_list_id", result_list_id

        
        
        
        
        ####        

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

