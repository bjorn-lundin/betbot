import psycopg2
import os
import sys

class Db(object):
    """put bet on games with low odds"""
    
    def __init__(self):
        
        self.hostname = os.uname()[1]

        if self.hostname == 'HP-Mini' :
            self.conn = psycopg2.connect("dbname='betting' \
                                          user='bnl' \
                                          host='192.168.0.24' \
                                          password=None") 

        elif self.hostname == 'raspberrypi' :
            self.conn = psycopg2.connect("dbname='betting' \
                                          user='bnl' \
                                          host='192.168.0.24' \
                                          password=None") 
                                          
        elif self.hostname == 'ip-10-64-5-16' :                     
            self.conn = psycopg2.connect("dbname='bnl' \
                                          user='bnl' \
                                          host='nonodev.com' \
                                          password='BettingFotboll1$'") 
        else :
            raise Exception("Bad hostname: " + self.hostname)
        ######## end init ##########
######## end class ########## 
