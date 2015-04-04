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


def analyse_1(conn):
    '''
    Main analysis 1
    '''
    cur = None
    data = None
    try:
        cur = conn.cursor()
        cur.execute(queries.QUERIES['q1'])
        data = cur.fetchall()
    except psycopg2.Error as error:
        print(error)
    finally:
        cur.close()
        conn.commit()

    u_m = {} # Dict with entity Market as unique key
    for row in data:
        market = entity.Market(row[0])
        t_s = row[1] # timestamp
        
        if market not in u_m:
            u_m[market] = []

        if t_s not in u_m[market]:
            u_m[market].append(t_s)
            if len(u_m[market]) > 1:
                diff = diff_ts(u_m[market][-2], u_m[market][-1])
                if diff < 1:
                    starttime = u_m[market][-2]
                    market.starttime = starttime
                    print(market)
                    break


if __name__ == "__main__":
    CONN = psycopg2.connect("dbname=dry user=joakim")
    analyse_1(CONN)
    CONN.close()
    exit(0)

