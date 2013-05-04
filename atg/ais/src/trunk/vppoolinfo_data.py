#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
Data handling regarding vppoolinfo data
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import logging
import util
import db
import datetime

LOG = logging.getLogger('AIS')

def load_into_db(datadir=None):
    filelist = sorted(util.list_files_with_path(datadir))
    racingcard_filelist = [f for f in filelist if 'fetchVPPoolInfo' in f]
    # Get all loaded filenames from db
    loaded_files = []
    for loaded in db.LoadedEODFiles.read_all():
        loaded_files.append(loaded.filename)
    # Compare with filename
    for filepath in racingcard_filelist:
        filename = util.get_filename_from_path(filepath)
        if filename not in loaded_files:
            now = datetime.datetime.now()
            loaded_file = db.LoadedEODFiles(filename=filename, loadtime=now)
            db.create(entity=loaded_file)

            LOG.info('Parsing ' + util.get_filename_from_path(filename))
            root = util.get_xml_object(filepath)
            print(root)
                        
def print_all_data(datadir=None):
    '''
    Iterate over all saved (local) vppoolinfo files and
    print the data.
    '''
    filelist = sorted(util.list_files_with_path(datadir))
    data_filelist = [f for f in filelist if 'fetchVPPoolInfo' in f]

    for filepath in data_filelist:
        LOG.debug('Parsing ' + util.get_filename_from_path(filepath))
        root = util.get_xml_object(filepath)
        print(root)

if __name__ == "__main__":
    pass
    