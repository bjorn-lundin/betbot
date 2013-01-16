# coding=iso-8859-15
""" The Bet Object """

import psycopg2
import sys
from time import sleep, time

# IS NEEDED???

class Bet(object):
    """ The Funding Object """
    MAX_SALDO = 3100.0
    MIN_SALDO = 300.0
    TRANSFER_SUM = 1000.0
    MAX_EXPOSURE = 600.0

    def __init__(self, api, log, conn):
        self.api = api
        self.conn = conn
        self.log = log
    ############################# end __init__
        



    def insert_bet(self, bet, resp, bet_type, name):
        self.log.info( 'insert bet' )
        cur = self.conn.cursor()
        
        if self.DRY_RUN :
            # get a new bet id, we are in dry_run mode
            cur.execute("select * from BETS where MARKET_ID = %s and SELECTION_ID = %s", 
                 (bet['marketId'],bet['selectionId']))
        else:
            cur.execute("select * from BETS where BET_ID = %s", (resp['bet_id'],))
            
        if cur.rowcount == 0 :
            if self.DRY_RUN :
               cur2 = self.conn.cursor()
               cur2.execute("select nextval('bet_id_serial')")
               row = cur2.fetchone()
               cur2.close()
               resp['bet_id'] = row[0]
                            
            self.log.debug( 'insert bet ' + str(resp['bet_id']))
                       
            cur.execute("insert into BETS ( \
                         BET_ID, MARKET_ID, SELECTION_ID, PRICE, \
                         CODE, SUCCESS, SIZE, BET_TYPE, RUNNER_NAME, BET_WON ) \
                         values \
                         (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)", \
               (resp['bet_id'], bet['marketId'], bet['selectionId'], \
                resp['price'], resp['code'], resp['success'], \
                resp['size'], bet_type, name, None))
        cur.close()
############################# end insert_bet
