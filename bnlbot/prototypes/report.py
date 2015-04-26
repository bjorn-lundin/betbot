'''
Report module for Betfair analysis
'''
from __future__ import print_function, division, absolute_import


def report_collection(markets):
    '''
    Report parts from collection
    '''
    nbr_markets = len(markets)
    nbr_from_start = 0
    not_from_start_markets = []
    not_sufficient_ts = []

    for market in markets:
        if market.data_from_start:
            nbr_from_start += 1
        else:
            not_from_start_markets.append(market.marketid)
            if len(market.tstamps) < 100:
                not_sufficient_ts.append(market.marketid)

    print('Markets:', nbr_markets)
    print('TS from start:', nbr_from_start)
    print('TS not from start:', len(not_from_start_markets))
    print('Not sufficient TS:', len(not_sufficient_ts))

    print('Markets not having TS from start:')
    for market in not_from_start_markets:
        print(market)

    print('Markets not having sufficient TS:')
    for market in not_sufficient_ts:
        print(market)

