'''
The main application to run when getting data from AIS
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import os
import errno

AIS_RUN_MODE = 'TEST'

from ConfigParser import SafeConfigParser
PARSER = SafeConfigParser()
PARSER.read('ais.ini')
URL = PARSER.get(AIS_RUN_MODE, 'url')
USERNAME = PARSER.get(AIS_RUN_MODE, 'username')
PASSWORD = PARSER.get(AIS_RUN_MODE, 'password')
DATADIR = PARSER.get(AIS_RUN_MODE, 'datadir')
DB_URL = PARSER.get(AIS_RUN_MODE, 'db_url')

try:
    os.makedirs(DATADIR)
except OSError as exception:
    if exception.errno != errno.EEXIST:
        raise

if __name__ == "__main__":
    import logging
    AIS_LOG_LEVEL = logging.DEBUG
    
    LOG = logging.getLogger('AIS')
    LOG.setLevel(AIS_LOG_LEVEL)
    FH = logging.FileHandler(DATADIR + '/ais.log', mode='a')
    FH.setLevel(AIS_LOG_LEVEL)
    FORMAT_STRING = '%(asctime)s %(name)s %(levelname)s %(message)s'
    FORMATTER = logging.Formatter(FORMAT_STRING)
    FH.setFormatter(FORMATTER)
    LOG.addHandler(FH)
    SUDS_LOG = logging.getLogger('suds')
    SUDS_LOG.setLevel(logging.CRITICAL)
    
    LOG.info('Starting application')
    
    import ais
    ws_client = ais.init_ws_client(URL, USERNAME, PASSWORD)
    import db
    db.init_db_client(DB_URL, db_init=True)
    
    ais.write_methods_file(ws_client, DATADIR)
    ais.write_wsdl_file(ws_client, DATADIR)
    
    ais.raceday_calendar(ws_client, DATADIR)
    #ais.fetchRaceDayCalendarSimple(CLIENT)
    #ais.fetchCurrentEventSequenceNumber(CLIENT)
    LOG.info('Ending application')
    logging.shutdown()

    exit(0) 