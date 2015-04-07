'''
Main prototype module for Betfair analysis
'''
from __future__ import print_function, division, absolute_import
import psycopg2
import query
import entity


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

    # Get markets and runners for each market

    collector = {} # { 'marketid': (Market, [selectionid]) }
    for row in data:
        marketid = row[0]
        selectionid = row[3]
        runnername = row[2]

        if marketid not in collector:
            collector[marketid] = (entity.Market(marketid), [])

        if selectionid not in collector[marketid][1]:
            collector[marketid][1].append(selectionid)
            runner = entity.Runner(selectionid)
            runner.name = runnername
            collector[marketid][0].runners.append(runner)

    for m_id in collector:
        print(collector[m_id][0].marketid)
        for runner in collector[m_id][0].runners:
            print(' '*3, runner.name)

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

