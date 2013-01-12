#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
The main application to run when getting data from AIS
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
from optparse import OptionParser
import os
import errno
import conf
import logging.handlers
import ais
import db
import util

# Set timezone Europe/Stockholm
# -> central european time, UTC+1
# -> central european summer time, UTC+2
os.putenv('TZ','Europe/Stockholm')

LOG = logging.getLogger('AIS')

CREATE_DIRS = [conf.AIS_LOGDIR, conf.AIS_DATADIR, conf.AIS_METADIR]
for cdir in CREATE_DIRS:
    try:
        os.makedirs(cdir)
    except OSError as exception:
        if exception.errno != errno.EEXIST:
            raise

def init_logging():
    '''
    Initiate all logging
    '''
    ais_log_level = logging.INFO
    LOG.setLevel(ais_log_level)
    
    filehandler = logging.handlers.RotatingFileHandler(
        conf.AIS_LOGDIR + '/ais.log',
        mode='a', maxBytes=5000000, backupCount=10, 
        encoding='utf-8', delay=0)
    filehandler.setLevel(ais_log_level)
    format_string = '%(asctime)s %(name)s %(levelname)s %(message)s'
    formatter = logging.Formatter(format_string)
    filehandler.setFormatter(formatter)
    LOG.addHandler(filehandler)
    
    if conf.EMAIL_LOG_ERRORS:
        mailhost = None
        if conf.EMAIL_LOG_PORT == '':
            mailhost = conf.EMAIL_LOG_HOST
        else:
            mailhost = (conf.EMAIL_LOG_HOST, conf.EMAIL_LOG_PORT)
        credentials = None
        secure = None
        if conf.EMAIL_LOG_USER != '' and conf.EMAIL_LOG_PASS != '':
            credentials = (conf.EMAIL_LOG_USER, conf.EMAIL_LOG_PASS)
        if conf.EMAIL_LOG_TLS:
            secure = ()
        smtphandler = logging.handlers.SMTPHandler(
            mailhost=mailhost,
            fromaddr=conf.EMAIL_LOG_FROM,
            toaddrs=conf.EMAIL_LOG_TO,
            subject=conf.EMAIL_LOG_SUBJECT,
            credentials=credentials,
            secure=secure
        )
        smtphandler.setLevel(logging.ERROR)
        smtphandler.setFormatter(formatter)
        LOG.addHandler(smtphandler)
    
    suds_log = logging.getLogger('suds')
    suds_log.setLevel(logging.CRITICAL)
    
def main():
    '''
    Main loop of application
    '''
    init_logging()
    LOG.info('Starting application')
    ws_client = ais.init_ws_client(conf.AIS_WS_URL, conf.AIS_USERNAME, 
                                   conf.AIS_PASSWORD)
    db.init_db_client(conf.AIS_DB_URL, db_init=False)
    
    init_db = 'init_db'
    meta_files = 'write_meta_files'
    ais_racedays = 'get_ais_racedays'
    daily_download = 'daily_download'
    usage = \
        "usage: %(prog)s [%(com0)s|%(com1)s|%(com2)s|%(com3)s]" % \
        {
            'prog':'%prog',
            'com0':init_db,
            'com1':meta_files,
            'com2':ais_racedays, 
            'com3':daily_download
        }
    parser = OptionParser(usage)
    args = parser.parse_args()[1]
    if len(args) < 1:
        parser.error("Please state command to run!")
    if init_db in args:
        LOG.info('Running ' + init_db)
        db.init_db_client(conf.AIS_DB_URL, db_init=True)
    if meta_files in args:
        LOG.info('Running ' + meta_files)
        util.write_meta_files(client=ws_client, path=conf.AIS_METADIR)
    if ais_racedays in args:
        LOG.info('Running ' + ais_racedays)
        params = {
            'client':ws_client,
            'datadir':conf.AIS_DATADIR,
            'metadir':conf.AIS_METADIR,
            'ais_version':conf.AIS_VERSION,
            'ais_type':conf.AIS_TYPE,
            'save_soap_file':True
        }
        ais.raceday_calendar(params)
    if daily_download in args:
        LOG.info('Running ' + daily_download)
        params = {
            'client':ws_client,
            'datadir':conf.AIS_DATADIR,
            'metadir':conf.AIS_METADIR,
            'ais_version':conf.AIS_VERSION,
            'ais_type':conf.AIS_TYPE,
            'save_soap_file':True
        }
        ais.download_history_via_calendar(params)
    LOG.info('Ending application')
    logging.shutdown()    
    exit(0)

if __name__ == "__main__":
    main()