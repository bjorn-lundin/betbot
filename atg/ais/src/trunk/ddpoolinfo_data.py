#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
Data handling regarding ddpoolinfo data
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
    racingcard_filelist = [f for f in filelist if 'fetchDDPoolInfo' in f]
    # Get all loaded filenames from db
    loaded_files = []
    for loaded in db.LoadedEODFiles.read_all():
        loaded_files.append(loaded.filename)
    # Compare with filename
    for filepath in racingcard_filelist:
        filename = util.get_filename_from_path(filepath)
        if filename not in loaded_files:
            LOG.info('Parsing ' + filename)
            root = util.get_xml_object(filepath=filepath)
            ddpoolinfo = root.Body.fetchDDPoolInfoResponse.result
            track = db.Track.read(atg_id=int(ddpoolinfo.trackKey.trackId))
            timestamp = util.params_to_datetime(
                year = ddpoolinfo.timestamp.date.year, 
                month = ddpoolinfo.timestamp.date.month, 
                day = ddpoolinfo.timestamp.date.date, 
                hour = ddpoolinfo.timestamp.time.hour, 
                minute = ddpoolinfo.timestamp.time.minute, 
                second = ddpoolinfo.timestamp.time.second, 
                tenth = ddpoolinfo.timestamp.time.tenth
            )
            date = util.strings_to_date(
                ddpoolinfo.date.year,
                ddpoolinfo.date.month,
                ddpoolinfo.date.date
            )
            ddpoolinfo_entity = db.DDPoolInfo.read(track.id, timestamp)
            if ddpoolinfo_entity is None:
                ddpoolinfo_entity = db.DDPoolInfo()
                ddpoolinfo_entity.date = date
                ddpoolinfo_entity.timestamp = timestamp
                ddpoolinfo_entity.pool_closed = bool(ddpoolinfo.poolClosed)
                ddpoolinfo_entity.sale_open = bool(ddpoolinfo.saleOpen)
                ddpoolinfo_entity.turnover_sum = int(ddpoolinfo.turnover.sum)
                ddpoolinfo_entity.turnover_currency = str(ddpoolinfo.turnover.currency)
                ddpoolinfo_entity.bettype_code = str(ddpoolinfo.betType.code)
                ddpoolinfo_entity.bettype_domestic_text = str(ddpoolinfo.betType.domesticText)
                ddpoolinfo_entity.bettype_english_text = str(ddpoolinfo.betType.englishText)
                ddpoolinfo_entity.nr_of_horses_leg_1 = int(ddpoolinfo.nrOfHorsesLegOne)
                ddpoolinfo_entity.nr_of_horses_leg_2 = int(ddpoolinfo.nrOfHorsesLegTwo)
                ddpoolinfo_entity.track_id = track.id
                db.create(ddpoolinfo_entity)
                
                for ddodds in ddpoolinfo.doubleOdds.getchildren():
                    ddodds_entity = db.DDOdds()
                    ddodds_entity.odds = int(ddodds.odds.odds)
                    ddodds_entity.scratched = bool(ddodds.odds.scratched)
                    ddodds_entity.start_nr_leg_1 = int(ddodds.startNrLeg1)
                    ddodds_entity.start_nr_leg_2 = int(ddodds.startNrLeg2)
                    ddodds_entity.ddpoolinfo_id = ddpoolinfo_entity.id
                    db.create(ddodds_entity)

            now = datetime.datetime.now()
            loaded_file = db.LoadedEODFiles(filename=filename, loadtime=now)
            db.create(entity=loaded_file)

def print_all_data(datadir=None):
    '''
    Iterate over all saved (local) ddpoolinfo files and
    print the data.
    '''
    filelist = sorted(util.list_files_with_path(datadir))
    data_filelist = [f for f in filelist if 'fetchDDPoolInfo' in f]
    for filepath in data_filelist:
        filename = util.get_filename_from_path(filepath)
        LOG.debug('Parsing ' + filename)
        
        # Convenience flag when developing
        if False:
            xml = util.clean_xml_namespaces(filepath)
            util.write_file(data=xml, filepath=filename, encoding='utf-8')
            exit(0)
        
        root = util.get_xml_object(filepath=filepath)
        ddpoolinfo = root.Body.fetchDDPoolInfoResponse.result
        print(ddpoolinfo.date.date)
        print(ddpoolinfo.date.month)
        print(ddpoolinfo.date.year)
        print(ddpoolinfo.poolClosed)
        print(ddpoolinfo.saleOpen)
        print(ddpoolinfo.timestamp.date.date)
        print(ddpoolinfo.timestamp.date.month)
        print(ddpoolinfo.timestamp.date.year)
        print(ddpoolinfo.timestamp.time.hour)
        print(ddpoolinfo.timestamp.time.minute)
        print(ddpoolinfo.timestamp.time.second)
        print(ddpoolinfo.timestamp.time.tenth)
        print(ddpoolinfo.track.code)
        print(ddpoolinfo.track.domesticText)
        print(ddpoolinfo.track.englishText)
        print(ddpoolinfo.trackKey.trackId)
        print(ddpoolinfo.turnover.currency)
        print(ddpoolinfo.turnover.sum)
        print(ddpoolinfo.betType.code)
        print(ddpoolinfo.betType.domesticText)
        print(ddpoolinfo.betType.englishText)
        print(ddpoolinfo.nrOfHorsesLegOne)
        print(ddpoolinfo.nrOfHorsesLegTwo)
        
        for ddodds in ddpoolinfo.doubleOdds.getchildren():
            print(ddodds.odds.odds)
            print(ddodds.odds.scratched)
            print(ddodds.startNrLeg1)
            print(ddodds.startNrLeg2)

if __name__ == "__main__":
    pass
    