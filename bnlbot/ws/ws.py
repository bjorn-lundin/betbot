import BaseHTTPServer
import os
import sys
import mimetypes 

from string import Template

class MyHandler( BaseHTTPServer.BaseHTTPRequestHandler ):
    server_version= "MyHandler/1.1"
        
    def do_GET(self):
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
            a = template.substitute(dict(name_1 = 'Tottenham', id_1 = '123',
                                         name_2 = 'Tottham',   id_2 = '523',
                                         name_3 = 'spurs',     id_3 = '456'))
            self.wfile.write(a)
        else :
            self.wfile.write(f.read())
            
#        for s in f:
#                self.wfile.write(s)

    def do_POST( self ):
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
            

def httpd(handler_class=MyHandler, server_address = ('', 8008), ):
    srvr = BaseHTTPServer.HTTPServer(server_address, handler_class)
#    srvr.handle_request() # serve_forever
    srvr.serve_forever()
if __name__ == "__main__":
    httpd( )
