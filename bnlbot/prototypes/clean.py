'''
Collect data used for cleaning up and making DB smaller
'''
from __future__ import print_function, division, absolute_import
import psycopg2
import conf


class Clean(object):
    '''
    Clean object
    '''
    def collect_clean(self, db_conn, markets):
        '''
        Insert temporary "cleaning" data into DB
        '''
        ins = 'insert into nisse values (%s)'
        conn = psycopg2.connect(db_conn)
        for market in markets:
            if not market.data_from_start:
                continue
            try:
                cur = conn.cursor()
                cur.execute(ins, (market.marketid,))
            except psycopg2.Error as error:
                pass
            finally:
                cur.close()
                conn.commit()
        conn.close()


def main():
    '''
    Main method
    '''
    markets = ['mark1', 'mark2', 'mark3']
    collect_clean = Clean()
    collect_clean.collect_clean(conf.DB, markets)
    exit(0)


if __name__ == '__main__':
    main()

