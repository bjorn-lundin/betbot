
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
        keys = ['FONDNUMMER', 'FONDBOLAG', 'FONDNAMN', 'VALUTA','DATUM',\
                'VALUTAKURS_K' ,'VALUTAKURS_S','FONDKURS_K' ,'FONDKURS_S', \
                'FONDKURS_SEK_K' ,'FONDKURS_SEK_S' ]
        #replace ',' with '.'
        myline = line.replace(',','.')
        vals = myline.split("\t")
        temp = dict(zip(keys, vals))
        print temp
    
        cur = self.conn.cursor()
        cur.execute("insert into FONDER ( \
                         FONDNUMMER, FONDBOLAG, FONDNAMN, VALUTA, \
                         DATUM, VALUTAKURS_K,VALUTAKURS_S, \
                         FONDKURS_K, FONDKURS_S , \
                         FONDKURS_SEK_K, FONDKURS_SEK_S ) \
                         values \
                         (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)", 
               (temp['FONDNUMMER'], temp['FONDBOLAG'], temp['FONDNAMN'], \
                temp['VALUTA'], temp['DATUM'], temp['VALUTAKURS_K'], \
                temp['VALUTAKURS_S'], temp['FONDKURS_K'], temp['FONDKURS_S'], \
                temp['FONDKURS_SEK_K'], temp['FONDKURS_SEK_S']))
        cur.close()    
        
    ##################################### 
    
    def main(self) :
        files = ['/Users/bnl/Downloads/ppm/Fondkurser_2000.txt',\
                 '/Users/bnl/Downloads/ppm/Fondkurser_2001.txt',\
                 '/Users/bnl/Downloads/ppm/Fondkurser_2002.txt',\
                 '/Users/bnl/Downloads/ppm/Fondkurser_2003.txt',\
                 '/Users/bnl/Downloads/ppm/Fondkurser_2004.txt',\
                 '/Users/bnl/Downloads/ppm/Fondkurser_2005.txt',\
                 '/Users/bnl/Downloads/ppm/Fondkurser_2006.txt']
                 
        for fi in files : 
            lineno = 0
            print fi
            f = open(fi)
            self.lines = f.readlines()
            f.close()

            for line in self.lines :
                lineno +=1
                if lineno >1 :
                    self.treat_line(line.strip())
            self.conn.commit()
             
    ##################################### 


sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

importer = PPM_Importer()
db = Db()
importer.conn = db.conn
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
