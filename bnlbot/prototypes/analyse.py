'''
Main prototype module for Betfair analysis
'''

from __future__ import print_function, division, absolute_import
import psycopg2
import query
import entity
import time

def analyse(conn, q_data, q_name):
    '''
    Main analysis
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

    # Get markets, market starttime and runners for each market

    markets = {} # { 'marketid': Market }
    runners = {} # { selectionid: {'marketid':Runner} }
    for row in data:
        marketid = row[0]
        selectionid = row[3]
        runnername = row[2]

        if marketid not in markets:
            markets[marketid] = entity.Market(marketid)

        if selectionid not in runners:
            runner = entity.Runner(selectionid)
            runner.name = runnername
            runners[selectionid] = {marketid: runner}

    for m in markets:
        nisse = []
        for r in runners:
            if m in runners[r].keys():
                nisse.append(runners[r][m])
        markets[m].runners = nisse
        
    for m in markets:
        print(markets[m].marketid)
        for r in markets[m].runners:
            print(' '*3, r.name)


'''
    # Get starttime for each market
    last_timestampt = None
    for row in data:
        timestamp = row[1]

        if marketid in markets and \
                markets[marketid][0].starttime is not None:
            continue

        if timestamp not in u_market[marketid][1]:
            u_market[marketid][1].append(timestamp)
            if len(u_market[marketid][1]) > 1:
                timediff = u_market[marketid][1][-1] - \
                        u_market[marketid][1][-2]
                if timediff.seconds < 1:
                    u_market[marketid][0].starttime = \
                            u_market[marketid][1][-2]


    # Populate entity Runner
    for row in data:

    # Find winner in each market
'''

def run_analysis(conn):
    '''
    Setting parameters and run analyse
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

    analyse(conn, q_data, q_name)


if __name__ == "__main__":
    CONN = psycopg2.connect("dbname=dry user=joakim")
    run_analysis(CONN)
    CONN.close()
    exit(0)

