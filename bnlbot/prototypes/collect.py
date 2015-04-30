'''
Collect module for Betfair analysis
'''
from __future__ import print_function, division, absolute_import
import psycopg2
import query
import entity
import conf
import clean

class Collector(object):
    '''
    A data collector
    '''
    def __init__(self):
        self.data = None # The result set from db
        self.collection = {} # { 'marketid': (Market, [selectionid]) }
        self.markets = [] # Condensed to market objects and returned


    def collect_step_1(self, db_conn, q_name, q_params):
        '''
        Query DB
        '''
        conn = psycopg2.connect(db_conn)
        try:
            cur = conn.cursor()
            cur.execute(query.named(q_name), q_params)
            self.data = cur.fetchall()
        except psycopg2.Error as error:
            print(error)
        finally:
            cur.close()
            conn.commit()
            conn.close()


    def collect_step_2(self):
        '''
        Collect markets
        '''
        for row in self.data:
            marketid = row[0]
            if marketid not in self.collection:
                market = entity.Market(marketid)
                self.collection[marketid] = (market, [])
                self.markets.append(market)


    def collect_step_3(self):
        '''
        Collect market timestamps and set starttime and data_from_start
        '''
        speed_set = {} # { marketid: set() }, much faster than iterate list
        for row in self.data:
            marketid = row[0]
            pricets = row[1]
            market = self.collection[marketid][0]

            if not marketid in speed_set:
                speed_set[marketid] = set()

            if pricets not in speed_set[marketid]:
                speed_set[marketid].add(pricets)
                market.tstamps.append(pricets)

        for marketid in self.collection:
            market = self.collection[marketid][0]

            if len(market.tstamps) > 1:
                timediff = market.tstamps[1] - market.tstamps[0]
            else:
                market.data_from_start = False
                continue

            if timediff.seconds < 1:
                market.data_from_start = False

            if market.data_from_start:
                for i in xrange(0, len(market.tstamps) - 1):
                    timediff = market.tstamps[i+1] - market.tstamps[i]
                    if timediff.seconds < 1:
                        market.start = i
                        break
            else:
                market.start = 0


    def collect_step_4(self):
        '''
        Collect runners
        '''
        for row in self.data:
            marketid = row[0]
            selectionid = row[3]
            runnername = row[2]

            if selectionid not in self.collection[marketid][1]:
                self.collection[marketid][1].append(selectionid)
                runner = entity.Runner(selectionid)
                runner.name = runnername
                self.collection[marketid][0].runners.append(runner)


    def run_collection(self, db_conn, q_name, q_params):
        '''
        Collect data
        '''
        self.collect_step_1(db_conn, q_name, q_params)
        self.collect_step_2()
        self.collect_step_3()
        self.collect_step_4()

        collect_clean = clean.Clean()
        collect_clean.collect_clean(db_conn, self.markets)

        return self.markets


def safe_run_collection_date(db_conn, q_name, q_params_part, date):
    '''
    Run collection based on date in separate collector (thread safe)
    '''
    q_params = []
    q_params.extend(q_params_part)

    if type(date) != 'tuple':
        date = (date,)

    q_params.append(date)
    q_params = tuple(q_params)
    collector = Collector()
    markets = collector.run_collection(db_conn, q_name, q_params)
    return markets


def multi_run(date):
    '''
    Multiprocessing...
    '''
    markets = safe_run_collection_date(conf.DB, 'q-without-marketid', \
            conf.Q_PARAMS_MAP_REDUCE, date)
    return markets

