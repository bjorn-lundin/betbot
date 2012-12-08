# coding=iso-8859-15
""" The Bet Object """

import psycopg2
import sys
from time import sleep, time


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
        

    def exists_on_market(self, market_id):
        """do we have a bet on this market already?"""

        cur = self.conn.cursor()
        cur.execute("select * from BETS \
                     where MARKET_ID = %s",(market_id,))
        row = cur.fetchone()
        row_count = cur.rowcount
        cur.close()
        return row_count >= 1        

    ############################# end exists_on_market
