'''
The main application to run when getting data from AIS
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import os
import errno
import conf
import logging
import ais
import db

AIS_RUN_MODE = 'TEST'

try:
    os.makedirs(conf.DATADIR)
except OSError as exception:
    if exception.errno != errno.EEXIST:
        raise

def run():
    AIS_LOG_LEVEL = logging.DEBUG
    LOG = logging.getLogger('AIS')
    LOG.setLevel(AIS_LOG_LEVEL)
    FH = logging.FileHandler(conf.DATADIR + '/ais.log', mode='a')
    FH.setLevel(AIS_LOG_LEVEL)
    FORMAT_STRING = '%(asctime)s %(name)s %(levelname)s %(message)s'
    FORMATTER = logging.Formatter(FORMAT_STRING)
    FH.setFormatter(FORMATTER)
    LOG.addHandler(FH)
    SUDS_LOG = logging.getLogger('suds')
    SUDS_LOG.setLevel(logging.CRITICAL)
    
    LOG.info('Starting application')
    
    WS_CLIENT = ais.init_ws_client(conf.WSDL_URL, conf.USERNAME, conf.PASSWORD)
    db.init_db_client(conf.DB_URL, db_init=True)
    
    ais.write_methods_file(WS_CLIENT, conf.DATADIR)
    ais.write_wsdl_file(WS_CLIENT, conf.DATADIR)
    
    ais.raceday_calendar(WS_CLIENT, conf.DATADIR)
    #ais.fetchRaceDayCalendarSimple(CLIENT)
    #ais.fetchCurrentEventSequenceNumber(CLIENT)
    LOG.info('Ending application')
    logging.shutdown()    

if __name__ == "__main__":
    run()
    exit(0) 