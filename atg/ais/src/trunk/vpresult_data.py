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
import decimal

LOG = logging.getLogger('AIS')

def load_into_db(datadir=None):
    filelist = sorted(util.list_files_with_path(datadir))
    racingcard_filelist = [f for f in filelist if 'fetchVPResult' in f]
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
            for vpresult in root.Body.fetchVPResultResponse.result.getchildren():
                date = util.strings_to_date(
                    vpresult.date.year,
                    vpresult.date.month,
                    vpresult.date.date
                )
                track_atg_id = int(vpresult.trackKey.trackId)
                race_nr = int(vpresult.raceNr)
                race = db.Race.read(
                    raceday_date=date, 
                    race_nr=race_nr, 
                    track_atg_id=track_atg_id
                )
                timestamp = util.params_to_datetime(
                    year = vpresult.timestamp.date.year, 
                    month = vpresult.timestamp.date.month, 
                    day = vpresult.timestamp.date.date, 
                    hour = vpresult.timestamp.time.hour, 
                    minute = vpresult.timestamp.time.minute, 
                    second = vpresult.timestamp.time.second, 
                    tenth = vpresult.timestamp.time.tenth
                )
                if race is not None:
                    vpresult_entity = db.VPResult.read(race.id, timestamp)
                    if vpresult_entity is None:
                        vpresult_entity = db.VPResult()
                        vpresult_entity.timestamp = timestamp
                        vpresult_entity.pool_closed = bool(vpresult.poolClosed)
                        vpresult_entity.sale_open = bool(vpresult.saleOpen)
                        vpresult_entity.turnover_win_sum = int(vpresult.turnoverVinnare.sum)
                        vpresult_entity.turnover_place_sum = int(vpresult.turnoverPlats.sum)
                        vpresult_entity.race = race
                        db.create(entity=vpresult_entity)
                        for totestart in vpresult.toteStarts.getchildren():
                            toteresult_entity = db.ToteResult()
                            if totestart.finalOddsPlats.text is not None:
                                toteresult_entity.final_odds_place = decimal.Decimal(str(totestart.finalOddsPlats))
                            if totestart.finalOddsVinnare.text is not None:
                                toteresult_entity.final_odds_win = decimal.Decimal(str(totestart.finalOddsVinnare))
                            toteresult_entity.start_nr = int(totestart.startNr)
                            toteresult_entity.tote_place = int(totestart.totePlace)
                            toteresult_entity.win_km_time = str(totestart.winKmTime)
                            toteresult_entity.vpresult = vpresult_entity
                            db.create(entity=toteresult_entity)
                        
            now = datetime.datetime.now()
            loaded_file = db.LoadedEODFiles(filename=filename, loadtime=now)
            db.create(entity=loaded_file)
                
def print_all_data(datadir=None):
    '''
    Iterate over all saved (local) vppoolinfo files and
    print the data.
    '''
    filelist = sorted(util.list_files_with_path(datadir))
    data_filelist = [f for f in filelist if 'fetchVPResult' in f]
    for filepath in data_filelist:
        filename = util.get_filename_from_path(filepath)
        LOG.debug('Parsing ' + filename)
        
        # Convenience flag when developing
        if False:
            xml = util.clean_xml_namespaces(filepath)
            util.write_file(data=xml, filepath=filename, encoding='utf-8')
            exit()
        
        root = util.get_xml_object(filepath=filepath)
        for vpresult in root.Body.fetchVPResultResponse.result.getchildren():
            print(vpresult.date.date)
            print(vpresult.date.month)
            print(vpresult.date.year)
            print(vpresult.poolClosed)
            print(vpresult.saleOpen)
            print(vpresult.timestamp.date.date)
            print(vpresult.timestamp.date.month)
            print(vpresult.timestamp.date.year)
            print(vpresult.timestamp.time.hour)
            print(vpresult.timestamp.time.minute)
            print(vpresult.timestamp.time.second)
            print(vpresult.timestamp.time.tenth)
            
            print(vpresult.track.code)#
            print(vpresult.track.domesticText)#
            print(vpresult.track.englishText)#
            print(vpresult.trackKey.trackId)#
            print(vpresult.turnover.currency)#
            print(vpresult.turnover.sum)#
            # TODO: For coupled... read 
            # http://www.freepatentsonline.com/article/Southern-Economic-Journal/59653225.html
            print(vpresult.coupledHorsesWinning) # boolean
            print(vpresult.raceNr)
            print(vpresult.turnover.currency, type(vpresult.turnover.currency))
            print(vpresult.turnover.sum, type(vpresult.turnover.sum))
            print(vpresult.turnover.currency.text, type(vpresult.turnover.currency.text))
            print(vpresult.turnover.sum.text, type(vpresult.turnover.sum.text))
            exit()
            print(vpresult.turnoverPlats.currency)
            print(vpresult.turnoverPlats.sum)
            print(vpresult.turnoverVinnare.currency)
            print(vpresult.turnoverVinnare.sum)
            print(vpresult.winStables)
            print(vpresult.scratchings)

            for totestart in vpresult.toteStarts.getchildren():
                print(totestart.finalOddsPlats)
                print(totestart.finalOddsVinnare)
                print(totestart.startNr)
                print(totestart.totePlace)
                print(totestart.winKmTime)
            
if __name__ == "__main__":
    pass
    