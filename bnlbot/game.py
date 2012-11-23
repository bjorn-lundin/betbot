# coding=iso-8859-15
""" The game Object """
#import datetime 
#import psycopg2

class Game(object):
    """ The game Object """
    
    def __init__(self, conn, home_team_id, away_team_id):
        self.xml_soccer_id = None
        self.kickoff = None
        self.home_team_id = None
        self.away_team_id = None
        self.time_in_game = None
        self.home_goals = None
        self.away_goals = None
        self.found = False
        self.time_in_game_numeric = False

        if not home_team_id : 
            return
        if not away_team_id : 
            return
        
        cur = conn.cursor()
        cur.execute("select * from GAMES where HOME_TEAM_ID = %s \
                     and AWAY_TEAM_ID = %s ", \
                    (home_team_id, away_team_id))
        row = cur.fetchone()
        rc = cur.rowcount
        if rc == 1 :
            self.xml_soccer_id = row[0] 
            self.kickoff = row[1] 
            self.home_team_id = row[2] 
            self.away_team_id = row[3] 
            self.time_in_game = row[4] 
            self.home_goals = row[5] 
            self.away_goals = row[6] 
            self.found = True
        cur.close()
        try : 
            i = int(self.time_in_game)
            self.time_in_game_numeric = True
            self.time_in_game_numeric = i
        except:
            self.time_in_game_numeric = False
        
###############################  end Game  
