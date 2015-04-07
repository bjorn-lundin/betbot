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


def collect_step_2(data):
    '''
    Collect markets and runners for each market
    '''
    collection = {} # { 'marketid': (Market, [selectionid]) }
    for row in data:
        marketid = row[0]
        selectionid = row[3]
        runnername = row[2]

        if marketid not in collection:
            collection[marketid] = (entity.Market(marketid), [])

        if selectionid not in collection[marketid][1]:
            collection[marketid][1].append(selectionid)
            runner = entity.Runner(selectionid)
            runner.name = runnername
            collection[marketid][0].runners.append(runner)

    for m_id in collection:
        print(collection[m_id][0].marketid)
        for runner in collection[m_id][0].runners:
            print(' '*3, runner.name)

    return collection


def collect_step_3(data, collection):
    '''
    Collect starttime for each market
    '''
    all_ts = {} # { 'marketid': [pricets] }
    for row in data:
        marketid = row[0]
        pricets = row[1]

        if collection[marketid][0].starttime is not None:
            continue

        if marketid in all_ts:
            all_ts[marketid].append(pricets)
            if len(all_ts[marketid]) > 1:
                timediff = all_ts[marketid][-1] - all_ts[marketid][-2]
                if timediff.seconds < 1:
                    collection[marketid][0].starttime = all_ts[marketid][-2]
        else:
            all_ts[marketid] = [pricets]
    all_ts = None

    for m_id in collection:
        print(collection[m_id][0].marketid)
        print(collection[m_id][0].starttime)

    return collection


def collect_step_4():
    '''
    Collect winner in each win market
    '''
    pass


def run_collection(conn):
    '''
    Collect parameters
    '''
    status = ('WINNER', 'LOSER')
    markettype = 'WIN'
    date = ('2014-09-02',)
    marketid = ('1.115258242', '1.115258254', '1.115258199')
    q_name = 'q-with-marketid'
    q_data = (status, markettype, date, marketid)

    if len(marketid) == 0:
        q_name = 'q-without-marketid'
        q_data = (status, markettype, date)

    data = collect_step_1(conn, q_data, q_name)
    collection = collect_step_2(data)
    collection = collect_step_3(data, collection)
    collect_step_4()

    return collection


def run_analysis():
    '''
    Run analysis
    '''
    pass


if __name__ == "__main__":
    CONN = psycopg2.connect("dbname=dry user=joakim")
    COLLECTION = run_collection(CONN)
    run_analysis()
    CONN.close()
    exit(0)

