'''
Main prototype module for Betfair analysis
'''

from __future__ import print_function, division, absolute_import
import psycopg2
from queries import queries
import entity

def diff_ts(ts0, ts1):
    '''
    Return the difference between time stamps in seconds
    '''
    diff = ts1 - ts0
    return diff.seconds


def analyse(conn, q_data, q_name):
    '''
    Main analysis
    '''

    cur = None
    data = None

    try:
        cur = conn.cursor()
        print(cur.mogrify(queries.QUERIES[q_name], q_data))
        cur.execute(queries.QUERIES[q_name], q_data)
        data = cur.fetchall()
    except psycopg2.Error as error:
        print(error)
    finally:
        cur.close()
        conn.commit()

    u_market = {} # Dict with entity Market as unique key
    for row in data:
        market = entity.Market(row[0])
        t_stamp = row[1] # timestamp

        if market not in u_market:
            u_market[market] = []

        if t_stamp not in u_market[market]:
            u_market[market].append(t_stamp)
            if len(u_market[market]) > 1:
                diff = diff_ts(u_market[market][-2], u_market[market][-1])
                if diff < 1:
                    starttime = u_market[market][-2]
                    market.starttime = starttime
                    print(market.marketid)
                    print(market.starttime)
                    break


if __name__ == "__main__":
    CONN = psycopg2.connect("dbname=dry user=joakim")

    STATUS = ('WINNER', 'LOSER')
    MARKETTYPE = 'WIN'
    DATE = ('2014-09-02',)
    MARKETID = ('1.115258242',)
    #MARKETID = ()

    Q_NAME = 'q-with-marketid'
    Q_DATA = (STATUS, MARKETTYPE, DATE, MARKETID)

    if len(MARKETID) == 0:
        print('hej')
        Q_NAME = 'q-without-marketid'
        Q_DATA = (STATUS, MARKETTYPE, DATE)

    analyse(CONN, Q_DATA, Q_NAME)
    CONN.close()
    exit(0)

