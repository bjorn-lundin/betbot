'''
Collect module for Betfair analysis
'''
from __future__ import print_function, division, absolute_import
import conf
import psycopg2
import query
import entity

class Collector(object):
    '''
    A data collector
    '''
    def __init__(self):
        self.q_data = None
        self.q_name = None
        self.data = None
        self.collection = {} # { 'marketid': (Market, [selectionid]) }


    def collect_step_1(self):
        '''
        Query DB
        '''
        conn = psycopg2.connect(conf.LOCAL_DRY)
        try:
            cur = conn.cursor()
            cur.execute(query.named(self.q_name), self.q_data)
            self.data = cur.fetchall()
        except psycopg2.Error as error:
            print(error)
        finally:
            cur.close()
            conn.commit()
            conn.close()


    def collect_step_2(self):
        '''
        Collect markets and runners for each market
        '''
        for row in self.data:
            marketid = row[0]
            if marketid not in self.collection:
                self.collection[marketid] = (entity.Market(marketid), [])


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
            timediff = market.tstamps[1] - market.tstamps[0]

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


    def run_collection(self):
        '''
        Collect data
        '''
        status = conf.Q_STATUS
        markettype = conf.Q_MARKETTYPE
        date = conf.Q_DATE
        marketid = conf.Q_MARKETID

        if len(marketid) == 0:
            self.q_name = 'q-without-marketid'
            self.q_data = (status, markettype, date)
        else:
            self.q_name = 'q-with-marketid'
            self.q_data = (status, markettype, date, marketid)

        self.collect_step_1()
        self.collect_step_2()
        self.collect_step_3()
        self.collect_step_4()
        return self.collection


    def run_collection_multiproc(self):
        '''
        Collect data multiprocess
        '''
        pass

