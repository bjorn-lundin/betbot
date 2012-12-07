# coding=iso-8859-15
"""The Market object"""
import datetime 
import psycopg2

class Market(object):
    """The Market object"""
    home_team_name = ""
    away_team_name = ""
    home_team_id = None
    away_team_id = None
    
    def __init__(self, conn, log, market_id = None, market_dict = None):
        self.conn = conn
        self.log = log
        
        self.conn = conn    
        if market_id != None :
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
            self.home_team        = ""
            self.away_team        = ""
            self.ts               = None
            self.xml_soccer_id    = None   
            
            # try read the missing values from db.
            cur = self.conn.cursor()
            cur.execute("select * from MARKETS \
                         where MARKET_ID = %s",(self.market_id,))
            row = cur.fetchone()
            cur.close()
            if row != None : 
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
            self.log.info('Market.init, no hit - market_id ' + str(market_id) )
            return None
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
        if self.home_team_name :
            self.log.info( 'home_team_name ' + self.home_team_name)
        else:
            self.log.info( 'home_team_name not found')
        if self.away_team_name :
            self.log.info( 'away_team_name ' + self.away_team_name)
        else:
            self.log.info( 'away_team_name not found')
        if self.home_team_id :
            self.log.info( 'home_team_id ' +  str(self.home_team_id))
        else:
            self.log.info( 'home_team_id not found')
        if self.away_team_id :
            self.log.info( 'away_team_id ' +  str(self.away_team_id))
        else:
            self.log.info('away_team_id not found')
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
        # extract teams from path, if possible
        #\Fotboll\england\premier leauge\10 november\stoke - arsenal
        #\Fotboll\england\premier leauge\10 november\stoke vs arsenal
        #\Fotboll\england\premier leauge\10 november\stoke versus arsenal
        # make path to list, split on '\', and use last item
        
        path_as_list = self.menu_path.split('\\')
        teams = path_as_list[len(path_as_list) -1].lower()
        
        teams = teams.replace(' - ','|')
        teams = teams.replace(' v ','|')
        teams = teams.replace(' vs ','|')
        teams = teams.replace(' versus ','|')
        list_teams = teams.split('|')
        try: 
            home_team = list_teams[0]
        except :
            home_team = None
        try: 
            away_team = list_teams[1]
        except :
            away_team = None        

        game_id = None
        
        cur8 = self.conn.cursor()
        cur8.execute("select GAMES.XML_SOCCER_ID from \
                MARKETS, \
                GAMES, \
                TEAM_ALIASES HOME_ALIASES, \
                TEAM_ALIASES AWAY_ALIASES \
                where MARKETS.HOME_TEAM = HOME_ALIASES.TEAM_ALIAS \
                and   MARKETS.AWAY_TEAM = AWAY_ALIASES.TEAM_ALIAS \
                and   GAMES.HOME_TEAM_ID = HOME_ALIASES.TEAM_ID \
                and   GAMES.AWAY_TEAM_ID = AWAY_ALIASES.TEAM_ID \
                and   MARKETS.MARKET_ID = %s", (self.market_id,))
        row = cur8.fetchone()
        if cur8.rowcount >= 1 :
            game_id = row[0]
        cur8.close()

        
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
                       home_team, away_team, None, game_id))
            cur.close()
            
        except psycopg2.IntegrityError:
            cur.close()
            cur6 = self.conn.cursor()
            cur6.execute("ROLLBACK TO SAVEPOINT MARKET_B" )
            cur6.close()
            if game_id :
                cur7 = self.conn.cursor()
                cur7.execute("update MARKETS set XML_SOCCER_ID = %s \
                              where MARKET_ID = %s \
                              and XML_SOCCER_ID is null", 
                              (game_id, self.market_id))
                cur7.close()
        
        
        for team in list_teams :
            cur2 = self.conn.cursor()
            cur2.execute("select * from TEAM_ALIASES \
                          where TEAM_ALIAS = %s", (team,))
            rc = cur2.rowcount
            cur2.close()
            if rc == 0 :
                self.log.warning( 'Team not found in TEAM_ALIASES: ' + team)
                cur3 = self.conn.cursor()
                cur3.execute("SAVEPOINT MARKET_A")
                cur3.close()
                try  :
                    cur4 = self.conn.cursor()
                    cur4.execute("insert into UNIDENTIFIED_TEAMS \
                                 (TEAM_NAME,COUNTRY_CODE) values (%s,%s)",
                                 (team, self.country_code))
                    cur4.close()
                except psycopg2.IntegrityError:
                    cur5 = self.conn.cursor()
                    cur5.execute("ROLLBACK TO SAVEPOINT MARKET_A" )
                    cur5.close()
                    
    ##############################################################                                        
            
###############################  end Market
