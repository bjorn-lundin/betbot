#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
Data handling regarding raceday data
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
    racingcard_filelist = [f for f in filelist if 'fetchRaceDayCalendar' in f]
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
            racedaycalendar = root.Body.fetchRaceDayCalendarResponse.result
            from_date = util.strings_to_date(
                racedaycalendar.fromdate.year,
                racedaycalendar.fromdate.month,
                racedaycalendar.fromdate.date
            )
            to_date = util.strings_to_date(
                racedaycalendar.todate.year,
                racedaycalendar.todate.month,
                racedaycalendar.todate.date
            )
            racedaycalendar_entity = \
                db.RacedayCalendar.read(from_date, to_date)
            if racedaycalendar_entity is None:
                racedaycalendar_entity = db.RacedayCalendar()
                racedaycalendar_entity.from_date = from_date
                racedaycalendar_entity.to_date = to_date
                db.create(racedaycalendar_entity)
            for racedayinfo in racedaycalendar.raceDayInfos.getchildren():
                track_atg_id = int(racedayinfo.trackKey.trackId)
                track = db.Track.read(atg_id=track_atg_id)
                if track is None:
                    track = db.Track()
                    track.atg_id = track_atg_id
                    track.code = unicode(racedayinfo.track.code)
                    track.domestic_text = unicode(racedayinfo.track.domesticText)
                    track.english_text = str(racedayinfo.track.englishText)
                    db.create(track)
                raceday_date = util.strings_to_date(
                    racedayinfo.raceDayDate.year,
                    racedayinfo.raceDayDate.month,
                    racedayinfo.raceDayDate.date
                )
                raceday = db.Raceday.read(track_id=track.id, raceday_date=raceday_date)
                if raceday is None:
                    raceday = db.Raceday()
                    raceday.country_code = str(racedayinfo.country.code)
                    raceday.country_domestic_text = unicode(racedayinfo.country.domesticText)
                    raceday.country_english_text = str(racedayinfo.country.englishText)
                    first_race_date = util.strings_to_date(
                        racedayinfo.firstRacePostTime.date.year,
                        racedayinfo.firstRacePostTime.date.month,
                        racedayinfo.firstRacePostTime.date.date
                    )
                    raceday.first_race_posttime_date = first_race_date
                    first_race_time = util.strings_to_time(
                        hour=racedayinfo.firstRacePostTime.time.hour,
                        minute=racedayinfo.firstRacePostTime.time.minute,
                        second=racedayinfo.firstRacePostTime.time.second,
                        tenth=racedayinfo.firstRacePostTime.time.tenth
                    )
                    raceday.first_race_posttime_time = first_race_time
                    first_race_time_utc = util.strings_to_time(
                        hour=racedayinfo.firstRacePostTimeUTC.time.hour,
                        minute=racedayinfo.firstRacePostTimeUTC.time.minute,
                        second=racedayinfo.firstRacePostTimeUTC.time.second,
                        tenth=racedayinfo.firstRacePostTimeUTC.time.tenth
                    )
                    raceday.first_race_posttime_utc_time = first_race_time_utc
                    raceday.includes_final_race = bool(racedayinfo.includesFinalRace)
                    raceday.international = bool(racedayinfo.international)
                    raceday.international_betting = bool(racedayinfo.internationalBetting)
                    raceday.meeting_number = int(racedayinfo.meetingNumber)
                    raceday.meetingtype_code = str(racedayinfo.meetingType.code)
                    raceday.meetingtype_domestic_text = str(racedayinfo.meetingType.domesticText)
                    raceday.meetingtype_english_text = str(racedayinfo.meetingType.englishText)
                    raceday.racecard_available = bool(racedayinfo.raceCardAvailable)
                    raceday.raceday_date = raceday_date
                    raceday.trot = bool(racedayinfo.trot)
                    raceday.track_id = track.id
                    db.create(raceday)

                    races_and_bettypes = \
                        get_races_and_bettypes(
                            racedayinfo=racedayinfo,
                            filename=filename
                        )

                    for raceinfo in racedayinfo.raceInfos.getchildren():
                        race_nr = int(raceinfo.raceNr)
                        race = db.Race.read(
                            raceday_date=raceday_date, 
                            race_nr=race_nr,
                            track_atg_id=track_atg_id
                        )
                        if race is None:
                            race = db.Race()
                            race.has_result = bool(raceinfo.hasResult)
                            race.post_time = util.strings_to_time(
                                hour=raceinfo.postTime.hour,
                                minute=raceinfo.postTime.minute,
                                second=raceinfo.postTime.second,
                                tenth=raceinfo.postTime.tenth
                            )
                            race.post_time_utc = util.strings_to_time(
                                hour=raceinfo.postTimeUTC.hour,
                                minute=raceinfo.postTimeUTC.minute,
                                second=raceinfo.postTimeUTC.second,
                                tenth=raceinfo.postTimeUTC.tenth
                            )
                            race.race_nr = race_nr
                            race.race_type_code = str(raceinfo.raceType.code)
                            race.race_type_domestic_text = str(raceinfo.raceType.domesticText)
                            race.race_type_english_text = str(raceinfo.raceType.englishText)
                            race.track_surface_code = unicode(raceinfo.trackSurface.code)
                            race.track_surface_domestic_text = unicode(raceinfo.trackSurface.domesticText)
                            race.track_surface_english_text = str(raceinfo.trackSurface.englishText)
                            race.raceday_id = raceday.id
                            for bettype in races_and_bettypes[race_nr]:
                                if isinstance(bettype, db.BettypeChild):
                                    race.bettype_childs.append(bettype)
                                else:
                                    race.bettypes.append(bettype)
                            db.create(race)
                    
            now = datetime.datetime.now()
            loaded_file = db.LoadedEODFiles(filename=filename, loadtime=now)
            db.create(entity=loaded_file)

