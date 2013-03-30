#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
The main application to run when getting data from AIS
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import os
import command_parser as cp
import errno
import conf
import logging.handlers
import ais
import db
import util
import time
import s3_mgmt

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
    
    suds_log = logging.getLogger('suds')
    suds_log.setLevel(logging.CRITICAL)
    
def email_log_stats_and_errors():
    '''
    Send an email after e.g. EOD download with stats 
    and errors if any.
    '''
    curr_date = util.date_to_string2(util.get_current_date())
    logfile = {'path':conf.AIS_LOGDIR, 'filename':conf.AIS_LOGFILE}
    log = util.read_file(file_name_dict=logfile)

    # If logging framework has rotated logs (created history) during last run,
    # we have to look in '.1' as well
    logfile_hist = {'path':conf.AIS_LOGDIR, 'filename':conf.AIS_LOGFILE + '.1'}
    log_hist = util.read_file(file_name_dict=logfile_hist)

    log_collection = []
    if log_hist:
        log_collection.append(log_hist)
    log_collection.append(log)
    write_count = 0
    error_count = 0
    for log_content in log_collection:
        for row in log_content.split('\n'):
            if curr_date in row:
                if 'Writing' in row:
                    write_count += 1
                if 'ERROR' in row:
                    error_count += 1
    nbr_of_data_files = len(util.list_files(conf.AIS_DATADIR))
    subject = conf.EMAIL_LOG_SUBJECT + ' ' + curr_date
    body = 'Number of written files: %d' % (write_count)
    body += '\n'
    body += 'Number of errors: %d' % (error_count)
    body += '\n'
    body += 'Total number of data files: %d' % (nbr_of_data_files)
    s3_mgmt.send_ses_email(
        username=conf.EMAIL_LOG_USERNAME,
        password=conf.EMAIL_LOG_PASSWORD,
        from_address=conf.EMAIL_LOG_FROM,
        subject=subject,
        body=body,
        send_list=conf.EMAIL_LOG_SENDLIST
    )

def main():
    '''
    Main loop of application
    '''
    command = cp.parse()
    init_logging()
    LOG.info('Starting application')

    if cp.INIT_DB in command:
        LOG.info('Running ' + cp.INIT_DB)
        db.init_db_client(db_init=True)
    ws_client = None
    if cp.INIT_LOCAL_RACEDAYS in command:
        LOG.info('Running ' + cp.INIT_LOCAL_RACEDAYS)
        if not ws_client:
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
        ais.load_calendar_history_into_db(params)
    
    if cp.EOD_DOWNLOAD in command:
        LOG.info('Running ' + cp.EOD_DOWNLOAD)
        if not ws_client:
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
        LOG.info('Running ' + cp.EMAIL_LOG_STATS)
        email_log_stats_and_errors()
    
    if cp.WRITE_META_FILES in command:
        LOG.info('Running ' + cp.WRITE_META_FILES)
        if not ws_client:
            ws_client = ais.init_ws_client(
                conf.AIS_WS_URL,
                conf.AIS_USERNAME,
                conf.AIS_PASSWORD
            )
        util.write_meta_files(client=ws_client, path=conf.AIS_METADIR)
    
    if cp.SAVE_FILES_IN_CLOUD in command:
        LOG.info('Running ' + cp.SAVE_FILES_IN_CLOUD)
        connection = s3_mgmt.get_aws_s3_connections(
            username=conf.AIS_S3_USER,
            password=conf.AIS_S3_PASSWORD
        )
        bucket = s3_mgmt.init_aws_s3_bucket(
            connection=connection,
            bucketname=conf.AIS_S3_BUCKET
        )
        s3_mgmt.save_files_in_aws_s3_bucket(
            from_datadir=conf.AIS_DATADIR, bucket=bucket
        )
        if connection:
            connection.close()
            
    if cp.EMAIL_LOG_STATS in command:
        LOG.info('Running ' + cp.EMAIL_LOG_STATS)
        email_log_stats_and_errors()
        
    LOG.info('Ending application')
    logging.shutdown()    
    exit(0)

if __name__ == "__main__":
    main()