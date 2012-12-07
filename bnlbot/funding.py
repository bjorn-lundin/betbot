# coding=iso-8859-15
""" The Funding Object """

import sys
from time import sleep, time


class Funding(object):
    """ The Funding Object """
    MAX_SALDO = 3100.0
    MIN_SALDO = 300.0
    TRANSFER_SUM = 1000.0
    MAX_EXPOSURE = 600.0

    def __init__(self, api, log):
        self.api = api
        self.funds = self.api.get_account_funds()
        self.funds_ok = None
        self.log = log

    def check_and_fix_funds(self):
        """do we have enough, or too much?"""
#        print 'funds', funds
        try:
            avail_balance = self.funds['availBalance']
            exposure     = abs(self.funds['exposure'])
        except :
            self.log.error( "check_and_fix_funds Unexpected error:" + sys.exc_info()[0])
            return False
          
        funds_ok = False
        if int(avail_balance) > self.MAX_SALDO :
            self.transfer_to_visa()
        elif int(avail_balance) < self.MIN_SALDO :  
            self.log.warning( 'ALARM, insufficient funds, only  ' + str(avail_balance) +' kr left!!')
        elif int(exposure) > self.MAX_EXPOSURE :  
            self.log.warning( 'ALARM, too much exposure ' + str(exposure) + ' > ' + str(self.MAX_EXPOSURE))
        else:  
            self.log.info( 'avail_balance ' + str(avail_balance) +  ' kr exposure ' + str(exposure) + ' kr')
            funds_ok = True
            
        self.funds_ok = funds_ok
############################# end check_and_fix_funds
    def transfer_to_visa(self):
        """send money to Visa card"""
        self.log.warning('ALARM, funds too big, transfer ' + str(self.TRANSFER_SUM) +
                          ' kr from saldo of ' + str(avail_balance) + ' kr')
        self.log.warning( 'transfer is not implementet yet')
        self.log.warning( 'REFUSING TO CONTINUE INSTEAD')
############################# end transfer_to_visa
