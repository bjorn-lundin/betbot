'''
Collect data used for cleaning up and making DB smaller
'''
from __future__ import print_function, division, absolute_import
import psycopg2

CLEAN_MARKETS = []

def collect_clean(db_conn, markets):
    '''
    Fill clean_markets and add to nisse
    '''
    for market in markets:
        if len(market.tstamps) > 1:
            timediff = market.tstamps[1] - market.tstamps[0]
            if timediff.seconds < 1:
                CLEAN_MARKETS.append(market.marketid)
        else:
            CLEAN_MARKETS.append(market.marketid)

    ins = 'insert into nisse values (%s)'

    try:
        conn = psycopg2.connect(db_conn)
        for market in CLEAN_MARKETS:
            cur = conn.cursor()
            cur.execute(ins, (market.marketid,))
    except psycopg2.Error as error:
        print(error)
    finally:
        cur.close()
        conn.commit()
        conn.close()