def get_races_and_bettypes(racedayinfo=None, filename=None):
    '''
    Create struct containing race numbers and 
    all bet type objects belonging to each race 
    '''
    bettype_nbr_of_legs_index = {
        'DD':2,
        'V3':3,
        'V65':6,
        'P':0,
        'TV':0,
        'V':0,
        'T':0,
        'LD':2,
        'V5':5,
        'V4':4,
        'K':0,
        'V75':7,
        'SK':0,
        'V86':8,
        'V64':6
    }
    
    races_and_bettypes = {}
    for bettype in racedayinfo.betTypes.getchildren():
        # TODO: Create static list to avoid this check 
        # every time?
        bettype_name_code = str(bettype.name.code)
        bettype_entity = db.Bettype.read(bettype_name_code)
        if bettype_entity is None:
            bettype_entity = db.Bettype()
            bettype_entity.name_code = bettype_name_code
            bettype_entity.name_domestic_text = str(bettype.name.domesticText)
            db.create(bettype_entity)
        try:
            nbr_of_legs = bettype_nbr_of_legs_index[bettype.name.code]
        except KeyError:
            LOG.exception('Bet type not registered: ' + bettype_name_code)
            continue
        race_numbers = []
        for race_nr in bettype.races.getchildren():
            race_numbers.append(race_nr)
        if len(race_numbers) == 0:
            LOG.info(
                'Bet type ' + bettype_name_code + \
                ' is missing races in ' + filename
            )
            continue
        # All races will have bettype_code, e.g. V, P and V75
        for race_nbr in race_numbers:
            if race_nbr not in races_and_bettypes:
                races_and_bettypes[race_nbr] = set()
            races_and_bettypes[race_nbr].add(bettype_entity)
        # All combo bets need bettype sub-parts like V75-1 and DD-2
        if nbr_of_legs > 0:
            for leg_nbr in range(nbr_of_legs):
                bettype_child_name = bettype.name.code + '-' + str(leg_nbr+1)
                bettype_child_entity = \
                    db.BettypeChild.read(name_code_child=bettype_child_name)
                if bettype_child_entity is None:
                    bettype_child_entity = db.BettypeChild()
                    bettype_child_entity.name_code_child = bettype_child_name
                    bettype_child_entity.bettype_id = bettype_entity.id
                    db.create(bettype_child_entity)
                race_nbr = race_numbers[leg_nbr]
                if race_nbr not in races_and_bettypes:
                    races_and_bettypes[race_nbr] = set()
                races_and_bettypes[race_nbr].add(bettype_child_entity)
    return races_and_bettypes    

