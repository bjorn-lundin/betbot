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
import aws_services
import subprocess as sp

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
    aws_services.send_ses_email(
        username=conf.EMAIL_LOG_USERNAME,
        password=conf.EMAIL_LOG_PASSWORD,
        from_address=conf.EMAIL_LOG_FROM,
        subject=subject,
        body=body,
        send_list=conf.EMAIL_LOG_SENDLIST
    )

def save_db_dump_in_cloud(db_name=None, dump_dir=None, bucket=None):
    '''
    Run commands to create db dump directory and
    generating a db dump into it.
    '''
    try:
        os.makedirs(dump_dir)
    except OSError as exception:
        if exception.errno != errno.EEXIST:
            LOG.exception()
    chmod_bin = '/bin/chmod'
    sudo_bin = '/usr/bin/sudo'
    su_bin = '/bin/su'
    pg_dump_bin = '/usr/bin/pg_dump'
    db_superuser = 'postgres'
    chmod_command = [chmod_bin, '777', dump_dir]
    proc = sp.Popen(chmod_command, stdout=sp.PIPE, stderr=sp.PIPE)
    error = proc.communicate()[1]
    file_path = None
    if not error:
        file_path = os.path.join(dump_dir, db_name + '.dmp')
        file_path = os.path.normpath(file_path)
        dump_command = [
            sudo_bin, su_bin, '-', '-c',
            pg_dump_bin + ' ' + db_name + '>' + \
            file_path, db_superuser
        ]
        proc = sp.Popen(dump_command, stdout=sp.PIPE, stderr=sp.PIPE)
        error = proc.communicate()[1]
        if error:
            LOG.error(
                'Need sudo rights without password.\n' +
                'E.g. "ubuntu ALL=(ALL) NOPASSWD:ALL" in /etc/sudoers. ' +
                'Use command visudo.'
            )
            LOG.error(error)
    else:
        LOG.error(error)
    if not error:
        aws_services.save_file_in_aws_s3_bucket(
            file_path=file_path,
            bucket=bucket,
            replace=True
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
    
    if cp.INIT_LOCAL_RACEDAYS in command:
        LOG.info('Running ' + cp.INIT_LOCAL_RACEDAYS)
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
        ws_client = ais.init_ws_client(
            conf.AIS_WS_URL,
            conf.AIS_USERNAME,
            conf.AIS_PASSWORD
        )
        util.write_meta_files(client=ws_client, path=conf.AIS_METADIR)
    
    if cp.SAVE_FILES_IN_CLOUD in command:
        LOG.info('Running ' + cp.SAVE_FILES_IN_CLOUD)
        connection = aws_services.get_aws_s3_connections(
            username=conf.AIS_S3_USER,
            password=conf.AIS_S3_PASSWORD
        )
        bucket = aws_services.init_aws_s3_bucket(
            connection=connection,
            bucketname=conf.AIS_S3_EOD_BUCKET
        )
        aws_services.save_files_in_aws_s3_bucket(
            from_datadir=conf.AIS_DATADIR, bucket=bucket
        )
        if connection:
            connection.close()
            
    if cp.EMAIL_LOG_STATS in command:
        LOG.info('Running ' + cp.EMAIL_LOG_STATS)
        email_log_stats_and_errors()

    if cp.SAVE_DB_DUMP_IN_CLOUD in command:
        LOG.info('Running ' + cp.SAVE_DB_DUMP_IN_CLOUD)
        connection = aws_services.get_aws_s3_connections(
            username=conf.AIS_S3_USER,
            password=conf.AIS_S3_PASSWORD
        )
        bucket = aws_services.init_aws_s3_bucket(
            connection=connection,
            bucketname=conf.AIS_S3_DB_DUMP_BUCKET,
            versioning=False
        )
        save_db_dump_in_cloud(
            db_name=conf.AIS_DB_NAME,
            dump_dir=conf.AIS_DBDUMPDIR,
            bucket=bucket
        )
        if connection:
            connection.close()
    
    if cp.DELETE_BUCKET_IN_CLOUD in command:
        LOG.info('Running ' + cp.DELETE_BUCKET_IN_CLOUD)
        aws_services.delete_aws_s3_bucket(
            host=conf.AIS_S3_HOST,
            username=conf.AIS_S3_USER,
            password=conf.AIS_S3_PASSWORD
        )
        LOG.info('Ending ' + cp.DELETE_BUCKET_IN_CLOUD)
        
    LOG.info('Ending application')
    logging.shutdown()    
    exit(0)

if __name__ == "__main__":
    main()