'''
Collect module for Betfair analysis
'''
from __future__ import print_function, division, absolute_import
import psycopg2
import query
import entity
import conf
import datetime
import multiprocessing

class Collector(object):
    '''
    A data collector
    '''
    def __init__(self):
        self.data = None # The result set from db
        self.collection = {} # { 'marketid': (Market, [selectionid]) }
        self.markets = [] # Condensed to market objects and returned


    def collect_step_1(self, q_name, q_params):
        '''
        Query DB
        '''
        db_conn_str = conf.DB
        try:
            conn = psycopg2.connect(db_conn_str)
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

        for market in self.markets:
            if len(market.tstamps) < conf.MIN_NBR_TS_TO_PASS:
                continue
            for i in range(len(market.tstamps)):
                if i < 1:
                    continue
                prev = i-1
                timediff = market.tstamps[i] - market.tstamps[prev]
                if timediff.seconds < 1:
                    market.start = prev
                    break


    def collect_step_4(self):
        '''
        Collect runners and their data
        '''
        for row in self.data:
            marketid = row[0]
            runnername = row[2]
            selectionid = row[3]
            backprice = row[4]
            layprice = row[5]
            totalmatched = row[6]

            if selectionid not in self.collection[marketid][1]:
                self.collection[marketid][1].append(selectionid)
                runner = entity.Runner(selectionid)
                runner.name = runnername
                runner.backprices.append(backprice)
                runner.layprices.append(layprice)
                runner.totalmatched.append(totalmatched)
                self.collection[marketid][0].runners.append(runner)
            else:
                for runner in self.collection[marketid][0].runners:
                    if selectionid == runner.selectionid:
                        runner.backprices.append(backprice)
                        runner.layprices.append(layprice)
                        runner.totalmatched.append(totalmatched)
                        break


    def collect_step_5(self):
        '''
        Query DB for market winners
        '''
        marketids = self.collection.keys()
        if len(marketids) < 1:
            return
        db_conn_str = conf.DB
        q_name = 'q-get-win-winner'
        winners = None
        marketids = (tuple(marketids),)

        try:
            conn = psycopg2.connect(db_conn_str)
            cur = conn.cursor()
            cur.execute(query.named(q_name), marketids)
            winners = cur.fetchall()
        except psycopg2.Error as error:
            print(error)
        finally:
            cur.close()
            conn.commit()
            conn.close()

        for row in winners:
            marketid = row[0]
            selectionid = row[1]
            self.collection[marketid][0].win_winner_id = selectionid


    def run_collection(self, q_name, q_params):
        '''
        Collect data
        '''
        self.collect_step_1(q_name, q_params)
        self.collect_step_2()
        self.collect_step_3()
        self.collect_step_4()
        self.collect_step_5()
        return self.markets


def run_collection_date(date):
    '''
    Run collection based on dates in separate collectors (thread safe)
    '''
    q_name = 'q-without-marketid'
    q_params = []
    q_params.extend(conf.Q_PARAMS_MAP_REDUCE)

    if type(date) != 'tuple':
        date = (date,)

    q_params.append(date)
    q_params = tuple(q_params)
    collector = Collector()
    markets = collector.run_collection(q_name, q_params)
    return markets


def run_collection_dates_multiproc():
    '''
    Setup method for multiprocessing
    '''
    print('Running map reduce in multiprocess mode...')
    dates = get_date_range(conf.START_DATE_STR, conf.END_DATE_STR)
    nbr_of_proc = multiprocessing.cpu_count()
    pool = multiprocessing.Pool(nbr_of_proc)
    markets = pool.map(run_collection_date, dates)
    return reduce(lambda x, y: x + y, markets)


def get_date_range(start_date_str, end_date_str):
    '''
    Create range (tuple) of dates based on start and stop date
    '''
    date_format = '%Y-%m-%d'
    try:
        start_date = \
            datetime.datetime.strptime(start_date_str, date_format).date()
        end_date = \
            datetime.datetime.strptime(end_date_str, date_format).date()
    except ValueError:
        return None

    if start_date > end_date:
        return None

    total_days = (end_date - start_date).days + 1
    dates = []

    for day_delta in range(total_days):
        date = start_date + datetime.timedelta(days=day_delta)
        date = date.strftime(date_format)
        dates.append(date)

    return tuple(dates)

