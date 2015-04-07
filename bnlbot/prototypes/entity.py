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
        self.runners = []


class Runner(object):
    '''
    Entity representing a runner (horse)
    '''
    def __init__(self, selectionid):
        self.selectionid = selectionid
        self.timestamp = None
        self.backprice = 0.0
        self.layprice = 0.0
        self.totalmatched = 0.0
        self.name = None

