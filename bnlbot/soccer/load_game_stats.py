# coding=iso-8859-15
"""put bet on games with low odds"""
from betfair.api import API
from time import sleep, time
import datetime 
import psycopg2
import urllib2
import ssl
import os
import sys

from market import Market
from funding import Funding
import socket

class Score_Stats(object):
    """put bet on games with low odds"""
    SLEEP_BETWEEN_TURNS = 5.0
    
    def __init__(self):
        self.league = sys.argv[1]
        self.season = sys.argv[2]
        self.filename = sys.argv[3]
        self.lines = tuple(open(self.filename, 'r'))
############################# end __init__
    def make_euro_date(self, datestring):
        print 'date_string_in', datestring
        tupe = datestring.split(' ')
        self.letter_month = tupe[0]
        self.letter_date = tupe[1]
        self.numeric_year= tupe[2]
        
        if self.letter_month == 'January' :
            self.numeric_month = '01'
        elif self.letter_month == 'February' :
            self.numeric_month = '02'
        elif self.letter_month == 'March' :
            self.numeric_month = '03'
        elif self.letter_month == 'April' :
            self.numeric_month = '04'
        elif self.letter_month == 'May' :
            self.numeric_month = '05'
        elif self.letter_month == 'June' :
            self.numeric_month = '06'
        elif self.letter_month == 'July' :
            self.numeric_month = '07'
        elif self.letter_month == 'August' :
            self.numeric_month = '08'
        elif self.letter_month == 'September' :
            self.numeric_month = '09'
        elif self.letter_month == 'October' :
            self.numeric_month = '10'
        elif self.letter_month == 'November' :
            self.numeric_month = '11'
        elif self.letter_month == 'December' :
            self.numeric_month = '12'
        else :
            self.numeric_month = '00'



        if self.letter_date == '1st' :
            self.letter_date = '01'
        elif self.letter_date == '2nd' :
            self.letter_date = '02'
        elif self.letter_date == '3rd' :
            self.letter_date = '03'
        elif self.letter_date == '4th' :
            self.letter_date = '04'
        elif self.letter_date == '5th' :
            self.letter_date = '05'
        elif self.letter_date == '6th' :
            self.letter_date = '06'
        elif self.letter_date == '7th' :
            self.letter_date = '07'
        elif self.letter_date == '8th' :
            self.letter_date = '08'
        elif self.letter_date == '9th' :
            self.letter_date = '09'
        elif self.letter_date == '10th' :
            self.letter_date = '10'
        elif self.letter_date == '11th' :
            self.letter_date = '11'
        elif self.letter_date == '12th' :
            self.letter_date = '12'
        elif self.letter_date == '13th' :
            self.letter_date = '13'
        elif self.letter_date == '14th' :
            self.letter_date = '14'
        elif self.letter_date == '15th' :
            self.letter_date = '15'
        elif self.letter_date == '16th' :
            self.letter_date = '16'
        elif self.letter_date == '17th' :
            self.letter_date = '17'
        elif self.letter_date == '18th' :
            self.letter_date = '18'
        elif self.letter_date == '19th' :
            self.letter_date = '19'
        elif self.letter_date == '20th' :
            self.letter_date = '20'
        elif self.letter_date == '21st' :
            self.letter_date = '21'
        elif self.letter_date == '22nd' :
            self.letter_date = '22'
        elif self.letter_date == '23rd' :
            self.letter_date = '23'
        elif self.letter_date == '24th' :
            self.letter_date = '24'
        elif self.letter_date == '25th' :
            self.letter_date = '25'
        elif self.letter_date == '26th' :
            self.letter_date = '26'
        elif self.letter_date == '27th' :
            self.letter_date = '27'
        elif self.letter_date == '28th' :
            self.letter_date = '28'
        elif self.letter_date == '29th' :
            self.letter_date = '29'
        elif self.letter_date == '30th' :
            self.letter_date = '30'
        elif self.letter_date == '31st' :
            self.letter_date = '31'
        else :
            self.letter_date = '00'
        
        self.euro_date = str(self.numeric_year) + '-' + self.numeric_month + '-' + self.letter_date
        
        print 'date_string_out', self.euro_date
        ################################################
        

    def load(self):
        print 'insert stat', self.league , self.season
        cur = self.conn.cursor()
        for line in self.lines :
            print 'line', line
            tups = line.split('\t')
            print 'tups', tups
            self.make_euro_date(tups[0]) 
            self.date = datetime.datetime.strptime(self.euro_date , '%Y-%m-%d')
            print 'self.date', self.date
            teams = tups[1].split(' - ')
            print 'teams', teams
            self.home_team = teams[0]
            self.away_team = teams[1]
            goals = tups[2].split('-')
            self.home_goals = goals[0]
            self.away_goals = goals[1]
         
            print 'row',self.league, self.season, self.date, \
               self.home_team, self.away_team, self.home_goals, self.away_goals
                
                
            cur.execute("insert into SCORE_STATISTICS ( \
                         LEAGUE, SEASON, EVENT_DATE, \
                         HOME_TEAM, AWAY_TEAM, HOME_GOALS, AWAY_GOALS ) \
                         values \
                         (%s,%s,%s,%s,%s,%s,%s)", \
               (self.league, self.season, self.date, self.home_team, \
                self.away_team, self.home_goals, self.away_goals))
        cur.close()
############################# end load




#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

stats = Score_Stats()
print 'Starting up:', datetime.datetime.now()
stats.conn = psycopg2.connect("dbname='betting' \
                             user='bnl' \
                             host='192.168.0.24' \
                             password=None") 
#bot.conn = psycopg2.connect("dbname='bnl' \
#                             user='bnl' \
#                             host='nonodev.com' \
#                             password='BettingFotboll1$'") 


stats.conn.set_client_encoding('LATIN1')
stats.load()    
stats.conn.commit()

print 'Ending:', datetime.datetime.now()

