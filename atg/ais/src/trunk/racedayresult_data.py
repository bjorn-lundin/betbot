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
    '''
    Iterate over all saved (local) racedayresult files and
    load the data into database
    '''
    filelist = sorted(util.list_files_with_path(datadir))
    racingcard_filelist = [f for f in filelist if 'fetchRaceDayResult' in f]
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
            ddresult = root.Body.fetchDDResultResponse.result
            date = util.strings_to_date(
                ddresult.date.year,
                ddresult.date.month,
                ddresult.date.date
            )
            timestamp = util.params_to_datetime(
                year = ddresult.timestamp.date.year, 
                month = ddresult.timestamp.date.month, 
                day = ddresult.timestamp.date.date, 
                hour = ddresult.timestamp.time.hour, 
                minute = ddresult.timestamp.time.minute, 
                second = ddresult.timestamp.time.second, 
                tenth = ddresult.timestamp.time.tenth
            )
            track_atg_id = int(ddresult.trackKey.trackId)
            track = db.Track.read(atg_id=track_atg_id)
            bettype_code = unicode(ddresult.betType.code)
            bettype = db.Bettype.read(name_code=bettype_code)
            ddresult_entity = db.DDResult.read(date=date, track_id=track.id)
            if ddresult_entity is None:
                ddresult_entity = db.DDResult()
                ddresult_entity.date = date
                ddresult_entity.timestamp = timestamp
                ddresult_entity.pool_closed = bool(ddresult.poolClosed)
                ddresult_entity.sale_open = bool(ddresult.saleOpen)
                ddresult_entity.turnover_sum = int(ddresult.turnover.sum)
                ddresult_entity.turnover_currency = unicode(ddresult.turnover.currency)
                ddresult_entity.final_odds = decimal.Decimal(unicode(ddresult.finalOddses.FinalDoubleOdds.finalOdds))
                ddresult_entity.start_nr_leg_1 = int(ddresult.finalOddses.FinalDoubleOdds.startNrLeg1)
                ddresult_entity.start_nr_leg_2 = int(ddresult.finalOddses.FinalDoubleOdds.startNrLeg2)
                ddresult_entity.scratched_leg_1 = unicode(ddresult.scratchedLeg1)
                ddresult_entity.scratched_leg_2 = unicode(ddresult.scratchedLeg2)
                ddresult_entity.possible_oddses = unicode(ddresult.possibleOddses)
                ddresult_entity.winners_leg_1 = int(ddresult.winnersLeg1.int)
                ddresult_entity.winners_leg_2 = int(ddresult.winnersLeg2.int)
                ddresult_entity.track_id = track.id
                ddresult_entity.bettype_id = bettype.id
                db.create(entity=ddresult_entity)
            now = datetime.datetime.now()
            loaded_file = db.LoadedEODFiles(filename=filename, loadtime=now)
            db.create(entity=loaded_file)

