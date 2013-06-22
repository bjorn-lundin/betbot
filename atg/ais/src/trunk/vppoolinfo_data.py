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
            LOG.info('Parsing ' + filename)
            root = util.get_xml_object(filepath=filepath)
            for vppoolinfo in root.Body.fetchVPPoolInfoResponse.result.getchildren():
                date = util.strings_to_date(
                    vppoolinfo.date.year,
                    vppoolinfo.date.month,
                    vppoolinfo.date.date
                )
                track_atg_id = int(vppoolinfo.trackKey.trackId)
                race_nr = int(vppoolinfo.raceNr)
                race = db.Race.read(
                    raceday_date=date, 
                    race_nr=race_nr, 
                    track_atg_id=track_atg_id
                )
                if race is None:
                    message = (
                        'Race {0} (date: {1}, track: {2})' + \
                        ' is missing in {3}'
                        ).format(
                            race_nr, 
                            date, 
                            track_atg_id, 
                            filename
                        )
                    LOG.info(message)
                    continue
                timestamp = util.params_to_datetime(
                    year = vppoolinfo.timestamp.date.year, 
                    month = vppoolinfo.timestamp.date.month, 
                    day = vppoolinfo.timestamp.date.date, 
                    hour = vppoolinfo.timestamp.time.hour, 
                    minute = vppoolinfo.timestamp.time.minute, 
                    second = vppoolinfo.timestamp.time.second, 
                    tenth = vppoolinfo.timestamp.time.tenth
                )
                vppoolinfo_entity = db.VPPoolInfo.read(race.id, timestamp)
                if vppoolinfo_entity is None:
                    vppoolinfo_entity = db.VPPoolInfo()
                    vppoolinfo_entity.timestamp = timestamp
                    vppoolinfo_entity.pool_closed = bool(vppoolinfo.poolClosed)
                    vppoolinfo_entity.sale_open = bool(vppoolinfo.saleOpen)
                    vppoolinfo_entity.number_of_horses = int(vppoolinfo.numberOfHorses)
                    vppoolinfo_entity.turnover_win_sum = int(vppoolinfo.turnoverVinnare.sum)
                    vppoolinfo_entity.turnover_win_currency = str(vppoolinfo.turnoverVinnare.currency)
                    vppoolinfo_entity.turnover_place_sum = int(vppoolinfo.turnoverPlats.sum)
                    vppoolinfo_entity.turnover_place_currency = str(vppoolinfo.turnoverPlats.currency)
                    vppoolinfo_entity.race = race
                    db.create(entity=vppoolinfo_entity)
                
                for vpodds in vppoolinfo.vpOdds.getchildren():
                    start_nr = int(vpodds.startNr)
                    vpodds_entity = db.Vpodds.read(race_id=race.id, start_nr=start_nr)
                    if vpodds_entity is None:
                        vpodds_entity = db.Vpodds()
                        vpodds_entity.invest_place_sum = int(vpodds.investmentPlats.sum)
                        vpodds_entity.invest_place_currency = str(vpodds.investmentPlats.currency)
                        vpodds_entity.invest_win_sum = int(vpodds.investmentVinnare.sum)
                        vpodds_entity.invest_win_currency = str(vpodds.investmentVinnare.currency)
                        vpodds_entity.place_max_odds = int(vpodds.platsOdds.maxOdds.odds)
                        vpodds_entity.place_max_scratched = bool(vpodds.platsOdds.maxOdds.scratched)
                        vpodds_entity.place_min_odds = int(vpodds.platsOdds.minOdds.odds)
                        vpodds_entity.place_min_scratched = bool(vpodds.platsOdds.minOdds.scratched)
                        vpodds_entity.scratched = bool(vpodds.scratched)
                        vpodds_entity.start_nr = int(vpodds.startNr)
                        vpodds_entity.win_odds = int(vpodds.vinnarOdds.odds)
                        vpodds_entity.win_scratched = bool(vpodds.vinnarOdds.scratched)
                        vpodds_entity.race = race
                        db.create(entity=vpodds_entity)
                
            now = datetime.datetime.now()
            loaded_file = db.LoadedEODFiles(filename=filename, loadtime=now)
            db.create(entity=loaded_file)
                
def print_all_data(datadir=None):
    '''
    Iterate over all saved (local) vppoolinfo files and
    print the data.
    '''
    filelist = sorted(util.list_files_with_path(datadir))
    data_filelist = [f for f in filelist if 'fetchVPPoolInfo' in f]
    for filepath in data_filelist:
        filename = util.get_filename_from_path(filepath)
        LOG.debug('Parsing ' + filename)
        xml_string = util.get_cleaned_xml_string(filepath=filepath)
        
        # Convenience flag when developing
        if False:
            util.write_file(
                data=xml_string, 
                filepath=filename, 
                encoding='utf-8'
            )
            exit(0)
        
        root = util.xml_string_to_object(xml_string=xml_string)
        for vppoolinfo in root.Body.fetchVPPoolInfoResponse.result.getchildren():
            print(vppoolinfo.date.date)
            print(vppoolinfo.date.month)
            print(vppoolinfo.date.year)
            print(vppoolinfo.poolClosed)
            print(vppoolinfo.saleOpen)
            print(vppoolinfo.timestamp.date.date)
            print(vppoolinfo.timestamp.date.month)
            print(vppoolinfo.timestamp.date.year)
            print(vppoolinfo.timestamp.time.hour)
            print(vppoolinfo.timestamp.time.minute)
            print(vppoolinfo.timestamp.time.second)
            print(vppoolinfo.timestamp.time.tenth)
            print(vppoolinfo.track.code)
            print(vppoolinfo.track.domesticText)
            print(vppoolinfo.track.englishText)
            print(vppoolinfo.trackKey.trackId)
            print(vppoolinfo.turnover.currency)
            print(vppoolinfo.turnover.sum)
            print(vppoolinfo.coupledHorsesInPool)
            print(vppoolinfo.coupledOddsArr)
            print(vppoolinfo.numberOfHorses)
            print(vppoolinfo.raceNr)
            print(vppoolinfo.turnoverPlats.currency)
            print(vppoolinfo.turnoverPlats.sum)
            print(vppoolinfo.turnoverVinnare.currency)
            print(vppoolinfo.turnoverVinnare.sum)
            for vpodds in vppoolinfo.vpOdds.getchildren():
                print(vpodds.investmentPlats.currency)
                print(vpodds.investmentPlats.sum)
                print(vpodds.investmentVinnare.currency)
                print(vpodds.investmentVinnare.sum)
                print(vpodds.platsOdds.maxOdds.odds)
                print(vpodds.platsOdds.maxOdds.scratched)
                print(vpodds.platsOdds.minOdds.odds)
                print(vpodds.platsOdds.minOdds.scratched)
                print(vpodds.scratched)
                print(vpodds.startNr)
                print(vpodds.vinnarOdds.odds)
                print(vpodds.vinnarOdds.scratched)

if __name__ == "__main__":
    pass
    