'''
Main prototype module for Betfair analysis
'''

from __future__ import print_function, division, absolute_import
import psycopg2
from queries import queries


def call_db_and_print(cursor, query):
    print(query[0])
    print('=' * 80)
    cursor.execute(query[1])
    print(cursor.fetchall())
    print()


def check_data(cursor):
    # eventid's with eventtypeid = 7
    q1 = \
        ''' 
        SELECT
            eventid
        FROM
            aevents
        WHERE
            eventtypeid = 7;
        '''
    event_ids = None
    try:
        cursor.execute(q1)
        event_ids = cursor.fetchall()
    except Exception as e:
        print('q1', e)
        print('q1', _)
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
            AND markettype = 'WIN';
        '''
    market_ids = []
    for _ in event_ids:
        try:
            cursor.execute(q2, _)
            market_ids.extend(cursor.fetchall())
        except Exception as e:
            print('q2', e)
            print('q2', _)
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
    for _ in market_ids:
        try:
            cursor.execute(q3, _)
            selection_ids = []
            selection_ids.extend(cursor.fetchall())
            if _ not in raceprice_keys:
                raceprice_keys[_] = selection_ids
            else:
                print('Duplicate marketid ->', _)
        except Exception as e:
            print('q3', e)
            print('q3', _)
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
    # For every marketid...
    for _ in raceprice_keys.keys():
        try:
            # ...together with every selectionid...
            for _2 in raceprice_keys[_]:
                cursor.execute(q4, [_, _2])
                # ...see if backprices exist
                if (len(cursor.fetchall()) > 0):
                    backprice += 1
                else:
                    no_backprice += 1
        except Exception as e:
            print('q4', e)
            print('q4', _)
    print('q4', 'no_backprice:', no_backprice)
    print('q4', 'backprice:', backprice)


if __name__ == "__main__":
    CONN = psycopg2.connect("dbname=dry user=joakim")
    CUR = CONN.cursor()
    #for q in queries.QUERIES:
    #    call_db_and_print(CUR, q)
    check_data(CUR)
    CUR.close()
    CONN.close()
    exit(0)
