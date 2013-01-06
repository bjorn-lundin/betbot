# coding=iso-8859-15
""" The Funding Object """

import sys
from time import sleep, time
import datetime
import smtplib
import os


class Funding(object):
    """ The Funding Object """
    LAST_MAIL_FILE = './mail_file'
    SMTP_SERVER = 'smtp.gmail.com'
    SMTP_PORT = 587
    
    MAX_SALDO = 2000.0
    MIN_SALDO = 300.0
    TRANSFER_SUM = 1000.0
    MAX_EXPOSURE = 600.0

    def __init__(self, api, log):
        self.api = api
        self.funds = self.api.get_account_funds()
        self.funds_ok = None
        self.log = log
        self.timestamp_last_mail_sent = self.modification_date() 
        
        try:
            self.avail_balance = self.funds['availBalance']
            self.exposure     = abs(self.funds['exposure'])
        except :
            self.log.error( "check_and_fix_funds Unexpected error:" + str(sys.exc_info()[0]))
            return False


    def check_and_fix_funds(self):
        """do we have enough, or too much?"""
#        print 'funds', funds
          
        funds_ok = False
        if int(self.avail_balance) > self.MAX_SALDO :
            self.transfer_to_visa()
            try :
                self.alert_via_mail()
            except:
                self.log.info('exception when sending mail')
                
        elif int(self.avail_balance) < self.MIN_SALDO :  
            self.log.warning( 'ALARM, insufficient funds, only  ' + str(self.avail_balance) +' kr left!!')
        elif int(self.exposure) > self.MAX_EXPOSURE :  
            self.log.warning( 'ALARM, too much exposure ' + str(self.exposure) + ' > ' + str(self.MAX_EXPOSURE))
        else:  
            self.log.info( 'avail_balance ' + str(self.avail_balance) +  ' kr exposure ' + str(self.exposure) + ' kr')
            funds_ok = True
            
        self.funds_ok = funds_ok
############################# end check_and_fix_funds


    def transfer_to_visa(self):
        """send money to Visa card"""
        self.log.warning('ALARM, funds too big, transfer ' + str(self.TRANSFER_SUM) +
                          ' kr from saldo of ' + str(self.avail_balance) + ' kr')
        self.log.warning( 'transfer is not implementet yet')
        self.log.warning( 'REFUSING TO CONTINUE INSTEAD')
############################# end transfer_to_visa

    def modification_date(self):
        try :
            t = os.path.getmtime(self.LAST_MAIL_FILE)
            return datetime.datetime.fromtimestamp(t)
        except :
            try :
                file = open(self.LAST_MAIL_FILE, 'w+')
                file.close()
            except :
                return self.modification_date()    
            
############################# end modification_date
             
    def alert_via_mail(self) :

        if self.modification_date() + datetime.timedelta(hours = 1) < datetime.datetime.now() :
            self.log.info('Send mail to remind of overflow')

            sender = 'bnlbetbot@gmail.com'
            recipient = 'b.f.lundin@gmail.com'
            subject = 'BetBot Saldo Overflow'
            body = 'Dags att flytta betbot-pengar'
            password = 'Alice2010'
 
            "Sends an e-mail to the specified recipient."
 
            body = "" + body + ""
 
            headers = ["From: " + sender,
                       "Subject: " + subject,
                       "To: " + recipient,
                       "MIME-Version: 1.0",
                       "Content-Type: text/html"]
            headers = "\r\n".join(headers)
 
            session = smtplib.SMTP(self.SMTP_SERVER, self.SMTP_PORT)
 
            session.ehlo()
            session.starttls()
            session.ehlo
            session.login(sender, password)
 
            session.sendmail(sender, recipient, headers + "\r\n\r\n" + body)
            session.quit()
            try :
                file = open(self.LAST_MAIL_FILE, 'w+')
                try :
                    file.write(str(datetime.datetime.now()) + ' ' + str(self.avail_balance))
                finally :
                    file.close()
            except :
                pass   
        else :    
            self.log.info('Less than 1 hour since last Send mail to remind of overflow')
############################# end alert_via_mail

