'''
Entities for nonobet prototype analysis
'''

class Market(object):
    '''
    Class representing a market (race)
    '''
    def __init__(self, marketid):
        self.marketid = marketid
        self.tstamps = []
        self.start = -1 # Index in tstamp
        self.data_from_start = True
        self.execution_delay = 1 # seconds
        self.runners = []
        self.win_winner_id = None # selectionid


class Runner(object):
    '''
    Entity representing a runner (horse)
    '''
    def __init__(self, selectionid):
        self.name = None
        self.selectionid = selectionid
        self.backprices = []
        self.layprices = []
        self.totalmatched = []

