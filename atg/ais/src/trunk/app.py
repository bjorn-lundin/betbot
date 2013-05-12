#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
The main application to run when getting data from AIS
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import os
import command_parser as cp
import conf
import logging.handlers
import ais
import db
import util
import time
import aws_services

# Make sure this application runs under
# tz CET / Europe/Stockholm
if time.tzname[0] != 'CET':
    os.putenv('TZ', 'Europe/Stockholm')
    time.tzset()

LOG = logging.getLogger('AIS')
util.create_directories(
    dirs=[conf.AIS_LOGDIR, conf.AIS_DATADIR, conf.AIS_METADIR]
)

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
    
    suds_log = logging.getLogger('suds')
    suds_log.setLevel(logging.CRITICAL)

def main():
    '''
    Main loop of application
    '''
    command = cp.parse()
    init_logging()
    LOG.info('Starting application')

    if cp.INIT_DB in command:
        LOG.info('Running ' + command)
        db.init_db_client(db_init=True)
        LOG.info('Ending ' + command)
    
    if cp.LOAD_EOD_RACEDAY in command:
        LOG.info('Running ' + command)
        ws_client = ais.init_ws_client(
            conf.AIS_WS_URL,
            conf.AIS_USERNAME,
            conf.AIS_PASSWORD
        )
        params = {
            'client':ws_client,
            'datadir':conf.AIS_DATADIR,
            'metadir':conf.AIS_METADIR,
            'ais_version':conf.AIS_VERSION,
            'ais_type':conf.AIS_TYPE,
            'save_soap_file':True
        }
        ais.load_eod_raceday_into_db(params)
        LOG.info('Ending ' + command)
    
    if cp.EOD_DOWNLOAD in command:
        LOG.info('Running ' + command)
        ws_client = ais.init_ws_client(
            conf.AIS_WS_URL,
            conf.AIS_USERNAME,
            conf.AIS_PASSWORD
        )
        params = {
            'client':ws_client,
            'datadir':conf.AIS_DATADIR,
            'metadir':conf.AIS_METADIR,
            'ais_version':conf.AIS_VERSION,
            'ais_type':conf.AIS_TYPE,
            'save_soap_file':True,
            'raceday_history':conf.AIS_RACEDAY_HISTORY,
            'raceday_exclude':conf.AIS_RACEDAY_EXCLUDE,
            'download_delay':conf.AIS_EOD_DOWNLOAD_DELAY
        }
        ais.eod_download_via_calendar(params)
        LOG.info('Ending ' + command)
    
    if cp.WRITE_META_FILES in command:
        LOG.info('Running ' + command)
        ws_client = ais.init_ws_client(
            conf.AIS_WS_URL,
            conf.AIS_USERNAME,
            conf.AIS_PASSWORD
        )
        util.write_meta_files(client=ws_client, path=conf.AIS_METADIR)
        LOG.info('Ending ' + command)
    
    if cp.SAVE_FILES_IN_CLOUD in command:
        LOG.info('Running ' + command)
        aws_services.save_files_in_aws_s3_bucket(
            sourcefiles=util.list_files_with_path(
                dir_path=conf.AIS_DATADIR),
            bucketname=conf.AIS_S3_EOD_BUCKET,
            host=conf.AIS_S3_HOST,
            username=conf.AIS_S3_USER,
            password=conf.AIS_S3_PASSWORD
        )
        LOG.info('Ending ' + command)

    if cp.EMAIL_LOG_STATS in command:
        LOG.info('Running ' + command)
        util.email_log_stats_and_errors(
            logdir=conf.AIS_LOGDIR,
            logfile=conf.AIS_LOGFILE,
            datadir=conf.AIS_DATADIR,
            subject=conf.EMAIL_LOG_SUBJECT,
            username=conf.EMAIL_LOG_USERNAME,
            password=conf.EMAIL_LOG_PASSWORD,
            from_address=conf.EMAIL_LOG_FROM,
            send_list=conf.EMAIL_LOG_SENDLIST
        )
        LOG.info('Ending ' + command)

    if cp.SAVE_DB_DUMP_IN_CLOUD in command:
        LOG.info('Running ' + command)
        util.save_db_dump_in_cloud(
            dbname=conf.AIS_DB_NAME,
            dumpdir=conf.AIS_DBDUMPDIR,
            bucketname=conf.AIS_S3_DB_DUMP_BUCKET,
            host=conf.AIS_S3_HOST,
            username=conf.AIS_S3_USER,
            password=conf.AIS_S3_PASSWORD
        )
        LOG.info('Ending ' + command)
    
    if cp.DELETE_BUCKET_IN_CLOUD in command:
        LOG.info('Running ' + command)
        aws_services.delete_aws_s3_bucket(host=conf.AIS_S3_HOST)
        LOG.info('Ending ' + command)
    
    if cp.LOAD_EOD_RACINGCARD in command:
        LOG.info('Running ' + command)
        ais.load_eod_racingcard_into_db(datadir=conf.AIS_DATADIR)
        LOG.info('Ending ' + command)
        
    if cp.LOAD_EOD_VPPOOLINFO in command:
        LOG.info('Running ' + command)
        ais.load_eod_vppoolinfo_into_db(datadir=conf.AIS_DATADIR)
        LOG.info('Ending ' + command)
        
    if cp.LOAD_EOD_VPRESULT in command:
        LOG.info('Running ' + command)
        ais.load_eod_vpresult_into_db(datadir=conf.AIS_DATADIR)
        LOG.info('Ending ' + command)

    LOG.info('Ending application')
    logging.shutdown()    
    exit(0)

if __name__ == "__main__":
    main()