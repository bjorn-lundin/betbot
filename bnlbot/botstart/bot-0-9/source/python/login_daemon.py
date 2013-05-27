# -*- coding: iso-8859-1 -*-

"""Login to betfair using api6, and return a Token"""
from betfair.api import API
import socket
        
def main():        
    self.api = API('uk') # exchange ('uk' or 'aus')
#    self.no_session = True
    HOST = ''                 # Symbolic name meaning the local host
    PORT = 27123              # Arbitrary non-privileged port
    
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind((HOST, PORT))
    s.listen(1)
    while 1:
        conn, addr = s.accept()
        print 'Connected by', addr
        data = conn.recv(1024)
        if not data: continue
        #got 'user=the_user,pwd=the_pwd,productid=pid,vendorid=0'
        input=data.split(',')
        username  =input[0],split('=')[1]
        password  =input[1],split('=')[1]
        productid =input[2],split('=')[1]
        vendorid  =input[3],split('=')[1]
        print 'input', input
         
        login_status = self.login_ng(username, password, productid, vendorid)
        if login_status == 'OK':
            conn.send(self.api.session_token)
            print 'self.api.session_token', self.api.session_token
        else :
            conn.send(login_status)            
            print 'login_status', login_status
        conn.close()        
    
    
if __name__ == "__main__":
    main()
