'''
Main prototype module for Betfair analysis
'''
from __future__ import print_function, division, absolute_import
import psycopg2
import query
import entity


def collect_step_1(conn, q_data, q_name):
    '''
    Query DB
    '''
    data = None
    try:
        cur = conn.cursor()
        cur.execute(query.named(q_name), q_data)
        data = cur.fetchall()
    except psycopg2.Error as error:
        print(error)
    finally:
        cur.close()
        conn.commit()
    return data


def collect_step_2(data, collection):
    '''
    Collect markets and runners for each market
    '''
    for row in data:
        marketid = row[0]
        if marketid not in collection:
            collection[marketid] = (entity.Market(marketid), [])


def collect_step_3(data, collection):
    '''
    Collect market timestamps and set starttime and data_from_start
    '''
    speed_set = {} # { marketid: set() }, much faster than iterate list
    for row in data:
        marketid = row[0]
        pricets = row[1]
        market = collection[marketid][0]

        if not marketid in speed_set:
            speed_set[marketid] = set()

        if pricets not in speed_set[marketid]:
            speed_set[marketid].add(pricets)
            market.tstamps.append(pricets)

    for marketid in collection:
        market = collection[marketid][0]
        timediff = market.tstamps[1] - market.tstamps[0]

        if timediff.seconds < 1:
            market.data_from_start = False

        if market.data_from_start:
            for i in xrange(0, len(market.tstamps) - 1):
                timediff = market.tstamps[i+1] - market.tstamps[i]
                if timediff.seconds < 1:
                    market.start = i
                    break
        else:
            market.start = 0


def collect_step_4(data, collection):
    '''
    Collect runners
    '''
    for row in data:
        marketid = row[0]
        selectionid = row[3]
        runnername = row[2]

        if selectionid not in collection[marketid][1]:
            collection[marketid][1].append(selectionid)
            runner = entity.Runner(selectionid)
            runner.name = runnername
            collection[marketid][0].runners.append(runner)


def run_collection(conn, collection):
    '''
    Collect data
    '''
    status = ('WINNER', 'LOSER')
    markettype = 'WIN'

    date = ('2014-09-01',)
    marketid = (
        '1.115253736',
        '1.115253744',
        '1.115253163',
        '1.115253165',
        '1.115253179')
    #marketid = ()

    # Against bnl/dry
    #date = ('2015-04-08',)
    #marketid = (
    #    '1.118127976',
    #    '1.118127984',
    #    '1.118127972',
    #    '1.118128058',
    #    '1.118128098')

    if len(marketid) == 0:
        q_name = 'q-without-marketid'
        q_data = (status, markettype, date)
    else:
        q_name = 'q-with-marketid'
        q_data = (status, markettype, date, marketid)

    data = collect_step_1(conn, q_data, q_name)
    collect_step_2(data, collection)
    collect_step_3(data, collection)
    collect_step_4(data, collection)


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


def run_analysis():
    '''
    Run analysis
    '''
    pass

def main():
    '''
    Main method
    '''

    conn = psycopg2.connect("dbname=dry user=joakim")

    #conn = psycopg2.connect(
    #    '''
    #    host=db.nonodev.com
    #    dbname=dry
    #    user=bnl
    #    password=BettingFotboll1$
    #    sslmode=require
    #    '''
    #)

    collection = {} # { 'marketid': (Market, [selectionid]) }
    run_collection(conn, collection)
    report_collection(collection)
    run_analysis()
    conn.close()
    exit(0)

if __name__ == "__main__":
    main()
