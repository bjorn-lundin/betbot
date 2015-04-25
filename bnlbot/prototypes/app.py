'''
Main application for Betfair analysis
'''
from __future__ import print_function, division, absolute_import
import sys
import collect
import report


def main(argv):
    '''
    Main method
    '''

    if len(argv) > 1 and 't' in argv[1]:
        print('Will be running multi-process when implemented...')
        #collect.run_collection_multiproc(conn, collection)
        exit(1)
    else:
        collection = collect.run_collection()
        report.report_collection(collection)
    exit(0)

if __name__ == "__main__":
    main(sys.argv)
