'''
AIS configuration file
'''
from __future__ import unicode_literals

TEST = True

WSDL_URL = None
USERNAME = None
PASSWORD = None
DATADIR = None
DB_URL = None

if TEST:
    WSDL_URL = 'https://media.atg.se/infostub/PartnerInfoEmulator/version8?WSDL'
    USERNAME = ''
    PASSWORD = ''
    DATADIR = ''
    DB_URL = ''
else:
    WSDL_URL = ''
    USERNAME = ''
    PASSWORD = ''
    DATADIR = ''
    DB_URL = ''
