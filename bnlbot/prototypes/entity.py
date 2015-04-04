'''
Entities for nonobet prototype analysis
'''

class Market(object):
    '''
    Class representing a market (race)
    '''
    _marketid = None
    _starttime = None

    def __init__(self, marketid):
        self._marketid = marketid

    @property
    def marketid(self):
        '''
        Get marketid
        '''
        return self._marketid

    @property
    def starttime(self):
        '''
        Get starttime
        '''
        return self._starttime

    @starttime.setter
    def starttime(self, value):
        '''
        Set starttime
        '''
        self._starttime = value

    def __hash__(self):
        return hash((self.marketid,))

    def __eq__(self, other):
        return (self.marketid,) == (other.marketid,)


class Runner(object):
    '''
    Entity representing a runner (horse)
    '''
    _selectionid = None

    def __init__(self, selectionid):
        self._selectionid = selectionid

    @property
    def selectionid(self):
        '''
        Get selectionid
        '''
        return self._selectionid

