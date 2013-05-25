# coding=iso-8859-15
"""The Market object"""
import datetime
import psycopg2

class DryRunner(object):
    """The DryRunner object"""


    def __init__(self, conn, log, runner_dict = None):
        self.conn = conn
        self.log = log

        self.marketid     = runner_dict['market_id']
        self.selectionid  = runner_dict['sel_id']
        self.backprice    = runner_dict['bp']
        self.layprice     = runner_dict['lp']
        self.index         = runner_dict['idx']
        self.name          = runner_dict['name']


    ###############################################################################



    def insert(self):
        cur7 = self.conn.cursor()
        cur7.execute("SAVEPOINT MARKET_B")
        cur7.close()
        try  :
            cur = self.conn.cursor()
            cur.execute("insert into DRY_RUNNERS ( \
                       MARKETID, SELECTIONID, \
                       INDEX, BACKPRICE, \
                       LAYPRICE, RUNNERNAME) \
                       values \
                      (%s,%s,%s,%s,%s,%s)",
                      (self.marketid,  self.selectionid,      \
                       self.index, self.backprice,  \
                       self.layprice,  self.name))
            cur.close()

        except psycopg2.IntegrityError:
            cur.close()
            cur6 = self.conn.cursor()
            cur6.execute("ROLLBACK TO SAVEPOINT MARKET_B" )
            cur6.close()



    ##############################################################


###############################  end Runner
