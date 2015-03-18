'''
Main prototype module for Betfair analysis
'''

from __future__ import print_function, division, absolute_import
import psycopg2
from queries import queries


def call_db_and_print(conn, queries):

    try:
        cur = conn.cursor()
        for _ in queries:
            print(_[0])
            print('=' * 80)
            cur.execute(_[1])
            print(cur.fetchall())
            print()
    except Exception as e:
        print(_, e)
    finally:
        cur.close()
        conn.commit()


def check_data(conn):
    # eventid's with eventtypeid = 7
    q1 = \
        ''' 
        SELECT
            eventid
        FROM
            aevents
        WHERE
            eventtypeid = 7
        AND countrycode in ('GB','IE');
        '''
    event_ids = None
    try:
        cur = conn.cursor()
        cur.execute(q1)
        event_ids = cur.fetchall()
    except Exception as e:
        print('q1', e)
        print('q1', _)
    finally:
        cur.close()
        conn.commit()
    print('q1', len(event_ids))

    # marketid's from events above with markettype WIN 
    q2 = \
        '''
        SELECT
            marketid
        FROM
            amarkets
        WHERE
            eventid = %s
        AND markettype = 'WIN'
        AND betdelay > 0;
        '''
    market_ids = []
    try:
        cur = conn.cursor()
        for _ in event_ids:
            cur.execute(q2, _)
            market_ids.extend(cur.fetchall())
    except Exception as e:
        print('q2', e)
        print('q2', _)
    finally:
        cur.close()
        conn.commit()
    print('q2', len(market_ids))
    
    # Join marketid's from above with selectionid's in dict raceprice_keys 
    #(key: marketid, value: [list of selectionid's])
    q3 = \
        '''
        SELECT
            selectionid
        FROM
            arunners
        WHERE
            marketid = %s;
        '''
    raceprice_keys = {}
    try:
        cur = conn.cursor()
        for _ in market_ids:
            selection_ids = []
            cur.execute(q3, _)
            selection_ids.extend(cur.fetchall())
            if _ not in raceprice_keys:
                raceprice_keys[_] = selection_ids
    except Exception as e:
        print('q3', e)
        print('q3', _)
    finally:
        cur.close()
        conn.commit()
    print('q3', len(raceprice_keys))

    q4 = \
        '''
        SELECT
            backprice
        FROM
            apricesfinish 
        WHERE
            marketid = %s 
            AND selectionid = %s
        LIMIT 1;
        '''
    backprice = 0
    no_backprice = 0
    try:
        cur = conn.cursor()
        # For every marketid...
        for _ in raceprice_keys.keys():
            # ...together with every selectionid...
            for _2 in raceprice_keys[_]:
                cur.execute(q4, [_, _2])
                # ...see if backprices exist
                row = cur.fetchone()
                if (row is not None):
                    backprice += 1
                else:
                    no_backprice += 1
    except Exception as e:
        print('q4', e)
        print('q4', _)
    finally:
        cur.close()
        conn.commit()
    print('q4', 'no_backprice:', no_backprice)
    print('q4', 'backprice:', backprice)


if __name__ == "__main__":
    CONN = psycopg2.connect("dbname=dry user=joakim")
    call_db_and_print(CONN, queries.QUERIES)
    #check_data(CONN)
    CONN.close()
    exit(0)

