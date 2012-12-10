import BaseHTTPServer
import os
import sys
import mimetypes 
import psycopg2
import difflib
from db import Db
import logging.handlers

from string import Template

class MyHandler( BaseHTTPServer.BaseHTTPRequestHandler ):
    
    
    def __init__(self, log):
        server_version= "pybnl/1.0"
        db = Db() 
        self.conn = db.conn 
        self.log = log
    
        
    #########################################################
    def do_GET(self):
        
#        self.conn = psycopg2.connect("dbname='betting' \
#                             user='bnl' \
#                             host='192.168.0.24' \
#                             password=None") 
#        
        try:
            filepath1 = self.path.lstrip('/') 
            # remove any char after a ?, inclusive
            filepath = filepath1.split('?')[0] 
            f = open(filepath)
        except IOError:
            self.send_error(404,'File Not Found: %s ' % filepath)
            return

        self.send_response(200)
        mimetype, _ = mimetypes.guess_type(filepath)
        self.send_header('Content-type', mimetype)
        self.end_headers()
        
        if filepath == 'teams.html' :
            template = Template(f.read())
            cur1 = self.conn.cursor()
            my_dict = dict()
            cur1.execute("select ID, TEAM_NAME from UNIDENTIFIED_TEAMS \
                          order by EVENTTIME desc")
            row = cur1.fetchone()
            if cur1.rowcount >= 1 :
                my_dict['unk_id']   = row[0] 
                my_dict['unk_name'] = row[1]
                self.log_message( "my_dict %s" % (my_dict))
            cur1.close() 


            cur2 = self.conn.cursor()
            cur2.execute("select TEAM_ID, TEAM_ALIAS from TEAM_ALIASES")
            my_whole_list = []
            
            rows2 = cur2.fetchone()
            while rows2 :
                my_whole_list.append(rows2[1])
                rows2 = cur2.fetchone()
            cur2.close()
            self.log_message( "passed 1" )
           
            result_list_name = difflib.get_close_matches(my_dict['unk_name'], my_whole_list)
            if len(result_list_name) == 0 :
                result_list_name =  ['-', '-', '-']
            elif len(result_list_name) == 1 :
                result_list_name.append('-')
                result_list_name.append('-')
            elif len(result_list_name) == 2 :
                result_list_name.append('-')
                
            result_list_id = []
            self.log_message( "passed result_list_name %s " % (result_list_name))

            for r in result_list_name :
                cur4 = self.conn.cursor()
                cur4.execute("select TEAM_ID from TEAM_ALIASES \
                          where TEAM_ALIAS = %s", (r,))
                self.log_message( "r % s " % (r) )
                rows4 = cur4.fetchone()
                if rows4 :
                    result_list_id.append(rows4[0])
                    self.log_message( "rows4[0] % s " % (rows4[0]) )
                cur4.close()
    
            if len(result_list_id) == 0 :
                result_list_id =  [-1, -1, -1]
            elif len(result_list_id) == 1 :
                result_list_id.append(-1)
                result_list_id.append(-1)
            elif len(result_list_id) == 2 :
                result_list_id.append(-1)
            
            self.log_message( "passed result_list_id %s " % (result_list_id))
             
            a = template.substitute(
                dict(
                    unk_name = my_dict['unk_name'], unk_id = my_dict['unk_id'],
                    name_1 = result_list_name[0] , id_1 = result_list_id[0],
                    name_2 = result_list_name[1],  id_2 = result_list_id[1],
                    name_3 = result_list_name[2],  id_3 = result_list_id[2])
                )
            self.wfile.write(a)
        else : 
            self.wfile.write(f.read())

        self.conn.commit()
        self.conn.close()

    #########################################################
    def do_POST( self ):
#        self.conn = psycopg2.connect("dbname='betting' \
#                             user='bnl' \
#                             host='192.168.0.24' \
#                             password=None") 
        self.log_message( "Command: %s Path: %s Headers: %r"
                          % ( self.command, self.path, self.headers.items() ) )
        if self.headers.has_key('content-length'):
            length= int( self.headers['content-length'] )

            
            
        self.log_message ("bnl self.path= %s ", self.path)
        dict_items = self.path.split('?')[1].split('&')
        d = dict()
        for items in dict_items:
            tmp = items.split('=')
            d[tmp[0]] = tmp[1]
                       
        self.log_message ("bnl d= %s ", d)
        self.send_response(200)
        self.conn.commit()
        self.conn.close()
            
    #########################################################

def httpd(handler_class=MyHandler, server_address = ('', 8008), ):
    log = logging.getLogger(__name__)
    log.setLevel(logging.DEBUG)
    FH = logging.handlers.RotatingFileHandler(
        '../logs/httpd.log',
        mode = 'a',
        maxBytes = 500000,
        backupCount = 10,
        encoding = 'iso-8859-15',
        delay = False
    ) 
    FH.setLevel(logging.DEBUG)
    FORMATTER = logging.Formatter('%(asctime)s %(name)s %(levelname)s %(message)s')
    FH.setFormatter(FORMATTER)
    log.addHandler(FH)
    log.info('Starting application')


    
    srvr = BaseHTTPServer.HTTPServer(server_address, handler_class(log))
#    srvr.handle_request() # serve_forever
#    srvr.conn = psycopg2.connect("dbname='betting' \
#                             user='bnl' \
#                             host='192.168.0.24' \
#                             password=None") 
    srvr.serve_forever()

if __name__ == "__main__":
    try:
       httpd( )
    except KeyboardInterrupt :
       pass     
    log.info('Ending application')
    logging.shutdown()

    
    
    