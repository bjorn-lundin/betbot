
import sys
import os  
import psycopg2
from optparse import OptionParser

class Db(object):
    """db obj"""
    
    def __init__(self):
        
        self.hostname = os.uname()[1]

        if self.hostname == 'HP-Mini' :
            self.conn = psycopg2.connect("dbname='bfhistory' \
                                          user='bnl' \
                                          host='sebjlun-deb' \
                                          password=None") 
                                          
        elif self.hostname == 'Rebecca.local' :
            self.conn = psycopg2.connect("dbname='bfhistory' \
                                          user='bnl' \
                                          host='sebjlun-deb' \
                                          password=None") 

        elif self.hostname == 'sebjlun-deb' :
            self.conn = psycopg2.connect("dbname='bfhistory' \
                                          user='bnl' \
                                          host='localhost' \
                                          password=None") 
                                          
        elif self.hostname == 'ip-10-64-5-16' :                     
            self.conn = psycopg2.connect("dbname='bfhistory' \
                                          user='bnl' \
                                          host='nonodev.com' \
                                          password='BettingFotboll1$'") 
        else :
            raise Exception("Bad hostname: " + self.hostname)
        ######## end init ##########
######## end class ########## 


class Betfair_Historic_Data_Importer(object):
    """base object"""
    
    
    def __init__(self, opts):
        self.file = opts.file
        self.lines = None
        self.horse = False
        self.other_keys = ['SPORTS_ID', 'EVENT_ID', 'SETTLED_DATE', 'FULL_DESCRIPTION','SCHEDULED_OFF',\
                'DT ACTUAL_OFF' ,'SELECTION_ID','SELECTION' ,'ODDS', \
                'NUMBER_BETS' ,'VOLUME_MATCHED', 'LATEST_TAKEN','FIRST_TAKEN','WIN_FLAG','IN_PLAY' ]
        self.horse_keys = ['SPORTS_ID', 'EVENT_ID', 'SETTLED_DATE', 'COUNTRY', 'FULL_DESCRIPTION', 'COURSE', 'SCHEDULED_OFF',\
                'ACTUAL_OFF' ,'SELECTION_ID','SELECTION' ,'ODDS', \
                'NUMBER_BETS' ,'VOLUME_MATCHED', 'LATEST_TAKEN','FIRST_TAKEN','WIN_FLAG','IN_PLAY' ]

    def treat_line(self, line) :
        #replace " with nothing
        if self.horse :
            keys = self.horse_key
        else :
            keys = self.other_key
            
        myline = line.replace('"','')
        vals = myline.split(",")
        temp = dict(zip(keys, vals))
        
        if not self.horse :
            temp['COUNTRY'] = None    
            temp['COURSE'] = None    
            temp['ACTUAL_OFF'] = temp['DT ACTUAL_OFF']     
        
        print temp

#  SPORTSID integer,
#  EVENTID integer,
#  SETTLEDDATE timestamp,
#  COUNTRY varchar,
#  FULLDESCRIPTION varchar,
#  COURSE varchar,
#  SCHEDULEDOFF timestamp,
#  EVENT varchar,
#  SELECTIONID integer,
#  SELECTION  varchar,
#  ODDS float,
#  NUMBERBETS integer,
#  VOLUMEMATCHED float,
#  LATESTTAKEN timestamp,
#  FIRSTTAKEN timestamp,
#  WINFLAG boolean,
#  INPLAY  varchar,


        
        cur = self.conn.cursor()
        cur.execute("insert into HISTORY ( \
                         SPORTSID, EVENTID, SETTLEDDATE, COUNTRY, \
                         FULLDESCRIPTION, COURSE, SCHEDULEDOFF, \
                         EVENT, SELECTIONID , \
                         SELECTION, ODDS, NUMBERBETS, VOLUMEMATCHED,\
                         LATESTTAKEN, FIRSTTAKEN, WINFLAG, INPLAY) \
                         values \
                         (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)", 
               (temp['SPORTS_ID'], temp['EVENT_ID'], temp['SETTLED_DATE'], \
                temp['COUNTRY'], temp['FULL_DESCRIPTION'], temp['COURSE'], \
                temp['SCHEDULED_OFF'], temp['EVENT'], temp['SELECTION_ID'], \
                temp['SELECTION'], temp['ODDS']  temp['NUMBER_BETS'], \
                temp['VOLUME_MATCHED'], temp['LATEST_TAKEN'], temp['FIRST_TAKEN'],\
                temp['WIN_FLAG'], temp['IN_PLAY']))
        cur.close()    
        
    ##################################### 
    
    def main(self) :
            print self.file
            f = open(self.file)
            self.lines = f.readlines()
            f.close()

            for line in self.lines :
                #First line is headers
                lineno +=1
                if lineno >1 :
                    self.treat_line(line.strip())
                else :
                    #find if filename containes 'horse'
                    self.horse = True
            self.conn.commit()
             
    ##################################### 


sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

parser = OptionParser()
parser.add_option("-f", "--file", dest="file", action="store", \
                  type="string", help="file to process")

(options, args) = parser.parse_args()

importer = Betfair_Historic_Data_Importer(options)
db = Db()
importer.conn = db.conn
importer.main()


#create sequence betfair_historic_data_pk_serial;
#create table history (
#  pk integer default nextval('betfair_historic_data_pk_serial'),
#  SPORTSID integer,
#  EVENTID integer,
#  SETTLEDDATE timestamp,
#  COUNTRY varchar,
#  FULLDESCRIPTION varchar,
#  COURSE varchar,
#  SCHEDULEDOFF timestamp,
#  EVENT varchar,
#  SELECTIONID integer,
#  SELECTION  varchar,
#  ODDS float,
#  NUMBERBETS integer,
#  VOLUMEMATCHED float,
#  LATESTTAKEN timestamp,
#  FIRSTTAKEN timestamp,
#  WINFLAG boolean,
#  INPLAY  varchar,
#  primary key (pk)
#);
