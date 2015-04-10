'''
Entities for nonobet prototype analysis
'''

class Market(object):
    '''
    Class representing a market (race)
    '''
    def __init__(self, marketid):
        self.marketid = marketid
        self.starttime = None
        self.stoptime = None
        self.duration = None # seconds
        self.data_from_start = True
        self.execution_delay = 1 # seconds
        self.runners = []


class Runner(object):
    '''
    Entity representing a runner (horse)
    '''
    def __init__(self, selectionid):
        self.selectionid = selectionid
        self.timestamp = None
        self.win_backprice = 0.0
        self.win_layprice = 0.0
        self.totalmatched = 0.0
        self.name = None

