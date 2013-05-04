#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
Data handling regarding racingcard data
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import logging
import util
import ast
import db
import datetime

LOG = logging.getLogger('AIS')

def load_into_db(datadir=None):
    filelist = sorted(util.list_files_with_path(datadir))
    racingcard_filelist = [f for f in filelist if 'fetchRacingCard' in f]
    # Get all loaded filenames from db
    loaded_files = []
    for loaded in db.LoadedEODFiles.read_all():
        loaded_files.append(loaded.filename)
    # Compare with filename
    for filepath in racingcard_filelist:
        filename = util.get_filename_from_path(filepath)
#        if filename not in loaded_files:
        if True:
            LOG.info('Parsing ' + filename)
            print('Parsing ' + filename)
            root = util.get_xml_object(filepath=filepath)
            rc = db.Racingcard()
            data = root.Body.fetchRacingCardResponse.result
            rc.date = util.strings_to_date(
                year=data.date.year.text,
                month=data.date.month.text, 
                date=data.date.date.text
            )
            rc.track_code = data.track.code.text
            rc.bettype_code = data.betType.code.text
            if not db.Racingcard.read(rc):
                all_horses = []
                all_drivers = []
                data = root.Body.fetchRacingCardResponse.result.races
                for race in data.getchildren():
                    race_horses = []
                    race_drivers = []
                    for start in race.starts.getchildren():
                        atg_id = int(start.horse.key.id.text)
                        # Horses (only include horses with an atg id)
                        if atg_id > 0:
                            horse = db.Horse()
                            horse.atg_id = atg_id
                            horse.name = start.horse.key.name.text
                            horse.name_and_nationality = \
                                start.horse.horseNameAndNationality.text
                            horse.seregnr = start.horse.key.seRegNr.text
                            horse.uelnnr = start.horse.key.uelnNr.text
                            if not db.Horse.read(horse):
                                db.create(entity=horse)
                            all_horses.append(horse)
                            race_horses.append(horse)
                        atg_id = int(start.driver.id.text)
                        # Drivers (only include drivers with an atg id)
                        if atg_id > 0:
                            driver = db.Driver()
                            driver.atg_id = atg_id
                            driver.initials = start.driver.initials.text
                            driver.name = start.driver.name.text
                            driver.shortname = start.driver.shortName.text
                            driver.sport = start.driver.sport.text
                            driver.surname = start.driver.surName.text
                            driver.swedish = \
                                ast.literal_eval(start.driver.swedish.text.title())
                            driver.amateur = \
                                ast.literal_eval(start.driver.amateur.text.title())
                            driver.driver_colour = start.driverColour.text
                            if not db.Driver.read(driver):
                                db.create(entity=driver)
                            all_drivers.append(driver)
                            race_drivers.append(driver)
                    db.Race.update_horses_and_drivers(
                        date=rc.date, 
                        track=rc.track_code, 
                        race_number=race.raceNr.text, 
                        horses=race_horses,
                        drivers=race_drivers
                    )
                rc.horses = all_horses
                rc.drivers = all_drivers
                db.create(entity=rc)

            now = datetime.datetime.now()
            loaded_file = db.LoadedEODFiles(filename=filename, loadtime=now)
            db.create(entity=loaded_file)

