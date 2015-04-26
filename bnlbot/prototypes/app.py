'''
Main application for Betfair analysis
'''
from __future__ import print_function, division, absolute_import
import sys
import conf
import collect
import report


def main(argv):
    '''
    Main method
    '''


    def map_func(date):
        '''
        Map
        '''
        print(date)
        collector = collect.Collector()
        collection = collector.run_collection_map_reduce((date,))
        print(len(collection))
        return collection


    def red_func(list_a, list_b):
        '''
        Reduce
        '''
        return list_a + list_b


    argv.append('r')
    if len(argv) == 2:
        if 'r' in argv[1]:
            print('Running map reduce...')
            dates = [] # Split on date
            for date in conf.Q_DATE_MAP_REDUCE:
                dates.append((date,))
            collections = [map_func(date) for date in dates]
            res = reduce(red_func, collections)
            report.report_collection(res)
        elif 'p' in argv[1]:
            print('Running multi process...')
            #collect.run_collection_multiproc(conn, collection)
        else:
            print('Nope!')
            exit(1)
    else:
        print('Running normal...')
        collector = collect.Collector()
        collection = collector.run_collection()
        report.report_collection(collection)
    exit(0)

if __name__ == "__main__":
    main(sys.argv)

