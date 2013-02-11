
import sys
import os
import psycopg2

class Db(object):
    """db obj"""

    def __init__(self):

        self.hostname = os.uname()[1]

        if self.hostname == 'HP-Mini' :
            self.conn = psycopg2.connect("dbname='betting' \
                                          user='bnl' \
                                          host='192.168.0.24' \
                                          password=None")

        elif self.hostname == 'Rebecca.local' :
            self.conn = psycopg2.connect("dbname='betting' \
                                          user='bnl' \
                                          host='192.168.0.24' \
                                          password=None")

        elif self.hostname == 'Rebecca' :
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


class PPM_Importer(object):
    """base object"""





    def treat_line(self, line) :
        keys = ['animal', 'bet_name', 'bet_type', 'delta','price',\
                'min' ,'saldo','max' ]
        vals = line.split(" ")
        temp = dict(zip(keys, vals))
        print temp
        return temp


    #####################################

    def main(self) :
#        files = ['/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-hound-Vinnare-back-2013-01-31-2013-02-07-None.dat',\
#                 '/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-hound-Vinnare-back-2013-02-01-2013-02-08-None.dat',\
#                 '/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-hound-Vinnare-back-2013-02-02-2013-02-09-None.dat',\
#                 '/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-hound-Vinnare-back-2013-02-03-2013-02-10-None.dat']

#        files = ['/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-human-3.5-back-2013-01-31-2013-02-07-2.dat',\
#                 '/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-human-3.5-back-2013-02-01-2013-02-08-2.dat',\
#                 '/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-human-3.5-back-2013-02-02-2013-02-09-2.dat',\
#                 '/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-human-3.5-back-2013-02-03-2013-02-10-2.dat']

#        files = ['/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-human-4.5-back-2013-01-31-2013-02-07-2.dat',\
#                 '/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-human-4.5-back-2013-02-01-2013-02-08-2.dat',\
#                 '/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-human-4.5-back-2013-02-02-2013-02-09-2.dat',\
#                 '/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-human-4.5-back-2013-02-03-2013-02-10-2.dat']

        files = ['/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-human-straff-back-2013-01-31-2013-02-07-1.dat',\
                 '/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-human-straff-back-2013-02-01-2013-02-08-1.dat',\
                 '/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-human-straff-back-2013-02-02-2013-02-09-1.dat',\
                 '/home/bnl/Dropbox/betfair/png/intressanta/weekly/dat/simulation3-human-straff-back-2013-02-03-2013-02-10-1.dat']



        global_list = []

        for fi in files :
            print fi
            f = open(fi)
            self.lines = f.readlines()
            f.close()

            for line in self.lines :
                dct=self.treat_line(line.strip())
                idx=str(dct['price'] + '_' + dct['delta'] )

                found = False
                for item in global_list :
                    if item[1] == idx :
                        new_saldo = float(item[0]) + float(dct['saldo'])
                        global_list.remove(item)
                        global_list.append((new_saldo, idx))
                        found = True
                        break
                if not found :
                    global_list.append((float(dct['saldo']), idx))


        tmp_list = sorted(global_list)
        for item in tmp_list :
            print item

    #####################################


sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

importer = PPM_Importer()
#db = Db()
#importer.conn = db.conn
importer.main()



#create sequence funds_pk_serial;
#create table fonder (
#  pk integer default nextval('funds_pk_serial'),
#  FONDNUMMER integer,
#  FONDBOLAG varchar,
#  FONDNAMN varchar,
#  VALUTA varchar,
#  DATUM timestamp,
#  VALUTAKURS_K float,
#  VALUTAKURS_S float,
#  FONDKURS_K  float,
#  FONDKURS_S float,
#  FONDKURS_SEK_K float,
#  FONDKURS_SEK_S float,
#  primary key (pk)
#);
