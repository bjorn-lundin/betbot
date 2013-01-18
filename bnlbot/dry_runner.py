# coding=iso-8859-15
"""The Market object"""
import datetime 
import psycopg2

class DryRunner(object):
    """The DryRunner object"""

    
    def __init__(self, conn, log, runner_dict = None):
        self.conn = conn
        self.log = log

        self.market_id    = runner_dict['market_id']       
        self.selection_id = runner_dict['sel_id']
        self.back_price   = runner['bp']        
        self.lay_price    = runner['lp']        
        self.index        = runner['idx']        


    ###############################################################################        



    def insert(self):
        cur7 = self.conn.cursor()
        cur7.execute("SAVEPOINT MARKET_B")
        cur7.close()
        try  :
            cur = self.conn.cursor()
            cur.execute("insert into DRY_RUNNERS ( \
                       MARKET_ID, SELECTION_ID, \
                       INDEX, BACK_PRICE, \
                       LAY_PRICE, RUNNER_NAME) \
                       values \
                      (%s,%s,%s,%s,%s,%s)",
                      (self.market_id,  self.selection_id,      \
                       self.back_price, self.lay_price, \
                       self.index,      None))
            cur.close()
            
        except psycopg2.IntegrityError:
            cur.close()
            cur6 = self.conn.cursor()
            cur6.execute("ROLLBACK TO SAVEPOINT MARKET_B" )
            cur6.close()


                    
    ##############################################################           

            
###############################  end Runner
