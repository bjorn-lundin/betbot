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
import time

# Make sure this application runs under
# tz CET / Europe/Stockholm
if time.tzname[0] != 'CET':
    os.putenv('TZ', 'Europe/Stockholm')
    time.tzset()

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
    logfile = os.path.join(conf.AIS_LOGDIR, conf.AIS_LOGFILE)
    logfile = os.path.normpath(logfile)
    filehandler = logging.handlers.RotatingFileHandler(
        logfile, mode='a', maxBytes=5000000, 
        backupCount=10, encoding='utf-8', delay=0)
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
    cloud_storage_connection = None
    cloud_storage_bucket = None
    if conf.AIS_S3_STORE:
        cloud_storage_connection = util.get_aws_s3_connections(
            username=conf.AIS_S3_USER,
            password=conf.AIS_S3_PASSWORD
        )
        cloud_storage_bucket = util.init_aws_s3_bucket(
            connection=cloud_storage_connection,
            bucketname=conf.AIS_S3_BUCKET
        )
    init_db = 'init_db'
    init_local_racedays = 'init_local_racedays'
    daily_download = 'daily_download'
    meta_files = 'write_meta_files'
    save_files_in_cloud = 'save_files_in_cloud'
    get_files_from_cloud = 'get_files_from_cloud'
    
    usage_string = "usage: %(prog)s " + \
        "[%(com0)s|%(com1)s|%(com2)s|%(com3)s|" + \
        "%(com4)s|%(com5)s]"
    usage = usage_string % \
        {
            'prog':'%prog',
            'com0':init_db,
            'com1':init_local_racedays,
            'com2':daily_download, 
            'com3':meta_files,
            'com4':save_files_in_cloud,
            'com5':get_files_from_cloud
        }
    parser = OptionParser(usage)
    args = parser.parse_args()[1]
    if len(args) < 1:
        parser.error("Please state command to run!")
    
    if init_db in args:
        LOG.info('Running ' + init_db)
        db.init_db_client(db_init=True)
    
    if init_local_racedays in args:
        LOG.info('Running ' + init_local_racedays)
        params = {
            'client':ws_client,
            'datadir':conf.AIS_DATADIR,
            'metadir':conf.AIS_METADIR,
            'ais_version':conf.AIS_VERSION,
            'ais_type':conf.AIS_TYPE,
            'save_soap_file':True
        }
        ais.load_calendar_history_into_db(params)
    
    if daily_download in args:
        LOG.info('Running ' + daily_download)
        params = {
            'client':ws_client,
            'datadir':conf.AIS_DATADIR,
            'metadir':conf.AIS_METADIR,
            'ais_version':conf.AIS_VERSION,
            'ais_type':conf.AIS_TYPE,
            'save_soap_file':True,
            'raceday_history':conf.AIS_RACEDAY_HISTORY,
            'raceday_exclude':conf.AIS_RACEDAY_EXCLUDE
        }
        ais.download_history_via_calendar(params)
    
    if meta_files in args:
        LOG.info('Running ' + meta_files)
        util.write_meta_files(client=ws_client, path=conf.AIS_METADIR)
    
    if save_files_in_cloud in args:
        LOG.info('Running ' + save_files_in_cloud)
        util.save_files_in_aws_s3_bucket(from_datadir=conf.AIS_DATADIR,
                                         bucket=cloud_storage_bucket)
    
    if get_files_from_cloud in args:
        LOG.info('Running ' + get_files_from_cloud)
        util.get_files_from_aws_s3(to_datadir=conf.AIS_DATADIR,
                                   bucket=cloud_storage_bucket)
    if cloud_storage_connection:
        cloud_storage_connection.close()
        
    LOG.info('Ending application')
    logging.shutdown()    
    exit(0)

if __name__ == "__main__":
    main()