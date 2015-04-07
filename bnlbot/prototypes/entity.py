'''
Entities for nonobet prototype analysis
'''

class Market(object):
    '''
    Class representing a market (race)
    '''
    _marketid = None
    _starttime = None
    _runners = []

    def __init__(self, marketid):
        self._marketid = marketid

    # Getters
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

    @property
    def runners(self):
        '''
        Get runners
        '''
        return self._runners

    # Setters
    @starttime.setter
    def starttime(self, value):
        '''
        Set starttime
        '''
        self._starttime = value

    @runners.setter
    def runners(self, value):
        '''
        Set runners
        '''
        self._runners = value

    # Enable object be key in dict
    def __hash__(self):
        return hash((self.marketid,))

    def __eq__(self, other):
        return (self.marketid,) == (other.marketid,)


class Runner(object):
    '''
    Entity representing a runner (horse)
    '''
    _selectionid = None
    _timestamp = None
    _backprice = 0.0
    _layprice = 0.0
    _totalmatched = 0.0
    _name = None

    def __init__(self, selectionid):
        self._selectionid = selectionid

    # Getters
    @property
    def selectionid(self):
        '''
        Get selectionid
        '''
        return self._selectionid

    @property
    def timestamp(self):
        '''
        Get timestamp
        '''
        return self._timestamp

    @property
    def backprice(self):
        '''
        Get backprice
        '''
        return self._backprice

    @property
    def layprice(self):
        '''
        Get layprice
        '''
        return self._layprice

    @property
    def totalmatched(self):
        '''
        Get totalmatched
        '''
        return self._totalmatched

    @property
    def name(self):
        '''
        Get name
        '''
        return self._name

    # Setters
    @selectionid.setter
    def selectionid(self, value):
        '''
        Set selectionid
        '''
        self._selectionid = value

    @timestamp.setter
    def timestamp(self, value):
        '''
        Set timestamp
        '''
        self._timestamp = value

    @backprice.setter
    def backprice(self, value):
        '''
        Set backprice
        '''
        self._backprice = value

    @layprice.setter
    def layprice(self, value):
        '''
        Set layprice
        '''
        self._layprice = value

    @totalmatched.setter
    def totalmatched(self, value):
        '''
        Set totalmatched
        '''
        self._totalmatched = value

    @name.setter
    def name(self, value):
        '''
        Set name
        '''
        self._name = value

