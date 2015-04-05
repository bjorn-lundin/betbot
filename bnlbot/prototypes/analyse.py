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
        print(cur.mogrify(query.named(q_name), q_data))
        cur.execute(query.named(q_name), q_data)
        data = cur.fetchall()
    except psycopg2.Error as error:
        print(error)
    finally:
        cur.close()
        conn.commit()

    u_market = {} # Entity Market as unique key
    for row in data:
        market = entity.Market(row[0])
        t_stamp = row[1]

        if market not in u_market:
            u_market[market] = []

        if t_stamp not in u_market[market]:
            u_market[market].append(t_stamp)
            if len(u_market[market]) > 1:
                time_diff = u_market[market][-1] - u_market[market][-2]
                if time_diff.seconds < 1:
                    market.starttime = u_market[market][-2]
                    break


def run_analysis(conn):
    '''
    Setting parameters and run analyse
    '''
    status = ('WINNER', 'LOSER')
    markettype = 'WIN'
    date = ('2014-09-02',)
    marketid = ('1.115258242',)
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

