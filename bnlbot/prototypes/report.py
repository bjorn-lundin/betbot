'''
Report module for Betfair analysis
'''
from __future__ import print_function, division, absolute_import


def report_collection(markets):
    '''
    Report parts from collection
    '''
    print('Number of markets:', len(markets))

    for market in markets:
        if len(market.tstamps) < 100:
            print('Market id:', market.marketid)
            print('  Number of TS:', len(market.tstamps))
            print('  Start TS index:', market.start)
        if market.start < 1:
            print('Market id:', market.marketid)
            print('  market.start < 1 !!!')

