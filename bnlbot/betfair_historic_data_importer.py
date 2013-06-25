
import sys
import os
import psycopg2
from optparse import OptionParser
from datetime import datetime
import re


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
                                          password=bnl")

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
        self.other_keys = ['SPORTS_ID', 'EVENT_ID', 'SETTLED_DATE', 'FULL_DESCRIPTION','SCHEDULED_OFF','EVENT', \
                'DT ACTUAL_OFF' ,'SELECTION_ID','SELECTION' ,'ODDS', \
                'NUMBER_BETS' ,'VOLUME_MATCHED', 'LATEST_TAKEN','FIRST_TAKEN','WIN_FLAG','IN_PLAY' ]
        self.horse_keys = ['SPORTS_ID', 'EVENT_ID', 'SETTLED_DATE', 'COUNTRY', 'FULL_DESCRIPTION', 'COURSE', 'SCHEDULED_OFF',\
                'EVENT','ACTUAL_OFF' ,'SELECTION_ID','SELECTION' ,'ODDS', \
                'NUMBER_BETS' ,'VOLUME_MATCHED', 'LATEST_TAKEN','FIRST_TAKEN','WIN_FLAG','IN_PLAY' ]

    def treat_line(self, line) :
        row_is_ok = True
        #replace " with nothing
        if self.horse :
            keys = self.horse_keys
        else :
            keys = self.other_keys

        # some files hav values in "" some does not
        if line.lower().find('"') > -1 :
            vals = line.split('\",\"')
        else :
            vals = line.split(',')

        temp = dict(zip(keys, vals))
        for t in temp :
           v = temp[t].replace('"','')
           temp[t] = v.strip()

#        print 'line', line
#        print 'keys/val'
#        for t in temp :
#           print t, temp[t]
#        print 'done'


        #check that we actually want this row

        # must be PreEvent
        # fixed in file we treat via grep -v \"IP\" | grep -v \"AUS\"
#        row_is_ok = row_is_ok and temp['IN_PLAY'] != 'IP'
#        if not row_is_ok : return
#
#        row_is_ok = row_is_ok and temp['IN_PLAY'] != 'IP'
#        if not row_is_ok : return


        # event must start with num-char or char-num or 'hp' or 'hc' or 'or' or 'iv'
        # not case sensitive
        na = re.compile('^[0-9][a-z]', re.IGNORECASE)
        num_alfa = na.match(temp['EVENT'])
        if num_alfa :
            row_is_ok = True
        elif temp['EVENT'] == 'TO BE PLACED' :
            row_is_ok = True
        else :
            an = re.compile('^[a-z][0-9]', re.IGNORECASE)
            alfa_num = an.match(temp['EVENT'])
            if alfa_num :
                row_is_ok = True
            else :
                h = re.compile('^h[pc]', re.IGNORECASE)
                h_start = h.match(temp['EVENT'])
                if h_start :
                    row_is_ok = True
                else :
                    a_or = re.compile('^or', re.IGNORECASE)
                    or_start = a_or.match(temp['EVENT'])
                    if or_start :
                        row_is_ok = True
                    else :
                        iv = re.compile('^iv', re.IGNORECASE)
                        iv_start = iv.match(temp['EVENT'])
                        if iv_start :
                            row_is_ok = True
                        else :
                            row_is_ok = False

        if not row_is_ok : return

        #we dont want 'a v b'
        row_is_ok = temp['EVENT'].lower().find(' v ') == -1
        if not row_is_ok : return

        row_is_ok = temp['EVENT'].lower().find('forecast') == -1
        if not row_is_ok : return

        row_is_ok = temp['EVENT'].lower().find('challenge') == -1
        if not row_is_ok : return

        row_is_ok = temp['EVENT'].lower().find('fc') == -1
        if not row_is_ok : return

        row_is_ok = temp['EVENT'].lower().find('reverse') == -1
        if not row_is_ok : return

        row_is_ok = temp['EVENT'].lower().find('without') == -1
        if not row_is_ok : return

        row_is_ok = temp['EVENT'].lower().find('track record') == -1
        if not row_is_ok : return

        row_is_ok = temp['EVENT'].lower().find('age of winner') == -1
        if not row_is_ok : return

        row_is_ok = temp['EVENT'].lower().find('winning') == -1
        if not row_is_ok : return



        if not self.horse :
            temp['COUNTRY'] = 'NON'
            temp['COURSE'] = 'NON'
            temp['ACTUAL_OFF'] = temp['DT ACTUAL_OFF']
#        print 1,temp['EVENT_ID']

        if temp['SETTLED_DATE'] == '' :
            temp['SETTLED_DATE'] = None
        else:
            temp['SETTLED_DATE'] = datetime.strptime(temp['SETTLED_DATE'], '%d-%m-%Y %H:%M:%S')
#        print 2,temp['EVENT_ID']


        if temp['ACTUAL_OFF'] == '' :
            temp['ACTUAL_OFF'] = None
        else:
            temp['ACTUAL_OFF'] = datetime.strptime(temp['ACTUAL_OFF'], '%d-%m-%Y %H:%M:%S')
#        print 3,temp['EVENT_ID']

        if temp['LATEST_TAKEN'] == '' :
            temp['LATEST_TAKEN'] = None
        else:
            temp['LATEST_TAKEN'] = datetime.strptime(temp['LATEST_TAKEN'], '%d-%m-%Y %H:%M:%S')
#        print 4,temp['EVENT_ID']

        if temp['FIRST_TAKEN'] == '' :
            temp['FIRST_TAKEN'] = None
        else:
            temp['FIRST_TAKEN'] = datetime.strptime(temp['FIRST_TAKEN'], '%d-%m-%Y %H:%M:%S')
#        print 5,temp['EVENT_ID']

        if temp['SCHEDULED_OFF'] == '' :
            temp['SCHEDULED_OFF'] = None
        else:
            temp['SCHEDULED_OFF'] = datetime.strptime(temp['SCHEDULED_OFF'], '%d-%m-%Y %H:%M')
#        print 6,temp['EVENT_ID']

        if temp['COUNTRY'] == 'GB' or temp['COUNTRY'] == 'UK' :
            temp['COUNTRY'] = 'GBR'

#        print temp

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
                temp['SELECTION'], temp['ODDS'],  temp['NUMBER_BETS'], \
                temp['VOLUME_MATCHED'], temp['LATEST_TAKEN'], temp['FIRST_TAKEN'],\
                temp['WIN_FLAG'], temp['IN_PLAY']))
        cur.close()

    #####################################

    def main(self) :
            print self.file
            f = open(self.file)
            self.lines = f.readlines()
            f.close()
            lineno = 0

            for line in self.lines :
                #First line is headers
                lineno +=1
                if lineno >1 :
                    self.treat_line(line.strip())
                else :
                    #find if filename containes 'horse'
                    if self.file.lower().find('horse') == -1 :
                        self.horse = False
                    else:
                        self.horse = True

                    print "self.horse", self.horse
            self.conn.commit()

    #####################################


sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

parser = OptionParser()
parser.add_option("-f", "--file", dest="file", action="store", \
                  type="string", help="file to process")

(options, args) = parser.parse_args()

importer = Betfair_Historic_Data_Importer(options)
db = Db()
db.conn.set_client_encoding('LATIN1')
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



