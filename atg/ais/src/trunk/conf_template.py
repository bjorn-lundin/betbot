#-*- coding: utf-8 -*-
'''
AIS configuration file
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals

AIS_WS_HOST = 'https://media.atg.se/'
AIS_VERSION = '8'
AIS_LOGDIR = 'log'
AIS_METADIR = 'meta_data'
EMAIL_LOG_ERRORS = False

AIS_TYPE = 'test'

if AIS_TYPE == 'test':
    AIS_WS_URL = AIS_WS_HOST + 'infostub/PartnerInfoEmulator/version' + \
                 AIS_VERSION + '?WSDL'
    AIS_USERNAME = ''
    AIS_PASSWORD = ''
    AIS_DATADIR = 'test_data'
    AIS_DB_URL = 'postgresql://<user>:<pass>@localhost:5432/ais_test_db'
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
    AIS_DATADIR = 'prod_data'
    AIS_DB_URL = 'postgresql://<user>:<pass>@localhost:5432/ais_prod_db'
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
