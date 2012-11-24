# coding=iso-8859-15
""" The Funding Object """

import sys


class Funding(object):
    """ The Funding Object """
    MAX_SALDO = 3100.0
    MIN_SALDO = 300.0
    TRANSFER_SUM = 1000.0
    MAX_EXPOSURE = 400.0

    def __init__(self, api):
        self.api = api
        self.funds = self.api.get_account_funds()
        self.funds_ok = None

    def check_and_fix_funds(self):
        """do we have enough, or too much?"""
#        print 'funds', funds
        try:
            avail_balance = self.funds['availBalance']
            exposure     = abs(self.funds['exposure'])
        except :
            print "check_and_fix_funds Unexpected error:", sys.exc_info()[0]
            return False
          
        funds_ok = False
        if int(avail_balance) > self.MAX_SALDO :
            self.transfer_to_visa()
        elif int(avail_balance) < self.MIN_SALDO :  
            print 'ALARM, insufficient funds', avail_balance, 'left!!'
        elif int(exposure) > self.MAX_EXPOSURE :  
            print 'ALARM, too much exposure', exposure, '>',  self.MAX_EXPOSURE
        else:  
            print 'avail_balance', avail_balance, 'exposure', exposure
            funds_ok = True
            
        self.funds_ok = funds_ok
############################# end check_and_fix_funds
    def transfer_to_visa(self):
        """send money to Visa card"""
        print 'ALARM, funds too big, transfer', self.TRANSFER_SUM, \
                 'from', avail_balance
        print 'transfer is not implementet yet'
        print 'REFUSING TO CONTINUE INSTEAD'
############################# end transfer_to_visa
