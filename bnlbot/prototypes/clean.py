'''
Collect data to prepare for cleaning up and making DB smaller
'''
from __future__ import print_function, division, absolute_import
import psycopg2
import conf

DELETE_MARKETS = []


def collect_clean(markets):
    '''
    Fill clean_markets with markets to delete 
    and add every marketid to nisse
    '''
    db_conn_str = conf.DB
    for market in markets:
        if market.start < 0:
            DELETE_MARKETS.append(market)
    ins = 'insert into nisse values (%s)'
    
    conn = psycopg2.connect(db_conn_str)
    for market in DELETE_MARKETS:
        try:
            cur = conn.cursor()
            cur.execute(ins, (market.marketid,))
        except psycopg2.Error:
            pass
        finally:
            cur.close()
            conn.commit()
    conn.close()

