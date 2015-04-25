'''
Report module for Betfair analysis
'''
from __future__ import print_function, division, absolute_import


def report_collection(collection):
    '''
    Report parts from collection
    '''
    nbr_markets = len(collection)
    nbr_from_start = 0
    nbr_not_from_start = 0
    not_from_start_markets = []

    for marketid in collection:
        if collection[marketid][0].data_from_start:
            nbr_from_start += 1
        else:
            nbr_not_from_start += 1
            not_from_start_markets.append(marketid)

    print(nbr_markets)
    print(nbr_from_start)
    print(nbr_not_from_start)
    for market in not_from_start_markets:
        print(market)
