#-*- coding: utf-8 -*-
'''
AIS configuration file
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import os
import datetime

AIS_TYPE = 'test'
AIS_HOME = '/home/joakim/workspace/ais/trunk'
AIS_DATA = '/home/joakim/projects/ais/latest_dl_error_data'
AIS_VERSION = '9'
AIS_LOGDIR = os.path.normpath(os.path.join(AIS_DATA, 'log'))
AIS_DBDUMPDIR = os.path.normpath(os.path.join(AIS_DATA, 'db_dump'))
AIS_RACEDAY_HISTORY = 6 # Nbr of history days in ATG database
AIS_RACEDAY_EXCLUDE = {
    '2011-10-21':[17], 
    '2011-10-22':[23], 
    '2013-01-30':[54], 
    '2013-04-07':[35], 
    '2013-12-30':[17],
    '2014-08-14':[49]
}
AIS_S3_HOST = 's3-eu-west-1.amazonaws.com'
AIS_EOD_DOWNLOAD_DELAY = 1 # E.g. 0.1 equals 100 ms, 2 equals 2 seconds
AIS_EOD_DOWNLOAD_TIMEOUT = 60 # E.g. 0.1 equals 100 ms, 2 equals 2 seconds

# TODO: Refactor code and remove this 
# (and possibly also AIS_RACEDAY_EXCLUDE)
# 
# I'm gussing the fix is to update Raceday up until current 
# date to incorporate changes (e.g. bettypes) in schedule
AIS_RACEDAY_BETTYPE_EXCLUDE = \
[
    {
        'bettype':'V5', 
        'date':datetime.date(2013,05,10), 
        'track':59
    },
    {
        'bettype':'V3', 
        'date':datetime.date(2013,05,13), 
        'track':32
    },
    {
        'bettype':'Trio',
        'date':datetime.date(2013,07,12),
        'track':67
    },
    {
        'bettype':'Trio',
        'date':datetime.date(2013,11,20),
        'track':78
    },
    {
        'bettype':'Trio',
        'date':datetime.date(2014,01,23),
        'track':77
    },
    {
        'bettype':'V65',
        'date':datetime.date(2014,05,31),
        'track':82
    },
    {
        'bettype':'V65',
        'date':datetime.date(2015,02,06),
        'track':82
    },

]

if AIS_TYPE == 'test':
    AIS_WS_URL = \
        'https://media.atg.se' + \
        '/infostub/PartnerInfoEmulator/version' + \
        AIS_VERSION
    AIS_WSDL_URL = AIS_WS_URL + '?WSDL'
    AIS_USERNAME = ''
    AIS_PASSWORD = ''
    AIS_DATADIR = os.path.normpath(os.path.join(AIS_DATA, 'test_data'))
    AIS_DB_NAME = 'ais-test'
    AIS_DB_URL = 'postgresql:///' + AIS_DB_NAME # Unix socket/domain syntax
    AIS_LOGFILE = 'ais_test.log'
    AIS_S3_EOD_BUCKET = 'ais-end-of-day-data-test'
    AIS_S3_DB_DUMP_BUCKET = 'ais-db-dump-test'
    AIS_S3_USER = ''
    AIS_S3_PASSWORD = ''
    EMAIL_LOG_FROM = '"Nonobet AIS" <ais@nonobet.com>'
    EMAIL_LOG_SENDLIST = ['joakim@birgerson.com']
    EMAIL_LOG_SUBJECT = 'TEST AIS EOD download report'
    EMAIL_LOG_USERNAME = ''
    EMAIL_LOG_PASSWORD = ''

elif AIS_TYPE == 'prod':
    AIS_WS_URL = \
        'https://media.atg.se' + \
        '/info/PartnerInfoService/version' + \
        AIS_VERSION
    AIS_WSDL_URL = AIS_WS_URL + '?WSDL'
    AIS_USERNAME = ''
    AIS_PASSWORD = ''
    AIS_DATADIR = os.path.normpath(os.path.join(AIS_DATA, 'prod_data'))
    AIS_DB_NAME = 'ais_db_prod'
    AIS_DB_URL = 'postgresql://<user>:<pass>@localhost:5432/' + AIS_DB_NAME
    AIS_LOGFILE = 'ais.log'
    AIS_S3_EOD_BUCKET = 'ais-end-of-day-data-prod'
    AIS_S3_DB_DUMP_BUCKET = 'ais-db-dump-prod'
    AIS_S3_USER = ''
    AIS_S3_PASSWORD = ''
    EMAIL_LOG_FROM = '"Nonobet AIS" <ais@nonobet.com>'
    EMAIL_LOG_SENDLIST = ['joakim@birgerson.com']
    EMAIL_LOG_SUBJECT = 'AIS EOD download report'
    EMAIL_LOG_USERNAME = ''
    EMAIL_LOG_PASSWORD = ''

else:
    exit(1)
