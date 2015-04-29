'''
Main application for Betfair analysis
'''
from __future__ import print_function, division, absolute_import
import sys
import conf
import collect
import report
import multiprocessing


def main(argv):
    '''
    Main method
    '''
    argv.append('p')
    markets = []
    
    if len(argv) == 2:
        if 'r' in argv[1]:
            print('Running map reduce...')
            markets = [collect.safe_run_collection_date(conf.DB, \
                    'q-without-marketid', conf.Q_PARAMS_MAP_REDUCE, date) \
                    for date in conf.Q_DATE_MAP_REDUCE]
        elif 'p' in argv[1]:
            print('Running multiprocess...')
            pool = multiprocessing.Pool(multiprocessing.cpu_count())
            markets = pool.map(collect.multi_map, conf.Q_DATE_MAP_REDUCE)
        else:
            print('Nope!')
            exit(1)
        markets = reduce(lambda x, y: x + y, markets)
    else:
        print('Running normal...')
        collector = collect.Collector()
        markets = collector.run_collection(conf.DB, 'q-with-marketid', \
                conf.Q_PARAMS_ID)

    report.report_collection(markets)
    exit(0)


if __name__ == "__main__":
    main(sys.argv)

