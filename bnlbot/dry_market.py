# coding=iso-8859-15
"""The Market object"""
import datetime 
import psycopg2
from market import Market

class DryMarket(Market):
    """The DryMarket object"""
    
    def __init__(self, conn, log, market_id = None, market_dict = None):
        super(Market, self).__init__()


    def insert(self):

        last_refresh = str(datetime.datetime.fromtimestamp(int(self.last_refresh)/1000))
        
        cur7 = self.conn.cursor()
        cur7.execute("SAVEPOINT DRY_MARKET_B")
        cur7.close()
        try  :
            cur = self.conn.cursor()
            cur.execute("insert into DRY_MARKETS ( \
                       MARKET_ID, BSP_MARKET, \
                       MARKET_TYPE, EVENT_HIERARCHY, \
                       LAST_REFRESH, TURNING_IN_PLAY, \
                       MENU_PATH, BET_DELAY, \
                       EXCHANGE_ID, COUNTRY_CODE, \
                       MARKET_NAME, MARKET_STATUS, \
                       EVENT_DATE, NO_OF_RUNNERS, \
                       TOTAL_MATCHED, NO_OF_WINNERS) \
                       values \
                      (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s, \
                      %s,%s,%s,%s,%s)",
                      (self.market_id,     self.bsp_market,      \
                       self.market_type,   self.event_hierarchy, \
                       last_refresh ,      self.turning_in_play, \
                       self.menu_path,     self.bet_delay, \
                       self.exchange_id,   self.country_code,    \
                       self.market_name,   self.market_status, \
                       self.event_date,    self.no_of_runners,   \
                       self.total_matched, self.no_of_winners))
            cur.close()
            
        except psycopg2.IntegrityError:
            cur.close()
            cur6 = self.conn.cursor()
            cur6.execute("ROLLBACK TO SAVEPOINT DRY_MARKET_B" )
            cur6.close()

            
###############################  end DryMarket
