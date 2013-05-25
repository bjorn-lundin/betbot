# coding=iso-8859-15
"""The Market object"""
import datetime
import psycopg2
from market import Market

class DryMarket(Market):
    """The DryMarket object"""

    def __init__(self, conn, log, market_dict):
        Market.__init__(self, conn, log, market_dict = market_dict )


    def insert(self):

        last_refresh = str(datetime.datetime.fromtimestamp(int(self.last_refresh)/1000))

        cur7 = self.conn.cursor()
        cur7.execute("SAVEPOINT DRY_MARKET_B")
        cur7.close()
        try  :
            cur = self.conn.cursor()
            cur.execute("insert into DRYMARKETS ( \
                       MARKETID, BSPMARKET, \
                       MARKETTYPE, EVENTHIERARCHY, \
                       LASTREFRESH, TURNINGINPLAY, \
                       MENUPATH, BETDELAY, \
                       EXCHANGEID, COUNTRYCODE, \
                       MARKETNAME, MARKETSTATUS, \
                       EVENTDATE, NOOFRUNNERS, \
                       TOTALMATCHED, NOOFWINNERS) \
                       values \
                      (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s, \
                      %s,%s,%s,%s,%s)",
                      (self.marketid,     self.bspmarket,      \
                       self.markettype,   self.eventhierarchy, \
                       last_refresh ,      self.turninginplay, \
                       self.menupath,     self.betdelay, \
                       self.exchangeid,   self.countrycode,    \
                       self.marketname,   self.marketstatus, \
                       self.eventdate,    self.noofrunners,   \
                       self.totalmatched, self.noofwinners))
            cur.close()

        except psycopg2.IntegrityError:
            cur.close()
            cur6 = self.conn.cursor()
            cur6.execute("ROLLBACK TO SAVEPOINT DRY_MARKET_B" )
            cur6.close()


###############################  end DryMarket
