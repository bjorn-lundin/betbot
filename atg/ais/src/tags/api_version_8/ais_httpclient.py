#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
A simple straight forward http implementation (compare suds)
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import base64
import urllib2
import ssl
import conf
import logging

LOG = logging.getLogger('AIS')

authorization = \
    'Basic {0}'.format(
        base64.b64encode('{0}:{1}'.format(
            conf.AIS_USERNAME, 
            conf.AIS_PASSWORD))
    )

headers = {
    'Content-Type': 'text/xml; charset=utf-8',
    'Authorization':authorization,
    'Connection':'Keep-Alive'
    }

def get_data(request_data=None):
    '''
    Call AIS service based on request_data and 
    return resulting xml data.
    '''
    request = urllib2.Request(conf.AIS_WS_URL, request_data, headers)
    LOG.debug('Request headers:', request.headers)
    response = None
    data = None
    try:
        response = urllib2.urlopen(
            request, 
            timeout=conf.AIS_EOD_DOWNLOAD_TIMEOUT
        )
    except urllib2.URLError:
        LOG.exception(request_data)
    # Needed when timeout occur with https protocol
    except ssl.SSLError:
        LOG.exception(request_data)
    except:
        LOG.exception('Unexpected exception!\n' + request_data)

    if response is not None:
        LOG.debug('Response headers:', response.headers)
        data = response.read()
        if response.getcode() is not 200:
            LOG.error(
                'Expected response code 200, got ' + 
                str(response.getcode()) + '\n' + 
                'Content in response:\n' + 
                data
            )
            data = None
    return data
            
if __name__ == "__main__":
    pass