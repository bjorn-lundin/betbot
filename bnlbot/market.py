# coding=iso-8859-15
"""The Market object"""
import datetime 
import psycopg2

class Market(object):
    """The Market object"""
    home_team_name = None
    away_team_name = None
    home_team_id = None
    away_team_id = None
    market_id = None       
    bsp_market = None
    market_type = None
    event_hierarchy = None
    last_refresh = None
    turning_in_play = None
    menu_path = None
    bet_delay = None
    exchange_id = None
    country_code = None
    market_name = None
    market_status = None
    event_date = None
    no_of_runners = 0
    total_matched = None
    no_of_winners = 0
    home_team = None
    away_team = None
    ts = None
    xml_soccer_id = None   


    
    def __init__(self, conn, log, market_id = None, market_dict = None, simulate = False):
        self.conn = conn
        self.log = log
        
        self.conn = conn    
        if market_id != None  :
            cur = self.conn.cursor()
            if not simulate :
                cur.execute("select * from MARKETS \
                         where MARKET_ID = %s",(market_id,))
            else :
                cur.execute("select * from DRY_MARKETS \
                         where MARKET_ID = %s",(market_id,))
                         
            row = cur.fetchone()
            cur.close()
            if row != None : 
                #  0  market_id       | integer                     | not null
                #  1  bsp_market      | character varying           | 
                #  2  market_type     | character varying           | 
                #  3  event_hierarchy | character varying           | 
                #  4  last_refresh    | timestamp without time zone | 
                #  5  turning_in_play | character varying           | 
                #  6  menu_path       | character varying           | 
                #  7  bet_delay       | integer                     | 
                #  8  exchange_id     | integer                     | 
                #  9  country_code    | character varying           | 
                # 10  market_name     | character varying           | 
                # 11  market_status   | character varying           | 
                # 12  event_date      | timestamp without time zone | 
                # 13  no_of_runners   | integer                     | 
                # 14  total_matched   | integer                     | 
                # 15  no_of_winners   | integer                     | 
                # 16  home_team       | character varying           | 
                # 17  away_team       | character varying           | 
                # 18  ts              | timestamp without time zone | 
                # 19  xml_soccer_id   | integer                     | 
    
                self.market_id = row[0]       
                self.bsp_market = row[1]
                self.market_type = row[2]
                self.event_hierarchy = row[3]
                self.last_refresh = row[4]
                self.turning_in_play = row[5]
                self.menu_path = row[6]
                self.bet_delay = row[7]
                self.exchange_id = row[8]
                self.country_code = row[9]
                self.market_name = row[10]
                self.market_status = row[11]
                self.event_date = row[12]
                self.no_of_runners = row[13]
                self.total_matched = row[14]
                self.no_of_winners = row[15]
                self.home_team = None
                self.away_team = None
                self.ts = None
                self.xml_soccer_id = None   
        elif market_dict != None :
            self.market_id        = market_dict['market_id']       
            self.bsp_market       = market_dict['bsp_market']
            self.market_type      = market_dict['market_type']
            self.event_hierarchy  = market_dict['event_hierarchy']
            self.last_refresh     = market_dict['last_refresh']
            self.turning_in_play  = market_dict['turning_in_play']
            self.menu_path        = market_dict['menu_path']
            self.bet_delay        = market_dict['bet_delay']
            self.exchange_id      = market_dict['exchange_id']
            self.country_code     = market_dict['country_code']
            self.market_name      = market_dict['market_name']
            self.market_status    = market_dict['market_status']
            self.event_date       = market_dict['event_date']
            self.no_of_runners    = market_dict['no_of_runners']
            self.total_matched    = market_dict['total_matched']
            self.no_of_winners    = market_dict['no_of_winners']
            self.home_team        = None
            self.away_team        = None
            self.ts               = None
            self.xml_soccer_id    = None   
            
            # try read the missing values from db.
            
            
    ###############################################################################        
        
    def try_set_gamestart(self) :
        try :
            # try set game start time, if not set
            if int(self.bet_delay) > 0 :
                cur = self.conn.cursor()
                cur.execute("update MARKETS set TS = %s where TS is null and MARKET_ID = %s ", (datetime.datetime.now(), self.market_id))
                cur.close()
        except AttributeError :
            return    
    ###############################################################################        
        
    def print_me(self):
        """ Simple printout """
        self.log.info('nothing to print ...')
    ############################# end print me
            
 
 
    def market_in_xmlfeed(self) :
        found = False
        cur = self.conn.cursor()
        cur.execute("select * from MARKET_IN_XML_FEED \
                     where MARKET_ID = %s" , (self.market_id,))
        row = cur.fetchone()
        if cur.rowcount == 1 :
            found = True
        cur.close()
        return found
    ############################# end market_in_xmlfeed

    def insert(self):
        last_refresh = str(datetime.datetime.fromtimestamp(int(self.last_refresh)/1000))
        
        
        cur7 = self.conn.cursor()
        cur7.execute("SAVEPOINT MARKET_B")
        cur7.close()
        try  :
            cur = self.conn.cursor()
            cur.execute("insert into MARKETS ( \
                       MARKET_ID, BSP_MARKET, \
                       MARKET_TYPE, EVENT_HIERARCHY, \
                       LAST_REFRESH, TURNING_IN_PLAY, \
                       MENU_PATH, BET_DELAY, \
                       EXCHANGE_ID, COUNTRY_CODE, \
                       MARKET_NAME, MARKET_STATUS, \
                       EVENT_DATE, NO_OF_RUNNERS, \
                       TOTAL_MATCHED, NO_OF_WINNERS, \
                       HOME_TEAM, AWAY_TEAM, \
                       TS, XML_SOCCER_ID) \
                       values \
                      (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s, \
                      %s,%s,%s,%s,%s,%s,%s,%s,%s)",
                      (self.market_id,     self.bsp_market,      \
                       self.market_type,   self.event_hierarchy, \
                       last_refresh ,      self.turning_in_play, \
                       self.menu_path,     self.bet_delay, \
                       self.exchange_id,   self.country_code,    \
                       self.market_name,   self.market_status, \
                       self.event_date,    self.no_of_runners,   \
                       self.total_matched, self.no_of_winners,
                       None, None, None, None))
            cur.close()
            
        except psycopg2.IntegrityError:
            cur.close()
            cur6 = self.conn.cursor()
            cur6.execute("ROLLBACK TO SAVEPOINT MARKET_B" )
            cur6.close()

                    
    ##############################################################           
    def bet_exists_already(self, bet_type = None) :
        """do we have a bet on this market already?"""

        cur = self.conn.cursor()
        if bet_type is None :
            cur.execute("select * from BETS \
                     where MARKET_ID = %s",(self.market_id,))
        else :
            cur.execute("select * from BETS \
                     where MARKET_ID = %s and BET_TYPE = %s",
                       (self.market_id, bet_type))
        
        row = cur.fetchone()
        row_count = cur.rowcount
        cur.close()
#        self.log.info('Market.init, # hits ' + str(row_count) + '  market_id ' + str(self.market_id) )
        return row_count >= 1 
    #######################################################
            
###############################  end Market
