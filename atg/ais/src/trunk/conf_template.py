#-*- coding: utf-8 -*-
'''
AIS configuration file
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import os

AIS_TYPE = 'test'
AIS_HOME = '/home/sejoabi/workspace/ais/trunk'
AIS_WS_HOST = 'https://media.atg.se/'
AIS_VERSION = '8'
AIS_LOGDIR = os.path.normpath(os.path.join(AIS_HOME, 'log'))
AIS_METADIR = os.path.normpath(os.path.join(AIS_HOME, 'meta_data'))
AIS_RACEDAY_HISTORY = 6 # Nbr of history days in ATG database
AIS_RACEDAY_EXCLUDE = {17:'2011-10-21', 23:'2011-10-22', 54:'2013-01-30'}
EMAIL_LOG_ERRORS = False
AIS_S3_HOST = 's3-eu-west-1.amazonaws.com'
AIS_EOD_DOWNLOAD_DELAY = 1 # E.g. 0.1 equals 100 ms, 2 equals 2 seconds

if AIS_TYPE == 'test':
    AIS_WS_URL = AIS_WS_HOST + 'infostub/PartnerInfoEmulator/version' + \
                 AIS_VERSION + '?WSDL'
    AIS_USERNAME = ''
    AIS_PASSWORD = ''
    AIS_DATADIR = os.path.normpath(os.path.join(AIS_HOME, 'test_data'))
    AIS_DB_URL = 'postgresql://<user>:<pass>@localhost:5432/ais_test_db'
    AIS_LOGFILE = 'ais_test.log'
    AIS_S3_BUCKET = 'ais-end-of-day-data-test'
    AIS_S3_USER = ''
    AIS_S3_PASSWORD = ''
    EMAIL_LOG_HOST = 'smtprelay1.telia.com'
    EMAIL_LOG_PORT = ''
    EMAIL_LOG_FROM = 'ais@nonobet.com'
    EMAIL_LOG_TO = ['joakim@birgerson.com']
    EMAIL_LOG_SUBJECT = 'AIS ERROR'
    EMAIL_LOG_USER = ''
    EMAIL_LOG_PASS = ''
    EMAIL_LOG_TLS = False

elif AIS_TYPE == 'prod':
    AIS_WS_URL = AIS_WS_HOST + 'info/PartnerInfoService/version' + \
                 AIS_VERSION + '?WSDL'
    AIS_USERNAME = ''
    AIS_PASSWORD = ''
    AIS_DATADIR = os.path.normpath(os.path.join(AIS_HOME, 'prod_data'))
    AIS_DB_URL = 'postgresql://<user>:<pass>@localhost:5432/ais_prod_db'
    AIS_LOGFILE = 'ais.log'
    AIS_S3_BUCKET = 'ais-end-of-day-data-prod'
    AIS_S3_USER = ''
    AIS_S3_PASSWORD = ''
    EMAIL_LOG_HOST = ''
    EMAIL_LOG_PORT = ''
    EMAIL_LOG_FROM = ''
    EMAIL_LOG_TO = []
    EMAIL_LOG_SUBJECT = 'AIS ERROR'
    EMAIL_LOG_USER = ''
    EMAIL_LOG_PASS = ''
    EMAIL_LOG_TLS = False

else:
    exit(1)
