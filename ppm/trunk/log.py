#!/usr/bin/env python

'''
Log implementation
'''
from __future__ import division, absolute_import, print_function
import logging.handlers
import conf

logger = logging.getLogger('ppm')
log_level = logging.INFO
logger.setLevel(log_level)
filehandle = logging.handlers.RotatingFileHandler(
    conf.LOGDIR + '/ppm.log',
    mode = 'a',
    maxBytes = 5000000,
    backupCount = 10,
    encoding = 'utf-8',
    delay = 0) 
filehandle.setLevel(log_level)
format_string = '%(asctime)s %(name)s %(levelname)s %(message)s'
formatter = logging.Formatter(format_string)
filehandle.setFormatter(formatter)
logger.addHandler(filehandle)

def shutdown():
    logging.shutdown()