def print_all_data(datadir=None):
    '''
    Iterate over all saved (local) racecard files and
    print the data.
    
    For parsing examples see http://www.saltycrane.com/blog/2011/07/example-parsing-xml-lxml-objectify/
    '''
    filelist = sorted(util.list_files_with_path(datadir))
    racingcard_filelist = [f for f in filelist if 'fetchRacingCard' in f]

    for filepath in racingcard_filelist:
        LOG.debug('Parsing ' + util.get_filename_from_path(filepath))
        root = util.get_xml_object(filepath)

        date_data = root.Body.fetchRacingCardResponse.result.date
        print(date_data.year.text)
        print(date_data.month.text)
        print(date_data.date.text)
        
        bettype_data = root.Body.fetchRacingCardResponse.result.betType
        print(bettype_data.code.text)
        print(bettype_data.domesticText.text)
        print(bettype_data.englishText.text)
        
        timestamp_data = root.Body.fetchRacingCardResponse.result.timestamp
        print(timestamp_data.date.year.text)
        print(timestamp_data.date.month.text)
        print(timestamp_data.date.date.text)
        print(timestamp_data.time.hour.text)
        print(timestamp_data.time.minute.text)
        print(timestamp_data.time.second.text)
        print(timestamp_data.time.tenth.text)
        
        track_data = root.Body.fetchRacingCardResponse.result.track
        print(track_data.code.text)
        print(track_data.domesticText.text)
        print(track_data.englishText.text)
        
        for race in root.Body.fetchRacingCardResponse.result.races.getchildren():
            print(ast.literal_eval(race.cancelled.text.title()))
            print(race.conditions.raceName.text)
            print(race.conditions.textLong.text)
            print(race.conditions.textShort.text)
            print(race.coupledHorses.text)
            print(ast.literal_eval(race.coupledHorsesInPool.text.title()))
            print(race.distance.text)
            print(ast.literal_eval(race.entriesReleased.text.title()))
            
            try:
                print(race.entryDate.date.year.text)
                print(race.entryDate.date.month.text)
                print(race.entryDate.date.date.text)
            except AttributeError as e:
                LOG.debug(str(e) + ' in race.entryDate')
            
            print(race.gallopRaceInfo.text)
            print(race.postTime.hour.text)
            print(race.postTime.minute.text)
            print(race.postTime.second.text)
            print(race.postTime.tenth.text)
            print(race.postTimeUTC.hour.text)
            print(race.postTimeUTC.minute.text)
            print(race.postTimeUTC.second.text)
            print(race.postTimeUTC.tenth.text)
            print(race.raceNr.text)
            print(race.raceType.code.text)
            print(race.raceType.domesticText.text)
            print(race.raceType.englishText.text)
            print(race.reservorder.text)
            print(ast.literal_eval(race.resultReleased.text.title()))
            print(ast.literal_eval(race.swedish.text.title()))
            print(race.trackState.code.text)
            print(race.trackState.domesticText.text)
            print(race.trackState.englishText.text)
            
            try:
                print(ast.literal_eval(race.trotRaceInfo.monte.text.title()))
                print(race.trotRaceInfo.startMethod.code.text)
                print(race.trotRaceInfo.startMethod.domesticText.text)
                print(race.trotRaceInfo.startMethod.englishText.text)
            except AttributeError as e:
                LOG.debug(str(e) + ' in race.trotRaceInfo')
            
            for start in race.starts.getchildren():
                # Driver
                print(ast.literal_eval(start.driver.amateur.text.title()))
                print(start.driver.id.text)
                print(start.driver.initials.text)
                print(start.driver.name.text)
                print(start.driver.shortName.text)
                print(start.driver.sport.text)
                print(start.driver.surName.text)
                print(ast.literal_eval(start.driver.swedish.text.title()))
                print(ast.literal_eval(start.driverChanged.text.title()))
                print(start.driverColour.text)
                print(start.gallopStartInfo.text)
                # Horse
                print(start.horse.age.text)
                print(start.horse.breed.code.text)
                print(start.horse.breed.domesticText.text)
                print(start.horse.breed.englishText.text)
                print(start.horse.breeder.text)
                print(start.horse.colour.code.text)
                print(start.horse.colour.domesticText.text)
                print(start.horse.colour.englishText.text)
                print(start.horse.dam.id.text)
                print(start.horse.dam.name.text)
                print(start.horse.dam.seRegNr.text)
                print(start.horse.dam.uelnNr.text)
                print(start.horse.damSire.id.text)
                print(start.horse.damSire.name.text)
                print(start.horse.damSire.seRegNr.text)
                print(start.horse.damSire.uelnNr.text)
                print(start.horse.horseNameAndNationality.text)
                print(start.horse.key.id.text)
                print(start.horse.key.name.text)
                print(start.horse.key.seRegNr.text)
                print(start.horse.key.uelnNr.text)
                print(ast.literal_eval(start.horse.linkable.text.title()))
                print(start.horse.nationalityBorn.text)
                print(start.horse.nationalityOwner.text)
                print(start.horse.nationalityRaised.text)
                print(start.horse.owner.text)
                print(start.horse.ownerId.text)
                print(start.horse.sex.code.text)
                print(start.horse.sex.domesticText.text)
                print(start.horse.sex.englishText.text)
                print(start.horse.sire.id.text)
                print(start.horse.sire.name.text)
                print(start.horse.sire.seRegNr.text)
                print(start.horse.sire.uelnNr.text)
                print(ast.literal_eval(start.horse.swedenReg.text.title()))
                print(ast.literal_eval(start.horse.thoroughbred.text.title()))
                # Misc
                print(ast.literal_eval(start.outsideTote.text.title()))
                print(start.startNr.text)
                print(start.startPoint.text)
                # Trainer
                print(ast.literal_eval(start.trainer.amateur.text.title()))
                print(start.trainer.id.text)
                print(start.trainer.initials.text)
                print(start.trainer.name.text)
                print(start.trainer.shortName.text)
                print(start.trainer.sport.text)
                print(start.trainer.surName.text)
                print(ast.literal_eval(start.trainer.swedish.text.title()))

                # trotStartInfo
                try:
                    print(start.trotStartInfo.distance.text)
                    print(start.trotStartInfo.homeTrack.code.text)
                    print(start.trotStartInfo.homeTrack.domesticText.text)
                    print(start.trotStartInfo.homeTrack.englishText.text)
                    print(start.trotStartInfo.postPosition.text)
                except AttributeError as e:
                    LOG.debug(str(e) + ' in start.trotStartInfo')
            
                try:
                    for record in start.trotStartInfo.records.getchildren():
                        print(record.date.year.text)
                        print(record.date.month.text)
                        print(record.date.date.text)
                        print(record.distance.text)
                        print(record.place.text)
                        print(record.raceNr.text)
                        print(record.recType.code.text)
                        print(record.recType.domesticText.text)
                        print(record.recType.englishText.text)
                        print(record.recType.code.text)
                        print(record.place.text)
                        print(record.time.hour.text)
                        print(record.time.minute.text)
                        print(record.time.second.text)
                        print(record.time.tenth.text)
                        print(record.track.code.text)
                        print(record.track.domesticText.text)
                        print(record.track.englishText.text)
                        print(ast.literal_eval(record.winner.text.title()))
                except AttributeError as e:
                    LOG.debug(str(e) + ' in start.trotStartInfo.records')
                
                # Types with same structure, pastPerformances excluded
                stattypes = ['current', 'previous', 'total']
                for stattype in stattypes:
                    horsestat = None 
                    horsestat_string = 'start.horseStat.' + stattype
                    try:
                        horsestat = eval(horsestat_string)
                    except NameError:
                        LOG.exception(
                            'Unexpected error, name "%s should be defined'
                            % horsestat_string
                        )
                    print(horsestat.amAutoRecord.text)
                    try:
                        print(horsestat.autoRecord.date.year.text)
                        print(horsestat.autoRecord.date.month.text)
                        print(horsestat.autoRecord.date.date.text)
                    except AttributeError as e:
                        LOG.debug(str(e) + ' in %s' % horsestat_string)
    
                    try:
                        print(horsestat.autoRecord.distance.text)
                        print(horsestat.autoRecord.place.text)
                        print(horsestat.autoRecord.raceNr.text)
                        print(horsestat.autoRecord.recType.code.text)
                        print(horsestat.autoRecord.recType.domesticText.text)
                        print(horsestat.autoRecord.recType.englishText.text)
                        print(horsestat.autoRecord.time.hour.text)
                        print(horsestat.autoRecord.time.minute.text)
                        print(horsestat.autoRecord.time.second.text)
                        print(horsestat.autoRecord.time.tenth.text)
                        print(horsestat.autoRecord.track.code.text)
                        print(horsestat.autoRecord.track.domesticText.text)
                        print(horsestat.autoRecord.track.englishText.text)
                        print(ast.literal_eval(horsestat.autoRecord.winner.text.title()))
                    except AttributeError as e:
                        LOG.debug(str(e) + ' in %s' % horsestat_string)
                    
                    print(horsestat.bonusEarning.currency.text)
                    print(horsestat.bonusEarning.sum.text)
                    print(horsestat.earning.currency.text)
                    print(horsestat.earning.sum.text)
                    print(horsestat.first.text)
                    print(horsestat.forcedEarning.currency.text)
                    print(horsestat.forcedEarning.sum.text)
                    print(horsestat.nrOfStarts.text)
                    print(horsestat.percent123.text)
                    print(horsestat.percentWin.text)
                    print(horsestat.second.text)
                    print(horsestat.third.text)
                    
                    try:
                        print(horsestat.voltRecord.date.year.text)
                        print(horsestat.voltRecord.date.month.text)
                        print(horsestat.voltRecord.date.date.text)
                    except AttributeError as e:
                        LOG.debug(str(e) + ' in %s' % horsestat_string)
    
                    try:
                        print(horsestat.voltRecord.distance.text)
                        print(horsestat.voltRecord.place.text)
                        print(horsestat.voltRecord.raceNr.text)
                        print(horsestat.voltRecord.recType.code.text)
                        print(horsestat.voltRecord.recType.domesticText.text)
                        print(horsestat.voltRecord.recType.englishText.text)
                        print(horsestat.voltRecord.time.hour.text)
                        print(horsestat.voltRecord.time.minute.text)
                        print(horsestat.voltRecord.time.second.text)
                        print(horsestat.voltRecord.time.tenth.text)
                        print(horsestat.voltRecord.track.code.text)
                        print(horsestat.voltRecord.track.domesticText.text)
                        print(horsestat.voltRecord.track.englishText.text)
                        print(ast.literal_eval(horsestat.voltRecord.winner.text.title()))
                    except AttributeError as e:
                        LOG.debug(str(e) + ' in %s' % horsestat_string)

                    try:
                        print(horsestat.year.year.text)
                        print(horsestat.year.month.text)
                        print(horsestat.year.date.text)
                    except AttributeError as e:
                        LOG.debug(str(e) + ' in %s' % horsestat_string)

                # horseStat pastPerformances
                for resultrow in start.horseStat.pastPerformances.getchildren():
                    print(resultrow.circumstances.distance.text)
                    print(ast.literal_eval(resultrow.circumstances.monte.text.title()))
                    print(resultrow.circumstances.postPosition.text)
                    print(resultrow.circumstances.shoeInfo.text)
                    print(resultrow.circumstances.trackState.code.text)
                    print(resultrow.circumstances.trackState.domesticText.text)
                    print(resultrow.circumstances.trackState.englishText.text)
                    print(ast.literal_eval(resultrow.driver.amateur.text.title()))
                    print(resultrow.driver.id.text)
                    print(resultrow.driver.initials.text)
                    print(resultrow.driver.name.text)
                    print(resultrow.driver.shortName.text)
                    print(resultrow.driver.sport.text)
                    print(resultrow.driver.surName.text)
                    print(ast.literal_eval(resultrow.driver.swedish.text.title()))
                    
                    try:
                        print(resultrow.earning.currency.text)
                        print(resultrow.earning.sum.text)
                    except AttributeError as e:
                        LOG.debug(str(e) + ' in resultrow.earning')
                        
                    print(resultrow.firstPrize.currency.text)
                    print(resultrow.firstPrize.sum.text)
                    print(resultrow.formattedTime.text)
                    print(resultrow.gallopInfo.text)
                    print(ast.literal_eval(resultrow.kmTime.gallop.text.title()))
                    print(resultrow.kmTime.noTimeCode.text)
                    print(resultrow.kmTime.startMethod.text)
                    print(resultrow.kmTime.time.hour.text)
                    print(resultrow.kmTime.time.minute.text)
                    print(resultrow.kmTime.time.second.text)
                    print(resultrow.kmTime.time.tenth.text)
                    print(ast.literal_eval(resultrow.nationalRace.text.title()))
                    print(resultrow.odds.text)
                    print(ast.literal_eval(resultrow.placeInfo.disqualified.text.title()))
                    print(resultrow.placeInfo.formattedResult.text)
                    print(resultrow.placeInfo.place.text)
                    print(ast.literal_eval(resultrow.placeInfo.reported.text.title()))
                    print(ast.literal_eval(resultrow.placeInfo.scratched.text.title()))
                    print(resultrow.placeInfo.scratchedReason.text)
                    print(resultrow.raceKey.date.year.text)
                    print(resultrow.raceKey.date.month.text)
                    print(resultrow.raceKey.date.date.text)
                    print(resultrow.raceKey.raceNr.text)
                    print(ast.literal_eval(resultrow.raceKey.resultExists.text.title()))
                    print(resultrow.raceKey.track.code.text)
                    print(resultrow.raceKey.track.domesticText.text)
                    print(resultrow.raceKey.track.englishText.text)
                    
                    try:
                        print(resultrow.raceKey.trackKey.trackId.text)
                    except AttributeError as e:
                        LOG.debug(str(e) + ' in resultrow.raceKey.trackKey')
                    
                    print(resultrow.raceType.text)
                    print(resultrow.startNr.text)
                    print(ast.literal_eval(resultrow.totalTime.gallop.text.title()))
                    print(resultrow.totalTime.noTimeCode.text)
                    print(resultrow.totalTime.startMethod.text)
                    print(resultrow.totalTime.time.hour.text)
                    print(resultrow.totalTime.time.minute.text)
                    print(resultrow.totalTime.time.second.text)
                    print(resultrow.totalTime.time.tenth.text)

if __name__ == "__main__":
    pass
    