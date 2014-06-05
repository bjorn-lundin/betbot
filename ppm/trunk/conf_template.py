#-*- coding: utf-8 -*-
'''PPM configuration file

DB_SSL possible values:
disable, allow, prefer, require, verify-ca, verify-full
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals

PPM_TYPE = 'test'

if PPM_TYPE == 'test':
    LOGDIR = '/home/sejoabi/workspace_ppm/ppm/trunk/log'
    DATADIR = '/home/sejoabi/workspace_ppm/ppm/trunk/ppm_data'
    DB_SERVER = 'localhost'
    DB_PORT = '5432'
    DB_NAME = 'ppm'
    DB_USER = 'ppm'
    DB_PASSWORD = 'ppm'
    DB_URL = 'postgresql://' + DB_USER + ':' + DB_PASSWORD + '@' + DB_SERVER + ':' + DB_PORT + '/' + DB_NAME
    DB_SSL = 'allow'

elif PPM_TYPE == 'prod':
    DB_SSL = 'require'