def print_all_data(datadir=None):
    '''
    Iterate over all saved (local) fetchRaceDayCalendar files and
    print the data.
    '''
    filelist = sorted(util.list_files_with_path(datadir))
    data_filelist = [f for f in filelist if 'fetchRaceDayCalendar' in f]
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
        racedaycalendar = root.Body.fetchRaceDayCalendarResponse.result
        print(racedaycalendar.fromdate.date)
        print(racedaycalendar.fromdate.month)
        print(racedaycalendar.fromdate.year)
        print(racedaycalendar.todate.date)
        print(racedaycalendar.todate.month)
        print(racedaycalendar.todate.year)
        
        for racedayinfo in racedaycalendar.raceDayInfos.getchildren():
            print(racedayinfo.country.code)
            print(racedayinfo.firstRacePostTime.date.date)
            print(racedayinfo.firstRacePostTime.date.month)
            print(racedayinfo.firstRacePostTime.date.year)
            print(racedayinfo.firstRacePostTime.time.hour)
            print(racedayinfo.firstRacePostTime.time.minute)
            print(racedayinfo.firstRacePostTime.time.second)
            print(racedayinfo.firstRacePostTime.time.tenth)
            print(racedayinfo.firstRacePostTimeUTC.date.date)
            print(racedayinfo.firstRacePostTimeUTC.date.month)
            print(racedayinfo.firstRacePostTimeUTC.date.year)
            print(racedayinfo.firstRacePostTimeUTC.time.hour)
            print(racedayinfo.firstRacePostTimeUTC.time.minute)
            print(racedayinfo.firstRacePostTimeUTC.time.second)
            print(racedayinfo.firstRacePostTimeUTC.time.tenth)
            print(racedayinfo.includesFinalRace)
            print(racedayinfo.international)
            print(racedayinfo.internationalBetting)
            print(racedayinfo.itspEventCode)
            print(racedayinfo.meetingNumber)
            print(racedayinfo.meetingType.code)
            print(racedayinfo.meetingType.domesticText)
            print(racedayinfo.meetingType.englishText)
            print(racedayinfo.raceCardAvailable)
            print(racedayinfo.raceDayDate.date)
            print(racedayinfo.raceDayDate.month)
            print(racedayinfo.raceDayDate.year)
            print(racedayinfo.track.code)
            print(racedayinfo.track.domesticText)
            print(racedayinfo.track.englishText)
            print(racedayinfo.trackKey.trackId)
            print(racedayinfo.trot)

            for bettype in racedayinfo.betTypes.getchildren():
                print(bettype.hasResult)
                print(bettype.name.code)
                print(bettype.name.domesticText)
                print(bettype.name.englishText)
                print(bettype.national)
                for race_nr in bettype.races.getchildren():
                    print(race_nr)
        
            for raceinfo in racedayinfo.raceInfos.getchildren():
                for bettype_code in raceinfo.betTypeCodes.getchildren():
                    print(bettype_code)
                print(raceinfo.hasResult)
                print(raceinfo.postTime.hour)
                print(raceinfo.postTime.minute)
                print(raceinfo.postTime.second)
                print(raceinfo.postTime.tenth)
                print(raceinfo.postTimeUTC.hour)
                print(raceinfo.postTimeUTC.minute)
                print(raceinfo.postTimeUTC.second)
                print(raceinfo.postTimeUTC.tenth)
                print(raceinfo.raceNr)
                print(raceinfo.raceType.code)
                print(raceinfo.raceType.domesticText)
                print(raceinfo.raceType.englishText)
                print(raceinfo.trackSurface.code)
                print(raceinfo.trackSurface.domesticText)
                print(raceinfo.trackSurface.englishText)

if __name__ == "__main__":
    pass
    