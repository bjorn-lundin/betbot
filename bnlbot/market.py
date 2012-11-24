# coding=iso-8859-15
"""The Market object"""
import datetime 

class Market(object):
    """The Market object"""
    home_team_name = None
    away_team_name = None
    home_team_id = None
    away_team_id = None
    
    def __init__(self, market_id, conn):
        self.conn = conn    
        cur = self.conn.cursor()
        cur.execute("select * from MARKETS \
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
#            print 'Market.init', row 

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
            self.home_team = row[16]
            self.away_team = row[17]
            self.ts = row[18]
            self.xml_soccer_id = row[19]   
                
            try:
                self.home_team_name = self.home_team
                self.away_team_name = self.away_team 
                cur2 = self.conn.cursor()
                cur2.execute("select TEAM_ID from TEAM_ALIASES \
                              where TEAM_ALIAS = %s", (self.home_team_name,))
                row = cur2.fetchone()
                if cur2.rowcount == 1 :
                    self.home_team_id = row[0]
                cur2.close()
                cur3 = self.conn.cursor()
                cur3.execute("select TEAM_ID from TEAM_ALIASES \
                              where TEAM_ALIAS = %s", (self.away_team_name,))
                row = cur3.fetchone()
                if cur3.rowcount == 1 :
                    self.away_team_id = row[0] 
                cur3.close()
            except :
                print 'Market.init, no hit - market_id', market_id 
                return None
        
        
    def try_set_gamestart(self) :
        try :
            if not self.ts and int(self.bet_delay) > 0 :
                cur = self.conn.cursor()
                cur.execute("update MARKETS set TS = %s where TS is null and MARKET_ID = %s ", (datetime.datetime.now(), self.market_id))
                cur.close()
        except AttributeError :
            return    
        
    def print_me(self):
        """ Simple printout """
        if self.home_team_name :
            print 'home_team_name', self.home_team_name
        else:
            print 'home_team_name not found'
        if self.away_team_name :
            print 'away_team_name', self.away_team_name
        else:
            print 'away_team_name not found'
        if self.home_team_id :
            print 'home_team_id', self.home_team_id
        else:
            print 'home_team_id not found'
        if self.away_team_id :
            print 'away_team_id', self.away_team_id
        else:
            print 'away_team_id not found'
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

            
###############################  end Market