def print_all_data(datadir=None):
    '''
    Iterate over all saved (local) racedayresult files and
    print the data.
    '''
    filelist = sorted(util.list_files_with_path(datadir))
    data_filelist = [f for f in filelist if 'fetchRaceDayResult' in f]
    for filepath in data_filelist:
        filename = util.get_filename_from_path(filepath)
        LOG.debug('Parsing ' + filename)
        xml_string = util.get_cleaned_xml_string(filepath=filepath)
        
        # Convenience flag when developing
        if False:
            util.write_file(
                data=util.get_html_unescape(html_string=xml_string),
                filepath=filename, 
                encoding='utf-8'
            )
            exit(0)
        
        root = util.xml_string_to_object(xml_string=xml_string)
        racedayresult = root.Body.fetchRaceDayResultResponse.result
        print(racedayresult.date.year)
        print(racedayresult.date.month)
        print(racedayresult.date.date)
        
        for raceresult in racedayresult.races.getchildren():
            print(raceresult.cancelled)
            print(raceresult.conditions.raceName)
            print(raceresult.conditions.textLong)
            print(raceresult.conditions.textShort)

            print(raceresult.coupledHorses)
            print(raceresult.coupledHorsesInPool)
            print(raceresult.distance)
            print(raceresult.entriesReleased)
            
            try:
                print(raceresult.entryDate.date.year)
                print(raceresult.entryDate.date.month)
                print(raceresult.entryDate.date.date)
                print(raceresult.entryDate.time.hour)
                print(raceresult.entryDate.time.minute)
                print(raceresult.entryDate.time.second)
                print(raceresult.entryDate.time.tenth)
            except AttributeError as e:
                LOG.debug(str(e) + ' in raceresult.entryDate')
        
            print(raceresult.gallopRaceInfo)
            
            print(raceresult.postTime.hour)
            print(raceresult.postTime.minute)
            print(raceresult.postTime.second)
            print(raceresult.postTime.tenth)
            print(raceresult.postTimeUTC.hour)
            print(raceresult.postTimeUTC.minute)
            print(raceresult.postTimeUTC.second)
            print(raceresult.postTimeUTC.tenth)
            
            print(raceresult.raceNr)
            print(raceresult.raceType.code)
            print(raceresult.raceType.domesticText)
            print(raceresult.raceType.englishText)
            
            print(raceresult.reservorder)
            print(raceresult.resultReleased)
            print(raceresult.swedish)

            print(raceresult.trackState.code)
            print(raceresult.trackState.domesticText)
            print(raceresult.trackState.englishText)
            
            try:
                print(raceresult.trotRaceInfo.monte)
                print(raceresult.trotRaceInfo.startMethod.code)
                print(raceresult.trotRaceInfo.startMethod.domesticText)
                print(raceresult.trotRaceInfo.startMethod.englishText)
            except AttributeError as e:
                LOG.debug(str(e) + ' in raceresult.trotRaceInfo')

            
            for startresult in raceresult.starts.getchildren():
                print(startresult.driver.amateur)
                print(startresult.driver.id)
                print(startresult.driver.initials)
                print(startresult.driver.name)
                print(startresult.driver.shortName)
                print(startresult.driver.sport)
                print(startresult.driver.surName)
                print(startresult.driver.swedish)
            
                print(startresult.driverChanged)
                print(startresult.driverColour)
                print(startresult.gallopStartInfo)
            
                print(startresult.horse.age)
                print(startresult.horse.breed.code)
                print(startresult.horse.breed.domesticText)
                print(startresult.horse.breed.englishText)
                print(startresult.horse.breeder)
                print(startresult.horse.colour.code)
                print(startresult.horse.colour.domesticText)
                print(startresult.horse.colour.englishText)
                print(startresult.horse.dam.id)
                print(startresult.horse.dam.name)
                print(startresult.horse.dam.seRegNr)
                print(startresult.horse.dam.uelnNr)
                print(startresult.horse.damSire.id)
                print(startresult.horse.damSire.name)
                print(startresult.horse.damSire.seRegNr)
                print(startresult.horse.damSire.uelnNr)
                print(startresult.horse.horseNameAndNationality)
                print(startresult.horse.key.id)
                print(startresult.horse.key.name)
                print(startresult.horse.key.seRegNr)
                print(startresult.horse.key.uelnNr)
                
                print(startresult.horse.linkable)
                print(startresult.horse.nationalityBorn)
                print(startresult.horse.nationalityOwner)
                print(startresult.horse.nationalityRaised)
                print(startresult.horse.owner)
                print(startresult.horse.ownerId)
                print(startresult.horse.sex.code)
                print(startresult.horse.sex.domesticText)
                print(startresult.horse.sex.englishText)
                print(startresult.horse.sire.id)
                print(startresult.horse.sire.name)
                print(startresult.horse.sire.seRegNr)
                print(startresult.horse.sire.uelnNr)
                print(startresult.horse.swedenReg)
                print(startresult.horse.thoroughbred)
                
                print(startresult.outsideTote)
                print(startresult.startNr)
                print(startresult.startPoint)
                
                print(startresult.trainer.amateur)
                print(startresult.trainer.id)
                print(startresult.trainer.initials)
                print(startresult.trainer.name)
                print(startresult.trainer.shortName)
                print(startresult.trainer.sport)
                print(startresult.trainer.surName)
                print(startresult.trainer.swedish)

                try:
                    print(startresult.trotStartInfo.distance)
                    print(startresult.trotStartInfo.homeTrack.code)
                    print(startresult.trotStartInfo.homeTrack.domesticText)
                    print(startresult.trotStartInfo.homeTrack.englishText)
                    print(startresult.trotStartInfo.postPosition)
                    for record in startresult.trotStartInfo.records.getchildren():
                        print(record.date.year)
                        print(record.date.month)
                        print(record.date.date)
                except AttributeError as e:
                    LOG.debug(str(e) + ' in startresult.trotStartInfo')
                
                    print(record.distance)
                    print(record.place)
                    print(record.raceNr)
                    
                    print(record.recType.code)
                    print(record.recType.domesticText)
                    print(record.recType.englishText)
                    
                    print(record.time.hour)
                    print(record.time.minute)
                    print(record.time.second)
                    print(record.time.tenth)
                
                    print(record.track.code)
                    print(record.track.domesticText)
                    print(record.track.englishText)
                
                    print(record.winner)
                
                print(startresult.earning.currency)
                print(startresult.earning.sum)
                print(startresult.finishingPosition)
                print(startresult.kmTime.gallop)
                print(startresult.kmTime.noTimeCode)
                print(startresult.kmTime.startMethod)
                print(startresult.kmTime.time.hour)
                print(startresult.kmTime.time.minute)
                print(startresult.kmTime.time.second)
                print(startresult.kmTime.time.tenth)
                
                print(startresult.odds)
                print(startresult.place.disqualified)
                print(startresult.place.formattedResult)
                print(startresult.place.place)
                print(startresult.place.reported)
                print(startresult.place.scratched)
                print(startresult.place.scratchedReason)
                
                try:
                    print(startresult.shoeInfo.foreshoes)
                    print(startresult.shoeInfo.hindshoes)
                except AttributeError as e:
                    LOG.debug(str(e) + ' in startresult.shoeInfo')
                
                try:
                    print(startresult.totalTime.gallop)
                    print(startresult.totalTime.noTimeCode)
                    print(startresult.totalTime.startMethod)
                    print(startresult.totalTime.time.hour)
                    print(startresult.totalTime.time.minute)
                    print(startresult.totalTime.time.second)
                    print(startresult.totalTime.time.tenth)
                except AttributeError as e:
                    LOG.debug(str(e) + ' in startresult.totalTime')

            print(raceresult.winMargin)
        print(racedayresult.timestamp.date.year)
        print(racedayresult.timestamp.date.month)
        print(racedayresult.timestamp.date.date)
        print(racedayresult.timestamp.time.hour)
        print(racedayresult.timestamp.time.minute)
        print(racedayresult.timestamp.time.second)
        print(racedayresult.timestamp.time.tenth)
        
        print(racedayresult.track.code)
        print(racedayresult.track.domesticText)
        print(racedayresult.track.englishText)
        
        
        
# TODO: Finish this work when moved to AIS v. 9


#         exit(0)
        
if __name__ == "__main__":
    pass
