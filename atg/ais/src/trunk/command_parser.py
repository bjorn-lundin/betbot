#-*- coding: utf-8 -*-
'''
Parse command line options
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
from optparse import OptionParser

INIT_DB = 'init_db'
LOAD_EOD_RACEDAY = 'load_eod_raceday'
EOD_DOWNLOAD = 'eod_download'
WRITE_META_FILES = 'write_meta_files'
SAVE_FILES_IN_CLOUD = 'save_files_in_cloud'
PRINT_VERSIONS_FROM_CLOUD = 'print_versions_from_cloud'
DELETE_BUCKET_IN_CLOUD = 'delete_bucket_in_cloud'
EMAIL_LOG_STATS = 'email_log_stats'
SAVE_DB_DUMP_IN_CLOUD = 'save_db_dump_in_cloud'
LOAD_EOD_RACINGCARD = 'load_eod_racingcard'
LOAD_EOD_VPPOOLINFO = 'load_eod_vppoolinfo'
LOAD_EOD_VPRESULT = 'load_eod_vpresult'
LOAD_EOD_DDPOOLINFO = 'load_eod_ddpoolinfo'
LOAD_EOD_DDRESULT = 'load_eod_ddresult'

def parse():
    '''
    Parse commands
    '''
    command_list = [
        INIT_DB,
        LOAD_EOD_RACEDAY,
        EOD_DOWNLOAD,
        WRITE_META_FILES,
        SAVE_FILES_IN_CLOUD,
        PRINT_VERSIONS_FROM_CLOUD,
        DELETE_BUCKET_IN_CLOUD,
        EMAIL_LOG_STATS,
        SAVE_DB_DUMP_IN_CLOUD,
        LOAD_EOD_RACINGCARD,
        LOAD_EOD_VPPOOLINFO,
        LOAD_EOD_VPRESULT,
        LOAD_EOD_DDPOOLINFO,
        LOAD_EOD_DDRESULT
    ]
    usage_string = "usage: %(prog)s " + \
        "[%(com0)s|%(com1)s|%(com2)s|%(com3)s|" + \
        "%(com4)s|%(com5)s|%(com6)s|%(com7)s]|" + \
        "%(com8)s|%(com9)s|%(com10)s|%(com11)s]" + \
        "%(com12)s|%(com13)s]"
    usage = usage_string % \
    {
        'prog':'%prog',
        'com0':command_list[0],
        'com1':command_list[1],
        'com2':command_list[2], 
        'com3':command_list[3],
        'com4':command_list[4],
        'com5':command_list[5],
        'com6':command_list[6],
        'com7':command_list[7],
        'com8':command_list[8],
        'com9':command_list[9],
        'com10':command_list[10],
        'com11':command_list[11],
        'com12':command_list[12],
        'com13':command_list[13],
    }
    parser = OptionParser(usage)
    args = parser.parse_args()[1]
    if len(args) != 1:
        parser.error("Please state the command to run")
    if args[0] not in command_list:
        parser.error("The stated command does not exist")
    return args[0]