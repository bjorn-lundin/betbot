'''
Report module for Betfair analysis
'''
from __future__ import print_function, division, absolute_import


def report_collection(markets):
    '''
    Report parts from collection
    '''
    print('Number of markets:', len(markets))
    
    delete_markets = []
    for market in markets:
        if market.start < 0:
            delete_markets.append(market)
    print('Number of deleted markets:', len(delete_markets))

