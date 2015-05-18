'''
Main application for Betfair analysis
'''
from __future__ import print_function, division, absolute_import
import collect
import clean
import report


def main():
    '''
    Main method
    '''
    markets = collect.run_collection_dates_multiproc()
    if True:
        clean.collect_clean(markets)
    report.report_collection(markets)
    exit(0)

if __name__ == "__main__":
    main()

