# coding=iso-8859-15
""" The Mailer_Proxy Object """

import socket
import datetime
import smtplib
try:
  from boto import ses
except ImportError, e:
    pass
    
import httplib


class Mailer_ses(object):
    """ The Funding Object """
    avail_balance = None
    exposure = None
    account = None
    
    def __init__ (self,avail,expo,account):
        self.avail_balance = avail
        self.exposure = expo
        self.account = account

    def mail_saldo(self) :
        subject = 'BetBot Saldo Report'
        body = 'Dagens saldo-rapport '
        body += '\r\n konto:     ' + self.account
        body += '\r\n saldo:     ' + str( self.avail_balance )
        body += '\r\n exposure:  ' + str( self.exposure )
        body += '\r\n timestamp: ' + str( datetime.datetime.now() )
        body += '\r\n sent from : ' + socket.gethostname()
        # for amazon, get the instance id        
        conn = httplib.HTTPConnection("169.254.169.254")
        conn.request("GET", "/latest/meta-data/instance-id")
        r1 = conn.getresponse()
        data2 = "bad responce"
        if r1.status == 200 :
            data2 = r1.read()
            
        body += '\r\n instance : ' + data2
        self.do_mail(subject, body)

    def do_mail(self, subject, body) : 
        sendlist = ['b.f.lundin@gmail.com', 'joakim@birgerson.com']
        from_address = '"Nonobet Betbot" <betbot@nonobet.com>'
        connection = ses.connect_to_region(
            'us-east-1',
            aws_access_key_id='AKIAJZDDS2DVUNB76S6A',
            aws_secret_access_key='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'
        )
        connection.send_email(
            from_address,
            subject,
            body,
            sendlist
        )

class Mailer_gmail(object) :
    avail_balance = None
    exposure = None
    account = None    
    SMTP_SERVER = 'smtp.gmail.com'
    SMTP_PORT = 587
    SENDER = 'bnlbetbot@gmail.com'
    RECIPIENT = 'b.f.lundin@gmail.com'
    PASSWORD = 'Alice2010'

    def __init__ (self,avail,expo,account):
        self.avail_balance = avail
        self.exposure = expo
        self.account = account

    def mail_saldo(self) :
        subject = 'BetBot Saldo Report'
        body = 'Dagens saldo-rapport '
        body += '\r\n konto:     ' + self.account
        body += '\r\n saldo:     ' + str( self.avail_balance )
        body += '\r\n exposure:  ' + str( self.exposure )
        body += '\r\n timestamp: ' + str( datetime.datetime.now() )
        body += '\r\n sent from : ' + socket.gethostname()
        self.do_mail(subject, body)


    def do_mail(self, subject, body) : 

        headers = ["From: " + self.SENDER,
                   "Subject: " + subject,
                   "To: " + self.RECIPIENT,
                   "MIME-Version: 1.0",
                   "Content-Type: text/plain"]
        headers = "\r\n".join(headers)

        session = smtplib.SMTP(self.SMTP_SERVER, self.SMTP_PORT)

        session.ehlo()
        session.starttls()
        session.ehlo
        session.login(self.SENDER, self.PASSWORD)

        session.sendmail(self.SENDER, self.RECIPIENT, headers + "\r\n\r\n" + body)
        session.quit()



def main():
    HOST = ''                 # Symbolic name meaning the local host
    PORT = 27124              # Arbitrary non-privileged port

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((HOST, PORT))
    s.listen(1)
    while 1:
        conn, addr = s.accept()
#        print 'Connected by', addr
        data = conn.recv(1024)
        if not data: continue
        #got 'avail=available,expo=exposure,account=bnlbnl'
        input=data.split(',')
        avail = input[0].split('=')[1]
        expo  = input[1].split('=')[1]
        account = input[2].split('=')[1]
        
        host = socket.gethostname()
        
#        print 'input', input
        # amazon hosts starts with 'ip' 
        if host[:2] == 'ip' :
            m = Mailer_ses(avail,expo,account)
        else :  
            m = Mailer_gmail(avail,expo,account)
            
        m.mail_saldo()        
        conn.send("saldo is mailed")
        conn.close()


if __name__ == "__main__":
    main()

############################# end mail_saldo

